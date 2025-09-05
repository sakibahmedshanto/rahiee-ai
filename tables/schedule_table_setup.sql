-- Clean Schedule Table Setup for Rahiee AI
-- This matches the ScheduleModel in the Dart code
-- Run this script in your Supabase SQL Editor after creating the my_users table

-- Drop existing schedule-related tables if they exist
DROP TABLE IF EXISTS public.employee_schedules CASCADE;

-- Main employee schedules table (matches ScheduleModel)
CREATE TABLE IF NOT EXISTS public.employee_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date_time TIMESTAMPTZ NOT NULL,
    end_date_time TIMESTAMPTZ NOT NULL,
    created_by_admin_id UUID NOT NULL REFERENCES public.my_users(id) ON DELETE CASCADE,
    assigned_user_id UUID NOT NULL REFERENCES public.my_users(id) ON DELETE CASCADE,
    actual_user_id UUID REFERENCES public.my_users(id), -- Who actually performed the task
    department VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8), -- GPS coordinates
    longitude DECIMAL(11, 8), -- GPS coordinates
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled', 'reassigned')),
    requirements JSONB, -- ML requirements, uniform check, etc.
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    tags TEXT[], -- Array of tags for categorization
    custom_fields JSONB, -- Future extensibility
    assignment_history JSONB, -- History tracking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CREATE INDEXES FOR BETTER PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_employee_schedules_assigned_user ON public.employee_schedules(assigned_user_id);
CREATE INDEX IF NOT EXISTS idx_employee_schedules_created_by ON public.employee_schedules(created_by_admin_id);
CREATE INDEX IF NOT EXISTS idx_employee_schedules_start_time ON public.employee_schedules(start_date_time);
CREATE INDEX IF NOT EXISTS idx_employee_schedules_end_time ON public.employee_schedules(end_date_time);
CREATE INDEX IF NOT EXISTS idx_employee_schedules_status ON public.employee_schedules(status);
CREATE INDEX IF NOT EXISTS idx_employee_schedules_department ON public.employee_schedules(department);
CREATE INDEX IF NOT EXISTS idx_employee_schedules_location ON public.employee_schedules(location);
CREATE INDEX IF NOT EXISTS idx_employee_schedules_active ON public.employee_schedules(is_active);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.employee_schedules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Users can view all schedules" ON public.employee_schedules;
DROP POLICY IF EXISTS "Users can view assigned schedules" ON public.employee_schedules;
DROP POLICY IF EXISTS "Admins can manage all schedules" ON public.employee_schedules;
DROP POLICY IF EXISTS "Admins can create schedules" ON public.employee_schedules;
DROP POLICY IF EXISTS "Authenticated users can view schedules" ON public.employee_schedules;
DROP POLICY IF EXISTS "Service role full access" ON public.employee_schedules;

-- RLS POLICIES FOR EMPLOYEE_SCHEDULES TABLE (Non-recursive)
CREATE POLICY "Authenticated users can view schedules" ON public.employee_schedules
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can update assigned schedules" ON public.employee_schedules
    FOR UPDATE USING (assigned_user_id = auth.uid() OR actual_user_id = auth.uid());

CREATE POLICY "Admins can insert schedules" ON public.employee_schedules
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Service role full access" ON public.employee_schedules
    FOR ALL USING (auth.role() = 'service_role');

-- GRANT PERMISSIONS
GRANT ALL ON public.employee_schedules TO authenticated;
GRANT SELECT ON public.employee_schedules TO anon;

-- CREATE FUNCTIONS FOR SCHEDULE MANAGEMENT

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-update timestamps
CREATE TRIGGER update_employee_schedules_updated_at BEFORE UPDATE ON public.employee_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to check schedule conflicts (time overlap)
CREATE OR REPLACE FUNCTION check_schedule_conflict(
    p_assigned_user_id UUID,
    p_start_time TIMESTAMPTZ,
    p_end_time TIMESTAMPTZ,
    p_exclude_schedule_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    conflict_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO conflict_count
    FROM public.employee_schedules es
    WHERE es.assigned_user_id = p_assigned_user_id
    AND es.status NOT IN ('cancelled', 'completed')
    AND es.is_active = true
    AND (
        (p_start_time BETWEEN es.start_date_time AND es.end_date_time) OR
        (p_end_time BETWEEN es.start_date_time AND es.end_date_time) OR
        (es.start_date_time BETWEEN p_start_time AND p_end_time) OR
        (es.end_date_time BETWEEN p_start_time AND p_end_time)
    )
    AND (p_exclude_schedule_id IS NULL OR es.id != p_exclude_schedule_id);
    
    RETURN conflict_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get schedules for an employee
CREATE OR REPLACE FUNCTION get_employee_schedules(
    p_assigned_user_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    schedule_id UUID,
    title VARCHAR,
    description TEXT,
    start_date_time TIMESTAMPTZ,
    end_date_time TIMESTAMPTZ,
    status VARCHAR,
    location VARCHAR,
    department VARCHAR,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        es.id,
        es.title,
        es.description,
        es.start_date_time,
        es.end_date_time,
        es.status,
        es.location,
        es.department,
        es.notes
    FROM public.employee_schedules es
    WHERE es.assigned_user_id = p_assigned_user_id
    AND es.is_active = true
    AND DATE(es.start_date_time) >= p_start_date
    AND DATE(es.start_date_time) < p_start_date + (p_days || ' days')::INTERVAL
    ORDER BY es.start_date_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get schedules by department and date range
CREATE OR REPLACE FUNCTION get_schedules_by_department(
    p_department VARCHAR,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_end_date DATE DEFAULT CURRENT_DATE + 7
)
RETURNS TABLE (
    schedule_id UUID,
    title VARCHAR,
    assigned_user_name VARCHAR,
    assigned_user_email VARCHAR,
    start_date_time TIMESTAMPTZ,
    end_date_time TIMESTAMPTZ,
    status VARCHAR,
    location VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        es.id,
        es.title,
        u.full_name,
        u.email,
        es.start_date_time,
        es.end_date_time,
        es.status,
        es.location
    FROM public.employee_schedules es
    JOIN public.my_users u ON es.assigned_user_id = u.id
    WHERE es.department = p_department
    AND es.is_active = true
    AND DATE(es.start_date_time) >= p_start_date
    AND DATE(es.start_date_time) <= p_end_date
    ORDER BY es.start_date_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
