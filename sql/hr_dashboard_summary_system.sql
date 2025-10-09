-- =====================================================
-- HR Dashboard Real-Time Summary System
-- =====================================================
-- This script creates all necessary tables, triggers, and RPC functions
-- for a comprehensive HR dashboard with real-time updates
-- =====================================================

-- =====================================================
-- 1. SYSTEM LOGS TABLE (for monitoring)
-- =====================================================
-- Tracks system events, pg_cron executions, and errors

CREATE TABLE IF NOT EXISTS system_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_logs_type ON system_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_system_logs_created_at ON system_logs(created_at DESC);

-- No RLS needed - admin-only access via RPC functions

-- =====================================================
-- 2. PAYMENT TRANSACTIONS TABLE
-- =====================================================
-- Tracks all payments made to employees separately from attendance

CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES my_users(id) ON DELETE CASCADE,
    attendance_ids UUID[] DEFAULT '{}', -- Multiple attendance records paid together
    
    -- Payment Details
    payment_period_start DATE NOT NULL,
    payment_period_end DATE NOT NULL,
    payment_type VARCHAR(50) DEFAULT 'salary', -- 'salary', 'overtime', 'bonus', 'deduction'
    
    -- Amounts
    base_amount NUMERIC(12,2) DEFAULT 0,
    overtime_amount NUMERIC(12,2) DEFAULT 0,
    bonus_amount NUMERIC(12,2) DEFAULT 0,
    deduction_amount NUMERIC(12,2) DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL,
    
    -- Payment Info
    payment_method VARCHAR(50), -- 'bank_transfer', 'cash', 'check'
    payment_reference VARCHAR(255), -- Transaction ID
    payment_date TIMESTAMPTZ,
    payment_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    
    -- Metadata
    approved_by UUID REFERENCES my_users(id),
    approved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT positive_total CHECK (total_amount >= 0)
);

-- Indexes for payment_transactions
CREATE INDEX IF NOT EXISTS idx_payment_user_id ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_status ON payment_transactions(payment_status);
CREATE INDEX IF NOT EXISTS idx_payment_period ON payment_transactions(payment_period_start, payment_period_end);
CREATE INDEX IF NOT EXISTS idx_payment_date ON payment_transactions(payment_date);

-- Enable RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for payment_transactions
CREATE POLICY "Users can view their own payments"
    ON payment_transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all payments"
    ON payment_transactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

CREATE POLICY "Admins can create payments"
    ON payment_transactions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

CREATE POLICY "Admins can update payments"
    ON payment_transactions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

-- =====================================================
-- 2. USER LIFETIME SUMMARY TABLE
-- =====================================================
-- All-time statistics for each employee

CREATE TABLE IF NOT EXISTS user_lifetime_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES my_users(id) ON DELETE CASCADE,
    
    -- Attendance Stats
    total_days_worked INTEGER DEFAULT 0,
    total_days_absent INTEGER DEFAULT 0,
    total_days_late INTEGER DEFAULT 0,
    total_schedules_assigned INTEGER DEFAULT 0,
    total_schedules_completed INTEGER DEFAULT 0,
    
    -- Work Hours
    total_work_hours NUMERIC(12,2) DEFAULT 0,
    total_overtime_hours NUMERIC(12,2) DEFAULT 0,
    avg_daily_hours NUMERIC(5,2) DEFAULT 0,
    
    -- Financial (Lifetime Earnings)
    total_earnings_approved NUMERIC(15,2) DEFAULT 0,
    total_earnings_pending NUMERIC(15,2) DEFAULT 0,
    total_earnings_paid NUMERIC(15,2) DEFAULT 0,
    total_earnings_rejected NUMERIC(15,2) DEFAULT 0,
    lifetime_overtime_pay NUMERIC(15,2) DEFAULT 0,
    
    -- Performance Metrics
    overall_attendance_rate NUMERIC(5,2) DEFAULT 100.00, -- %
    punctuality_rate NUMERIC(5,2) DEFAULT 100.00, -- % on-time arrivals
    uniform_compliance_rate NUMERIC(5,2) DEFAULT 100.00, -- %
    
    -- Streaks
    current_attendance_streak INTEGER DEFAULT 0,
    longest_attendance_streak INTEGER DEFAULT 0,
    current_absence_streak INTEGER DEFAULT 0,
    
    -- Date Tracking
    first_attendance_date DATE,
    last_attendance_date DATE,
    last_payment_date DATE,
    
    -- Metadata
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_rates CHECK (
        overall_attendance_rate >= 0 AND overall_attendance_rate <= 100 AND
        punctuality_rate >= 0 AND punctuality_rate <= 100 AND
        uniform_compliance_rate >= 0 AND uniform_compliance_rate <= 100
    )
);

