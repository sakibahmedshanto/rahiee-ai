-- 🔧 COMPREHENSIVE SCHEDULE EXCHANGE FIX
-- This script fixes all potential issues with the schedule exchange system

-- =====================================================
-- STEP 1: Fix RLS Policies (Critical Issue)
-- =====================================================
-- The RLS policies might be preventing the schedule updates

-- Drop existing policies that might be interfering
DROP POLICY IF EXISTS "Users can view assigned schedules" ON employee_schedules;
DROP POLICY IF EXISTS "Admins can view all schedules" ON employee_schedules;
DROP POLICY IF EXISTS "Users can update own schedules" ON employee_schedules;
DROP POLICY IF EXISTS "Admins can update schedules" ON employee_schedules;

-- Create proper RLS policies for employee_schedules
CREATE POLICY "Users can view assigned schedules" ON employee_schedules
    FOR SELECT USING (
        assigned_user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM schedule_exchange_requests ser
            WHERE ser.schedule_id = employee_schedules.id
            AND ser.requested_user_id = auth.uid()
            AND ser.status = 'approved'
        ) OR
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'super_admin')
        )
    );

-- Policy for admins to update schedules (needed for exchange transfers)
CREATE POLICY "Admins can update schedules" ON employee_schedules
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'super_admin')
        )
    );

-- Policy for admins to view all schedules
CREATE POLICY "Admins can view all schedules" ON employee_schedules
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'super_admin')
        )
    );

-- =====================================================
-- STEP 2: Fix Schedule Exchange Requests RLS Policies
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own exchange requests" ON schedule_exchange_requests;
DROP POLICY IF EXISTS "Users can create exchange requests" ON schedule_exchange_requests;
DROP POLICY IF EXISTS "Admins can update exchange requests" ON schedule_exchange_requests;

-- Create proper policies
CREATE POLICY "Users can view their own exchange requests" ON schedule_exchange_requests
    FOR SELECT USING (
        requester_user_id = auth.uid() OR 
        requested_user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Users can create exchange requests" ON schedule_exchange_requests
    FOR INSERT WITH CHECK (requester_user_id = auth.uid());

CREATE POLICY "Admins can update exchange requests" ON schedule_exchange_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'super_admin')
        )
    );

-- =====================================================
-- STEP 3: Enhanced Admin Manage Function with Better Error Handling
-- =====================================================
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
    v_old_assigned_user_id UUID;
    v_new_assigned_user_id UUID;
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

    -- Get exchange request details with more comprehensive data
    SELECT ser.*, es.*, 
           ru.full_name as requester_name,
           rd.full_name as requested_name,
           es.assigned_user_id as current_assigned_user_id
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
            'error', 'Exchange request is no longer pending. Current status: ' || v_request.status
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

    -- Verify the schedule still belongs to the requester
    IF v_request.current_assigned_user_id != v_request.requester_user_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schedule assignment has changed. Cannot process exchange.'
        );
    END IF;

    -- Get admin name
    SELECT full_name INTO v_admin_name FROM my_users WHERE id = p_admin_id;

    -- Handle different actions
    IF p_action = 'approve' THEN
        -- Store old and new assigned user IDs for logging
        v_old_assigned_user_id := v_request.requester_user_id;
        v_new_assigned_user_id := v_request.requested_user_id;

        -- Check if requested user has conflicts (more comprehensive check)
        IF EXISTS (
            SELECT 1 FROM employee_schedules
            WHERE assigned_user_id = v_new_assigned_user_id
            AND status = 'active'
            AND is_active = true
            AND id != v_request.schedule_id  -- Exclude the current schedule
            AND (
                (start_date_time < v_request.end_date_time AND end_date_time > v_request.start_date_time)
            )
        ) THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Requested user has a conflicting schedule during this time period'
            );
        END IF;

        -- Start transaction for atomic operation
        BEGIN
            -- Update the schedule assignment
            UPDATE employee_schedules
            SET assigned_user_id = v_new_assigned_user_id,
                updated_at = NOW()
            WHERE id = v_request.schedule_id;

            -- Check if the update was successful
            IF NOT FOUND THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Failed to update schedule assignment'
                );
            END IF;

            -- Update the exchange request
            UPDATE schedule_exchange_requests
            SET status = 'approved',
                admin_id = p_admin_id,
                admin_notes = p_admin_notes,
                reviewed_at = NOW(),
                updated_at = NOW()
            WHERE id = p_request_id;

            -- Log the successful transfer
            INSERT INTO schedule_deletion_log (
                schedules_deleted,
                attendance_records_deleted,
                exchange_requests_deleted,
                deletion_reason,
                executed_by,
                success
            ) VALUES (
                0, 0, 0,
                'schedule_exchange_approved_' || p_request_id,
                p_admin_id,
                true
            );

            RETURN json_build_object(
                'success', true,
                'message', 'Exchange request approved successfully. Schedule has been transferred.',
                'schedule_title', v_request.title,
                'old_user', v_request.requester_name,
                'new_user', v_request.requested_name,
                'old_user_id', v_old_assigned_user_id,
                'new_user_id', v_new_assigned_user_id,
                'schedule_id', v_request.schedule_id,
                'exchange_request_id', p_request_id
            );

        EXCEPTION
            WHEN OTHERS THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Database error during schedule transfer: ' || SQLERRM
                );
        END;

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

