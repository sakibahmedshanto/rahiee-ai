-- =====================================================
-- HR Dashboard pg_cron Scheduled Jobs
-- =====================================================
-- Automated jobs for weekly and monthly summary aggregations
-- =====================================================

-- =====================================================
-- 1. WEEKLY SUMMARY AGGREGATION
-- =====================================================
-- Runs daily at 1:00 AM to update current week's summary

SELECT cron.schedule(
    'update-weekly-summary',
    '0 1 * * *', -- Every day at 1:00 AM
    $$
    SELECT update_weekly_summary(
        EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
        EXTRACT(WEEK FROM CURRENT_DATE)::INTEGER
    )
    $$
);

-- =====================================================
-- 2. MONTHLY SUMMARY AGGREGATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION update_monthly_summary(p_year INTEGER, p_month INTEGER)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_month_start DATE;
    v_month_end DATE;
    v_month_name TEXT;
    v_top_performers JSONB;
    v_bottom_performers JSONB;
    v_most_overtime JSONB;
    v_most_absent JSONB;
    v_dept_summary JSONB;
    v_weekly_breakdown JSONB;
    v_working_days INTEGER;
BEGIN
    -- Calculate month boundaries
    v_month_start := make_date(p_year, p_month, 1);
    v_month_end := (v_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    v_month_name := to_char(v_month_start, 'Month');
    
    -- Count working days (excluding weekends)
    SELECT COUNT(*)
    INTO v_working_days
    FROM generate_series(v_month_start, v_month_end, '1 day'::interval) d
    WHERE EXTRACT(DOW FROM d) NOT IN (0, 6); -- 0=Sunday, 6=Saturday
    
    -- Get top performers (by attendance rate and hours)
    SELECT json_agg(
        json_build_object(
            'user_id', u.id,
            'name', u.full_name,
            'hours', stats.total_hours,
            'attendance_rate', stats.rate,
            'days_worked', stats.days
        ) ORDER BY stats.rate DESC, stats.total_hours DESC
    ) INTO v_top_performers
    FROM (
        SELECT 
            user_id,
            COUNT(DISTINCT date) as days,
            SUM(net_work_hours) as total_hours,
            ROUND(
                (COUNT(*) FILTER (WHERE status IN ('completed', 'approved'))::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ) as rate
        FROM attendance
        WHERE date >= v_month_start AND date <= v_month_end
        GROUP BY user_id
        HAVING COUNT(*) > 0
        ORDER BY rate DESC, total_hours DESC
        LIMIT 10
    ) stats
    JOIN my_users u ON u.id = stats.user_id;
    
    -- Get bottom performers
    SELECT json_agg(
        json_build_object(
            'user_id', u.id,
            'name', u.full_name,
            'attendance_rate', stats.rate,
            'absences', stats.absences
        ) ORDER BY stats.rate ASC
    ) INTO v_bottom_performers
    FROM (
        SELECT 
            user_id,
            COUNT(*) FILTER (WHERE status = 'absent') as absences,
            ROUND(
                (COUNT(*) FILTER (WHERE status IN ('completed', 'approved'))::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ) as rate
        FROM attendance
        WHERE date >= v_month_start AND date <= v_month_end
        GROUP BY user_id
        HAVING COUNT(*) > 0
        ORDER BY rate ASC
        LIMIT 10
    ) stats
    JOIN my_users u ON u.id = stats.user_id;
    
    -- Get most overtime employees
    SELECT json_agg(
        json_build_object(
            'user_id', u.id,
            'name', u.full_name,
            'overtime_hours', stats.overtime_hours,
            'overtime_pay', stats.overtime_pay
        ) ORDER BY stats.overtime_hours DESC
    ) INTO v_most_overtime
    FROM (
        SELECT 
            user_id,
            SUM(overtime_hours) as overtime_hours,
            SUM(overtime_amount) as overtime_pay
        FROM attendance
        WHERE date >= v_month_start AND date <= v_month_end
        AND overtime_hours > 0
        GROUP BY user_id
        ORDER BY overtime_hours DESC
        LIMIT 10
    ) stats
    JOIN my_users u ON u.id = stats.user_id;
    
    -- Get most absent employees
    SELECT json_agg(
        json_build_object(
            'user_id', u.id,
            'name', u.full_name,
            'absences', stats.absences
        ) ORDER BY stats.absences DESC
    ) INTO v_most_absent
    FROM (
        SELECT 
            user_id,
            COUNT(*) as absences
        FROM attendance
        WHERE date >= v_month_start AND date <= v_month_end
        AND status = 'absent'
        GROUP BY user_id
        ORDER BY absences DESC
        LIMIT 10
    ) stats
    JOIN my_users u ON u.id = stats.user_id;
    
    -- Get department summary
    SELECT jsonb_object_agg(
        department,
        jsonb_build_object(
            'employees', employee_count,
            'attendance_rate', attendance_rate,
            'total_hours', total_hours,
            'total_pay', total_pay
        )
    ) INTO v_dept_summary
    FROM (
        SELECT 
            u.department,
            COUNT(DISTINCT u.id) as employee_count,
            ROUND(
                (COUNT(*) FILTER (WHERE a.status IN ('completed', 'approved'))::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ) as attendance_rate,
            SUM(a.net_work_hours) as total_hours,
            SUM(a.total_amount) FILTER (WHERE a.status IN ('approved', 'granted')) as total_pay
        FROM attendance a
        JOIN my_users u ON u.id = a.user_id
        WHERE a.date >= v_month_start AND a.date <= v_month_end
        GROUP BY u.department
    ) dept_stats;
    
    -- Get weekly breakdown
    SELECT json_agg(
        json_build_object(
            'week', week_number,
            'total_hours', total_work_hours,
            'attendance_rate', weekly_attendance_rate
        ) ORDER BY week_number
    ) INTO v_weekly_breakdown
    FROM weekly_attendance_summary
    WHERE year = p_year 
    AND week_start_date >= v_month_start 
    AND week_end_date <= v_month_end;
    
    -- Insert or update monthly summary
    INSERT INTO monthly_attendance_summary (
        year, month, month_name,
        total_employees, total_working_days, avg_daily_attendance,
        total_work_hours, total_overtime_hours, avg_hours_per_employee, avg_hours_per_day,
        total_payroll, total_base_pay, total_overtime_pay,
        total_approved_earnings, total_pending_earnings, total_paid_amount, total_unpaid_amount,
        monthly_attendance_rate, monthly_punctuality_rate, monthly_uniform_compliance_rate,
        total_absences, total_late_arrivals, total_uniform_violations,
        department_summary, weekly_breakdown,
        top_performers, bottom_performers, most_overtime_employees, most_absent_employees,
        cost_per_employee, overtime_cost_ratio
    )
    SELECT 
        p_year, p_month, v_month_name,
        COUNT(DISTINCT user_id),
        v_working_days,
        AVG(daily_count),
        SUM(total_hours),
        SUM(overtime_hours),
        AVG(avg_hours),
        SUM(total_hours) / NULLIF(v_working_days, 0),
        SUM(total_pay),
        SUM(base_pay),
        SUM(overtime_pay),
        SUM(approved_pay),
        SUM(pending_pay),
        SUM(paid),
        SUM(unpaid),
        ROUND(AVG(attendance_rate), 2),
        ROUND(AVG(punctuality_rate), 2),
        ROUND(AVG(uniform_rate), 2),
        SUM(absences),
        SUM(late_count),
        SUM(uniform_violations),
        v_dept_summary,
        v_weekly_breakdown,
        v_top_performers,
        v_bottom_performers,
        v_most_overtime,
        v_most_absent,
        SUM(total_pay) / NULLIF(COUNT(DISTINCT user_id), 0),
        CASE 
            WHEN SUM(total_pay) = 0 THEN 0
            ELSE ROUND((SUM(overtime_pay) / SUM(total_pay)) * 100, 2)
        END
    FROM (
        SELECT 
            user_id,
            COUNT(*) as daily_count,
            SUM(net_work_hours) as total_hours,
            SUM(overtime_hours) as overtime_hours,
            AVG(net_work_hours) as avg_hours,
            SUM(total_amount) as total_pay,
            SUM(calculated_amount) as base_pay,
            SUM(overtime_amount) as overtime_pay,
            SUM(total_amount) FILTER (WHERE status IN ('approved', 'granted')) as approved_pay,
            SUM(total_amount) FILTER (WHERE status = 'pending') as pending_pay,
            SUM(paid_amount) as paid,
            SUM(total_amount - paid_amount) as unpaid,
            COUNT(*) FILTER (WHERE status = 'absent') as absences,
            COUNT(*) FILTER (WHERE is_late = true) as late_count,
            COUNT(*) FILTER (WHERE wearing_uniform = false) as uniform_violations,
            ROUND(
                (COUNT(*) FILTER (WHERE status IN ('completed', 'approved'))::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ) as attendance_rate,
            ROUND(
                (COUNT(*) FILTER (WHERE is_late = false)::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ) as punctuality_rate,
            ROUND(
                (COUNT(*) FILTER (WHERE wearing_uniform = true)::NUMERIC / 
                NULLIF(COUNT(*) FILTER (WHERE wearing_uniform IS NOT NULL), 0)) * 100, 2
            ) as uniform_rate
        FROM attendance
        WHERE date >= v_month_start AND date <= v_month_end
        GROUP BY user_id
    ) month_stats
    ON CONFLICT (year, month) 
    DO UPDATE SET
        total_employees = EXCLUDED.total_employees,
        total_working_days = EXCLUDED.total_working_days,
        avg_daily_attendance = EXCLUDED.avg_daily_attendance,
        total_work_hours = EXCLUDED.total_work_hours,
        total_overtime_hours = EXCLUDED.total_overtime_hours,
        avg_hours_per_employee = EXCLUDED.avg_hours_per_employee,
        avg_hours_per_day = EXCLUDED.avg_hours_per_day,
        total_payroll = EXCLUDED.total_payroll,
        total_base_pay = EXCLUDED.total_base_pay,
        total_overtime_pay = EXCLUDED.total_overtime_pay,
        total_approved_earnings = EXCLUDED.total_approved_earnings,
        total_pending_earnings = EXCLUDED.total_pending_earnings,
        total_paid_amount = EXCLUDED.total_paid_amount,
        total_unpaid_amount = EXCLUDED.total_unpaid_amount,
        monthly_attendance_rate = EXCLUDED.monthly_attendance_rate,
        monthly_punctuality_rate = EXCLUDED.monthly_punctuality_rate,
        monthly_uniform_compliance_rate = EXCLUDED.monthly_uniform_compliance_rate,
        total_absences = EXCLUDED.total_absences,
        total_late_arrivals = EXCLUDED.total_late_arrivals,
        total_uniform_violations = EXCLUDED.total_uniform_violations,
        department_summary = EXCLUDED.department_summary,
        weekly_breakdown = EXCLUDED.weekly_breakdown,
        top_performers = EXCLUDED.top_performers,
        bottom_performers = EXCLUDED.bottom_performers,
        most_overtime_employees = EXCLUDED.most_overtime_employees,
        most_absent_employees = EXCLUDED.most_absent_employees,
        cost_per_employee = EXCLUDED.cost_per_employee,
        overtime_cost_ratio = EXCLUDED.overtime_cost_ratio,
        last_updated = NOW();
    
    RETURN json_build_object(
        'success', true,
        'year', p_year,
        'month', p_month,
        'month_name', v_month_name,
        'working_days', v_working_days
    );
END;
$$;

-- =====================================================
-- 3. MONTHLY SUMMARY AGGREGATION SCHEDULE
-- =====================================================
-- Runs on 1st and 15th of each month at 2:00 AM

SELECT cron.schedule(
    'update-monthly-summary',
    '0 2 1,15 * *', -- 1st and 15th of every month at 2:00 AM
    $$
    SELECT update_monthly_summary(
        EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
        EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER
    )
    $$
);

-- =====================================================
-- 4. CLEANUP OLD DAILY SUMMARIES
-- =====================================================
-- Delete daily summaries older than 1 year (runs monthly)

CREATE OR REPLACE FUNCTION cleanup_old_summaries()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM daily_attendance_summary
    WHERE summary_date < CURRENT_DATE - INTERVAL '1 year';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'deleted_count', v_deleted_count,
        'message', format('Cleaned up %s old daily summaries', v_deleted_count)
    );
END;
$$;

-- Schedule cleanup on 1st of each month at 3:00 AM
SELECT cron.schedule(
    'cleanup-old-summaries',
    '0 3 1 * *',
    $$SELECT cleanup_old_summaries()$$
);

-- =====================================================
-- VIEW ALL SCHEDULED JOBS
-- =====================================================

-- To view all scheduled jobs:
-- SELECT * FROM cron.job WHERE jobname LIKE '%summary%' OR jobname LIKE '%cleanup%';

-- To view job execution history:
-- SELECT * FROM cron.job_run_details WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname LIKE '%summary%') ORDER BY start_time DESC LIMIT 20;

-- =====================================================
-- COMMENT: pg_cron jobs configured successfully!
-- Jobs will run automatically on schedule
-- =====================================================