-- Indexes for user_lifetime_summary
CREATE INDEX IF NOT EXISTS idx_user_lifetime_user_id ON user_lifetime_summary(user_id);
CREATE INDEX IF NOT EXISTS idx_user_lifetime_attendance_rate ON user_lifetime_summary(overall_attendance_rate DESC);
CREATE INDEX IF NOT EXISTS idx_user_lifetime_punctuality ON user_lifetime_summary(punctuality_rate DESC);

-- Enable RLS
ALTER TABLE user_lifetime_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own summary"
    ON user_lifetime_summary FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all summaries"
    ON user_lifetime_summary FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

-- =====================================================
-- 3. DAILY ATTENDANCE SUMMARY TABLE
-- =====================================================
-- Aggregated daily statistics for all employees

CREATE TABLE IF NOT EXISTS daily_attendance_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    summary_date DATE NOT NULL UNIQUE,
    
    -- Headcount
    total_employees_scheduled INTEGER DEFAULT 0,
    total_present INTEGER DEFAULT 0,
    total_absent INTEGER DEFAULT 0,
    total_late INTEGER DEFAULT 0,
    total_on_leave INTEGER DEFAULT 0,
    currently_active INTEGER DEFAULT 0, -- Checked in but not out
    
    -- Work Hours
    total_work_hours NUMERIC(12,2) DEFAULT 0,
    total_overtime_hours NUMERIC(12,2) DEFAULT 0,
    avg_hours_per_employee NUMERIC(5,2) DEFAULT 0,
    
    -- Financial
    total_earnings_today NUMERIC(12,2) DEFAULT 0,
    total_overtime_pay_today NUMERIC(12,2) DEFAULT 0,
    total_pending_approvals NUMERIC(12,2) DEFAULT 0,
    
    -- Performance Rates
    attendance_rate NUMERIC(5,2) DEFAULT 0, -- %
    punctuality_rate NUMERIC(5,2) DEFAULT 0, -- %
    
    -- Status Breakdown
    total_pending INTEGER DEFAULT 0,
    total_approved INTEGER DEFAULT 0,
    total_rejected INTEGER DEFAULT 0,
    total_completed INTEGER DEFAULT 0,
    
    -- Uniform Compliance
    uniform_compliant INTEGER DEFAULT 0,
    uniform_non_compliant INTEGER DEFAULT 0,
    uniform_compliance_rate NUMERIC(5,2) DEFAULT 0,
    
    -- Department Breakdown (JSONB for flexibility)
    department_breakdown JSONB DEFAULT '{}',
    -- Example: {"Engineering": {"present": 10, "absent": 2, "total_hours": 80}}
    
    -- Metadata
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    calculation_status VARCHAR(20) DEFAULT 'pending' -- 'pending', 'in_progress', 'completed'
);

-- Indexes for daily_attendance_summary
CREATE INDEX IF NOT EXISTS idx_daily_summary_date ON daily_attendance_summary(summary_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_summary_status ON daily_attendance_summary(calculation_status);

-- Enable RLS
ALTER TABLE daily_attendance_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can view daily summary"
    ON daily_attendance_summary FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

-- =====================================================
-- 4. WEEKLY ATTENDANCE SUMMARY TABLE
-- =====================================================
-- Aggregated weekly statistics

CREATE TABLE IF NOT EXISTS weekly_attendance_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year INTEGER NOT NULL,
    week_number INTEGER NOT NULL, -- 1-53 (ISO week)
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    
    -- Aggregated Metrics
    total_employees INTEGER DEFAULT 0,
    avg_daily_present NUMERIC(8,2) DEFAULT 0,
    total_absences INTEGER DEFAULT 0,
    total_late_arrivals INTEGER DEFAULT 0,
    
    -- Work Hours
    total_work_hours NUMERIC(12,2) DEFAULT 0,
    total_overtime_hours NUMERIC(12,2) DEFAULT 0,
    avg_hours_per_employee NUMERIC(8,2) DEFAULT 0,
    
    -- Financial
    total_earnings_week NUMERIC(15,2) DEFAULT 0,
    total_overtime_pay NUMERIC(12,2) DEFAULT 0,
    avg_earnings_per_employee NUMERIC(10,2) DEFAULT 0,
    
    -- Performance
    weekly_attendance_rate NUMERIC(5,2) DEFAULT 0,
    weekly_punctuality_rate NUMERIC(5,2) DEFAULT 0,
    weekly_uniform_compliance_rate NUMERIC(5,2) DEFAULT 0,
    
    -- Daily Breakdown (JSONB)
    daily_breakdown JSONB DEFAULT '[]',
    -- Example: [{"date": "2025-10-09", "present": 45, "absent": 5, "hours": 360}, ...]
    
    -- Top Performers
    top_performers JSONB DEFAULT '[]',
    -- Example: [{"user_id": "...", "name": "John", "hours": 50, "rate": 100}, ...]
    
    -- Department Summary
    department_summary JSONB DEFAULT '{}',
    
    -- Metadata
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    is_finalized BOOLEAN DEFAULT false,
    
    CONSTRAINT unique_week UNIQUE(year, week_number)
);

