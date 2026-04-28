-- =====================================================
-- CLEANUP OLD SUMMARY TABLES
-- =====================================================
-- This script safely removes the old daily_employee_summary and 
-- monthly_employee_summary tables that are no longer used.
-- 
-- These have been replaced by the new HR Dashboard system:
-- - daily_attendance_summary (NEW)
-- - monthly_attendance_summary (NEW)
-- - weekly_attendance_summary (NEW)
-- - user_lifetime_summary (NEW)
-- =====================================================

-- =====================================================
-- SAFETY CHECKS PERFORMED:
-- =====================================================
-- ✅ No triggers depend on these tables
-- ✅ No functions reference these tables
-- ✅ No views depend on these tables
-- ✅ Only foreign key is to my_users (safe to drop)
-- =====================================================

-- =====================================================
-- 1. DROP OLD DAILY EMPLOYEE SUMMARY TABLE
-- =====================================================

-- First, check if table exists and show row count
DO $$
DECLARE
    v_row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_row_count FROM daily_employee_summary;
    RAISE NOTICE 'daily_employee_summary has % rows - will be dropped', v_row_count;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'daily_employee_summary does not exist - skipping';
END $$;

-- Drop the table
DROP TABLE IF EXISTS daily_employee_summary CASCADE;

-- Log the action
INSERT INTO system_logs (event_type, event_data)
VALUES (
    'table_cleanup',
    jsonb_build_object(
        'table_name', 'daily_employee_summary',
        'action', 'dropped',
        'reason', 'Replaced by daily_attendance_summary in new HR dashboard system',
        'timestamp', NOW()
    )
);

-- =====================================================
-- 2. DROP OLD MONTHLY EMPLOYEE SUMMARY TABLE
-- =====================================================

-- First, check if table exists and show row count
DO $$
DECLARE
    v_row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_row_count FROM monthly_employee_summary;
    RAISE NOTICE 'monthly_employee_summary has % rows - will be dropped', v_row_count;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'monthly_employee_summary does not exist - skipping';
END $$;

-- Drop the table
DROP TABLE IF EXISTS monthly_employee_summary CASCADE;

-- Log the action
INSERT INTO system_logs (event_type, event_data)
VALUES (
    'table_cleanup',
    jsonb_build_object(
        'table_name', 'monthly_employee_summary',
        'action', 'dropped',
        'reason', 'Replaced by monthly_attendance_summary in new HR dashboard system',
        'timestamp', NOW()
    )
);

-- =====================================================
-- 3. VERIFICATION - LIST REMAINING SUMMARY TABLES
-- =====================================================

-- Show all remaining summary tables
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND (table_name LIKE '%summary%' OR table_name LIKE '%attendance%')
ORDER BY table_name;

-- =====================================================
-- CLEANUP COMPLETE!
-- =====================================================
-- Old tables removed:
-- ❌ daily_employee_summary (DELETED)
-- ❌ monthly_employee_summary (DELETED)
--
-- New tables in use:
-- ✅ daily_attendance_summary (ACTIVE)
-- ✅ monthly_attendance_summary (ACTIVE)
-- ✅ weekly_attendance_summary (ACTIVE)
-- ✅ user_lifetime_summary (ACTIVE)
-- ✅ payment_transactions (ACTIVE)
-- =====================================================

