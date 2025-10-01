-- 🚀 EMPLOYEE SCHEDULE FETCHING RPC FUNCTION
-- Handles complex schedule fetching including exchanged schedules

-- =====================================================
-- RPC FUNCTION: Get Employee Schedules with Exchanges
-- =====================================================
CREATE OR REPLACE FUNCTION get_employee_schedules_with_exchanges(
    p_user_id UUID,
    p_date DATE,
    p_include_exchanges BOOLEAN DEFAULT true
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    schedules JSON;
    start_of_day TIMESTAMPTZ;
    end_of_day TIMESTAMPTZ;
BEGIN
    -- Calculate date range
    start_of_day := p_date::TIMESTAMPTZ;
    end_of_day := (p_date + INTERVAL '1 day')::TIMESTAMPTZ;
    
    -- Get schedules with exchange information
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
            u.full_name as assigned_user_name,
            u.employee_id as assigned_user_employee_id,
            admin.full_name as created_by_admin_name
        FROM employee_schedules s
        LEFT JOIN my_users u ON s.assigned_user_id = u.id
        LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
        WHERE s.assigned_user_id = p_user_id
        AND s.start_date_time >= start_of_day
        AND s.start_date_time < end_of_day
        AND s.is_active = true
        
        UNION ALL
        
        -- Schedules received through approved exchanges
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
            u.full_name as assigned_user_name,
            u.employee_id as assigned_user_employee_id,
            admin.full_name as created_by_admin_name
        FROM employee_schedules s
        JOIN schedule_exchange_requests ser ON s.id = ser.schedule_id
        LEFT JOIN my_users u ON s.assigned_user_id = u.id
        LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
        LEFT JOIN my_users requester ON ser.requester_user_id = requester.id
        WHERE ser.requested_user_id = p_user_id
        AND ser.status = 'approved'
        AND s.start_date_time >= start_of_day
        AND s.start_date_time < end_of_day
        AND s.is_active = true
        
        UNION ALL
        
        -- Schedules given away through approved exchanges (for reference)
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
            u.full_name as assigned_user_name,
            u.employee_id as assigned_user_employee_id,
            admin.full_name as created_by_admin_name
        FROM employee_schedules s
        JOIN schedule_exchange_requests ser ON s.id = ser.schedule_id
        LEFT JOIN my_users u ON s.assigned_user_id = u.id
        LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
        LEFT JOIN my_users requester ON ser.requester_user_id = requester.id
        LEFT JOIN my_users requested ON ser.requested_user_id = requested.id
        WHERE ser.requester_user_id = p_user_id
        AND ser.status = 'approved'
        AND s.start_date_time >= start_of_day
        AND s.start_date_time < end_of_day
        AND s.is_active = true
    )
    SELECT json_agg(
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
            'assigned_user_name', assigned_user_name,
            'assigned_user_employee_id', assigned_user_employee_id,
            'created_by_admin_name', created_by_admin_name
        )
    ) INTO schedules
    FROM schedule_data
    ORDER BY start_date_time;
    
    -- Build result
    result := json_build_object(
        'success', true,
        'user_id', p_user_id,
        'date', p_date,
        'include_exchanges', p_include_exchanges,
        'schedules', COALESCE(schedules, '[]'::json),
        'schedule_counts', json_build_object(
            'total', COALESCE(json_array_length(schedules), 0),
            'assigned', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_type = 'assigned'), 0
            ),
            'received_via_exchange', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_type = 'received_via_exchange'), 0
            ),
            'given_via_exchange', COALESCE(
                (SELECT COUNT(*) FROM schedule_data WHERE schedule_type = 'given_via_exchange'), 0
            )
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
            'date', p_date
        );
END;
$$;

