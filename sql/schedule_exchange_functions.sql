-- Schedule Exchange System Functions
-- This file contains all the database functions needed for the schedule exchange system

-- 1. Create Schedule Exchange Request
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
    AND assigned_user_id = p_requester_user_id
    AND status = 'active'
    AND is_active = true;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schedule not found or not owned by requester'
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
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Requested user not found or inactive'
        );
    END IF;

    -- Check for existing pending request for this schedule
    IF EXISTS (
        SELECT 1 FROM schedule_exchange_requests
        WHERE schedule_id = p_schedule_id
        AND status = 'pending'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'A pending exchange request already exists for this schedule'
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

-- 2. Admin Manage Schedule Exchange Request
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
        -- Check if requested user has conflicts
        IF EXISTS (
            SELECT 1 FROM employee_schedules
            WHERE assigned_user_id = v_request.requested_user_id
            AND status = 'active'
            AND is_active = true
            AND (
                (start_date_time <= v_request.end_date_time AND end_date_time >= v_request.start_date_time)
                OR (start_date_time <= v_request.start_date_time AND end_date_time >= v_request.end_date_time)
            )
        ) THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Requested user has a conflicting schedule'
            );
        END IF;

        -- Update the schedule assignment
        UPDATE employee_schedules
        SET assigned_user_id = v_request.requested_user_id,
            updated_at = NOW()
        WHERE id = v_request.schedule_id;

        -- Update the exchange request
        UPDATE schedule_exchange_requests
        SET status = 'approved',
            admin_id = p_admin_id,
            admin_notes = p_admin_notes,
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_request_id;

        RETURN json_build_object(
            'success', true,
            'message', 'Exchange request approved successfully. Schedule has been transferred.',
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
            admin_id = p_admin_id,
            admin_notes = p_admin_notes,
            rejection_reason = p_rejection_reason,
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_request_id;

        RETURN json_build_object(
            'success', true,
            'message', 'Exchange request rejected successfully',
            'rejection_reason', p_rejection_reason
        );

    ELSIF p_action = 'cancel' THEN
        -- Update the exchange request
        UPDATE schedule_exchange_requests
        SET status = 'cancelled',
            admin_id = p_admin_id,
            admin_notes = p_admin_notes,
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_request_id;

        RETURN json_build_object(
            'success', true,
            'message', 'Exchange request cancelled successfully'
        );
    END IF;

    RETURN json_build_object(
        'success', false,
        'error', 'Unknown action'
    );
END;
$$;

-- 3. Get Schedule Exchange Requests
CREATE OR REPLACE FUNCTION get_schedule_exchange_requests(
    p_user_id UUID DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_request_type TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_requests JSON;
    v_total_count INTEGER;
BEGIN
    -- Build the query based on parameters
    WITH filtered_requests AS (
        SELECT 
            ser.id as request_id,
            ser.status,
            ser.request_type,
            ser.request_reason,
            ser.request_notes,
            ser.admin_notes,
            ser.rejection_reason,
            ser.created_at,
            ser.reviewed_at,
            ser.expires_at,
            
            -- Schedule info
            es.id as schedule_id,
            es.title,
            es.start_date_time,
            es.end_date_time,
            es.location,
            es.department,
            es.description,
            
            -- Requester info
            ru.id as requester_id,
            ru.full_name as requester_name,
            ru.employee_id as requester_employee_id,
            ru.email as requester_email,
            
            -- Requested user info
            rd.id as requested_id,
            rd.full_name as requested_name,
            rd.employee_id as requested_employee_id,
            rd.email as requested_email,
            
            -- Admin info
            au.full_name as admin_name,
            au.employee_id as admin_employee_id
            
        FROM schedule_exchange_requests ser
        JOIN employee_schedules es ON ser.schedule_id = es.id
        JOIN my_users ru ON ser.requester_user_id = ru.id
        JOIN my_users rd ON ser.requested_user_id = rd.id
        LEFT JOIN my_users au ON ser.admin_id = au.id
        WHERE 
            (p_user_id IS NULL OR ser.requester_user_id = p_user_id OR ser.requested_user_id = p_user_id)
            AND (p_status IS NULL OR ser.status = p_status)
            AND (p_request_type IS NULL OR ser.request_type = p_request_type)
        ORDER BY ser.created_at DESC
        LIMIT p_limit OFFSET p_offset
    ),
    total_count AS (
        SELECT COUNT(*) as count
        FROM schedule_exchange_requests ser
        WHERE 
            (p_user_id IS NULL OR ser.requester_user_id = p_user_id OR ser.requested_user_id = p_user_id)
            AND (p_status IS NULL OR ser.status = p_status)
            AND (p_request_type IS NULL OR ser.request_type = p_request_type)
    )
    SELECT 
        json_agg(
            json_build_object(
                'request_id', request_id,
                'request_details', json_build_object(
                    'status', status,
                    'request_type', request_type,
                    'request_reason', request_reason,
                    'request_notes', request_notes,
                    'admin_notes', admin_notes,
                    'rejection_reason', rejection_reason,
                    'created_at', created_at,
                    'reviewed_at', reviewed_at,
                    'expires_at', expires_at
                ),
                'schedule_info', json_build_object(
                    'id', schedule_id,
                    'title', title,
                    'start_time', start_date_time,
                    'end_time', end_date_time,
                    'location', location,
                    'department', department,
                    'description', description
                ),
                'requester_info', json_build_object(
                    'id', requester_id,
                    'name', requester_name,
                    'employee_id', requester_employee_id,
                    'email', requester_email
                ),
                'requested_user_info', json_build_object(
                    'id', requested_id,
                    'name', requested_name,
                    'employee_id', requested_employee_id,
                    'email', requested_email
                ),
                'admin_info', CASE 
                    WHEN admin_name IS NOT NULL THEN json_build_object(
                        'name', admin_name,
                        'employee_id', admin_employee_id
                    )
                    ELSE NULL
                END
            )
        ),
        (SELECT count FROM total_count)
    INTO v_requests, v_total_count
    FROM filtered_requests;

    RETURN json_build_object(
        'success', true,
        'requests', COALESCE(v_requests, '[]'::json),
        'total_count', v_total_count,
        'limit', p_limit,
        'offset', p_offset
    );
END;
$$;

-- 4. Cancel Schedule Exchange Request (User)
CREATE OR REPLACE FUNCTION cancel_schedule_exchange_request(
    p_user_id UUID,
    p_request_id UUID,
    p_cancellation_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
BEGIN
    -- Validate inputs
    IF p_user_id IS NULL OR p_request_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Missing required parameters'
        );
    END IF;

    -- Get exchange request details
    SELECT * INTO v_request
    FROM schedule_exchange_requests
    WHERE id = p_request_id
    AND requester_user_id = p_user_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Exchange request not found or not owned by user'
        );
    END IF;

    -- Check if request is still pending
    IF v_request.status != 'pending' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Only pending requests can be cancelled'
        );
    END IF;

    -- Update the exchange request
    UPDATE schedule_exchange_requests
    SET status = 'cancelled',
        cancellation_reason = p_cancellation_reason,
        updated_at = NOW()
    WHERE id = p_request_id;

    RETURN json_build_object(
        'success', true,
        'message', 'Exchange request cancelled successfully'
    );
