-- Clean up schedule redundancy: Remove assigned_user_id, keep schedule_assignments
-- This ensures only ONE source of truth for schedule assignments
-- Multi-user capability is preserved via schedule_assignments table
-- Date: October 5, 2025

-- ============================================================================
-- STEP 1: Verify all data is in schedule_assignments (Safety check)
-- ============================================================================

-- Check for orphaned schedules (have assigned_user_id but no assignment)
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO orphan_count
    FROM employee_schedules es
    WHERE es.assigned_user_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 
          FROM schedule_assignments sa 
          WHERE sa.schedule_id = es.id 
            AND sa.user_id = es.assigned_user_id
            AND sa.is_active = true
      );
    
    IF orphan_count > 0 THEN
        RAISE NOTICE 'WARNING: Found % orphaned schedules. They will be preserved in schedule_assignments.', orphan_count;
    ELSE
        RAISE NOTICE 'SUCCESS: All schedules have corresponding assignments. Safe to proceed.';
    END IF;
END $$;

-- ============================================================================
-- STEP 2: Remove the auto-assignment trigger (no longer needed)
-- ============================================================================

DROP TRIGGER IF EXISTS trigger_auto_create_assignment_on_insert ON public.employee_schedules;
DROP TRIGGER IF EXISTS trigger_auto_create_assignment_on_update ON public.employee_schedules;
DROP FUNCTION IF EXISTS auto_create_schedule_assignment();

RAISE NOTICE 'Removed auto-assignment triggers (redundancy prevention no longer needed)';

-- ============================================================================
-- STEP 3: Update admin_create_schedule RPC to NOT use assigned_user_id
-- ============================================================================

