-- =====================================================
-- SUMMARY REPORTS RPC FUNCTIONS
-- =====================================================
-- These functions provide data for the Summary Reports screen
-- Supporting Daily, Weekly, Monthly, and Custom Range views

-- =====================================================
-- 1. DAILY SUMMARY REPORTS
-- =====================================================
CREATE OR REPLACE FUNCTION get_daily_summary_reports(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 30
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_result JSON;
BEGIN
    -- Set default dates if not provided
    v_start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end_date := COALESCE(p_end_date, CURRENT_DATE);
    
    -- Get daily summary data
    SELECT json_build_object(
        'success', true,
        'period_type', 'daily',
        'start_date', v_start_date,
        'end_date', v_end_date,
        'total_records', COUNT(*),
        'data', json_agg(
            json_build_object(
                'period', to_char(date, 'DD/MM/YYYY'),
                'subPeriod', to_char(date, 'Day'),
                'attendanceRate', ROUND(attendance_rate, 1),
                'present', total_present,
                'total', total_employees_scheduled,
                'totalHours', ROUND(total_work_hours, 1),
                'status', CASE 
                    WHEN attendance_rate >= 90 THEN 'Excellent'
                    WHEN attendance_rate >= 75 THEN 'Good'
                    ELSE 'Needs Improvement'
                END,
                'date', date
            ) ORDER BY date DESC
        ),
        'summary_stats', json_build_object(
            'avgAttendance', ROUND(AVG(attendance_rate), 1),
            'totalHours', ROUND(SUM(total_work_hours), 1),
            'totalRecords', COUNT(*)
        )
    ) INTO v_result
    FROM daily_attendance_summary
    WHERE summary_date BETWEEN v_start_date AND v_end_date
    AND total_employees_scheduled > 0
    ORDER BY summary_date DESC
    LIMIT p_limit;
    
    RETURN COALESCE(v_result, json_build_object(
        'success', true,
        'period_type', 'daily',
        'data', '[]'::json,
        'summary_stats', json_build_object(
            'avgAttendance', 0,
            'totalHours', 0,
            'totalRecords', 0
        )
    ));
END;
$$;

-- =====================================================
-- 2. WEEKLY SUMMARY REPORTS
-- =====================================================
CREATE OR REPLACE FUNCTION get_weekly_summary_reports(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 12
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_result JSON;
BEGIN
    -- Set default dates if not provided
    v_start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '12 weeks');
    v_end_date := COALESCE(p_end_date, CURRENT_DATE);
    
    -- Get weekly summary data
    SELECT json_build_object(
        'success', true,
        'period_type', 'weekly',
        'start_date', v_start_date,
        'end_date', v_end_date,
        'total_records', COUNT(*),
        'data', json_agg(
            json_build_object(
                'period', 'Week ' || week_number,
                'subPeriod', to_char(week_start_date, 'DD/MM') || ' - ' || to_char(week_end_date, 'DD/MM'),
                'attendanceRate', ROUND(weekly_attendance_rate, 1),
                'present', ROUND(avg_daily_present, 0),
                'total', total_employees,
                'totalHours', ROUND(total_work_hours, 1),
                'status', CASE 
                    WHEN weekly_attendance_rate >= 90 THEN 'Excellent'
                    WHEN weekly_attendance_rate >= 75 THEN 'Good'
                    ELSE 'Needs Improvement'
                END,
                'weekStart', week_start_date,
                'weekEnd', week_end_date
            ) ORDER BY year DESC, week_number DESC
        ),
        'summary_stats', json_build_object(
            'avgAttendance', ROUND(AVG(weekly_attendance_rate), 1),
            'totalHours', ROUND(SUM(total_work_hours), 1),
            'totalRecords', COUNT(*)
        )
    ) INTO v_result
    FROM weekly_attendance_summary
    WHERE week_start_date BETWEEN v_start_date AND v_end_date
    AND total_employees > 0
    ORDER BY year DESC, week_number DESC
    LIMIT p_limit;
    
    RETURN COALESCE(v_result, json_build_object(
        'success', true,
        'period_type', 'weekly',
        'data', '[]'::json,
        'summary_stats', json_build_object(
            'avgAttendance', 0,
            'totalHours', 0,
            'totalRecords', 0
        )
    ));
END;
$$;

-- =====================================================
-- 3. MONTHLY SUMMARY REPORTS
-- =====================================================
CREATE OR REPLACE FUNCTION get_monthly_summary_reports(
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 12
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_result JSON;
BEGIN
    -- Set default dates if not provided
    v_start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '12 months');
    v_end_date := COALESCE(p_end_date, CURRENT_DATE);
    
    -- Get monthly summary data
    SELECT json_build_object(
        'success', true,
        'period_type', 'monthly',
        'start_date', v_start_date,
        'end_date', v_end_date,
        'total_records', COUNT(*),
        'data', json_agg(
            json_build_object(
                'period', month_name,
                'subPeriod', year::TEXT,
                'attendanceRate', ROUND(monthly_attendance_rate, 1),
                'present', ROUND(avg_daily_attendance, 0),
                'total', total_employees,
                'totalHours', ROUND(total_work_hours, 1),
                'status', CASE 
                    WHEN monthly_attendance_rate >= 90 THEN 'Excellent'
                    WHEN monthly_attendance_rate >= 75 THEN 'Good'
                    ELSE 'Needs Improvement'
                END,
                'year', year,
                'month', month
            ) ORDER BY year DESC, month DESC
        ),
        'summary_stats', json_build_object(
            'avgAttendance', ROUND(AVG(monthly_attendance_rate), 1),
            'totalHours', ROUND(SUM(total_work_hours), 1),
            'totalRecords', COUNT(*)
        )
    ) INTO v_result
    FROM monthly_attendance_summary
    WHERE make_date(year, month, 1) BETWEEN v_start_date AND v_end_date
    AND total_employees > 0
    ORDER BY year DESC, month DESC
    LIMIT p_limit;
    
    RETURN COALESCE(v_result, json_build_object(
        'success', true,
        'period_type', 'monthly',
        'data', '[]'::json,
        'summary_stats', json_build_object(
            'avgAttendance', 0,
            'totalHours', 0,
            'totalRecords', 0
        )
    ));
END;
$$;

-- =====================================================
-- 4. CUSTOM RANGE SUMMARY REPORTS
-- =====================================================
CREATE OR REPLACE FUNCTION get_custom_range_summary_reports(
    p_start_date DATE,
    p_end_date DATE,
    p_period_type TEXT DEFAULT 'daily'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_days_diff INTEGER;
BEGIN
    -- Validate input
    IF p_start_date IS NULL OR p_end_date IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Start date and end date are required'
        );
    END IF;
    
    IF p_start_date > p_end_date THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Start date cannot be after end date'
        );
    END IF;
    
    v_days_diff := p_end_date - p_start_date;
    
    -- Determine appropriate period type based on date range
    IF v_days_diff <= 7 THEN
        -- Use daily data for short ranges
        SELECT get_daily_summary_reports(p_start_date, p_end_date, v_days_diff + 1) INTO v_result;
    ELSIF v_days_diff <= 90 THEN
        -- Use weekly data for medium ranges
        SELECT get_weekly_summary_reports(p_start_date, p_end_date, (v_days_diff / 7) + 1) INTO v_result;
    ELSE
        -- Use monthly data for long ranges
        SELECT get_monthly_summary_reports(p_start_date, p_end_date, (v_days_diff / 30) + 1) INTO v_result;
    END IF;
    
    RETURN v_result;
