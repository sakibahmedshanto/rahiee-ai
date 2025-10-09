-- ============================================================================
-- FINAL CLEANUP: Remove Old References to assigned_user_id & actual_user_id
-- ============================================================================
-- This script cleans up remaining references to the removed columns
-- ============================================================================

-- ============================================================================
-- STEP 1: Update check_schedule_conflict to use user_id instead of assigned_user_id
-- ============================================================================

-- Drop old version
DROP FUNCTION IF EXISTS public.check_schedule_conflict(uuid, timestamptz, timestamptz, uuid);

-- Create updated version
CREATE OR REPLACE FUNCTION public.check_schedule_conflict(
    p_user_id uuid,
    p_start_time timestamptz,
    p_end_time timestamptz,
    p_exclude_schedule_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check for conflicts in schedule_assignments
    RETURN EXISTS (
        SELECT 1
        FROM schedule_assignments sa
        JOIN employee_schedules es ON sa.schedule_id = es.id
        WHERE sa.user_id = p_user_id
        AND sa.is_active = true
        AND sa.status = 'active'
        AND es.is_active = true
        AND es.status = 'active'
        AND (p_exclude_schedule_id IS NULL OR es.id != p_exclude_schedule_id)
        AND (
            (es.start_date_time < p_end_time AND es.end_date_time > p_start_time)
        )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_schedule_conflict TO authenticated, service_role;

-- ============================================================================
-- STEP 2: Check and update handle_schedule_exchange_approval trigger function
-- ============================================================================

-- This trigger needs to work with schedule_assignments
CREATE OR REPLACE FUNCTION public.handle_schedule_exchange_approval()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only process when status changes to 'approved'
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        -- Remove requester from schedule_assignments
        UPDATE schedule_assignments
        SET status = 'removed',
            is_active = false,
            notes = COALESCE(notes, '') || ' | Removed via exchange approval',
            updated_at = NOW()
        WHERE schedule_id = NEW.schedule_id
        AND user_id = NEW.requester_user_id;

        -- Add requested user to schedule_assignments
        INSERT INTO schedule_assignments (
            schedule_id,
            user_id,
            assigned_by_admin_id,
            status,
            notes,
            is_active
        ) VALUES (
            NEW.schedule_id,
            NEW.requested_user_id,
            NEW.reviewed_by_admin_id,
            'active',
            'Assigned via approved exchange request',
            true
        )
        ON CONFLICT (schedule_id, user_id)
        DO UPDATE SET
            status = 'active',
            is_active = true,
            notes = 'Re-assigned via approved exchange request',
            updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$;

-- ============================================================================
-- STEP 3: Update validate_attendance_schedule trigger function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.validate_attendance_schedule()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate that user is assigned to the schedule
    IF NOT EXISTS (
        SELECT 1
        FROM schedule_assignments
        WHERE schedule_id = NEW.schedule_id
        AND user_id = NEW.user_id
        AND is_active = true
        AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'User is not assigned to this schedule';
    END IF;

    RETURN NEW;
END;
$$;

-- ============================================================================
-- STEP 4: Update get_admin_schedule_report (if used)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_admin_schedule_report(
    p_start_date date,
    p_end_date date,
    p_department varchar DEFAULT NULL,
    p_employee_id uuid DEFAULT NULL
)
RETURNS TABLE (
    schedule_id uuid,
    schedule_title varchar,
    schedule_date date,
    start_time timestamptz,
    end_time timestamptz,
    department varchar,
    location varchar,
    assigned_employees jsonb,
    schedule_status varchar,
    attendance_count integer,
    is_multi_user boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        es.id as schedule_id,
        es.title as schedule_title,
        DATE(es.start_date_time) as schedule_date,
        es.start_date_time as start_time,
        es.end_date_time as end_time,
        es.department,
        es.location,
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'user_id', u.id,
                    'full_name', u.full_name,
                    'employee_id', u.employee_id
                )
            )
            FROM schedule_assignments sa
            JOIN my_users u ON sa.user_id = u.id
            WHERE sa.schedule_id = es.id
            AND sa.is_active = true
            AND sa.status = 'active'
        ) as assigned_employees,
        es.status as schedule_status,
        (
            SELECT COUNT(*)::integer
            FROM attendance a
            WHERE a.schedule_id = es.id
        ) as attendance_count,
        es.is_multi_user
    FROM employee_schedules es
    WHERE DATE(es.start_date_time) BETWEEN p_start_date AND p_end_date
    AND (p_department IS NULL OR es.department = p_department)
    AND (p_employee_id IS NULL OR EXISTS (
        SELECT 1 FROM schedule_assignments sa
        WHERE sa.schedule_id = es.id
        AND sa.user_id = p_employee_id
        AND sa.is_active = true
    ))
    AND es.is_active = true
    ORDER BY es.start_date_time;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_admin_schedule_report TO authenticated, service_role;

-- ============================================================================
-- STEP 5: Check for any views that might reference old columns
-- ============================================================================

-- Drop any views that reference the old columns (if they exist)
DROP VIEW IF EXISTS public.schedule_overview CASCADE;
DROP VIEW IF EXISTS public.attendance_with_schedule CASCADE;
DROP VIEW IF EXISTS public.schedule_with_users CASCADE;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check remaining references (should return empty)
DO $$
DECLARE
    v_count integer;
BEGIN
    -- Check for any remaining function references
    SELECT COUNT(*) INTO v_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
    AND p.prokind = 'f'
    AND (
        pg_get_functiondef(p.oid) LIKE '%assigned_user_id%' OR
        pg_get_functiondef(p.oid) LIKE '%actual_user_id%'
    );
    
    RAISE NOTICE 'Functions still referencing old columns: %', v_count;
END $$;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- ✅ Updated check_schedule_conflict to use p_user_id
-- ✅ Updated handle_schedule_exchange_approval trigger
-- ✅ Updated validate_attendance_schedule trigger
-- ✅ Updated get_admin_schedule_report
-- ✅ Dropped any old views
-- 
-- Note: Some functions may still have parameter names with old naming
-- but they work with schedule_assignments internally (like admin_get_schedules)
-- ============================================================================




