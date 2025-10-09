-- =====================================================
-- HR Dashboard Trigger Functions
-- =====================================================
-- Auto-update summary tables when attendance changes
-- =====================================================

-- =====================================================
-- 1. UPDATE USER LIFETIME SUMMARY TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION update_user_lifetime_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_total_days INTEGER;
    v_total_hours NUMERIC;
BEGIN
    -- Get user_id from NEW or OLD record
    v_user_id := COALESCE(NEW.user_id, OLD.user_id);
    
    -- Ensure user has a summary record
    INSERT INTO user_lifetime_summary (user_id)
    VALUES (v_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Recalculate all stats for this user
    UPDATE user_lifetime_summary uls
    SET
        -- Attendance Stats
        total_days_worked = (
            SELECT COUNT(DISTINCT date) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND status IN ('completed', 'approved', 'granted')
        ),
        total_days_absent = (
            SELECT COUNT(DISTINCT date) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND status = 'absent'
        ),
        total_days_late = (
            SELECT COUNT(DISTINCT date) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND is_late = true
        ),
        total_schedules_assigned = (
            SELECT COUNT(*) 
            FROM schedule_assignments 
            WHERE user_id = v_user_id 
            AND is_active = true
        ),
        total_schedules_completed = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND status IN ('completed', 'approved')
        ),
        
        -- Work Hours
        total_work_hours = (
            SELECT COALESCE(SUM(net_work_hours), 0) 
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        total_overtime_hours = (
            SELECT COALESCE(SUM(overtime_hours), 0) 
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        avg_daily_hours = (
            SELECT COALESCE(AVG(net_work_hours), 0) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND status IN ('completed', 'approved')
        ),
        
        -- Financial
        total_earnings_approved = (
            SELECT COALESCE(SUM(total_amount), 0) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND status IN ('approved', 'granted')
        ),
        total_earnings_pending = (
            SELECT COALESCE(SUM(total_amount), 0) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND status = 'pending'
        ),
        total_earnings_paid = (
            SELECT COALESCE(SUM(paid_amount), 0) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND payment_status = 'paid'
        ),
        total_earnings_rejected = (
            SELECT COALESCE(SUM(total_amount), 0) 
            FROM attendance 
            WHERE user_id = v_user_id 
            AND status IN ('rejected', 'not_granted')
        ),
        lifetime_overtime_pay = (
            SELECT COALESCE(SUM(overtime_amount), 0) 
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        
        -- Performance Metrics
        overall_attendance_rate = (
            SELECT CASE 
                WHEN COUNT(*) = 0 THEN 100.00
                ELSE ROUND(
                    (COUNT(*) FILTER (WHERE status IN ('completed', 'approved', 'granted'))::NUMERIC / 
                    COUNT(*)) * 100, 2
                )
            END
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        punctuality_rate = (
            SELECT CASE 
                WHEN COUNT(*) FILTER (WHERE status IN ('completed', 'approved')) = 0 THEN 100.00
                ELSE ROUND(
                    (COUNT(*) FILTER (WHERE is_late = false AND status IN ('completed', 'approved'))::NUMERIC / 
                    COUNT(*) FILTER (WHERE status IN ('completed', 'approved'))) * 100, 2
                )
            END
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        uniform_compliance_rate = (
            SELECT CASE 
                WHEN COUNT(*) FILTER (WHERE wearing_uniform IS NOT NULL) = 0 THEN 100.00
                ELSE ROUND(
                    (COUNT(*) FILTER (WHERE wearing_uniform = true)::NUMERIC / 
                    COUNT(*) FILTER (WHERE wearing_uniform IS NOT NULL)) * 100, 2
                )
            END
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        
        -- Date Tracking
        first_attendance_date = (
            SELECT MIN(date) 
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        last_attendance_date = (
            SELECT MAX(date) 
            FROM attendance 
            WHERE user_id = v_user_id
        ),
        last_payment_date = (
            SELECT MAX(payment_date) 
            FROM payment_transactions 
            WHERE user_id = v_user_id 
            AND payment_status = 'completed'
        ),
        
        last_updated = NOW()
    WHERE uls.user_id = v_user_id;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Attach trigger to attendance table
DROP TRIGGER IF EXISTS trg_update_user_lifetime_summary ON attendance;
CREATE TRIGGER trg_update_user_lifetime_summary
AFTER INSERT OR UPDATE OR DELETE ON attendance
FOR EACH ROW
EXECUTE FUNCTION update_user_lifetime_summary();

-- =====================================================
-- 2. UPDATE DAILY SUMMARY TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION update_daily_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_date DATE;
    v_dept_breakdown JSONB;
BEGIN
    v_date := COALESCE(NEW.date, OLD.date);
    
    -- Ensure daily summary record exists
    INSERT INTO daily_attendance_summary (summary_date)
    VALUES (v_date)
    ON CONFLICT (summary_date) DO NOTHING;
    
    -- Calculate department breakdown
    SELECT jsonb_object_agg(
        COALESCE(department, 'Unknown'),
        jsonb_build_object(
            'present', present_count,
            'absent', absent_count,
            'late', late_count,
            'total_hours', total_hours
        )
    ) INTO v_dept_breakdown
    FROM (
        SELECT 
            u.department,
            COUNT(*) FILTER (WHERE a.status IN ('completed', 'approved', 'granted')) as present_count,
            COUNT(*) FILTER (WHERE a.status = 'absent') as absent_count,
            COUNT(*) FILTER (WHERE a.is_late = true) as late_count,
            COALESCE(SUM(a.net_work_hours), 0) as total_hours
        FROM attendance a
        JOIN my_users u ON u.id = a.user_id
        WHERE a.date = v_date
        GROUP BY u.department
    ) dept_stats;
    
    -- Update daily summary
    UPDATE daily_attendance_summary das
    SET
        -- Headcount
        total_employees_scheduled = (
            SELECT COUNT(DISTINCT user_id) 
            FROM attendance 
            WHERE date = v_date
        ),
        total_present = (
            SELECT COUNT(DISTINCT user_id) 
            FROM attendance 
            WHERE date = v_date 
            AND status IN ('completed', 'approved', 'granted', 'pending_checkout')
        ),
        total_absent = (
            SELECT COUNT(DISTINCT user_id) 
            FROM attendance 
            WHERE date = v_date 
            AND status = 'absent'
        ),
        total_late = (
            SELECT COUNT(DISTINCT user_id) 
            FROM attendance 
            WHERE date = v_date 
            AND is_late = true
        ),
        currently_active = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE date = v_date 
            AND check_in_time IS NOT NULL 
            AND check_out_time IS NULL
        ),
        
        -- Work Hours
        total_work_hours = (
            SELECT COALESCE(SUM(net_work_hours), 0) 
            FROM attendance 
            WHERE date = v_date
        ),
        total_overtime_hours = (
            SELECT COALESCE(SUM(overtime_hours), 0) 
            FROM attendance 
            WHERE date = v_date
        ),
        avg_hours_per_employee = (
            SELECT COALESCE(AVG(net_work_hours), 0) 
            FROM attendance 
            WHERE date = v_date 
            AND net_work_hours > 0
        ),
        
        -- Financial
        total_earnings_today = (
            SELECT COALESCE(SUM(total_amount), 0) 
            FROM attendance 
            WHERE date = v_date 
            AND status IN ('approved', 'granted')
        ),
        total_overtime_pay_today = (
            SELECT COALESCE(SUM(overtime_amount), 0) 
            FROM attendance 
            WHERE date = v_date
        ),
        total_pending_approvals = (
            SELECT COALESCE(SUM(total_amount), 0) 
            FROM attendance 
            WHERE date = v_date 
            AND status = 'pending'
        ),
        
        -- Performance Rates
        attendance_rate = (
            SELECT CASE 
                WHEN COUNT(*) = 0 THEN 0
                ELSE ROUND(
                    (COUNT(*) FILTER (WHERE status IN ('completed', 'approved', 'granted'))::NUMERIC / 
                    COUNT(*)) * 100, 2
                )
            END
            FROM attendance 
            WHERE date = v_date
        ),
        punctuality_rate = (
            SELECT CASE 
                WHEN COUNT(*) FILTER (WHERE status IN ('completed', 'approved')) = 0 THEN 0
                ELSE ROUND(
                    (COUNT(*) FILTER (WHERE is_late = false)::NUMERIC / 
                    COUNT(*) FILTER (WHERE status IN ('completed', 'approved'))) * 100, 2
                )
            END
            FROM attendance 
            WHERE date = v_date
        ),
        
        -- Status Breakdown
        total_pending = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE date = v_date 
            AND status = 'pending'
        ),
        total_approved = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE date = v_date 
            AND status IN ('approved', 'granted')
        ),
        total_rejected = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE date = v_date 
            AND status IN ('rejected', 'not_granted')
        ),
        total_completed = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE date = v_date 
            AND status = 'completed'
        ),
        
        -- Uniform Compliance
        uniform_compliant = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE date = v_date 
            AND wearing_uniform = true
        ),
        uniform_non_compliant = (
            SELECT COUNT(*) 
            FROM attendance 
            WHERE date = v_date 
            AND wearing_uniform = false
        ),
        uniform_compliance_rate = (
            SELECT CASE 
                WHEN COUNT(*) FILTER (WHERE wearing_uniform IS NOT NULL) = 0 THEN 0
                ELSE ROUND(
                    (COUNT(*) FILTER (WHERE wearing_uniform = true)::NUMERIC / 
                    COUNT(*) FILTER (WHERE wearing_uniform IS NOT NULL)) * 100, 2
                )
            END
            FROM attendance 
            WHERE date = v_date
        ),
        
        -- Department Breakdown
        department_breakdown = COALESCE(v_dept_breakdown, '{}'::jsonb),
        
        last_updated = NOW(),
        calculation_status = 'completed'
    WHERE das.summary_date = v_date;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Attach trigger to attendance table
DROP TRIGGER IF EXISTS trg_update_daily_summary ON attendance;
CREATE TRIGGER trg_update_daily_summary
AFTER INSERT OR UPDATE OR DELETE ON attendance
FOR EACH ROW
EXECUTE FUNCTION update_daily_summary();

-- =====================================================
-- 3. UPDATE PAYMENT TRACKING TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION update_payment_tracking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update user lifetime summary with payment info
    UPDATE user_lifetime_summary
    SET 
        total_earnings_paid = total_earnings_paid + 
            CASE 
                WHEN NEW.payment_status = 'completed' THEN NEW.total_amount
                ELSE 0
            END,
        last_payment_date = CASE 
            WHEN NEW.payment_status = 'completed' THEN NEW.payment_date
            ELSE last_payment_date
        END,
        last_updated = NOW()
    WHERE user_id = NEW.user_id;
    
    -- Update attendance records as paid
    IF NEW.payment_status = 'completed' AND array_length(NEW.attendance_ids, 1) > 0 THEN
        UPDATE attendance
        SET 
            payment_status = 'paid',
            paid_amount = total_amount,
            updated_at = NOW()
        WHERE id = ANY(NEW.attendance_ids);
    END IF;
    
    RETURN NEW;
END;
$$;

-- Attach trigger to payment_transactions table
DROP TRIGGER IF EXISTS trg_update_payment_tracking ON payment_transactions;
CREATE TRIGGER trg_update_payment_tracking
AFTER INSERT OR UPDATE ON payment_transactions
FOR EACH ROW
EXECUTE FUNCTION update_payment_tracking();

-- =====================================================
-- COMMENT: Trigger functions created successfully!
-- These will auto-update summary tables on attendance changes
-- =====================================================