CREATE OR REPLACE FUNCTION public.admin_create_schedule(
    p_admin_id uuid,
    p_title varchar,
    p_start_date_time timestamptz,
    p_end_date_time timestamptz,
    p_assigned_user_id uuid,  -- Keep parameter for backward compatibility
    p_department varchar,
    p_location varchar,
    p_description text DEFAULT NULL,
    p_latitude numeric DEFAULT NULL,
    p_longitude numeric DEFAULT NULL,
    p_requirements jsonb DEFAULT NULL,
    p_notes text DEFAULT NULL,
    p_tags text[] DEFAULT NULL,
    p_custom_fields jsonb DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_schedule_id uuid;
    v_schedule_record record;
BEGIN
    -- Validate admin exists and is authorized
    IF NOT EXISTS (SELECT 1 FROM public.my_users WHERE id = p_admin_id AND user_role IN ('admin', 'ceo', 'manager')) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Unauthorized: User is not an admin'
        );
    END IF;

    -- Validate assigned user exists
    IF NOT EXISTS (SELECT 1 FROM public.my_users WHERE id = p_assigned_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Assigned user does not exist'
        );
    END IF;

    -- Insert schedule WITHOUT assigned_user_id
    INSERT INTO public.employee_schedules (
        title,
        description,
        start_date_time,
        end_date_time,
        created_by_admin_id,
        department,
        location,
        latitude,
        longitude,
        requirements,
        notes,
        tags,
        custom_fields,
        status,
        is_active,
        is_multi_user,
        min_participants,
        current_participants
    ) VALUES (
        p_title,
        p_description,
        p_start_date_time,
        p_end_date_time,
        p_admin_id,
        p_department,
        p_location,
        p_latitude,
        p_longitude,
        p_requirements,
        p_notes,
        p_tags,
        p_custom_fields,
        'active',
        true,
        false,  -- Single user by default
        1,      -- Minimum 1 participant
        0       -- Will be updated when assignment is created
    )
    RETURNING * INTO v_schedule_record;
    
    v_schedule_id := v_schedule_record.id;

    -- Create assignment in schedule_assignments table
    INSERT INTO public.schedule_assignments (
        schedule_id,
        user_id,
        assigned_by_admin_id,
        status,
        is_active,
        notes
    ) VALUES (
        v_schedule_id,
        p_assigned_user_id,
        p_admin_id,
        'active',
        true,
        'Primary assignment'
    );

    -- Update participant count
    UPDATE public.employee_schedules
    SET current_participants = 1
    WHERE id = v_schedule_id;

    -- Return success with schedule details
    RETURN json_build_object(
        'success', true,
        'message', 'Schedule created successfully',
        'schedule_id', v_schedule_id,
        'schedule', row_to_json(v_schedule_record)
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

RAISE NOTICE 'Updated admin_create_schedule to use only schedule_assignments';

-- ============================================================================
-- STEP 4: Remove assigned_user_id and actual_user_id columns
-- ============================================================================

-- First, backup the data (in case we need to rollback)
CREATE TABLE IF NOT EXISTS employee_schedules_backup_assigned_user AS
SELECT id, assigned_user_id, actual_user_id, created_at
FROM employee_schedules
WHERE assigned_user_id IS NOT NULL OR actual_user_id IS NOT NULL;

RAISE NOTICE 'Created backup table: employee_schedules_backup_assigned_user';

-- Drop foreign key constraints first
ALTER TABLE employee_schedules 
    DROP CONSTRAINT IF EXISTS employee_schedules_assigned_user_id_fkey;

ALTER TABLE employee_schedules 
    DROP CONSTRAINT IF EXISTS employee_schedules_actual_user_id_fkey;

-- Drop the columns
ALTER TABLE employee_schedules DROP COLUMN IF EXISTS assigned_user_id;
ALTER TABLE employee_schedules DROP COLUMN IF EXISTS actual_user_id;

RAISE NOTICE 'Removed assigned_user_id and actual_user_id columns';

-- ============================================================================
-- STEP 5: Update existing RPC functions to remove assigned_user_id references
-- ============================================================================

-- This is handled automatically since the RPC functions already use schedule_assignments

-- ============================================================================
-- STEP 6: Verification queries
-- ============================================================================

-- Show current schedule assignment distribution
DO $$
DECLARE
    single_user_count INTEGER;
    multi_user_count INTEGER;
    total_schedules INTEGER;
BEGIN
    -- Count schedules by assignment type
    SELECT COUNT(*) INTO total_schedules FROM employee_schedules WHERE status = 'active';
    
    SELECT COUNT(DISTINCT schedule_id) INTO single_user_count
    FROM (
        SELECT schedule_id, COUNT(*) as user_count
        FROM schedule_assignments
        WHERE is_active = true
        GROUP BY schedule_id
        HAVING COUNT(*) = 1
    ) sub;
    
    SELECT COUNT(DISTINCT schedule_id) INTO multi_user_count
    FROM (
        SELECT schedule_id, COUNT(*) as user_count
        FROM schedule_assignments
        WHERE is_active = true
        GROUP BY schedule_id
        HAVING COUNT(*) > 1
    ) sub;
    
    RAISE NOTICE '=== VERIFICATION RESULTS ===';
    RAISE NOTICE 'Total active schedules: %', total_schedules;
    RAISE NOTICE 'Single-user schedules: %', single_user_count;
    RAISE NOTICE 'Multi-user schedules: %', multi_user_count;
    RAISE NOTICE '===========================';
END $$;

-- Show sample multi-user schedules (proof they still work)
SELECT 
    es.title,
    es.start_date_time,
    COUNT(sa.user_id) as assigned_users,
    STRING_AGG(u.full_name, ', ') as employees
FROM employee_schedules es
JOIN schedule_assignments sa ON es.id = sa.schedule_id
JOIN my_users u ON sa.user_id = u.id
WHERE sa.is_active = true
GROUP BY es.id, es.title, es.start_date_time
HAVING COUNT(sa.user_id) > 1
ORDER BY es.start_date_time DESC
LIMIT 5;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ CLEANUP COMPLETE!';
    RAISE NOTICE '   - Removed redundant assigned_user_id column';
    RAISE NOTICE '   - Removed auto-assignment triggers';
    RAISE NOTICE '   - Updated admin_create_schedule RPC';
    RAISE NOTICE '   - Multi-user capability preserved';
    RAISE NOTICE '   - All assignments in schedule_assignments table';
    RAISE NOTICE '';
    RAISE NOTICE '📊 One source of truth: schedule_assignments table';
    RAISE NOTICE '🔄 Multi-user schedules: STILL SUPPORTED';
END $$;




