-- ============================================================================
-- UPDATE SCHEDULE EXCHANGE SYSTEM FOR MULTI-USER SCHEDULES
-- ============================================================================
-- This updates the schedule exchange logic to work with the new multi-user
-- schedule assignment system using the schedule_assignments table.
-- ============================================================================

-- Drop the old function
DROP FUNCTION IF EXISTS admin_manage_schedule_exchange_request(UUID, UUID, TEXT, TEXT, TEXT);

-- Create updated admin_manage_schedule_exchange_request function
CREATE OR REPLACE FUNCTION admin_manage_schedule_exchange_request(
    p_admin_id UUID,
    p_request_id UUID,
    p_action TEXT,
    p_admin_notes TEXT DEFAULT NULL,
    p_rejection_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
    v_schedule RECORD;
    v_requester_name TEXT;
    v_requested_name TEXT;
    v_admin_name TEXT;
BEGIN
    -- Validate inputs
    IF p_admin_id IS NULL OR p_request_id IS NULL OR p_action IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Missing required parameters'
        );
    END IF;

    -- Validate action
    IF p_action NOT IN ('approve', 'reject', 'cancel') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid action. Must be approve, reject, or cancel'
        );
    END IF;

    -- Check if admin has proper permissions
    IF NOT EXISTS (
        SELECT 1 FROM my_users
        WHERE id = p_admin_id
        AND user_role IN ('admin', 'ceo', 'manager')
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unauthorized: Only admins can manage exchange requests'
        );
    END IF;

    -- Get exchange request details
    SELECT ser.*, es.*, 
           ru.full_name as requester_name,
           rd.full_name as requested_name
    INTO v_request
    FROM schedule_exchange_requests ser
    JOIN employee_schedules es ON ser.schedule_id = es.id
    JOIN my_users ru ON ser.requester_user_id = ru.id
    JOIN my_users rd ON ser.requested_user_id = rd.id
    WHERE ser.id = p_request_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Exchange request not found'
        );
    END IF;

    -- Check if request is still pending
    IF v_request.status != 'pending' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Exchange request is no longer pending'
        );
    END IF;

    -- Check if request has expired
    IF v_request.expires_at < NOW() THEN
        -- Auto-expire the request
        UPDATE schedule_exchange_requests
        SET status = 'expired',
            updated_at = NOW()
        WHERE id = p_request_id;
        
        RETURN json_build_object(
            'success', false,
            'error', 'Exchange request has expired'
        );
    END IF;

    -- Get admin name
    SELECT full_name INTO v_admin_name FROM my_users WHERE id = p_admin_id;

    -- Handle different actions
    IF p_action = 'approve' THEN
        -- Check if requester is still assigned to this schedule
        IF NOT EXISTS (
            SELECT 1 FROM schedule_assignments
            WHERE schedule_id = v_request.schedule_id
            AND user_id = v_request.requester_user_id
            AND is_active = true
            AND status = 'active'
        ) THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Requester is no longer assigned to this schedule'
            );
        END IF;

        -- Check if requested user has conflicts using the new assignment system
        IF EXISTS (
            SELECT 1 
            FROM employee_schedules es
            JOIN schedule_assignments sa ON es.id = sa.schedule_id
            WHERE sa.user_id = v_request.requested_user_id
            AND sa.is_active = true
            AND sa.status = 'active'
            AND es.status = 'active'
            AND es.is_active = true
            AND (
                (es.start_date_time, es.end_date_time) OVERLAPS 
                (v_request.start_date_time, v_request.end_date_time)
            )
        ) THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Requested user has a conflicting schedule'
            );
        END IF;

        -- UPDATED: Use schedule_assignments instead of direct employee_schedules update
        -- Remove the requester from the schedule
        UPDATE schedule_assignments
        SET status = 'removed',
            is_active = false,
            notes = COALESCE(notes, '') || ' | Removed via exchange request',
            updated_at = NOW()
        WHERE schedule_id = v_request.schedule_id
        AND user_id = v_request.requester_user_id;

        -- Add the requested user to the schedule
        INSERT INTO schedule_assignments (
            schedule_id,
            user_id,
            assigned_by_admin_id,
            status,
            notes,
            is_active,
            assigned_at,
            created_at,
            updated_at
        ) VALUES (
            v_request.schedule_id,
            v_request.requested_user_id,
            p_admin_id,
            'active',
            'Assigned via approved exchange request',
            true,
            NOW(),
            NOW(),
            NOW()
        )
        ON CONFLICT (schedule_id, user_id) 
        DO UPDATE SET
            status = 'active',
            is_active = true,
            assigned_by_admin_id = p_admin_id,
            notes = 'Re-assigned via approved exchange request',
            updated_at = NOW();

        -- Also update the old employee_schedules.assigned_user_id for backward compatibility
        -- Only if it's a single-user schedule
        UPDATE employee_schedules
        SET assigned_user_id = v_request.requested_user_id,
            updated_at = NOW()
        WHERE id = v_request.schedule_id
        AND (is_multi_user = false OR is_multi_user IS NULL);

        -- Update the exchange request status
        UPDATE schedule_exchange_requests
        SET status = 'approved',
            reviewed_by_admin_id = p_admin_id,
            admin_notes = p_admin_notes,
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_request_id;

        RETURN json_build_object(
            'success', true,
            'message', 'Exchange request approved. Schedule assignment transferred.',
            'schedule_title', v_request.title,
            'old_user', v_request.requester_name,
            'new_user', v_request.requested_name
        );

    ELSIF p_action = 'reject' THEN
        -- Validate rejection reason
        IF p_rejection_reason IS NULL OR TRIM(p_rejection_reason) = '' THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Rejection reason is required'
            );
        END IF;

        -- Update the exchange request
        UPDATE schedule_exchange_requests
        SET status = 'rejected',
            reviewed_by_admin_id = p_admin_id,
            admin_notes = p_admin_notes,
            rejection_reason = p_rejection_reason,
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_request_id;

        RETURN json_build_object(
            'success', true,
            'message', 'Exchange request rejected',
            'schedule_title', v_request.title,
            'requester', v_request.requester_name,
            'rejection_reason', p_rejection_reason
        );

    ELSIF p_action = 'cancel' THEN
        -- Update the exchange request
        UPDATE schedule_exchange_requests
        SET status = 'cancelled',
            updated_at = NOW()
        WHERE id = p_request_id;

        RETURN json_build_object(
            'success', true,
            'message', 'Exchange request cancelled',
            'schedule_title', v_request.title
        );
    END IF;

    RETURN json_build_object(
        'success', false,
        'error', 'Unknown error occurred'
    );