-- =====================================================
-- STEP 4: Enhanced get_employee_schedules Function
-- =====================================================
-- Make sure the RPC function properly handles exchanged schedules

CREATE OR REPLACE FUNCTION get_employee_schedules(
    p_user_id UUID,
    p_date DATE DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_include_exchanges BOOLEAN DEFAULT true,
    p_include_given_schedules BOOLEAN DEFAULT false,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    schedules JSON;
    start_filter TIMESTAMPTZ;
    end_filter TIMESTAMPTZ;
    total_count INTEGER;
BEGIN
    -- Determine date range
    IF p_date IS NOT NULL THEN
        start_filter := p_date::TIMESTAMPTZ;
        end_filter := (p_date + INTERVAL '1 day')::TIMESTAMPTZ;
    ELSIF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
        start_filter := p_start_date::TIMESTAMPTZ;
        end_filter := (p_end_date + INTERVAL '1 day')::TIMESTAMPTZ;
    ELSE
        start_filter := CURRENT_DATE::TIMESTAMPTZ;
        end_filter := (CURRENT_DATE + INTERVAL '1 day')::TIMESTAMPTZ;
    END IF;
    
    -- Get schedules with comprehensive exchange information
    WITH schedule_data AS (
        -- Directly assigned schedules
        SELECT 
            s.id,
            s.title,
            s.description,
            s.start_date_time,
            s.end_date_time,
            s.created_by_admin_id,
            s.assigned_user_id,
            s.actual_user_id,
            s.department,
            s.location,
            s.latitude,
            s.longitude,
            s.status,
            s.requirements,
            s.created_at,
            s.updated_at,
            s.notes,
            s.is_active,
            s.tags,
            s.custom_fields,
            s.assignment_history,
            'assigned' as schedule_type,
            NULL::UUID as exchange_request_id,
            NULL::TEXT as exchange_status,
            NULL::UUID as original_assignee_id,
            NULL::TEXT as original_assignee_name,
            NULL::UUID as exchange_requester_id,
            NULL::TEXT as exchange_requester_name,
            NULL::TIMESTAMPTZ as exchange_created_at,
            NULL::TIMESTAMPTZ as exchange_approved_at,
            u.full_name as assigned_user_name,
            u.employee_id as assigned_user_employee_id,
            admin.full_name as created_by_admin_name,
            admin.employee_id as created_by_admin_employee_id,
            CASE 
                WHEN s.start_date_time > NOW() THEN 'upcoming'
                WHEN s.start_date_time <= NOW() AND s.end_date_time >= NOW() THEN 'current'
                ELSE 'past'
            END as schedule_status,
            EXTRACT(EPOCH FROM (s.end_date_time - s.start_date_time))/3600 as duration_hours
        FROM employee_schedules s
        LEFT JOIN my_users u ON s.assigned_user_id = u.id
        LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
        WHERE s.assigned_user_id = p_user_id
        AND s.start_date_time >= start_filter
        AND s.start_date_time < end_filter
        AND s.is_active = true
        
        UNION ALL
        
        -- Schedules received through approved exchanges (if enabled)
        SELECT 
            s.id,
            s.title,
            s.description,
            s.start_date_time,
            s.end_date_time,
            s.created_by_admin_id,
            s.assigned_user_id,
            s.actual_user_id,
            s.department,
            s.location,
            s.latitude,
            s.longitude,
            s.status,
            s.requirements,
            s.created_at,
            s.updated_at,
            s.notes,
            s.is_active,
            s.tags,
            s.custom_fields,
            s.assignment_history,
            'received_via_exchange' as schedule_type,
            ser.id as exchange_request_id,
            ser.status as exchange_status,
            ser.requester_user_id as original_assignee_id,
            requester.full_name as original_assignee_name,
            ser.requester_user_id as exchange_requester_id,
            requester.full_name as exchange_requester_name,
            ser.created_at as exchange_created_at,
            ser.reviewed_at as exchange_approved_at,
            u.full_name as assigned_user_name,
            u.employee_id as assigned_user_employee_id,
            admin.full_name as created_by_admin_name,
            admin.employee_id as created_by_admin_employee_id,
            CASE 
                WHEN s.start_date_time > NOW() THEN 'upcoming'
                WHEN s.start_date_time <= NOW() AND s.end_date_time >= NOW() THEN 'current'
                ELSE 'past'
            END as schedule_status,
            EXTRACT(EPOCH FROM (s.end_date_time - s.start_date_time))/3600 as duration_hours
        FROM employee_schedules s
        JOIN schedule_exchange_requests ser ON s.id = ser.schedule_id
        LEFT JOIN my_users u ON s.assigned_user_id = u.id
        LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
        LEFT JOIN my_users requester ON ser.requester_user_id = requester.id
        WHERE ser.requested_user_id = p_user_id
        AND ser.status = 'approved'
        AND s.start_date_time >= start_filter
        AND s.start_date_time < end_filter
        AND s.is_active = true
        AND p_include_exchanges = true
        
        UNION ALL
        
        -- Schedules given away through approved exchanges (if enabled)
        SELECT 
            s.id,
            s.title,
            s.description,
            s.start_date_time,
            s.end_date_time,
            s.created_by_admin_id,
            s.assigned_user_id,
            s.actual_user_id,
            s.department,
            s.location,
            s.latitude,
            s.longitude,
            s.status,
            s.requirements,
            s.created_at,
            s.updated_at,
            s.notes,
            s.is_active,
            s.tags,
            s.custom_fields,
            s.assignment_history,
            'given_via_exchange' as schedule_type,
            ser.id as exchange_request_id,
            ser.status as exchange_status,
            ser.requested_user_id as original_assignee_id,
            requested.full_name as original_assignee_name,
            ser.requester_user_id as exchange_requester_id,
            requester.full_name as exchange_requester_name,
            ser.created_at as exchange_created_at,
            ser.reviewed_at as exchange_approved_at,
            u.full_name as assigned_user_name,
            u.employee_id as assigned_user_employee_id,
            admin.full_name as created_by_admin_name,
            admin.employee_id as created_by_admin_employee_id,
            CASE 
                WHEN s.start_date_time > NOW() THEN 'upcoming'
                WHEN s.start_date_time <= NOW() AND s.end_date_time >= NOW() THEN 'current'
                ELSE 'past'
            END as schedule_status,
            EXTRACT(EPOCH FROM (s.end_date_time - s.start_date_time))/3600 as duration_hours
        FROM employee_schedules s
        JOIN schedule_exchange_requests ser ON s.id = ser.schedule_id
        LEFT JOIN my_users u ON s.assigned_user_id = u.id
        LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
        LEFT JOIN my_users requester ON ser.requester_user_id = requester.id
        LEFT JOIN my_users requested ON ser.requested_user_id = requested.id
        WHERE ser.requester_user_id = p_user_id
        AND ser.status = 'approved'
        AND s.start_date_time >= start_filter
        AND s.start_date_time < end_filter
        AND s.is_active = true
        AND p_include_given_schedules = true
    ),
    paginated_schedules AS (
        SELECT *
        FROM schedule_data
        ORDER BY start_date_time ASC
        LIMIT p_limit OFFSET p_offset
    )
    SELECT 
        json_agg(
            json_build_object(
                'id', id,
                'title', title,
                'description', description,
                'start_date_time', start_date_time,
                'end_date_time', end_date_time,
                'created_by_admin_id', created_by_admin_id,
                'assigned_user_id', assigned_user_id,
                'actual_user_id', actual_user_id,
                'department', department,
                'location', location,
                'latitude', latitude,
                'longitude', longitude,
                'status', status,
                'requirements', requirements,
                'created_at', created_at,
                'updated_at', updated_at,
                'notes', notes,
                'is_active', is_active,
                'tags', tags,
                'custom_fields', custom_fields,
                'assignment_history', assignment_history,
                'schedule_type', schedule_type,
                'exchange_request_id', exchange_request_id,
                'exchange_status', exchange_status,
                'original_assignee_id', original_assignee_id,
                'original_assignee_name', original_assignee_name,
                'exchange_requester_id', exchange_requester_id,
                'exchange_requester_name', exchange_requester_name,
                'exchange_created_at', exchange_created_at,
                'exchange_approved_at', exchange_approved_at,
                'assigned_user_name', assigned_user_name,
                'assigned_user_employee_id', assigned_user_employee_id,
                'created_by_admin_name', created_by_admin_name,
                'created_by_admin_employee_id', created_by_admin_employee_id,
                'schedule_status', schedule_status,
                'duration_hours', duration_hours
            )
        ),
        COUNT(*) as total_count
    INTO schedules, total_count
    FROM paginated_schedules;
    
    -- Build comprehensive result
    result := json_build_object(
        'success', true,
        'user_id', p_user_id,
        'date_filter', CASE 
            WHEN p_date IS NOT NULL THEN json_build_object('type', 'single_date', 'date', p_date)
            WHEN p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN json_build_object('type', 'date_range', 'start_date', p_start_date, 'end_date', p_end_date)
            ELSE json_build_object('type', 'default', 'date', CURRENT_DATE)
        END,
        'include_exchanges', p_include_exchanges,
        'include_given_schedules', p_include_given_schedules,
        'schedules', COALESCE(schedules, '[]'::json),
        'pagination', json_build_object(
            'total_count', total_count,
            'limit', p_limit,
            'offset', p_offset,
            'has_more', (p_offset + p_limit) < total_count,
            'current_page', (p_offset / p_limit) + 1,
            'total_pages', CEIL(total_count::DECIMAL / p_limit)
        ),
        'summary', json_build_object(
            'total_schedules', total_count,
            'assigned_schedules', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_type = 'assigned'), 0
            ),
            'received_via_exchange', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_type = 'received_via_exchange'), 0
            ),
            'given_via_exchange', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_type = 'given_via_exchange'), 0
            ),
            'upcoming_schedules', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_status = 'upcoming'), 0
            ),
            'current_schedules', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_status = 'current'), 0
            ),
            'past_schedules', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_status = 'past'), 0
            ),
            'total_hours', COALESCE(
                (SELECT SUM(duration_hours) FROM schedule_data), 0
            )
        ),
        'metadata', json_build_object(
            'query_timestamp', NOW(),
            'date_range_start', start_filter,
            'date_range_end', end_filter,
            'function_version', '2.1'
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE,
            'user_id', p_user_id,
            'date_filter', CASE 
                WHEN p_date IS NOT NULL THEN json_build_object('type', 'single_date', 'date', p_date)
                WHEN p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN json_build_object('type', 'date_range', 'start_date', p_start_date, 'end_date', p_end_date)
                ELSE json_build_object('type', 'default', 'date', CURRENT_DATE)
            END,
            'query_timestamp', NOW()
        );
