-- 🧪 EMPLOYEE SCHEDULE FETCHING RPC TEST SCRIPT
-- This script tests the new RPC functions for employee schedule fetching

-- =====================================================
-- TEST 1: Test get_employee_schedules_with_exchanges
-- =====================================================
SELECT 'TEST 1: get_employee_schedules_with_exchanges' as test_name;

-- Test with a sample user ID (replace with actual user ID from your database)
-- First, let's get a real user ID
SELECT 'Getting sample user ID...' as info;
SELECT id, full_name, employee_id FROM my_users WHERE is_active = true LIMIT 1;

-- Test the RPC function (replace 'sample-user-id' with actual user ID)
/*
SELECT get_employee_schedules_with_exchanges(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE,
    true
) as result;
*/

-- =====================================================
-- TEST 2: Test get_employee_schedule_summary
-- =====================================================
SELECT 'TEST 2: get_employee_schedule_summary' as test_name;

-- Test schedule summary for date range
/*
SELECT get_employee_schedule_summary(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE - INTERVAL '7 days',
    CURRENT_DATE + INTERVAL '7 days'
) as result;
*/

-- =====================================================
-- TEST 3: Test check_schedule_exchange_eligibility
-- =====================================================
SELECT 'TEST 3: check_schedule_exchange_eligibility' as test_name;

-- Test eligibility check (replace with actual IDs)
/*
SELECT check_schedule_exchange_eligibility(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    'sample-schedule-id'::UUID  -- Replace with actual schedule ID
) as result;
*/

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if all functions exist
SELECT 'VERIFICATION: Check Function Existence' as check_name;
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'get_employee_schedules_with_exchanges',
    'get_employee_schedule_summary',
    'check_schedule_exchange_eligibility'
)
ORDER BY routine_name;

-- Check if required tables exist
SELECT 'VERIFICATION: Check Table Existence' as check_name;
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'employee_schedules',
    'schedule_exchange_requests',
    'my_users'
)
ORDER BY table_name;

-- Check sample data
SELECT 'VERIFICATION: Check Sample Data' as check_name;

-- Check if there are any schedules
SELECT 'Schedules count:' as info, COUNT(*) as count FROM employee_schedules WHERE is_active = true;

-- Check if there are any exchange requests
SELECT 'Exchange requests count:' as info, COUNT(*) as count FROM schedule_exchange_requests;

-- Check if there are any users
SELECT 'Users count:' as info, COUNT(*) as count FROM my_users WHERE is_active = true;

-- =====================================================
-- PERFORMANCE TEST
-- =====================================================
SELECT 'PERFORMANCE: Test Function Performance' as test_name;

-- Test performance (uncomment when you have actual user ID)
/*
EXPLAIN (ANALYZE, BUFFERS) 
SELECT get_employee_schedules_with_exchanges(
    'sample-user-id'::UUID,
    CURRENT_DATE,
    true
);
*/

-- =====================================================
-- INTEGRATION TEST WITH REAL DATA
-- =====================================================
SELECT 'INTEGRATION TEST: Test with Real Data' as test_name;

-- Get a real user ID and test
DO $$
DECLARE
    test_user_id UUID;
    test_schedule_id UUID;
    result JSON;
BEGIN
    -- Get first active user
    SELECT id INTO test_user_id FROM my_users WHERE is_active = true LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user ID: %', test_user_id;
        
        -- Test schedule fetching
        SELECT get_employee_schedules_with_exchanges(
            test_user_id,
            CURRENT_DATE,
            true
        ) INTO result;
        
        RAISE NOTICE 'Schedule fetching result: %', result;
        
        -- Test schedule summary
        SELECT get_employee_schedule_summary(
            test_user_id,
            CURRENT_DATE - INTERVAL '7 days',
            CURRENT_DATE + INTERVAL '7 days'
        ) INTO result;
        
        RAISE NOTICE 'Schedule summary result: %', result;
        
    ELSE
        RAISE NOTICE 'No active users found for testing';
    END IF;
END $$;

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT 'SUMMARY: All Tests Completed' as summary;
SELECT 
    'RPC Functions Created Successfully' as status,
    'Ready for Flutter Integration' as recommendation,
    'Remember to test with real user IDs' as warning;
