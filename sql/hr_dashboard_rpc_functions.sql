-- =====================================================
-- HR Dashboard RPC Functions
-- =====================================================
-- Functions for querying dashboard data and managing payroll
-- =====================================================

-- =====================================================
-- 1. GET REALTIME DASHBOARD STATS
-- =====================================================
-- Returns current day's statistics for admin dashboard

CREATE OR REPLACE FUNCTION get_realtime_dashboard_stats()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_today DATE := CURRENT_DATE;
BEGIN
    SELECT json_build_object(
        'today', json_build_object(
            'date', v_today,
            'total_scheduled', COALESCE(das.total_employees_scheduled, 0),
            'total_present', COALESCE(das.total_present, 0),
            'total_absent', COALESCE(das.total_absent, 0),
            'total_late', COALESCE(das.total_late, 0),
            'currently_active', COALESCE(das.currently_active, 0),
            'attendance_rate', COALESCE(das.attendance_rate, 0),
            'punctuality_rate', COALESCE(das.punctuality_rate, 0),
            'total_hours', COALESCE(das.total_work_hours, 0),
            'total_overtime', COALESCE(das.total_overtime_hours, 0),
            'total_earnings', COALESCE(das.total_earnings_today, 0),
            'pending_approvals', COALESCE(das.total_pending_approvals, 0),
            'uniform_compliance_rate', COALESCE(das.uniform_compliance_rate, 0),
            'department_breakdown', COALESCE(das.department_breakdown, '{}'::jsonb)
        ),
        'this_week', json_build_object(
            'total_hours', COALESCE(was.total_work_hours, 0),
            'total_earnings', COALESCE(was.total_earnings_week, 0),
            'attendance_rate', COALESCE(was.weekly_attendance_rate, 0),
            'top_performers', COALESCE(was.top_performers, '[]'::jsonb)
        ),
        'this_month', json_build_object(
            'total_payroll', COALESCE(mas.total_payroll, 0),
            'total_hours', COALESCE(mas.total_work_hours, 0),
            'attendance_rate', COALESCE(mas.monthly_attendance_rate, 0),
            'total_employees', COALESCE(mas.total_employees, 0)
        ),
        'last_updated', NOW()
    ) INTO v_result
    FROM daily_attendance_summary das
    LEFT JOIN weekly_attendance_summary was ON (
        was.year = EXTRACT(YEAR FROM v_today)::INTEGER AND
        was.week_number = EXTRACT(WEEK FROM v_today)::INTEGER
    )
    LEFT JOIN monthly_attendance_summary mas ON (
        mas.year = EXTRACT(YEAR FROM v_today)::INTEGER AND
        mas.month = EXTRACT(MONTH FROM v_today)::INTEGER
    )
    WHERE das.summary_date = v_today;
    
    -- If no data exists for today, return default values
    IF v_result IS NULL THEN
        v_result := json_build_object(
            'today', json_build_object(
                'date', v_today,
                'total_scheduled', 0,
                'total_present', 0,
                'total_absent', 0,
                'total_late', 0,
                'currently_active', 0,
                'attendance_rate', 0,
                'punctuality_rate', 0,
                'total_hours', 0,
                'total_overtime', 0,
                'total_earnings', 0,
                'pending_approvals', 0,
                'uniform_compliance_rate', 0,
                'department_breakdown', '{}'::jsonb
            ),
            'this_week', json_build_object(
                'total_hours', 0,
                'total_earnings', 0,
                'attendance_rate', 0,
                'top_performers', '[]'::jsonb
            ),
            'this_month', json_build_object(
                'total_payroll', 0,
                'total_hours', 0,
                'attendance_rate', 0,
                'total_employees', 0
            ),
            'last_updated', NOW()
        );
    END IF;
    
    RETURN v_result;
END;
$$;

-- =====================================================
-- 2. GET USER PERFORMANCE SUMMARY
-- =====================================================
-- Returns detailed performance stats for a specific user

