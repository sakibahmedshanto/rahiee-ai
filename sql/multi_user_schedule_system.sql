-- ============================================================================
-- MULTI-USER SCHEDULE ASSIGNMENT SYSTEM
-- ============================================================================
-- This migration transforms the schedule system to support multiple users
-- assigned to a single schedule. This allows admins to assign multiple
-- employees to the same schedule and each employee can mark their own attendance.
-- ============================================================================

-- Step 1: Create the schedule_assignments junction table
-- This table creates a many-to-many relationship between schedules and users
CREATE TABLE IF NOT EXISTS public.schedule_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL REFERENCES public.employee_schedules(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.my_users(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by_admin_id UUID REFERENCES public.my_users(id),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'removed', 'completed', 'reassigned')),
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one user can only be assigned to a schedule once (active assignments)
    UNIQUE(schedule_id, user_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_schedule_assignments_schedule_id ON public.schedule_assignments(schedule_id);
CREATE INDEX IF NOT EXISTS idx_schedule_assignments_user_id ON public.schedule_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_schedule_assignments_status ON public.schedule_assignments(status);
CREATE INDEX IF NOT EXISTS idx_schedule_assignments_active ON public.schedule_assignments(schedule_id, user_id) WHERE is_active = true;

-- Add RLS policies for schedule_assignments
ALTER TABLE public.schedule_assignments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own assignments
CREATE POLICY "Users can view their own schedule assignments"
    ON public.schedule_assignments FOR SELECT
    USING (user_id = auth.uid() OR assigned_by_admin_id = auth.uid());

-- Policy: Admins can insert/update/delete assignments
CREATE POLICY "Admins can manage schedule assignments"
    ON public.schedule_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.my_users
            WHERE id = auth.uid()
            AND user_role IN ('admin', 'ceo', 'manager')
        )
    );

-- ============================================================================
-- Step 2: Migrate existing data from employee_schedules to schedule_assignments
-- ============================================================================
INSERT INTO public.schedule_assignments (schedule_id, user_id, assigned_by_admin_id, status, assigned_at, is_active)
SELECT 
    id as schedule_id,
    assigned_user_id as user_id,
    created_by_admin_id as assigned_by_admin_id,
    CASE 
        WHEN status = 'active' THEN 'active'
        WHEN status = 'completed' THEN 'completed'
        WHEN status = 'cancelled' THEN 'removed'
        WHEN status = 'reassigned' THEN 'reassigned'
        ELSE 'active'
    END as status,
    created_at as assigned_at,
    is_active
FROM public.employee_schedules
WHERE assigned_user_id IS NOT NULL
ON CONFLICT (schedule_id, user_id) DO NOTHING;

-- ============================================================================
-- Step 3: Add new columns to employee_schedules for multi-user support
-- ============================================================================
ALTER TABLE public.employee_schedules 
    ADD COLUMN IF NOT EXISTS max_participants INTEGER DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS min_participants INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS current_participants INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_multi_user BOOLEAN DEFAULT false;

-- Add comment to explain the columns
COMMENT ON COLUMN public.employee_schedules.max_participants IS 'Maximum number of users that can be assigned (NULL = unlimited)';
COMMENT ON COLUMN public.employee_schedules.min_participants IS 'Minimum number of users required for the schedule';
COMMENT ON COLUMN public.employee_schedules.current_participants IS 'Current number of active assigned users';
COMMENT ON COLUMN public.employee_schedules.is_multi_user IS 'Indicates if this schedule supports multiple users';

-- Update existing schedules to reflect current participant count
UPDATE public.employee_schedules es
SET current_participants = (
    SELECT COUNT(*)
    FROM public.schedule_assignments sa
    WHERE sa.schedule_id = es.id
    AND sa.is_active = true
    AND sa.status = 'active'
);

