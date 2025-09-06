-- =====================================================
-- ATTENDANCE FUNCTIONS - CLOCK IN/OUT SYSTEM
-- =====================================================
-- This file contains the RPC functions for attendance management

-- Function to handle clock in
CREATE OR REPLACE FUNCTION clock_in(
    p_employee_id UUID,
    p_schedule_id UUID,
    p_check_in_lat DECIMAL DEFAULT NULL,
    p_check_in_lng DECIMAL DEFAULT NULL,
    p_check_in_address TEXT DEFAULT NULL,
    p_device_info JSONB DEFAULT NULL,
    p_employee_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_attendance_id UUID;
    v_schedule_record RECORD;
    v_existing_attendance RECORD;
    v_result JSONB;
BEGIN
    -- Validate employee exists
    IF NOT EXISTS (SELECT 1 FROM my_users WHERE id = p_employee_id AND user_role IN ('employee', 'manager')) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Employee not found or invalid user role'
        );
    END IF;

    -- Validate schedule exists and employee is authorized
    SELECT * INTO v_schedule_record
    FROM employee_schedules 
    WHERE id = p_schedule_id 
        AND is_active = true
        AND (assigned_user_id = p_employee_id OR actual_user_id = p_employee_id);
    
    IF NOT FOUND THEN
        -- Check if there's an approved swap for this schedule
        IF EXISTS (
            SELECT 1 FROM schedule_swap_requests 
            WHERE (original_schedule_id = p_schedule_id OR target_schedule_id = p_schedule_id)
                AND requesting_employee_id = p_employee_id 
                AND status = 'approved'
        ) THEN
            -- Employee is authorized via swap
            SELECT * INTO v_schedule_record
            FROM employee_schedules 
            WHERE id = p_schedule_id AND is_active = true;
        ELSE
            RETURN jsonb_build_object(
                'success', false,
                'message', 'Schedule not found or you are not authorized to check in for this schedule'
            );
        END IF;
    END IF;

    -- Check if already checked in for this schedule today
    SELECT * INTO v_existing_attendance
    FROM attendance 
    WHERE employee_id = p_employee_id 
        AND schedule_id = p_schedule_id
        AND date = CURRENT_DATE;
    
    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'You have already checked in for this schedule today',
            'attendance_id', v_existing_attendance.id
        );
    END IF;

    -- Create new attendance record
    v_attendance_id := gen_random_uuid();
    
    INSERT INTO attendance (
        id,
        employee_id,
        schedule_id,
        date,
        check_in_time,
        check_in_latitude,
        check_in_longitude,
        check_in_address,
        status,
        device_info,
        employee_notes,
        created_at,
        updated_at
    ) VALUES (
        v_attendance_id,
        p_employee_id,
        p_schedule_id,
        CURRENT_DATE,
        NOW(),
        p_check_in_lat,
        p_check_in_lng,
        p_check_in_address,
        'pending_checkout',
        p_device_info,
        p_employee_notes,
        NOW(),
        NOW()
    );

    -- Update schedule status if needed
    UPDATE employee_schedules 
    SET 
        actual_user_id = p_employee_id,
        status = 'in_progress',
        updated_at = NOW()
    WHERE id = p_schedule_id;

    -- Return success response
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Checked in successfully',
        'attendance_id', v_attendance_id,
        'check_in_time', NOW()
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'message', 'Error during check-in: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle clock out
CREATE OR REPLACE FUNCTION clock_out(
    p_attendance_id UUID,
    p_employee_id UUID,
    p_check_out_lat DECIMAL DEFAULT NULL,
    p_check_out_lng DECIMAL DEFAULT NULL,
    p_check_out_address TEXT DEFAULT NULL,
    p_employee_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_attendance_record RECORD;
    v_total_hours DECIMAL;
    v_overtime_hours DECIMAL := 0;
    v_calculated_amount DECIMAL := 0;
    v_standard_hours DECIMAL := 8.0; -- Standard work day
    v_hourly_rate DECIMAL := 15.0; -- Default hourly rate
BEGIN
    -- Get attendance record
    SELECT * INTO v_attendance_record
    FROM attendance 
    WHERE id = p_attendance_id 
        AND employee_id = p_employee_id
        AND check_out_time IS NULL;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Attendance record not found or already checked out'
        );
    END IF;

    -- Calculate total work hours
    v_total_hours := EXTRACT(EPOCH FROM (NOW() - v_attendance_record.check_in_time)) / 3600.0;
    
    -- Calculate overtime (anything over standard hours)
    IF v_total_hours > v_standard_hours THEN
        v_overtime_hours := v_total_hours - v_standard_hours;
    END IF;

    -- Get employee hourly rate if available
    SELECT COALESCE(salary_rate, v_hourly_rate) INTO v_hourly_rate
    FROM my_users 
    WHERE id = p_employee_id;

    -- Calculate payment amount
    v_calculated_amount := (v_standard_hours * v_hourly_rate) + (v_overtime_hours * v_hourly_rate * 1.5);

    -- Update attendance record
    UPDATE attendance 
    SET 
        check_out_time = NOW(),
        check_out_latitude = p_check_out_lat,
        check_out_longitude = p_check_out_lng,
        check_out_address = p_check_out_address,
        status = 'completed',
        total_work_hours = v_total_hours,
        net_work_hours = v_total_hours,
        overtime_hours = v_overtime_hours,
        employee_notes = COALESCE(employee_notes || ' | ' || p_employee_notes, p_employee_notes),
        updated_at = NOW()
    WHERE id = p_attendance_id;

    -- Update schedule status
    UPDATE employee_schedules 
    SET 
        status = 'completed',
        updated_at = NOW()
    WHERE id = v_attendance_record.schedule_id;

    -- Return success response
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Checked out successfully',
        'total_hours', v_total_hours,
        'overtime_hours', v_overtime_hours,
        'calculated_amount', v_calculated_amount,
        'check_out_time', NOW()
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'message', 'Error during check-out: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending attendance for review
CREATE OR REPLACE FUNCTION get_pending_attendance_for_review()
RETURNS SETOF RECORD AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.employee_id,
        u.full_name as employee_name,
        u.employee_id as employee_code,
        a.date,
        a.check_in_time,
        a.check_out_time,
        a.total_work_hours,
        a.net_work_hours,
        a.overtime_hours,
        a.status,
        a.employee_notes,
        es.title as schedule_title
    FROM attendance a
    JOIN my_users u ON a.employee_id = u.id
    LEFT JOIN employee_schedules es ON a.schedule_id = es.id
    WHERE a.status = 'pending'
    ORDER BY a.date DESC, a.check_in_time DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to bulk update attendance status
CREATE OR REPLACE FUNCTION bulk_update_attendance_status(
    p_attendance_ids UUID[],
    p_status TEXT,
    p_reviewed_by UUID,
    p_admin_notes TEXT DEFAULT NULL,
    p_review_reason TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_updated_count INTEGER := 0;
BEGIN
    -- Update all specified attendance records
    UPDATE attendance 
    SET 
        status = p_status,
        reviewed_by = p_reviewed_by,
        reviewed_at = NOW(),
        admin_notes = p_admin_notes,
        review_reason = p_review_reason,
        updated_at = NOW()
    WHERE id = ANY(p_attendance_ids);
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    RETURN jsonb_build_object(
        'success', true,
        'updated_count', v_updated_count,
        'message', format('%s records updated successfully', v_updated_count)
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'message', 'Error updating attendance records: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
