-- ============================================================================
-- FIX: Remove assigned_user_id reference from exchange approval
-- ============================================================================
-- This removes the backward compatibility code that tries to update the
-- deleted assigned_user_id column when approving exchange requests.
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

        -- NOTE: assigned_user_id column has been removed - all assignments now use schedule_assignments table
        -- No backward compatibility update needed

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
            'new_user', v_request.requested_name,
            'admin', v_admin_name
        );

    ELSIF p_action = 'reject' THEN
        -- Update the exchange request status
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
            'admin', v_admin_name
        );

    ELSIF p_action = 'cancel' THEN
        -- Update the exchange request status
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

    -- Should never reach here
    RETURN json_build_object(
        'success', false,
        'error', 'Invalid action'
    );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION admin_manage_schedule_exchange_request TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '✅ Exchange Approval Function Fixed!';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 What was fixed:';
    RAISE NOTICE '  - Removed reference to deleted assigned_user_id column';
    RAISE NOTICE '  - Uses only schedule_assignments table now';
    RAISE NOTICE '  - No more backward compatibility code';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Function updated: admin_manage_schedule_exchange_request';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 You can now approve/reject exchange requests!';
    RAISE NOTICE '============================================================================';
END;
$$;