-- ============================================================================
-- Step 4: Create trigger to automatically update current_participants
-- ============================================================================
CREATE OR REPLACE FUNCTION update_schedule_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the schedule's current participant count
    UPDATE public.employee_schedules
    SET 
        current_participants = (
            SELECT COUNT(*)
            FROM public.schedule_assignments
            WHERE schedule_id = COALESCE(NEW.schedule_id, OLD.schedule_id)
            AND is_active = true
            AND status = 'active'
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.schedule_id, OLD.schedule_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_update_schedule_participant_count ON public.schedule_assignments;
CREATE TRIGGER trigger_update_schedule_participant_count
    AFTER INSERT OR UPDATE OR DELETE ON public.schedule_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_schedule_participant_count();

-- ============================================================================
-- Step 5: RPC Functions for Multi-User Schedule Management
-- ============================================================================

-- Function: Assign multiple users to a schedule
CREATE OR REPLACE FUNCTION assign_users_to_schedule(
    p_schedule_id UUID,
    p_user_ids UUID[],
    p_admin_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_schedule RECORD;
    v_assigned_count INTEGER := 0;
    v_failed_count INTEGER := 0;
    v_results JSON[] := '{}';
    v_result JSON;
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.my_users
        WHERE id = p_admin_id
        AND user_role IN ('admin', 'ceo', 'manager')
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unauthorized: Only admins can assign users to schedules'
        );
    END IF;
    
    -- Get schedule details
    SELECT * INTO v_schedule
    FROM public.employee_schedules
    WHERE id = p_schedule_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schedule not found'
        );
    END IF;
    
    -- Check if schedule is active
    IF v_schedule.status != 'active' OR v_schedule.is_active = false THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot assign users to inactive schedule'
        );
    END IF;
    
    -- Loop through each user and assign
    FOREACH v_user_id IN ARRAY p_user_ids
    LOOP
        BEGIN
            -- Check if max participants limit reached
            IF v_schedule.max_participants IS NOT NULL 
               AND v_schedule.current_participants >= v_schedule.max_participants THEN
                v_result := json_build_object(
                    'user_id', v_user_id,
                    'success', false,
                    'error', 'Maximum participants limit reached'
                );
                v_failed_count := v_failed_count + 1;
            ELSE
                -- Insert or update assignment
                INSERT INTO public.schedule_assignments (
                    schedule_id,
                    user_id,
                    assigned_by_admin_id,
                    notes,
                    status,
                    is_active
                ) VALUES (
                    p_schedule_id,
                    v_user_id,
                    p_admin_id,
                    p_notes,
                    'active',
                    true
                )
                ON CONFLICT (schedule_id, user_id)
                DO UPDATE SET
                    status = 'active',
                    is_active = true,
                    assigned_by_admin_id = p_admin_id,
                    notes = p_notes,
                    updated_at = NOW();
                
                v_result := json_build_object(
                    'user_id', v_user_id,
                    'success', true,
                    'message', 'User assigned successfully'
                );
                v_assigned_count := v_assigned_count + 1;
            END IF;
            
            v_results := v_results || v_result;
        EXCEPTION WHEN OTHERS THEN
            v_result := json_build_object(
                'user_id', v_user_id,
                'success', false,
                'error', SQLERRM
            );
            v_results := v_results || v_result;
            v_failed_count := v_failed_count + 1;
        END;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'assigned_count', v_assigned_count,
        'failed_count', v_failed_count,
        'results', array_to_json(v_results)
    );
END;
$$;

-- Function: Remove user from schedule
CREATE OR REPLACE FUNCTION remove_user_from_schedule(
    p_schedule_id UUID,
    p_user_id UUID,
    p_admin_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_schedule RECORD;
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.my_users
        WHERE id = p_admin_id
        AND user_role IN ('admin', 'ceo', 'manager')
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unauthorized: Only admins can remove users from schedules'
        );
    END IF;
    
    -- Update assignment status
    UPDATE public.schedule_assignments
    SET 
        status = 'removed',
        is_active = false,
        notes = COALESCE(p_reason, notes),
        updated_at = NOW()
    WHERE schedule_id = p_schedule_id
    AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Assignment not found'
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'User removed from schedule successfully'
    );
END;
$$;

