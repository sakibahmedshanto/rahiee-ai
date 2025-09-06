-- =====================================================
-- COMPREHENSIVE ATTENDANCE MANAGEMENT SYSTEM - SQL SCHEMA
-- =====================================================
-- This file contains the complete database schema for the attendance management system
-- Including schedule management, attendance tracking, schedule swaps, and real-time summaries

-- =====================================================
-- 1. ENHANCED SCHEDULE SWAP SYSTEM
-- =====================================================

-- Schedule Swap Requests Table
CREATE TABLE IF NOT EXISTS schedule_swap_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    original_schedule_id UUID NOT NULL REFERENCES employee_schedules(id) ON DELETE CASCADE,
    requesting_employee_id UUID NOT NULL REFERENCES my_users(id) ON DELETE CASCADE,
    target_employee_id UUID NOT NULL REFERENCES my_users(id) ON DELETE CASCADE,
    target_schedule_id UUID REFERENCES employee_schedules(id) ON DELETE CASCADE,
    swap_type VARCHAR(20) NOT NULL DEFAULT 'direct' CHECK (swap_type IN ('direct', 'coverage', 'trade')),
    request_reason TEXT,
    admin_approval_required BOOLEAN DEFAULT true,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'completed')),
    
    -- Approval workflow
    approved_by_employee BOOLEAN DEFAULT false,
    approved_by_target BOOLEAN DEFAULT false,
    approved_by_admin UUID REFERENCES my_users(id),
    admin_approval_date TIMESTAMPTZ,
    admin_notes TEXT,
    
    -- Automatic expiry
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '72 hours'),
    
    -- Swap details
    compensation_offered NUMERIC(10,2) DEFAULT 0.00,
    swap_conditions JSONB,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT different_employees CHECK (requesting_employee_id != target_employee_id),
    CONSTRAINT valid_expiry CHECK (expires_at > created_at)
);

-- Schedule Coverage Requests (for one-way coverage without swap)
CREATE TABLE IF NOT EXISTS schedule_coverage_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    schedule_id UUID NOT NULL REFERENCES employee_schedules(id) ON DELETE CASCADE,
    requesting_employee_id UUID NOT NULL REFERENCES my_users(id) ON DELETE CASCADE,
    covering_employee_id UUID REFERENCES my_users(id) ON DELETE CASCADE,
    coverage_type VARCHAR(20) NOT NULL DEFAULT 'full' 
        CHECK (coverage_type IN ('full', 'partial', 'emergency')),
    
    status VARCHAR(20) NOT NULL DEFAULT 'open' 
        CHECK (status IN ('open', 'accepted', 'rejected', 'completed', 'cancelled')),
    
    -- Coverage details
    coverage_start_time TIMESTAMPTZ,
    coverage_end_time TIMESTAMPTZ,
    compensation_rate NUMERIC(10,2),
    emergency_priority INTEGER DEFAULT 0,
    
    -- Reason and notes
    reason TEXT NOT NULL,
    covering_employee_notes TEXT,
    admin_notes TEXT,
    
    -- Approval
    requires_admin_approval BOOLEAN DEFAULT false,
    approved_by UUID REFERENCES my_users(id),
    approved_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '48 hours')
);

-- =====================================================
-- 2. NOTIFICATION SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES my_users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    
    -- Status
    is_read BOOLEAN DEFAULT false,
    is_push_sent BOOLEAN DEFAULT false,
    
    -- Priority and category
    priority INTEGER DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
    category VARCHAR(50) DEFAULT 'general',
    
    -- References
    reference_id UUID, -- Can reference schedule, attendance, swap request, etc.
    reference_type VARCHAR(50),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
);

-- =====================================================
-- 3. ENHANCED REAL-TIME DASHBOARD VIEWS
-- =====================================================