END;
$$;

-- =====================================================
-- 5. SUMMARY REPORTS OVERVIEW STATS
-- =====================================================
CREATE OR REPLACE FUNCTION get_summary_reports_overview(
    p_period_type TEXT DEFAULT 'daily'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    CASE p_period_type
        WHEN 'daily' THEN
            SELECT json_build_object(
                'success', true,
                'period_type', 'daily',
                'totalRecords', COUNT(*),
                'avgAttendance', ROUND(AVG(attendance_rate), 1),
                'totalHours', ROUND(SUM(total_work_hours), 1),
                'lastUpdated', MAX(last_updated)
            ) INTO v_result
            FROM daily_attendance_summary
            WHERE summary_date >= CURRENT_DATE - INTERVAL '30 days'
            AND total_employees_scheduled > 0;
            
        WHEN 'weekly' THEN
            SELECT json_build_object(
                'success', true,
                'period_type', 'weekly',
                'totalRecords', COUNT(*),
                'avgAttendance', ROUND(AVG(weekly_attendance_rate), 1),
                'totalHours', ROUND(SUM(total_work_hours), 1),
                'lastUpdated', MAX(last_updated)
            ) INTO v_result
            FROM weekly_attendance_summary
            WHERE week_start_date >= CURRENT_DATE - INTERVAL '12 weeks'
            AND total_employees > 0;
            
        WHEN 'monthly' THEN
            SELECT json_build_object(
                'success', true,
                'period_type', 'monthly',
                'totalRecords', COUNT(*),
                'avgAttendance', ROUND(AVG(monthly_attendance_rate), 1),
                'totalHours', ROUND(SUM(total_work_hours), 1),
                'lastUpdated', MAX(last_updated)
            ) INTO v_result
            FROM monthly_attendance_summary
            WHERE make_date(year, month, 1) >= CURRENT_DATE - INTERVAL '12 months'
            AND total_employees > 0;
            
        ELSE
            v_result := json_build_object(
                'success', false,
                'error', 'Invalid period type. Use: daily, weekly, or monthly'
            );
    END CASE;
    
    RETURN COALESCE(v_result, json_build_object(
        'success', true,
        'period_type', p_period_type,
        'totalRecords', 0,
        'avgAttendance', 0,
        'totalHours', 0,
        'lastUpdated', NULL
    ));
END;
$$;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================
GRANT EXECUTE ON FUNCTION get_daily_summary_reports(DATE, DATE, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_summary_reports(DATE, DATE, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_summary_reports(DATE, DATE, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_custom_range_summary_reports(DATE, DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_summary_reports_overview(TEXT) TO authenticated;

-- =====================================================
-- COMMENT
-- =====================================================
COMMENT ON FUNCTION get_daily_summary_reports IS 'Get daily summary reports data for the Summary Reports screen';
COMMENT ON FUNCTION get_weekly_summary_reports IS 'Get weekly summary reports data for the Summary Reports screen';
COMMENT ON FUNCTION get_monthly_summary_reports IS 'Get monthly summary reports data for the Summary Reports screen';
COMMENT ON FUNCTION get_custom_range_summary_reports IS 'Get custom range summary reports data for the Summary Reports screen';
COMMENT ON FUNCTION get_summary_reports_overview IS 'Get overview statistics for summary reports';