-- Function: Get schedules with their assigned users
CREATE OR REPLACE FUNCTION get_schedule_with_assignments(
    p_schedule_id UUID DEFAULT NULL,
    p_date DATE DEFAULT NULL,
    p_department VARCHAR DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    schedule_record RECORD;
    schedules_array JSON[] := '{}';
    schedule_obj JSON;
    assigned_users JSON;
BEGIN
    FOR schedule_record IN
        SELECT s.*,
               EXTRACT(EPOCH FROM (s.end_date_time - s.start_date_time))/3600 as duration_hours
        FROM public.employee_schedules s
        WHERE (p_schedule_id IS NULL OR s.id = p_schedule_id)
        AND (p_date IS NULL OR s.start_date_time::date = p_date)
        AND (p_department IS NULL OR s.department = p_department)
        AND s.status != 'cancelled'
        ORDER BY s.start_date_time
    LOOP
        -- Get assigned users for this schedule
        SELECT json_agg(
            json_build_object(
                'user_id', u.id,
                'employee_id', u.employee_id,
                'full_name', u.full_name,
                'email', u.email,
                'department', u.department,
                'position', u.position,
                'assignment_status', sa.status,
                'assigned_at', sa.assigned_at,
                'notes', sa.notes
            )
        ) INTO assigned_users
        FROM public.schedule_assignments sa
        JOIN public.my_users u ON sa.user_id = u.id
        WHERE sa.schedule_id = schedule_record.id
        AND sa.is_active = true;
        
        -- Build schedule object with assignments
        schedule_obj := json_build_object(
            'id', schedule_record.id,
            'title', schedule_record.title,
            'description', schedule_record.description,
            'start_date_time', schedule_record.start_date_time,
            'end_date_time', schedule_record.end_date_time,
            'location', schedule_record.location,
            'department', schedule_record.department,
            'duration_hours', schedule_record.duration_hours,
            'status', schedule_record.status,
            'is_multi_user', schedule_record.is_multi_user,
            'current_participants', schedule_record.current_participants,
            'min_participants', schedule_record.min_participants,
            'max_participants', schedule_record.max_participants,
            'created_by_admin_id', schedule_record.created_by_admin_id,
            'is_active', schedule_record.is_active,
            'created_at', schedule_record.created_at,
            'updated_at', schedule_record.updated_at,
            'assigned_users', COALESCE(assigned_users, '[]'::json)
        );
        
        schedules_array := schedules_array || schedule_obj;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'schedules', array_to_json(schedules_array),
        'total_count', array_length(schedules_array, 1)
    );
END;
$$;