-- Real-time Active Schedules View
CREATE OR REPLACE VIEW active_schedules_view AS
SELECT 
    es.id,
    es.title,
    es.start_date_time,
    es.end_date_time,
    es.status as schedule_status,
    es.department,
    es.location,
    
    -- Employee details
    assigned_emp.id as assigned_employee_id,
    assigned_emp.full_name as assigned_employee_name,
    assigned_emp.employee_id as assigned_employee_code,
    
    actual_emp.id as actual_employee_id,
    actual_emp.full_name as actual_employee_name,
    actual_emp.employee_id as actual_employee_code,
    
    -- Admin details
    admin.full_name as created_by_admin_name,
    
    -- Attendance status
    att.id as attendance_id,
    att.check_in_time,
    att.check_out_time,
    att.status as attendance_status,
    att.total_work_hours,
    att.net_work_hours,
    att.overtime_hours,
    
    -- Swap information
    CASE 
        WHEN swap_req.id IS NOT NULL THEN true 
        ELSE false 
    END as has_swap_request,
    swap_req.status as swap_status,
    swap_req.requesting_employee_id as swap_requester_id,
    swap_req.target_employee_id as swap_target_id,
    
    -- Coverage information
    CASE 
        WHEN cov_req.id IS NOT NULL THEN true 
        ELSE false 
    END as has_coverage_request,
    cov_req.status as coverage_status,
    cov_req.covering_employee_id,
    
    es.created_at,
    es.updated_at
    
FROM employee_schedules es
LEFT JOIN my_users assigned_emp ON es.assigned_user_id = assigned_emp.id
LEFT JOIN my_users actual_emp ON es.actual_user_id = actual_emp.id
LEFT JOIN my_users admin ON es.created_by_admin_id = admin.id
LEFT JOIN attendance att ON att.employee_id = COALESCE(es.actual_user_id, es.assigned_user_id) 
    AND att.date = es.start_date_time::date
LEFT JOIN schedule_swap_requests swap_req ON swap_req.original_schedule_id = es.id 
    AND swap_req.status IN ('pending', 'approved')
LEFT JOIN schedule_coverage_requests cov_req ON cov_req.schedule_id = es.id 
    AND cov_req.status IN ('open', 'accepted')
WHERE es.is_active = true
ORDER BY es.start_date_time ASC;

-- Real-time Employee Performance Dashboard
CREATE OR REPLACE VIEW employee_performance_dashboard AS
SELECT 
    u.id as employee_id,
    u.employee_id as employee_code,
    u.full_name,
    u.department,
    u.position,
    u.user_role,
    u.salary_rate,
    
    -- Current month statistics
    COALESCE(monthly.total_work_hours, 0) as monthly_work_hours,
    COALESCE(monthly.total_overtime_hours, 0) as monthly_overtime_hours,
    COALESCE(monthly.total_granted_hours, 0) as monthly_granted_hours,
    COALESCE(monthly.attendance_rate, 0) as monthly_attendance_rate,
    COALESCE(monthly.gross_earnings, 0) as monthly_gross_earnings,
    COALESCE(monthly.total_paid, 0) as monthly_paid,
    COALESCE(monthly.total_unpaid, 0) as monthly_unpaid,
    
    -- Today's status
    today_att.check_in_time as today_check_in,
    today_att.check_out_time as today_check_out,
    today_att.status as today_attendance_status,
    COALESCE(today_att.net_work_hours, 0) as today_work_hours,
    
    -- Schedule information
    upcoming_schedules.upcoming_count,
    upcoming_schedules.next_schedule_time,
    
    -- Swap and coverage statistics
    u.total_coverage_given,
    u.total_coverage_received,
    swap_stats.pending_swap_requests,
    swap_stats.completed_swaps_this_month,
    
    -- Performance metrics
    COALESCE(monthly.punctuality_rate, 100) as punctuality_rate,
    COALESCE(monthly.approval_rate, 0) as approval_rate,
    
    u.is_active,
    u.created_on,
    u.updated_at
    
FROM my_users u
LEFT JOIN monthly_employee_summary monthly ON monthly.employee_id = u.id 
    AND monthly.year = EXTRACT(YEAR FROM NOW())
    AND monthly.month = EXTRACT(MONTH FROM NOW())
LEFT JOIN attendance today_att ON today_att.employee_id = u.id 
    AND today_att.date = CURRENT_DATE
