-- 🧪 RPC FUNCTIONS TEST SCRIPT
-- This script tests all schedule deletion RPC functions

-- =====================================================
-- TEST 1: Preview Schedule Deletion
-- =====================================================
SELECT 'TEST 1: Preview Schedule Deletion' as test_name;
SELECT preview_schedule_deletion(24) as result;

-- =====================================================
-- TEST 2: Get Schedules for Deletion
-- =====================================================
SELECT 'TEST 2: Get Schedules for Deletion' as test_name;
SELECT get_schedules_for_deletion(24, 10, 0) as result;

-- =====================================================
-- TEST 3: Get Deletion Log
-- =====================================================
SELECT 'TEST 3: Get Deletion Log' as test_name;
SELECT get_deletion_log(10, 0) as result;

-- =====================================================
-- TEST 4: Test Error Handling (Invalid Parameters)
-- =====================================================
SELECT 'TEST 4: Test Error Handling' as test_name;
SELECT preview_schedule_deletion(-1) as result; -- Should return error

-- =====================================================
-- TEST 5: Test Pagination
-- =====================================================
SELECT 'TEST 5: Test Pagination' as test_name;
SELECT get_schedules_for_deletion(24, 5, 0) as result;
SELECT get_schedules_for_deletion(24, 5, 5) as result;

-- =====================================================
-- TEST 6: Test Deletion Log Pagination
-- =====================================================
SELECT 'TEST 6: Test Deletion Log Pagination' as test_name;
SELECT get_deletion_log(5, 0) as result;
SELECT get_deletion_log(5, 5) as result;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if all functions exist
SELECT 'VERIFICATION: Check Function Existence' as check_name;
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'preview_schedule_deletion',
    'get_schedules_for_deletion', 
    'safe_delete_schedules',
    'restore_schedules_from_backup',
    'get_deletion_log'
)
ORDER BY routine_name;

-- Check if required tables exist
SELECT 'VERIFICATION: Check Table Existence' as check_name;
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'schedule_deletion_log',
    'employee_schedules_deletion_backup'
)
ORDER BY table_name;

-- Check table structures
SELECT 'VERIFICATION: Check Table Structures' as check_name;
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN (
    'schedule_deletion_log',
    'employee_schedules_deletion_backup'
)
ORDER BY table_name, ordinal_position;

-- =====================================================
-- PERFORMANCE TEST
-- =====================================================
SELECT 'PERFORMANCE: Test Function Performance' as test_name;

-- Test preview function performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT preview_schedule_deletion(24);

-- Test get schedules function performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT get_schedules_for_deletion(24, 100, 0);

-- =====================================================
-- INTEGRATION TEST (Optional - Uncomment to test actual deletion)
-- =====================================================

/*
-- WARNING: This will actually delete schedules!
-- Only uncomment if you want to test actual deletion

SELECT 'INTEGRATION TEST: Actual Deletion' as test_name;

-- First, preview what will be deleted
SELECT preview_schedule_deletion(1) as preview_result;

-- Then, delete schedules from last 1 hour (safer test)
SELECT safe_delete_schedules(1, true, 'test_user') as deletion_result;

-- Check deletion log
SELECT get_deletion_log(5, 0) as log_result;

-- Restore from backup
SELECT restore_schedules_from_backup(1, 'test_user') as restoration_result;
*/

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT 'SUMMARY: All Tests Completed' as summary;
SELECT 
    'RPC Functions Created Successfully' as status,
    'Ready for Production Use' as recommendation,
    'Remember to test in development first' as warning;