-- Indexes for weekly_attendance_summary
CREATE INDEX IF NOT EXISTS idx_weekly_summary_year_week ON weekly_attendance_summary(year, week_number DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_summary_date_range ON weekly_attendance_summary(week_start_date, week_end_date);

-- Enable RLS
ALTER TABLE weekly_attendance_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can view weekly summary"
    ON weekly_attendance_summary FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

-- =====================================================
-- 5. MONTHLY ATTENDANCE SUMMARY TABLE
-- =====================================================
-- Aggregated monthly statistics for payroll and performance review

CREATE TABLE IF NOT EXISTS monthly_attendance_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year INTEGER NOT NULL,
    month INTEGER NOT NULL, -- 1-12
    month_name VARCHAR(20), -- 'January', 'February', etc.
    
    -- Headcount
    total_employees INTEGER DEFAULT 0,
    total_working_days INTEGER DEFAULT 0,
    avg_daily_attendance NUMERIC(8,2) DEFAULT 0,
    
    -- Work Hours
    total_work_hours NUMERIC(15,2) DEFAULT 0,
    total_overtime_hours NUMERIC(12,2) DEFAULT 0,
    avg_hours_per_employee NUMERIC(10,2) DEFAULT 0,
    avg_hours_per_day NUMERIC(8,2) DEFAULT 0,
    
    -- Financial (PAYROLL)
    total_payroll NUMERIC(18,2) DEFAULT 0,
    total_base_pay NUMERIC(18,2) DEFAULT 0,
    total_overtime_pay NUMERIC(15,2) DEFAULT 0,
    total_bonuses NUMERIC(15,2) DEFAULT 0,
    total_deductions NUMERIC(15,2) DEFAULT 0,
    
    -- Payment Status
    total_approved_earnings NUMERIC(18,2) DEFAULT 0,
    total_pending_earnings NUMERIC(15,2) DEFAULT 0,
    total_paid_amount NUMERIC(18,2) DEFAULT 0,
    total_unpaid_amount NUMERIC(15,2) DEFAULT 0,
    
    -- Performance
    monthly_attendance_rate NUMERIC(5,2) DEFAULT 0,
    monthly_punctuality_rate NUMERIC(5,2) DEFAULT 0,
    monthly_uniform_compliance_rate NUMERIC(5,2) DEFAULT 0,
    
    -- Absences & Issues
    total_absences INTEGER DEFAULT 0,
    total_late_arrivals INTEGER DEFAULT 0,
    total_uniform_violations INTEGER DEFAULT 0,
    
    -- Department Breakdown
    department_summary JSONB DEFAULT '{}',
    -- Example: {"Engineering": {"employees": 20, "attendance_rate": 95.5, "total_pay": 50000}}
    
    -- Weekly Breakdown
    weekly_breakdown JSONB DEFAULT '[]',
    -- Links to weekly_attendance_summary
    
    -- Employee Rankings
    top_performers JSONB DEFAULT '[]', -- Top 10 by attendance
    bottom_performers JSONB DEFAULT '[]', -- Bottom 10
    most_overtime_employees JSONB DEFAULT '[]',
    most_absent_employees JSONB DEFAULT '[]',
    
    -- Cost Analysis
    cost_per_employee NUMERIC(12,2) DEFAULT 0,
    overtime_cost_ratio NUMERIC(5,2) DEFAULT 0, -- Overtime as % of total
    absence_cost_impact NUMERIC(15,2) DEFAULT 0,
    
    -- Metadata
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    is_finalized BOOLEAN DEFAULT false, -- Locked after month end
    finalized_by UUID REFERENCES my_users(id),
    finalized_at TIMESTAMPTZ,
    
    CONSTRAINT unique_month UNIQUE(year, month)
);

-- Indexes for monthly_attendance_summary
CREATE INDEX IF NOT EXISTS idx_monthly_summary_year_month ON monthly_attendance_summary(year DESC, month DESC);
CREATE INDEX IF NOT EXISTS idx_monthly_summary_finalized ON monthly_attendance_summary(is_finalized);

-- Enable RLS
ALTER TABLE monthly_attendance_summary ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can view monthly summary"
    ON monthly_attendance_summary FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

-- =====================================================
-- COMMENT: Tables created successfully!
-- Next: Create trigger functions in separate file
-- =====================================================