LEFT JOIN (
    SELECT 
        COALESCE(assigned_user_id, actual_user_id) as employee_id,
        COUNT(*) as upcoming_count,
        MIN(start_date_time) as next_schedule_time
    FROM employee_schedules 
    WHERE start_date_time > NOW() 
        AND is_active = true 
        AND status = 'active'
    GROUP BY COALESCE(assigned_user_id, actual_user_id)
) upcoming_schedules ON upcoming_schedules.employee_id = u.id
LEFT JOIN (
    SELECT 
        requesting_employee_id as employee_id,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_swap_requests,
        COUNT(CASE WHEN status = 'completed' 
                  AND DATE_TRUNC('month', completed_at) = DATE_TRUNC('month', NOW()) 
                  THEN 1 END) as completed_swaps_this_month
    FROM schedule_swap_requests
    GROUP BY requesting_employee_id
) swap_stats ON swap_stats.employee_id = u.id
WHERE u.user_role IN ('employee', 'manager')
ORDER BY u.full_name;

-- =====================================================
-- 4. ENHANCED FUNCTIONS FOR SCHEDULE MANAGEMENT
-- =====================================================

-- Function to create schedule swap request
CREATE OR REPLACE FUNCTION create_schedule_swap_request(
    p_original_schedule_id UUID,
    p_requesting_employee_id UUID,
    p_target_employee_id UUID,
    p_target_schedule_id UUID DEFAULT NULL,
    p_swap_type VARCHAR DEFAULT 'direct',
    p_reason TEXT DEFAULT NULL,
    p_compensation NUMERIC DEFAULT 0.00
) RETURNS UUID AS $$
DECLARE
    v_swap_request_id UUID;
    v_requires_admin_approval BOOLEAN := true;
    v_original_schedule RECORD;
    v_target_schedule RECORD;
BEGIN
    -- Validate original schedule exists and belongs to requesting employee
    SELECT * INTO v_original_schedule 
    FROM employee_schedules 
    WHERE id = p_original_schedule_id 
        AND (assigned_user_id = p_requesting_employee_id OR actual_user_id = p_requesting_employee_id)
        AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Schedule not found or does not belong to requesting employee';
    END IF;
    
    -- If target schedule specified, validate it
    IF p_target_schedule_id IS NOT NULL THEN
        SELECT * INTO v_target_schedule 
        FROM employee_schedules 
        WHERE id = p_target_schedule_id 
            AND (assigned_user_id = p_target_employee_id OR actual_user_id = p_target_employee_id)
            AND is_active = true;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Target schedule not found or does not belong to target employee';
        END IF;
        
        -- Check for schedule conflicts
        IF check_schedule_conflict(p_requesting_employee_id, v_target_schedule.start_date_time, v_target_schedule.end_date_time) THEN
            RAISE EXCEPTION 'Schedule conflict detected for requesting employee';
        END IF;
        
        IF check_schedule_conflict(p_target_employee_id, v_original_schedule.start_date_time, v_original_schedule.end_date_time) THEN
            RAISE EXCEPTION 'Schedule conflict detected for target employee';
        END IF;
    END IF;
    
    -- Create swap request
    INSERT INTO schedule_swap_requests (
        original_schedule_id,
        requesting_employee_id,
        target_employee_id,
        target_schedule_id,
        swap_type,
        request_reason,
        compensation_offered,
        admin_approval_required
    ) VALUES (
        p_original_schedule_id,
        p_requesting_employee_id,
        p_target_employee_id,
        p_target_schedule_id,
        p_swap_type,
        p_reason,
        p_compensation,
        v_requires_admin_approval
    ) RETURNING id INTO v_swap_request_id;
    
    -- Create notification for target employee
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        reference_id,
        reference_type,
        data
    ) VALUES (
        p_target_employee_id,
        'schedule_swap_request',
        'New Schedule Swap Request',
        'You have received a new schedule swap request',
        v_swap_request_id,
        'schedule_swap_request',
        jsonb_build_object(
            'requesting_employee_id', p_requesting_employee_id,
            'original_schedule_id', p_original_schedule_id,
            'swap_type', p_swap_type
        )
    );
    
    RETURN v_swap_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to approve/reject schedule swap request