END;
$$;

-- Update the create_schedule_exchange_request function to check schedule_assignments
DROP FUNCTION IF EXISTS create_schedule_exchange_request(UUID, UUID, UUID, TEXT, TEXT, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION create_schedule_exchange_request(
    p_requester_user_id UUID,
    p_schedule_id UUID,
    p_requested_user_id UUID,
    p_request_reason TEXT DEFAULT NULL,
    p_request_notes TEXT DEFAULT NULL,
    p_request_type TEXT DEFAULT 'exchange',
    p_expires_in_days INTEGER DEFAULT 7
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_schedule RECORD;
    v_requester_name TEXT;
    v_requested_name TEXT;
    v_expires_at TIMESTAMP;
    v_request_id UUID;
BEGIN
    -- Validate inputs
    IF p_requester_user_id IS NULL OR p_schedule_id IS NULL OR p_requested_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Missing required parameters'
        );
    END IF;

    -- Check if requester and requested user are different
    IF p_requester_user_id = p_requested_user_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot request exchange with yourself'
        );
    END IF;

    -- Get schedule details
    SELECT * INTO v_schedule
    FROM employee_schedules
    WHERE id = p_schedule_id
    AND status = 'active'
    AND is_active = true;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schedule not found or not active'
        );
    END IF;

    -- UPDATED: Check if requester is assigned using schedule_assignments table
    IF NOT EXISTS (
        SELECT 1 FROM schedule_assignments
        WHERE schedule_id = p_schedule_id
        AND user_id = p_requester_user_id
        AND is_active = true
        AND status = 'active'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'You are not assigned to this schedule'
        );
    END IF;

    -- Check if schedule is in the future
    IF v_schedule.start_date_time <= NOW() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot exchange schedules that have already started'
        );
    END IF;

    -- Check if requested user exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM my_users 
        WHERE id = p_requested_user_id 
        AND is_active = true
        AND user_role = 'employee'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Requested user not found, inactive, or not an employee'
        );
    END IF;

    -- Check if requested user is already assigned to this schedule
    IF EXISTS (
        SELECT 1 FROM schedule_assignments
        WHERE schedule_id = p_schedule_id
        AND user_id = p_requested_user_id
        AND is_active = true
        AND status = 'active'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Requested user is already assigned to this schedule'
        );
    END IF;

    -- Check for existing pending request for this schedule by this requester
    IF EXISTS (
        SELECT 1 FROM schedule_exchange_requests
        WHERE schedule_id = p_schedule_id
        AND requester_user_id = p_requester_user_id
        AND status = 'pending'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'You already have a pending exchange request for this schedule'
        );
    END IF;

    -- Get user names
    SELECT full_name INTO v_requester_name FROM my_users WHERE id = p_requester_user_id;
    SELECT full_name INTO v_requested_name FROM my_users WHERE id = p_requested_user_id;

    -- Calculate expiration date
    v_expires_at := NOW() + (p_expires_in_days || ' days')::INTERVAL;

    -- Create the exchange request
    INSERT INTO schedule_exchange_requests (
        requester_user_id,
        requested_user_id,
        schedule_id,
        request_reason,
        request_notes,
        request_type,
        status,
        expires_at,
        created_at
    ) VALUES (
        p_requester_user_id,
        p_requested_user_id,
        p_schedule_id,
        p_request_reason,
        p_request_notes,
        p_request_type,
        'pending',
        v_expires_at,
        NOW()
    ) RETURNING id INTO v_request_id;

    RETURN json_build_object(
        'success', true,
        'message', 'Exchange request created successfully',
        'request_id', v_request_id,
        'schedule_title', v_schedule.title,
        'requester_name', v_requester_name,
        'requested_name', v_requested_name
    );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION admin_manage_schedule_exchange_request TO authenticated;
GRANT EXECUTE ON FUNCTION create_schedule_exchange_request TO authenticated;

-- ============================================================================
-- Verification and Testing
-- ============================================================================

-- Test query to check if functions exist
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('admin_manage_schedule_exchange_request', 'create_schedule_exchange_request')
ORDER BY routine_name;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'Schedule Exchange System Updated for Multi-User Schedules';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Key Changes:';
    RAISE NOTICE '1. ✓ Exchange now uses schedule_assignments table';
    RAISE NOTICE '2. ✓ Removes requester from schedule_assignments';
    RAISE NOTICE '3. ✓ Adds requested user to schedule_assignments';
    RAISE NOTICE '4. ✓ Maintains backward compatibility for single-user schedules';
    RAISE NOTICE '5. ✓ Checks conflicts using new assignment system';
    RAISE NOTICE '6. ✓ Validates requester is actually assigned';
    RAISE NOTICE '7. ✓ Prevents duplicate assignments';
    RAISE NOTICE '';
    RAISE NOTICE 'The schedule exchange system is now fully compatible with multi-user schedules!';
    RAISE NOTICE '============================================================================';
END $$;

