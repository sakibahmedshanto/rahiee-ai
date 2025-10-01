-- 🚀 PERFECT EMPLOYEE SCHEDULES RPC FUNCTION
-- Comprehensive function that handles all schedule scenarios including exchanges

-- =====================================================
-- RPC FUNCTION: get_employee_schedules
-- =====================================================
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
        -- Single date
        start_filter := p_date::TIMESTAMPTZ;
        end_filter := (p_date + INTERVAL '1 day')::TIMESTAMPTZ;
    ELSIF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
        -- Date range
        start_filter := p_start_date::TIMESTAMPTZ;
        end_filter := (p_end_date + INTERVAL '1 day')::TIMESTAMPTZ;
    ELSE
        -- Default to today
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
            -- Additional metadata
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
            -- Additional metadata
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
            -- Additional metadata
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
            'function_version', '2.0'
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