END;
$$;

-- 5. Check Schedule Conflict
CREATE OR REPLACE FUNCTION check_schedule_conflict(
    p_assigned_user_id UUID,
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conflict_count INTEGER;
BEGIN
    -- Check for conflicts
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM employee_schedules
    WHERE assigned_user_id = p_assigned_user_id
    AND status = 'active'
    AND is_active = true
    AND (
        (start_date_time <= p_end_time AND end_date_time >= p_start_time)
        OR (start_date_time <= p_start_time AND end_date_time >= p_end_time)
    );

    -- Return true if there's a conflict (count > 0)
    RETURN v_conflict_count > 0;
END;
$$;

-- 6. Create the schedule_exchange_requests table if it doesn't exist
CREATE TABLE IF NOT EXISTS schedule_exchange_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_user_id UUID NOT NULL REFERENCES my_users(id),
    requested_user_id UUID NOT NULL REFERENCES my_users(id),
    schedule_id UUID NOT NULL REFERENCES employee_schedules(id),
    request_reason TEXT,
    request_notes TEXT,
    request_type TEXT NOT NULL DEFAULT 'exchange',
    status TEXT NOT NULL DEFAULT 'pending',
    admin_id UUID REFERENCES my_users(id),
    admin_notes TEXT,
    rejection_reason TEXT,
    cancellation_reason TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMP,
    
    CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'expired')),
    CONSTRAINT valid_request_type CHECK (request_type IN ('exchange', 'swap', 'coverage'))
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_schedule_exchange_requests_requester ON schedule_exchange_requests(requester_user_id);
CREATE INDEX IF NOT EXISTS idx_schedule_exchange_requests_requested ON schedule_exchange_requests(requested_user_id);
CREATE INDEX IF NOT EXISTS idx_schedule_exchange_requests_schedule ON schedule_exchange_requests(schedule_id);
CREATE INDEX IF NOT EXISTS idx_schedule_exchange_requests_status ON schedule_exchange_requests(status);
CREATE INDEX IF NOT EXISTS idx_schedule_exchange_requests_created ON schedule_exchange_requests(created_at);

-- Add RLS policies if needed
ALTER TABLE schedule_exchange_requests ENABLE ROW LEVEL SECURITY;

-- Policy for users to see their own requests
CREATE POLICY "Users can view their own exchange requests" ON schedule_exchange_requests
    FOR SELECT USING (
        requester_user_id = auth.uid() OR 
        requested_user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- Policy for users to create their own requests
CREATE POLICY "Users can create exchange requests" ON schedule_exchange_requests
    FOR INSERT WITH CHECK (requester_user_id = auth.uid());

-- Policy for admins to update requests
CREATE POLICY "Admins can update exchange requests" ON schedule_exchange_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );
