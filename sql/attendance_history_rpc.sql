-- ============================================================================
-- ATTENDANCE HISTORY RPC FUNCTION
-- ============================================================================
-- Purpose: Fetch user's attendance history with pagination and filtering
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_attendance_history(
    p_user_id UUID,
    p_status TEXT DEFAULT NULL,           -- Filter by status: 'checked_in', 'checked_out', 'absent'
    p_start_date DATE DEFAULT NULL,       -- Filter from date
    p_end_date DATE DEFAULT NULL,         -- Filter to date
    p_limit INTEGER DEFAULT 20,           -- Pagination limit
    p_offset INTEGER DEFAULT 0            -- Pagination offset
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    attendance_array JSONB[] := '{}';
    attendance_obj JSONB;
    total_count INTEGER;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    -- Set default date range (last 30 days if not specified)
    v_start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end_date := COALESCE(p_end_date, CURRENT_DATE);
    
    -- Get total count for pagination
    SELECT COUNT(*) INTO total_count
    FROM public.attendance a
    WHERE a.user_id = p_user_id
    AND (a.check_in_time::date BETWEEN v_start_date AND v_end_date
         OR a.check_out_time::date BETWEEN v_start_date AND v_end_date
         OR a.created_at::date BETWEEN v_start_date AND v_end_date)
    AND (p_status IS NULL OR a.status = p_status);
    
    -- Fetch attendance records with schedule and location details
    FOR attendance_obj IN
        SELECT jsonb_build_object(
            'id', a.id,
            'schedule_id', a.schedule_id,
            'user_id', a.user_id,
            'date', COALESCE(a.check_in_time::date, a.created_at::date),
            'check_in_time', a.check_in_time,
            'check_out_time', a.check_out_time,
            'check_in_latitude', a.check_in_latitude,
            'check_in_longitude', a.check_in_longitude,
            'check_out_latitude', a.check_out_latitude,
            'check_out_longitude', a.check_out_longitude,
            'status', a.status,
            'notes', a.notes,
            'work_duration_minutes', a.work_duration_minutes,
            'created_at', a.created_at,
            'updated_at', a.updated_at,
            -- Schedule information
            'schedule', jsonb_build_object(
                'id', s.id,
                'title', s.title,
                'description', s.description,
                'start_date_time', s.start_date_time,
                'end_date_time', s.end_date_time,
                'location', s.location,
                'department', s.department,
                'duration_hours', EXTRACT(EPOCH FROM (s.end_date_time - s.start_date_time))/3600
            )
        )
        FROM public.attendance a
        LEFT JOIN public.employee_schedules s ON a.schedule_id = s.id
        WHERE a.user_id = p_user_id
        AND (a.check_in_time::date BETWEEN v_start_date AND v_end_date
             OR a.check_out_time::date BETWEEN v_start_date AND v_end_date
             OR a.created_at::date BETWEEN v_start_date AND v_end_date)
        AND (p_status IS NULL OR a.status = p_status)
        ORDER BY COALESCE(a.check_in_time, a.created_at) DESC
        LIMIT p_limit
        OFFSET p_offset
    LOOP
        attendance_array := attendance_array || attendance_obj;
    END LOOP;
    
    -- Return paginated result
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'attendance_records', COALESCE(array_to_json(attendance_array), '[]'::json),
            'total_count', total_count,
            'limit', p_limit,
            'offset', p_offset,
            'has_more', (p_offset + p_limit) < total_count,
            'date_range', jsonb_build_object(
                'start_date', v_start_date,
                'end_date', v_end_date
            )
        )
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_user_attendance_history TO authenticated;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

-- Get last 20 attendance records for user
-- SELECT get_user_attendance_history('user-uuid-here', NULL, NULL, NULL, 20, 0);

-- Get checked_out records only
-- SELECT get_user_attendance_history('user-uuid-here', 'checked_out', NULL, NULL, 20, 0);

-- Get records from specific date range
-- SELECT get_user_attendance_history('user-uuid-here', NULL, '2025-09-01', '2025-10-02', 20, 0);

-- Get next page (pagination)
-- SELECT get_user_attendance_history('user-uuid-here', NULL, NULL, NULL, 20, 20);