-- =====================================================
-- RPC FUNCTION: Get Employee Schedule Summary
-- =====================================================
CREATE OR REPLACE FUNCTION get_employee_schedule_summary(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    summary JSON;
BEGIN
    -- Get schedule summary for date range
    WITH schedule_summary AS (
        SELECT 
            DATE(s.start_date_time) as schedule_date,
            COUNT(*) as total_schedules,
            COUNT(CASE WHEN s.assigned_user_id = p_user_id THEN 1 END) as assigned_schedules,
            COUNT(CASE WHEN ser.requested_user_id = p_user_id AND ser.status = 'approved' THEN 1 END) as received_schedules,
            COUNT(CASE WHEN ser.requester_user_id = p_user_id AND ser.status = 'approved' THEN 1 END) as given_schedules,
            SUM(EXTRACT(EPOCH FROM (s.end_date_time - s.start_date_time))/3600) as total_hours
        FROM employee_schedules s
        LEFT JOIN schedule_exchange_requests ser ON s.id = ser.schedule_id
        WHERE (
            s.assigned_user_id = p_user_id 
            OR (ser.requested_user_id = p_user_id AND ser.status = 'approved')
            OR (ser.requester_user_id = p_user_id AND ser.status = 'approved')
        )
        AND s.start_date_time >= p_start_date::TIMESTAMPTZ
        AND s.start_date_time < (p_end_date + INTERVAL '1 day')::TIMESTAMPTZ
        AND s.is_active = true
        GROUP BY DATE(s.start_date_time)
    )
    SELECT json_agg(
        json_build_object(
            'date', schedule_date,
            'total_schedules', total_schedules,
            'assigned_schedules', assigned_schedules,
            'received_schedules', received_schedules,
            'given_schedules', given_schedules,
            'total_hours', total_hours
        )
    ) INTO summary
    FROM schedule_summary
    ORDER BY schedule_date;
    
    -- Build result
    result := json_build_object(
        'success', true,
        'user_id', p_user_id,
        'start_date', p_start_date,
        'end_date', p_end_date,
        'summary', COALESCE(summary, '[]'::json)
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;

-- =====================================================
-- RPC FUNCTION: Check Schedule Exchange Eligibility
-- =====================================================
CREATE OR REPLACE FUNCTION check_schedule_exchange_eligibility(
    p_user_id UUID,
    p_schedule_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    schedule_info JSON;
    user_info JSON;
    eligibility_info JSON;
BEGIN
    -- Get schedule information
    SELECT json_build_object(
        'id', s.id,
        'title', s.title,
        'start_date_time', s.start_date_time,
        'end_date_time', s.end_date_time,
        'assigned_user_id', s.assigned_user_id,
        'status', s.status,
        'is_active', s.is_active,
        'created_at', s.created_at
    ) INTO schedule_info
    FROM employee_schedules s
    WHERE s.id = p_schedule_id;
    
    -- Get user information
    SELECT json_build_object(
        'id', u.id,
        'full_name', u.full_name,
        'employee_id', u.employee_id,
        'user_role', u.user_role,
        'is_active', u.is_active
    ) INTO user_info
    FROM my_users u
    WHERE u.id = p_user_id;
    
    -- Check eligibility
    SELECT json_build_object(
        'can_exchange', (
            schedule_info IS NOT NULL 
            AND user_info IS NOT NULL
            AND (schedule_info->>'assigned_user_id')::UUID = p_user_id
            AND (schedule_info->>'status') = 'active'
            AND (schedule_info->>'is_active')::BOOLEAN = true
            AND (user_info->>'is_active')::BOOLEAN = true
            AND (schedule_info->>'start_date_time')::TIMESTAMPTZ > NOW()
        ),
        'reason', CASE
            WHEN schedule_info IS NULL THEN 'Schedule not found'
            WHEN user_info IS NULL THEN 'User not found'
            WHEN (schedule_info->>'assigned_user_id')::UUID != p_user_id THEN 'User not assigned to this schedule'
            WHEN (schedule_info->>'status') != 'active' THEN 'Schedule is not active'
            WHEN (schedule_info->>'is_active')::BOOLEAN = false THEN 'Schedule is inactive'
            WHEN (user_info->>'is_active')::BOOLEAN = false THEN 'User is inactive'
            WHEN (schedule_info->>'start_date_time')::TIMESTAMPTZ <= NOW() THEN 'Schedule has already started'
            ELSE 'Eligible for exchange'
        END,
        'schedule_info', schedule_info,
        'user_info', user_info
    ) INTO eligibility_info;
    
    -- Build result
    result := json_build_object(
        'success', true,
        'eligibility', eligibility_info
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;