-- Function: Get user schedules (updated to work with assignments table)
CREATE OR REPLACE FUNCTION get_user_schedules_multi(
    p_user_id UUID,
    p_date DATE DEFAULT CURRENT_DATE,
    p_include_attendance BOOLEAN DEFAULT true
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    schedule_record RECORD;
    attendance_record RECORD;
    schedules_array JSON[] := '{}';
    schedule_obj JSON;
BEGIN
    FOR schedule_record IN
        SELECT s.*, 
               EXTRACT(EPOCH FROM (s.end_date_time - s.start_date_time))/3600 as duration_hours,
               sa.assigned_at,
               sa.notes as assignment_notes
        FROM public.employee_schedules s
        JOIN public.schedule_assignments sa ON s.id = sa.schedule_id
        WHERE sa.user_id = p_user_id
        AND sa.is_active = true
        AND sa.status = 'active'
        AND s.start_date_time::date = p_date
        AND s.status != 'cancelled'
        ORDER BY s.start_date_time
    LOOP
        -- Initialize attendance info
        attendance_record := NULL;
        
        IF p_include_attendance THEN
            -- Get attendance for this specific schedule
            SELECT * INTO attendance_record
            FROM public.attendance
            WHERE user_id = p_user_id 
            AND schedule_id = schedule_record.id 
            AND date = p_date
            ORDER BY created_at DESC
            LIMIT 1;
        END IF;
        
        -- Build schedule object
        schedule_obj := json_build_object(
            'id', schedule_record.id,
            'schedule_id', schedule_record.id,
            'title', schedule_record.title,
            'description', schedule_record.description,
            'start_date_time', schedule_record.start_date_time,
            'end_date_time', schedule_record.end_date_time,
            'location', schedule_record.location,
            'department', schedule_record.department,
            'duration_hours', schedule_record.duration_hours,
            'schedule_status', schedule_record.status,
            'status', schedule_record.status,
            'assigned_user_id', p_user_id,
            'created_by_admin_id', schedule_record.created_by_admin_id,
            'is_active', schedule_record.is_active,
            'is_multi_user', schedule_record.is_multi_user,
            'current_participants', schedule_record.current_participants,
            'created_at', schedule_record.created_at,
            'updated_at', schedule_record.updated_at,
            'assignment_notes', schedule_record.assignment_notes,
            'assigned_at', schedule_record.assigned_at
        );
        
        -- Add attendance info if requested
        IF p_include_attendance THEN
            schedule_obj := schedule_obj || json_build_object(
                'attendance_id', COALESCE(attendance_record.id, null),
                'has_checked_in', attendance_record.check_in_time IS NOT NULL,
                'has_checked_out', attendance_record.check_out_time IS NOT NULL,
                'check_in_time', attendance_record.check_in_time,
                'check_out_time', attendance_record.check_out_time,
                'attendance_status', COALESCE(attendance_record.status, 'not_started'),
                'can_check_in', 
                CASE 
                    WHEN attendance_record.check_in_time IS NULL THEN true
                    ELSE false
                END,
                'can_check_out',
                CASE 
                    WHEN attendance_record.check_in_time IS NOT NULL AND attendance_record.check_out_time IS NULL THEN true
                    ELSE false
                END,
                'work_status',
                CASE 
                    WHEN attendance_record.check_out_time IS NOT NULL THEN 'completed'
                    WHEN attendance_record.check_in_time IS NOT NULL THEN 'in_progress'
                    ELSE 'not_started'
                END
            );
        END IF;
        
        schedules_array := schedules_array || schedule_obj;
    END LOOP;
    
    RETURN json_build_object(
        'error', false,
        'schedules', array_to_json(schedules_array),
        'total_schedules', array_length(schedules_array, 1)
    );
END;
$$;

-- Function: Get available users for schedule assignment
CREATE OR REPLACE FUNCTION get_available_users_for_schedule(
    p_schedule_id UUID,
    p_department VARCHAR DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    schedule_record RECORD;
    users_array JSON;
BEGIN
    -- Get schedule details
    SELECT * INTO schedule_record
    FROM public.employee_schedules
    WHERE id = p_schedule_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Schedule not found'
        );
    END IF;
    
    -- Get users who are:
    -- 1. Active employees (not admins unless needed)
    -- 2. Not already assigned to this schedule
    -- 3. In the same department (if specified)
    -- 4. Don't have conflicting schedules at the same time
    SELECT json_agg(
        json_build_object(
            'id', u.id,
            'employee_id', u.employee_id,
            'full_name', u.full_name,
            'email', u.email,
            'department', u.department,
            'position', u.position
        )
    ) INTO users_array
    FROM public.my_users u
    WHERE u.is_active = true
    AND u.user_role = 'employee'
    AND (p_department IS NULL OR u.department = p_department OR u.department = schedule_record.department)
    -- Not already assigned to this schedule
    AND NOT EXISTS (
        SELECT 1 FROM public.schedule_assignments sa
        WHERE sa.schedule_id = p_schedule_id
        AND sa.user_id = u.id
        AND sa.is_active = true
        AND sa.status = 'active'
    )
    -- No schedule conflicts
    AND NOT EXISTS (
        SELECT 1 
        FROM public.employee_schedules es
        JOIN public.schedule_assignments sa ON es.id = sa.schedule_id
        WHERE sa.user_id = u.id
        AND sa.is_active = true
        AND sa.status = 'active'
        AND es.status = 'active'
        AND es.is_active = true
        AND (
            (es.start_date_time, es.end_date_time) OVERLAPS 
            (schedule_record.start_date_time, schedule_record.end_date_time)
        )
    )
    ORDER BY u.full_name;
    
    RETURN json_build_object(
        'success', true,
        'available_users', COALESCE(users_array, '[]'::json),
        'schedule_time', json_build_object(
            'start', schedule_record.start_date_time,
            'end', schedule_record.end_date_time
        )
    );
END;
$$;

-- ============================================================================
-- Step 6: Update existing RPC to maintain backward compatibility
-- ============================================================================
-- This ensures the old get_schedules_with_attendance_status still works
-- but now pulls from schedule_assignments table
CREATE OR REPLACE FUNCTION public.get_schedules_with_attendance_status(
    p_employee_id uuid, 
    p_date date DEFAULT CURRENT_DATE
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    -- Simply call the new multi-user function
    RETURN get_user_schedules_multi(p_employee_id, p_date, true);
END;
$function$;

-- ============================================================================
-- Step 7: Grant necessary permissions
-- ============================================================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.schedule_assignments TO authenticated;
GRANT EXECUTE ON FUNCTION assign_users_to_schedule TO authenticated;
GRANT EXECUTE ON FUNCTION remove_user_from_schedule TO authenticated;
GRANT EXECUTE ON FUNCTION get_schedule_with_assignments TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_schedules_multi TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_users_for_schedule TO authenticated;
GRANT EXECUTE ON FUNCTION get_schedules_with_attendance_status TO authenticated;

-- ============================================================================
-- Verification Queries (Run these to verify the migration)
-- ============================================================================

-- Check schedule_assignments table
-- SELECT COUNT(*) as total_assignments FROM public.schedule_assignments;

-- Check migrated data
-- SELECT s.title, u.full_name, sa.status, sa.assigned_at
-- FROM public.schedule_assignments sa
-- JOIN public.employee_schedules s ON sa.schedule_id = s.id
-- JOIN public.my_users u ON sa.user_id = u.id
-- LIMIT 10;

-- Test the new RPC
-- SELECT get_schedule_with_assignments(NULL, CURRENT_DATE, NULL);