CREATE OR REPLACE FUNCTION process_schedule_swap_request(
    p_swap_request_id UUID,
    p_approver_id UUID,
    p_approver_type VARCHAR, -- 'employee', 'target', 'admin'
    p_action VARCHAR, -- 'approve', 'reject'
    p_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_swap_request RECORD;
    v_can_complete BOOLEAN := false;
BEGIN
    -- Get swap request details
    SELECT * INTO v_swap_request 
    FROM schedule_swap_requests 
    WHERE id = p_swap_request_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Swap request not found or already processed';
    END IF;
    
    -- Process based on approver type
    IF p_approver_type = 'employee' AND p_approver_id = v_swap_request.requesting_employee_id THEN
        UPDATE schedule_swap_requests 
        SET approved_by_employee = (p_action = 'approve')
        WHERE id = p_swap_request_id;
    ELSIF p_approver_type = 'target' AND p_approver_id = v_swap_request.target_employee_id THEN
        UPDATE schedule_swap_requests 
        SET approved_by_target = (p_action = 'approve')
        WHERE id = p_swap_request_id;
    ELSIF p_approver_type = 'admin' THEN
        UPDATE schedule_swap_requests 
        SET 
            approved_by_admin = p_approver_id,
            admin_approval_date = NOW(),
            admin_notes = p_notes
        WHERE id = p_swap_request_id;
    ELSE
        RAISE EXCEPTION 'Invalid approver or approver type';
    END IF;
    
    -- Check if request is rejected
    IF p_action = 'reject' THEN
        UPDATE schedule_swap_requests 
        SET status = 'rejected', updated_at = NOW()
        WHERE id = p_swap_request_id;
        
        -- Notify requesting employee
        INSERT INTO notifications (
            user_id, type, title, message, reference_id, reference_type
        ) VALUES (
            v_swap_request.requesting_employee_id,
            'schedule_swap_rejected',
            'Schedule Swap Request Rejected',
            'Your schedule swap request has been rejected',
            p_swap_request_id,
            'schedule_swap_request'
        );
        
        RETURN true;
    END IF;
    
    -- Re-fetch updated request
    SELECT * INTO v_swap_request 
    FROM schedule_swap_requests 
    WHERE id = p_swap_request_id;
    
    -- Check if all approvals are complete
    v_can_complete := COALESCE(v_swap_request.approved_by_employee, false) 
                     AND COALESCE(v_swap_request.approved_by_target, false)
                     AND (NOT v_swap_request.admin_approval_required OR v_swap_request.approved_by_admin IS NOT NULL);
    
    -- Complete the swap if all approvals are done
    IF v_can_complete THEN
        -- Swap the employee assignments
        UPDATE employee_schedules 
        SET actual_user_id = v_swap_request.target_employee_id,
            updated_at = NOW()
        WHERE id = v_swap_request.original_schedule_id;
        
        -- If there's a target schedule, swap that too
        IF v_swap_request.target_schedule_id IS NOT NULL THEN
            UPDATE employee_schedules 
            SET actual_user_id = v_swap_request.requesting_employee_id,
                updated_at = NOW()
            WHERE id = v_swap_request.target_schedule_id;
        END IF;
        
        -- Update swap request status
        UPDATE schedule_swap_requests 
        SET status = 'completed', completed_at = NOW(), updated_at = NOW()
        WHERE id = p_swap_request_id;
        
        -- Update user coverage statistics
        UPDATE my_users 
        SET total_coverage_given = total_coverage_given + 1
        WHERE id = v_swap_request.target_employee_id;
        
        UPDATE my_users 
        SET total_coverage_received = total_coverage_received + 1
        WHERE id = v_swap_request.requesting_employee_id;
        
        -- Create completion notifications
        INSERT INTO notifications (user_id, type, title, message, reference_id, reference_type)
        VALUES 
        (v_swap_request.requesting_employee_id, 'schedule_swap_completed', 'Schedule Swap Completed', 'Your schedule swap has been completed successfully', p_swap_request_id, 'schedule_swap_request'),
        (v_swap_request.target_employee_id, 'schedule_swap_completed', 'Schedule Swap Completed', 'Schedule swap has been completed successfully', p_swap_request_id, 'schedule_swap_request');
    END IF;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get real-time dashboard data
CREATE OR REPLACE FUNCTION get_realtime_admin_dashboard(
    p_date_from DATE DEFAULT CURRENT_DATE,
    p_date_to DATE DEFAULT CURRENT_DATE
) RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'summary', json_build_object(
            'total_employees', (SELECT COUNT(*) FROM my_users WHERE user_role = 'employee' AND is_active = true),
            'total_schedules_today', (SELECT COUNT(*) FROM employee_schedules WHERE start_date_time::date = CURRENT_DATE AND is_active = true),
            'checked_in_today', (SELECT COUNT(*) FROM attendance WHERE date = CURRENT_DATE AND check_in_time IS NOT NULL),
            'checked_out_today', (SELECT COUNT(*) FROM attendance WHERE date = CURRENT_DATE AND check_out_time IS NOT NULL),
            'pending_approvals', (SELECT COUNT(*) FROM attendance WHERE status = 'pending'),
            'pending_swap_requests', (SELECT COUNT(*) FROM schedule_swap_requests WHERE status = 'pending'),
            'active_coverage_requests', (SELECT COUNT(*) FROM schedule_coverage_requests WHERE status IN ('open', 'accepted'))
        ),
        'active_schedules', (
            SELECT json_agg(row_to_json(asv))
            FROM active_schedules_view asv
            WHERE asv.start_date_time::date BETWEEN p_date_from AND p_date_to
        ),
        'pending_attendance', (
            SELECT json_agg(
                json_build_object(
                    'id', a.id,
                    'employee_name', u.full_name,
                    'employee_code', u.employee_id,
                    'date', a.date,
                    'check_in_time', a.check_in_time,
                    'check_out_time', a.check_out_time,
                    'total_work_hours', a.total_work_hours,
                    'net_work_hours', a.net_work_hours,
                    'overtime_hours', a.overtime_hours,
                    'status', a.status,
                    'employee_notes', a.employee_notes
                )
            )
            FROM attendance a
            JOIN my_users u ON a.employee_id = u.id
            WHERE a.status = 'pending'
            ORDER BY a.date DESC, a.check_in_time DESC
        ),
        'recent_swaps', (
            SELECT json_agg(
                json_build_object(
                    'id', ssr.id,
                    'requesting_employee', req_emp.full_name,
                    'target_employee', tgt_emp.full_name,
                    'status', ssr.status,
                    'swap_type', ssr.swap_type,
                    'created_at', ssr.created_at,
                    'original_schedule_title', es.title,
                    'schedule_date', es.start_date_time
                )
            )
            FROM schedule_swap_requests ssr
            JOIN my_users req_emp ON ssr.requesting_employee_id = req_emp.id
            JOIN my_users tgt_emp ON ssr.target_employee_id = tgt_emp.id
            JOIN employee_schedules es ON ssr.original_schedule_id = es.id
            WHERE ssr.created_at >= CURRENT_DATE - INTERVAL '7 days'
            ORDER BY ssr.created_at DESC
            LIMIT 10
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. TRIGGERS FOR REAL-TIME UPDATES
-- =====================================================

-- Trigger function for real-time notifications
CREATE OR REPLACE FUNCTION notify_realtime_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify attendance changes
    IF TG_TABLE_NAME = 'attendance' THEN
        PERFORM pg_notify('attendance_changes', json_build_object(
            'action', TG_OP,
            'employee_id', COALESCE(NEW.employee_id, OLD.employee_id),
            'attendance_id', COALESCE(NEW.id, OLD.id),
            'status', COALESCE(NEW.status, OLD.status),
            'date', COALESCE(NEW.date, OLD.date)
        )::text);
    END IF;
    
    -- Notify schedule changes
    IF TG_TABLE_NAME = 'employee_schedules' THEN
        PERFORM pg_notify('schedule_changes', json_build_object(
            'action', TG_OP,
            'schedule_id', COALESCE(NEW.id, OLD.id),
            'assigned_user_id', COALESCE(NEW.assigned_user_id, OLD.assigned_user_id),
            'actual_user_id', COALESCE(NEW.actual_user_id, OLD.actual_user_id),
            'status', COALESCE(NEW.status, OLD.status)
        )::text);
    END IF;
    
    -- Notify swap request changes
    IF TG_TABLE_NAME = 'schedule_swap_requests' THEN
        PERFORM pg_notify('swap_request_changes', json_build_object(
            'action', TG_OP,
            'swap_request_id', COALESCE(NEW.id, OLD.id),
            'requesting_employee_id', COALESCE(NEW.requesting_employee_id, OLD.requesting_employee_id),
            'target_employee_id', COALESCE(NEW.target_employee_id, OLD.target_employee_id),
            'status', COALESCE(NEW.status, OLD.status)
        )::text);
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create triggers for real-time notifications
DROP TRIGGER IF EXISTS attendance_realtime_trigger ON attendance;
CREATE TRIGGER attendance_realtime_trigger
    AFTER INSERT OR UPDATE OR DELETE ON attendance
    FOR EACH ROW EXECUTE FUNCTION notify_realtime_changes();

DROP TRIGGER IF EXISTS schedule_realtime_trigger ON employee_schedules;
CREATE TRIGGER schedule_realtime_trigger
    AFTER INSERT OR UPDATE OR DELETE ON employee_schedules
    FOR EACH ROW EXECUTE FUNCTION notify_realtime_changes();

DROP TRIGGER IF EXISTS swap_request_realtime_trigger ON schedule_swap_requests;
CREATE TRIGGER swap_request_realtime_trigger
    AFTER INSERT OR UPDATE OR DELETE ON schedule_swap_requests
    FOR EACH ROW EXECUTE FUNCTION notify_realtime_changes();

-- =====================================================
-- 6. INDEXES FOR PERFORMANCE
-- =====================================================

-- Performance indexes for schedule swaps
CREATE INDEX IF NOT EXISTS idx_schedule_swap_requests_requesting_employee ON schedule_swap_requests(requesting_employee_id);
CREATE INDEX IF NOT EXISTS idx_schedule_swap_requests_target_employee ON schedule_swap_requests(target_employee_id);
CREATE INDEX IF NOT EXISTS idx_schedule_swap_requests_status ON schedule_swap_requests(status);
CREATE INDEX IF NOT EXISTS idx_schedule_swap_requests_created_at ON schedule_swap_requests(created_at);

-- Performance indexes for coverage requests
CREATE INDEX IF NOT EXISTS idx_schedule_coverage_requests_schedule_id ON schedule_coverage_requests(schedule_id);
CREATE INDEX IF NOT EXISTS idx_schedule_coverage_requests_status ON schedule_coverage_requests(status);
CREATE INDEX IF NOT EXISTS idx_schedule_coverage_requests_covering_employee ON schedule_coverage_requests(covering_employee_id);

-- Performance indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_status_date ON attendance(status, date);
CREATE INDEX IF NOT EXISTS idx_schedules_employee_date ON employee_schedules(assigned_user_id, start_date_time);
CREATE INDEX IF NOT EXISTS idx_schedules_actual_employee_date ON employee_schedules(actual_user_id, start_date_time);

-- =====================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE schedule_swap_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_coverage_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for schedule_swap_requests
CREATE POLICY "Users can view their own swap requests" ON schedule_swap_requests
    FOR SELECT USING (requesting_employee_id = auth.uid() OR target_employee_id = auth.uid());

CREATE POLICY "Users can create swap requests" ON schedule_swap_requests
    FOR INSERT WITH CHECK (requesting_employee_id = auth.uid());

CREATE POLICY "Users can update their own swap requests" ON schedule_swap_requests
    FOR UPDATE USING (requesting_employee_id = auth.uid() OR target_employee_id = auth.uid());

CREATE POLICY "Admins can view all swap requests" ON schedule_swap_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM my_users 
            WHERE id = auth.uid() 
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

-- RLS Policies for schedule_coverage_requests
CREATE POLICY "Users can view relevant coverage requests" ON schedule_coverage_requests
    FOR SELECT USING (
        requesting_employee_id = auth.uid() 
        OR covering_employee_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM employee_schedules es
            WHERE es.id = schedule_id 
            AND (es.assigned_user_id = auth.uid() OR es.actual_user_id = auth.uid())
        )
    );

CREATE POLICY "Users can create coverage requests" ON schedule_coverage_requests
    FOR INSERT WITH CHECK (requesting_employee_id = auth.uid());

-- RLS Policies for notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- =====================================================
-- 8. SAMPLE DATA FOR TESTING
-- =====================================================

-- Note: This section would typically be run separately in development
-- Uncomment the following lines if you want to insert sample data

/*
-- Sample swap request
INSERT INTO schedule_swap_requests (
    original_schedule_id,
    requesting_employee_id,
    target_employee_id,
    swap_type,
    request_reason
) SELECT 
    es1.id,
    es1.assigned_user_id,
    es2.assigned_user_id,
    'direct',
    'Need to attend family emergency'
FROM employee_schedules es1, employee_schedules es2
WHERE es1.id != es2.id 
    AND es1.is_active = true 
    AND es2.is_active = true
LIMIT 1;
*/

-- =====================================================
-- END OF COMPREHENSIVE ATTENDANCE SYSTEM SCHEMA
-- =====================================================