END;
$$;

-- =====================================================
-- STEP 5: Create Debug Function for Exchange Issues
-- =====================================================
CREATE OR REPLACE FUNCTION debug_schedule_exchange(
    p_user_id UUID,
    p_date DATE DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    target_date DATE;
BEGIN
    target_date := COALESCE(p_date, CURRENT_DATE);
    
    result := json_build_object(
        'user_id', p_user_id,
        'target_date', target_date,
        'user_info', (
            SELECT json_build_object(
                'id', id,
                'full_name', full_name,
                'employee_id', employee_id,
                'user_role', user_role,
                'is_active', is_active
            )
            FROM my_users WHERE id = p_user_id
        ),
        'directly_assigned_schedules', (
            SELECT json_agg(
                json_build_object(
                    'id', id,
                    'title', title,
                    'start_date_time', start_date_time,
                    'end_date_time', end_date_time,
                    'assigned_user_id', assigned_user_id,
                    'status', status,
                    'is_active', is_active
                )
            )
            FROM employee_schedules
            WHERE assigned_user_id = p_user_id
            AND DATE(start_date_time) = target_date
            AND is_active = true
        ),
        'received_via_exchange', (
            SELECT json_agg(
                json_build_object(
                    'schedule_id', s.id,
                    'schedule_title', s.title,
                    'start_date_time', s.start_date_time,
                    'end_date_time', s.end_date_time,
                    'exchange_request_id', ser.id,
                    'exchange_status', ser.status,
                    'original_assignee', requester.full_name,
                    'exchange_created_at', ser.created_at,
                    'exchange_approved_at', ser.reviewed_at
                )
            )
            FROM employee_schedules s
            JOIN schedule_exchange_requests ser ON s.id = ser.schedule_id
            LEFT JOIN my_users requester ON ser.requester_user_id = requester.id
            WHERE ser.requested_user_id = p_user_id
            AND ser.status = 'approved'
            AND DATE(s.start_date_time) = target_date
            AND s.is_active = true
        ),
        'given_via_exchange', (
            SELECT json_agg(
                json_build_object(
                    'schedule_id', s.id,
                    'schedule_title', s.title,
                    'start_date_time', s.start_date_time,
                    'end_date_time', s.end_date_time,
                    'exchange_request_id', ser.id,
                    'exchange_status', ser.status,
                    'new_assignee', requested.full_name,
                    'exchange_created_at', ser.created_at,
                    'exchange_approved_at', ser.reviewed_at
                )
            )
            FROM employee_schedules s
            JOIN schedule_exchange_requests ser ON s.id = ser.schedule_id
            LEFT JOIN my_users requested ON ser.requested_user_id = requested.id
            WHERE ser.requester_user_id = p_user_id
            AND ser.status = 'approved'
            AND DATE(s.start_date_time) = target_date
            AND s.is_active = true
        ),
        'rpc_function_result', (
            SELECT get_employee_schedules(p_user_id, target_date, NULL, NULL, true, false, 100, 0)
        )
    );
    
    RETURN result;
END;
$$;

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT 'SCHEDULE EXCHANGE FIX COMPLETE' as status;
SELECT 
    'RLS policies updated' as fix1,
    'Admin manage function enhanced' as fix2,
    'get_employee_schedules function improved' as fix3,
    'Debug function created' as fix4,
    'Ready for testing' as next_step;
