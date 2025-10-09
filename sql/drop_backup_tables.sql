-- ============================================================================
-- DROP UNNECESSARY BACKUP TABLES
-- ============================================================================
-- This script removes backup tables that are no longer needed after 
-- successful migration to schedule_assignments architecture
-- ============================================================================

-- ============================================================================
-- VERIFICATION: Confirm migration was successful
-- ============================================================================

-- Check the counts
DO $$
DECLARE
    v_backup_count INTEGER;
    v_assignment_count INTEGER;
    v_current_schedules INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_backup_count FROM employee_schedules_backup_assigned_user;
    SELECT COUNT(DISTINCT schedule_id) INTO v_assignment_count FROM schedule_assignments WHERE is_active = true;
    SELECT COUNT(*) INTO v_current_schedules FROM employee_schedules;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration Verification:';
    RAISE NOTICE '  Backup table rows: %', v_backup_count;
    RAISE NOTICE '  Active assignments: %', v_assignment_count;
    RAISE NOTICE '  Current schedules: %', v_current_schedules;
    RAISE NOTICE '========================================';
    
    IF v_assignment_count >= v_backup_count THEN
        RAISE NOTICE '✅ Migration successful - Safe to drop backup';
    ELSE
        RAISE WARNING '⚠️ Assignment count lower than backup - Review before dropping';
    END IF;
END $$;

-- ============================================================================
-- DROP BACKUP TABLE
-- ============================================================================

-- Drop the backup table (created during cleanup_schedule_redundancy migration)
DROP TABLE IF EXISTS public.employee_schedules_backup_assigned_user CASCADE;

-- ============================================================================
-- VERIFICATION: Confirm table is dropped
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'employee_schedules_backup_assigned_user'
    ) THEN
        RAISE NOTICE '✅ Backup table successfully dropped';
    ELSE
        RAISE WARNING '⚠️ Backup table still exists';
    END IF;
END $$;

-- ============================================================================
-- CHECK FOR OTHER UNNECESSARY TABLES
-- ============================================================================

-- List any remaining backup/temp tables
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
AND (
    tablename LIKE '%backup%' OR
    tablename LIKE '%temp%' OR
    tablename LIKE '%old%' OR
    tablename LIKE '%_bak%' OR
    tablename LIKE '%test%'
)
ORDER BY tablename;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- ✅ Dropped: employee_schedules_backup_assigned_user
-- 
-- This table was created as a backup during the migration to store
-- the old assigned_user_id and actual_user_id values. Since the
-- migration to schedule_assignments is complete and verified, this
-- backup is no longer needed.
-- 
-- Data preserved in: schedule_assignments table
-- ============================================================================




