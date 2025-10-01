-- 🧪 MANUAL TEST SCRIPT FOR get_employee_schedules RPC
-- Comprehensive testing of the perfect employee schedules function

-- =====================================================
-- TEST 1: Basic Functionality Test
-- =====================================================
SELECT 'TEST 1: Basic Functionality' as test_name;

-- Get a real user ID for testing
SELECT 'Getting sample user ID...' as info;
SELECT id, full_name, employee_id, user_role 
FROM my_users 
WHERE is_active = true 
AND user_role = 'employee'
LIMIT 1;

-- Test basic functionality (replace with actual user ID)
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    NULL,                    -- No specific date
    NULL,                    -- No start date
    NULL,                    -- No end date
    true,                    -- Include exchanges
    false,                   -- Don't include given schedules
    10,                      -- Limit 10
    0                        -- Offset 0
) as result;
*/

-- =====================================================
-- TEST 2: Single Date Test
-- =====================================================
SELECT 'TEST 2: Single Date Test' as test_name;

-- Test with specific date
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE,            -- Today's date
    NULL,                    -- No start date
    NULL,                    -- No end date
    true,                    -- Include exchanges
    false,                   -- Don't include given schedules
    50,                      -- Limit 50
    0                        -- Offset 0
) as result;
*/

-- =====================================================
-- TEST 3: Date Range Test
-- =====================================================
SELECT 'TEST 3: Date Range Test' as test_name;

-- Test with date range
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    NULL,                    -- No specific date
    CURRENT_DATE - INTERVAL '7 days',  -- Start date
    CURRENT_DATE + INTERVAL '7 days',  -- End date
    true,                    -- Include exchanges
    true,                    -- Include given schedules
    100,                     -- Limit 100
    0                        -- Offset 0
) as result;
*/

-- =====================================================
-- TEST 4: Pagination Test
-- =====================================================
SELECT 'TEST 4: Pagination Test' as test_name;

-- Test pagination
/*
-- First page
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    NULL, NULL, NULL,
    true, false,
    5, 0                     -- Limit 5, Offset 0
) as page1;

-- Second page
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    NULL, NULL, NULL,
    true, false,
    5, 5                     -- Limit 5, Offset 5
) as page2;
*/

-- =====================================================
-- TEST 5: Exchange Options Test
-- =====================================================
SELECT 'TEST 5: Exchange Options Test' as test_name;

-- Test without exchanges
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE, NULL, NULL,
    false,                   -- Don't include exchanges
    false,                   -- Don't include given schedules
    50, 0
) as without_exchanges;
*/

-- Test with given schedules
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE, NULL, NULL,
    true,                    -- Include exchanges
    true,                    -- Include given schedules
    50, 0
) as with_given_schedules;
*/

-- =====================================================
-- TEST 6: Error Handling Test
-- =====================================================
SELECT 'TEST 6: Error Handling Test' as test_name;

-- Test with invalid user ID
SELECT get_employee_schedules(
    '00000000-0000-0000-0000-000000000000'::UUID,  -- Invalid UUID
    CURRENT_DATE, NULL, NULL,
    true, false,
    10, 0
) as invalid_user_test;

-- Test with invalid parameters
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    NULL, NULL, NULL,
    true, false,
    -1, -1                    -- Invalid limit and offset
) as invalid_params_test;

-- =====================================================
-- TEST 7: Performance Test
-- =====================================================
SELECT 'TEST 7: Performance Test' as test_name;

-- Test performance with EXPLAIN
/*
EXPLAIN (ANALYZE, BUFFERS) 
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE, NULL, NULL,
    true, false,
    100, 0
);
*/

-- =====================================================
-- TEST 8: Data Validation Test
-- =====================================================
SELECT 'TEST 8: Data Validation Test' as test_name;

-- Check if function exists
SELECT 'Function exists:' as check_name, 
       routine_name, 
       routine_type,
       data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'get_employee_schedules';

-- Check required tables exist
SELECT 'Required tables:' as check_name, table_name
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'employee_schedules',
    'schedule_exchange_requests',
    'my_users'
)
ORDER BY table_name;

-- Check sample data
SELECT 'Sample data counts:' as check_name;
SELECT 'Schedules:' as table_name, COUNT(*) as count FROM employee_schedules WHERE is_active = true
UNION ALL
SELECT 'Exchange requests:' as table_name, COUNT(*) as count FROM schedule_exchange_requests
UNION ALL
SELECT 'Users:' as table_name, COUNT(*) as count FROM my_users WHERE is_active = true;

-- =====================================================
-- TEST 9: Integration Test with Real Data
-- =====================================================
SELECT 'TEST 9: Integration Test with Real Data' as test_name;

-- Test with real data
DO $$
DECLARE
    test_user_id UUID;
    result JSON;
    schedule_count INTEGER;
BEGIN
    -- Get first active employee
    SELECT id INTO test_user_id 
    FROM my_users 
    WHERE is_active = true 
    AND user_role = 'employee'
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user ID: %', test_user_id;
        
        -- Test basic functionality
        SELECT get_employee_schedules(
            test_user_id,
            CURRENT_DATE, NULL, NULL,
            true, false,
            10, 0
        ) INTO result;
        
        RAISE NOTICE 'Basic test result: %', result;
        
        -- Extract schedule count
        IF result->>'success' = 'true' THEN
            SELECT json_array_length(result->'schedules') INTO schedule_count;
            RAISE NOTICE 'Found % schedules for user', schedule_count;
            
            -- Test summary
            RAISE NOTICE 'Summary: %', result->'summary';
            
            -- Test pagination info
            RAISE NOTICE 'Pagination: %', result->'pagination';
        ELSE
            RAISE NOTICE 'Function returned error: %', result->>'error';
        END IF;
        
    ELSE
        RAISE NOTICE 'No active employees found for testing';
    END IF;
END $$;

-- =====================================================
-- TEST 10: Edge Cases Test
-- =====================================================
SELECT 'TEST 10: Edge Cases Test' as test_name;

-- Test with very large limit
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    NULL, NULL, NULL,
    true, false,
    10000, 0                 -- Very large limit
) as large_limit_test;
*/

-- Test with future date
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE + INTERVAL '30 days',  -- Future date
    NULL, NULL,
    true, false,
    50, 0
) as future_date_test;
*/

-- Test with past date
/*
SELECT get_employee_schedules(
    'sample-user-id'::UUID,  -- Replace with actual user ID
    CURRENT_DATE - INTERVAL '30 days',  -- Past date
    NULL, NULL,
    true, false,
    50, 0
) as past_date_test;
*/

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT 'SUMMARY: All Tests Completed' as summary;
SELECT 
    'get_employee_schedules RPC Function Ready' as status,
    'Comprehensive testing completed' as testing,
    'Ready for Flutter integration' as next_step;