CREATE OR REPLACE FUNCTION get_user_performance_summary(
    p_user_id UUID,
    p_period VARCHAR DEFAULT 'lifetime' -- 'lifetime', 'month', 'week'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    -- Determine date range based on period
    v_end_date := CURRENT_DATE;
    CASE p_period
        WHEN 'week' THEN
            v_start_date := CURRENT_DATE - INTERVAL '7 days';
        WHEN 'month' THEN
            v_start_date := DATE_TRUNC('month', CURRENT_DATE)::DATE;
        ELSE
            v_start_date := '1900-01-01'::DATE; -- Lifetime
    END CASE;
    
    SELECT json_build_object(
        'user_id', p_user_id,
        'period', p_period,
        'lifetime_stats', json_build_object(
            'total_days_worked', COALESCE(uls.total_days_worked, 0),
            'total_days_absent', COALESCE(uls.total_days_absent, 0),
            'total_days_late', COALESCE(uls.total_days_late, 0),
            'total_work_hours', COALESCE(uls.total_work_hours, 0),
            'total_overtime_hours', COALESCE(uls.total_overtime_hours, 0),
            'avg_daily_hours', COALESCE(uls.avg_daily_hours, 0),
            'overall_attendance_rate', COALESCE(uls.overall_attendance_rate, 0),
            'punctuality_rate', COALESCE(uls.punctuality_rate, 0),
            'uniform_compliance_rate', COALESCE(uls.uniform_compliance_rate, 0),
            'total_earnings_approved', COALESCE(uls.total_earnings_approved, 0),
            'total_earnings_paid', COALESCE(uls.total_earnings_paid, 0),
            'current_attendance_streak', COALESCE(uls.current_attendance_streak, 0),
            'longest_attendance_streak', COALESCE(uls.longest_attendance_streak, 0)
        ),
        'period_stats', json_build_object(
            'days_worked', (
                SELECT COUNT(DISTINCT date) 
                FROM attendance 
                WHERE user_id = p_user_id 
                AND date >= v_start_date 
                AND date <= v_end_date
                AND status IN ('completed', 'approved', 'granted')
            ),
            'days_absent', (
                SELECT COUNT(DISTINCT date) 
                FROM attendance 
                WHERE user_id = p_user_id 
                AND date >= v_start_date 
                AND date <= v_end_date
                AND status = 'absent'
            ),
            'total_hours', (
                SELECT COALESCE(SUM(net_work_hours), 0) 
                FROM attendance 
                WHERE user_id = p_user_id 
                AND date >= v_start_date 
                AND date <= v_end_date
            ),
            'total_earnings', (
                SELECT COALESCE(SUM(total_amount), 0) 
                FROM attendance 
                WHERE user_id = p_user_id 
                AND date >= v_start_date 
                AND date <= v_end_date
                AND status IN ('approved', 'granted')
            )
        ),
        'recent_attendance', (
            SELECT json_agg(
                json_build_object(
                    'date', date,
                    'status', status,
                    'check_in_time', check_in_time,
                    'check_out_time', check_out_time,
                    'work_hours', net_work_hours,
                    'is_late', is_late,
                    'wearing_uniform', wearing_uniform
                ) ORDER BY date DESC
            )
            FROM (
                SELECT * FROM attendance 
                WHERE user_id = p_user_id 
                ORDER BY date DESC 
                LIMIT 10
            ) recent
        )
    ) INTO v_result
    FROM user_lifetime_summary uls
    WHERE uls.user_id = p_user_id;
    
    RETURN COALESCE(v_result, json_build_object('error', 'User not found'));
END;
$$;

-- =====================================================
-- 3. GET DEPARTMENT ANALYTICS
-- =====================================================
-- Returns analytics for a specific department

CREATE OR REPLACE FUNCTION get_department_analytics(
    p_department VARCHAR,
    p_period VARCHAR DEFAULT 'month' -- 'today', 'week', 'month'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    v_end_date := CURRENT_DATE;
    
    CASE p_period
        WHEN 'today' THEN
            v_start_date := CURRENT_DATE;
        WHEN 'week' THEN
            v_start_date := CURRENT_DATE - INTERVAL '7 days';
        WHEN 'month' THEN
            v_start_date := DATE_TRUNC('month', CURRENT_DATE)::DATE;
        ELSE
            v_start_date := CURRENT_DATE;
    END CASE;
    
    SELECT json_build_object(
        'department', p_department,
        'period', p_period,
        'total_employees', (
            SELECT COUNT(*) 
            FROM my_users 
            WHERE department = p_department 
            AND is_active = true
        ),
        'stats', json_build_object(
            'total_present', COUNT(*) FILTER (WHERE a.status IN ('completed', 'approved', 'granted')),
            'total_absent', COUNT(*) FILTER (WHERE a.status = 'absent'),
            'total_late', COUNT(*) FILTER (WHERE a.is_late = true),
            'total_hours', COALESCE(SUM(a.net_work_hours), 0),
            'total_overtime', COALESCE(SUM(a.overtime_hours), 0),
            'total_earnings', COALESCE(SUM(a.total_amount) FILTER (WHERE a.status IN ('approved', 'granted')), 0),
            'attendance_rate', ROUND(
                (COUNT(*) FILTER (WHERE a.status IN ('completed', 'approved', 'granted'))::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ),
            'punctuality_rate', ROUND(
                (COUNT(*) FILTER (WHERE a.is_late = false)::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            )
        ),
        'top_employees', (
            SELECT json_agg(
                json_build_object(
                    'user_id', u.id,
                    'name', u.full_name,
                    'total_hours', stats.total_hours,
                    'attendance_rate', stats.attendance_rate
                ) ORDER BY stats.total_hours DESC
            )
            FROM (
                SELECT 
                    user_id,
                    SUM(net_work_hours) as total_hours,
                    ROUND(
                        (COUNT(*) FILTER (WHERE status IN ('completed', 'approved'))::NUMERIC / 
                        NULLIF(COUNT(*), 0)) * 100, 2
                    ) as attendance_rate
                FROM attendance
                WHERE date >= v_start_date AND date <= v_end_date
                GROUP BY user_id
                ORDER BY total_hours DESC
                LIMIT 5
            ) stats
            JOIN my_users u ON u.id = stats.user_id
            WHERE u.department = p_department
        )
    ) INTO v_result
    FROM attendance a
    JOIN my_users u ON u.id = a.user_id
    WHERE u.department = p_department
    AND a.date >= v_start_date
    AND a.date <= v_end_date;
    
    RETURN COALESCE(v_result, json_build_object('error', 'No data found'));
END;
$$;

-- =====================================================
-- 4. GET PAYROLL SUMMARY
-- =====================================================
-- Returns monthly payroll summary

CREATE OR REPLACE FUNCTION get_payroll_summary(
    p_year INTEGER,
    p_month INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'year', p_year,
        'month', p_month,
        'summary', json_build_object(
            'total_payroll', COALESCE(total_payroll, 0),
            'total_base_pay', COALESCE(total_base_pay, 0),
            'total_overtime_pay', COALESCE(total_overtime_pay, 0),
            'total_approved', COALESCE(total_approved_earnings, 0),
            'total_pending', COALESCE(total_pending_earnings, 0),
            'total_paid', COALESCE(total_paid_amount, 0),
            'total_unpaid', COALESCE(total_unpaid_amount, 0),
            'total_employees', COALESCE(total_employees, 0),
            'avg_per_employee', COALESCE(cost_per_employee, 0),
            'is_finalized', COALESCE(is_finalized, false)
        ),
        'breakdown_by_status', (
            SELECT json_object_agg(
                status,
                json_build_object(
                    'count', count,
                    'total_amount', total_amount
                )
            )
            FROM (
                SELECT 
                    status,
                    COUNT(*) as count,
                    SUM(total_amount) as total_amount
                FROM attendance
                WHERE EXTRACT(YEAR FROM date) = p_year
                AND EXTRACT(MONTH FROM date) = p_month
                GROUP BY status
            ) status_breakdown
        ),
        'top_earners', (
            SELECT json_agg(
                json_build_object(
                    'user_id', u.id,
                    'name', u.full_name,
                    'total_earnings', earnings.total
                ) ORDER BY earnings.total DESC
            )
            FROM (
                SELECT 
                    user_id,
                    SUM(total_amount) as total
                FROM attendance
                WHERE EXTRACT(YEAR FROM date) = p_year
                AND EXTRACT(MONTH FROM date) = p_month
                AND status IN ('approved', 'granted')
                GROUP BY user_id
                ORDER BY total DESC
                LIMIT 10
            ) earnings
            JOIN my_users u ON u.id = earnings.user_id
        )
    ) INTO v_result
    FROM monthly_attendance_summary
    WHERE year = p_year AND month = p_month;
    
    RETURN COALESCE(v_result, json_build_object('error', 'No payroll data found'));
END;
$$;

-- =====================================================
-- 5. GENERATE PAYMENT TRANSACTION
-- =====================================================
-- Creates a payment transaction for a user's approved attendance

CREATE OR REPLACE FUNCTION generate_payment_transaction(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_approved_by UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_attendance_ids UUID[];
    v_base_amount NUMERIC;
    v_overtime_amount NUMERIC;
    v_total_amount NUMERIC;
    v_payment_id UUID;
BEGIN
    -- Get all approved attendance records for the period
    SELECT 
        array_agg(id),
        COALESCE(SUM(calculated_amount), 0),
        COALESCE(SUM(overtime_amount), 0),
        COALESCE(SUM(total_amount), 0)
    INTO v_attendance_ids, v_base_amount, v_overtime_amount, v_total_amount
    FROM attendance
    WHERE user_id = p_user_id
    AND date >= p_start_date
    AND date <= p_end_date
    AND status IN ('approved', 'granted')
    AND payment_status = 'unpaid';
    
    -- Check if there are any records
    IF v_attendance_ids IS NULL OR array_length(v_attendance_ids, 1) = 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'No unpaid approved attendance records found'
        );
    END IF;
    
    -- Create payment transaction
    INSERT INTO payment_transactions (
        user_id,
        attendance_ids,
        payment_period_start,
        payment_period_end,
        payment_type,
        base_amount,
        overtime_amount,
        total_amount,
        payment_status,
        approved_by,
        approved_at
    ) VALUES (
        p_user_id,
        v_attendance_ids,
        p_start_date,
        p_end_date,
        'salary',
        v_base_amount,
        v_overtime_amount,
        v_total_amount,
        'pending',
        p_approved_by,
        NOW()
    ) RETURNING id INTO v_payment_id;
    
    RETURN json_build_object(
        'success', true,
        'payment_id', v_payment_id,
        'total_amount', v_total_amount,
        'attendance_count', array_length(v_attendance_ids, 1)
    );
END;
$$;

-- =====================================================
-- 6. APPROVE ATTENDANCE BATCH
-- =====================================================
-- Bulk approve multiple attendance records

CREATE OR REPLACE FUNCTION approve_attendance_batch(
    p_attendance_ids UUID[],
    p_approved_by UUID,
    p_admin_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE attendance
    SET 
        status = 'approved',
        reviewed_by = p_approved_by,
        reviewed_at = NOW(),
        admin_notes = COALESCE(p_admin_notes, admin_notes),
        updated_at = NOW()
    WHERE id = ANY(p_attendance_ids)
    AND status = 'pending';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'updated_count', v_updated_count,
        'message', format('%s attendance records approved', v_updated_count)
    );
END;
$$;

-- =====================================================
-- 7. UPDATE WEEKLY SUMMARY (Called by pg_cron)
-- =====================================================

CREATE OR REPLACE FUNCTION update_weekly_summary(p_year INTEGER, p_week INTEGER)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_week_start DATE;
    v_week_end DATE;
    v_top_performers JSONB;
    v_dept_summary JSONB;
    v_daily_breakdown JSONB;
BEGIN
    -- Calculate week start and end dates
    v_week_start := (p_year::TEXT || '-01-01')::DATE + ((p_week - 1) * 7 || ' days')::INTERVAL;
    v_week_end := v_week_start + INTERVAL '6 days';
    
    -- Get top performers
    SELECT json_agg(
        json_build_object(
            'user_id', u.id,
            'name', u.full_name,
            'hours', stats.total_hours,
            'attendance_rate', stats.rate
        ) ORDER BY stats.total_hours DESC
    ) INTO v_top_performers
    FROM (
        SELECT 
            user_id,
            SUM(net_work_hours) as total_hours,
            ROUND(
                (COUNT(*) FILTER (WHERE status IN ('completed', 'approved'))::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ) as rate
        FROM attendance
        WHERE date >= v_week_start AND date <= v_week_end
        GROUP BY user_id
        ORDER BY total_hours DESC
        LIMIT 10
    ) stats
    JOIN my_users u ON u.id = stats.user_id;
    
    -- Get department summary
    SELECT jsonb_object_agg(
        department,
        jsonb_build_object(
            'total_hours', total_hours,
            'avg_hours', avg_hours,
            'attendance_rate', attendance_rate
        )
    ) INTO v_dept_summary
    FROM (
        SELECT 
            u.department,
            SUM(a.net_work_hours) as total_hours,
            AVG(a.net_work_hours) as avg_hours,
            ROUND(
                (COUNT(*) FILTER (WHERE a.status IN ('completed', 'approved'))::NUMERIC / 
                NULLIF(COUNT(*), 0)) * 100, 2
            ) as attendance_rate
        FROM attendance a
        JOIN my_users u ON u.id = a.user_id
        WHERE a.date >= v_week_start AND a.date <= v_week_end
        GROUP BY u.department
    ) dept_stats;
    
    -- Get daily breakdown
    SELECT json_agg(
        json_build_object(
            'date', date,
            'present', present_count,
            'absent', absent_count,
            'hours', total_hours
        ) ORDER BY date
    ) INTO v_daily_breakdown
    FROM (
        SELECT 
            date,
            COUNT(*) FILTER (WHERE status IN ('completed', 'approved')) as present_count,
            COUNT(*) FILTER (WHERE status = 'absent') as absent_count,
            SUM(net_work_hours) as total_hours
        FROM attendance
        WHERE date >= v_week_start AND date <= v_week_end
        GROUP BY date
    ) daily_stats;
    
    -- Insert or update weekly summary
    INSERT INTO weekly_attendance_summary (
        year, week_number, week_start_date, week_end_date,
        total_employees, avg_daily_present, total_absences, total_late_arrivals,
        total_work_hours, total_overtime_hours, avg_hours_per_employee,
        total_earnings_week, total_overtime_pay, avg_earnings_per_employee,
        weekly_attendance_rate, weekly_punctuality_rate, weekly_uniform_compliance_rate,
        daily_breakdown, top_performers, department_summary
    )
    SELECT 
        p_year, p_week, v_week_start, v_week_end,
        COUNT(DISTINCT user_id),
        AVG(daily_present),
        SUM(absent_count),
        SUM(late_count),
        SUM(total_hours),
        SUM(overtime_hours),
        AVG(avg_hours),
        SUM(total_earnings),
        SUM(overtime_pay),
        AVG(avg_earnings),
        attendance_rate,
        punctuality_rate,
        uniform_rate,
        v_daily_breakdown,
        v_top_performers,
        v_dept_summary
    FROM (
        SELECT 
            user_id,
            COUNT(*) FILTER (WHERE status IN ('completed', 'approved')) as daily_present,
            COUNT(*) FILTER (WHERE status = 'absent') as absent_count,
            COUNT(*) FILTER (WHERE is_late = true) as late_count,
            SUM(net_work_hours) as total_hours,
            SUM(overtime_hours) as overtime_hours,
            AVG(net_work_hours) as avg_hours,
            SUM(total_amount) FILTER (WHERE status IN ('approved', 'granted')) as total_earnings,
            SUM(overtime_amount) as overtime_pay,
            AVG(total_amount) FILTER (WHERE status IN ('approved', 'granted')) as avg_earnings,
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
        WHERE date >= v_week_start AND date <= v_week_end
        GROUP BY user_id
    ) week_stats
    ON CONFLICT (year, week_number) 
    DO UPDATE SET
        total_employees = EXCLUDED.total_employees,
        avg_daily_present = EXCLUDED.avg_daily_present,
        total_absences = EXCLUDED.total_absences,
        total_late_arrivals = EXCLUDED.total_late_arrivals,
        total_work_hours = EXCLUDED.total_work_hours,
        total_overtime_hours = EXCLUDED.total_overtime_hours,
        avg_hours_per_employee = EXCLUDED.avg_hours_per_employee,
        total_earnings_week = EXCLUDED.total_earnings_week,
        total_overtime_pay = EXCLUDED.total_overtime_pay,
        avg_earnings_per_employee = EXCLUDED.avg_earnings_per_employee,
        weekly_attendance_rate = EXCLUDED.weekly_attendance_rate,
        weekly_punctuality_rate = EXCLUDED.weekly_punctuality_rate,
        weekly_uniform_compliance_rate = EXCLUDED.weekly_uniform_compliance_rate,
        daily_breakdown = EXCLUDED.daily_breakdown,
        top_performers = EXCLUDED.top_performers,
        department_summary = EXCLUDED.department_summary,
        last_updated = NOW();
    
    RETURN json_build_object(
        'success', true,
        'year', p_year,
        'week', p_week,
        'week_start', v_week_start,
        'week_end', v_week_end
    );
END;
$$;

-- =====================================================
-- COMMENT: RPC functions created successfully!
-- Use these functions from your Flutter app
-- =====================================================

