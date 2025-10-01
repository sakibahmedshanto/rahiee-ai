-- 🔍 DATABASE INVESTIGATION SCRIPT
-- Check the current state of schedule exchanges and assignments

-- =====================================================
-- CHECK 1: Recent Exchange Requests
-- =====================================================
SELECT 'CHECK 1: Recent Exchange Requests' as check_name;

SELECT 
    ser.id as exchange_request_id,
    ser.requester_user_id,
    ser.requested_user_id,
    ser.schedule_id,
    ser.status as exchange_status,
    ser.created_at as exchange_created_at,
    ser.reviewed_at as exchange_approved_at,
    requester.full_name as requester_name,
    requester.employee_id as requester_employee_id,
    requested.full_name as requested_name,
    requested.employee_id as requested_employee_id
FROM schedule_exchange_requests ser
LEFT JOIN my_users requester ON ser.requester_user_id = requester.id
LEFT JOIN my_users requested ON ser.requested_user_id = requested.id
WHERE ser.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY ser.created_at DESC;

-- =====================================================
-- CHECK 2: Schedule Assignments After Exchange
-- =====================================================
SELECT 'CHECK 2: Schedule Assignments After Exchange' as check_name;

-- Check schedules that were involved in recent exchanges
SELECT 
    s.id as schedule_id,
    s.title,
    s.start_date_time,
    s.end_date_time,
    s.assigned_user_id,
    s.actual_user_id,
    s.status as schedule_status,
    s.is_active,
    s.created_at as schedule_created_at,
    s.updated_at as schedule_updated_at,
    assigned_user.full_name as assigned_user_name,
    assigned_user.employee_id as assigned_user_employee_id,
    actual_user.full_name as actual_user_name,
    actual_user.employee_id as actual_user_employee_id
FROM employee_schedules s
LEFT JOIN my_users assigned_user ON s.assigned_user_id = assigned_user.id
LEFT JOIN my_users actual_user ON s.actual_user_id = actual_user.id
WHERE s.id IN (
    SELECT schedule_id 
    FROM schedule_exchange_requests 
    WHERE created_at >= NOW() - INTERVAL '24 hours'
)
ORDER BY s.updated_at DESC;

-- =====================================================
-- CHECK 3: Specific Users (Shantoo and Robin)
-- =====================================================
SELECT 'CHECK 3: Specific Users (Shantoo and Robin)' as check_name;

-- Find Shantoo's user ID
SELECT 'Shantoo User Info:' as info;
SELECT id, full_name, employee_id, user_role, is_active
FROM my_users 
WHERE LOWER(full_name) LIKE '%shantoo%' 
OR LOWER(employee_id) LIKE '%shantoo%';

-- Find Robin's user ID
SELECT 'Robin User Info:' as info;
SELECT id, full_name, employee_id, user_role, is_active
FROM my_users 
WHERE LOWER(full_name) LIKE '%robin%' 
OR LOWER(employee_id) LIKE '%robin%';

-- =====================================================
-- CHECK 4: Exchange Request #3 Details
-- =====================================================
SELECT 'CHECK 4: Exchange Request #3 Details' as check_name;

-- Check if there's an exchange request with ID 3 or similar
SELECT 
    ser.id as exchange_request_id,
    ser.requester_user_id,
    ser.requested_user_id,
    ser.schedule_id,
    ser.status as exchange_status,
    ser.request_reason,
    ser.admin_notes,
    ser.created_at,
    ser.reviewed_at,
    requester.full_name as requester_name,
    requested.full_name as requested_name,
    s.title as schedule_title,
    s.start_date_time,
    s.end_date_time,
    s.assigned_user_id as current_assigned_user_id,
    assigned_user.full_name as current_assigned_user_name
FROM schedule_exchange_requests ser
LEFT JOIN my_users requester ON ser.requester_user_id = requester.id
LEFT JOIN my_users requested ON ser.requested_user_id = requested.id
LEFT JOIN employee_schedules s ON ser.schedule_id = s.id
LEFT JOIN my_users assigned_user ON s.assigned_user_id = assigned_user.id
WHERE ser.id = 3 OR ser.id::text LIKE '%3%'
ORDER BY ser.created_at DESC;

-- =====================================================
-- CHECK 5: Test RPC Function with Real Users
-- =====================================================
SELECT 'CHECK 5: Test RPC Function with Real Users' as check_name;

-- Test the RPC function with Shantoo's user ID (replace with actual ID)
/*
SELECT 'Testing RPC with Shantoo:' as test_info;
SELECT get_employee_schedules(
    'shantoo-user-id'::UUID,  -- Replace with actual Shantoo user ID
    CURRENT_DATE, NULL, NULL,
    true, false,
    100, 0
) as shantoo_schedules;
*/

-- Test the RPC function with Robin's user ID (replace with actual ID)
/*
SELECT 'Testing RPC with Robin:' as test_info;
SELECT get_employee_schedules(
    'robin-user-id'::UUID,  -- Replace with actual Robin user ID
    CURRENT_DATE, NULL, NULL,
    true, false,
    100, 0
) as robin_schedules;
*/

-- =====================================================
-- CHECK 6: Schedule Exchange Functions Status
-- =====================================================
SELECT 'CHECK 6: Schedule Exchange Functions Status' as check_name;

-- Check if the exchange functions exist
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%schedule_exchange%'
ORDER BY routine_name;

-- Check if the main RPC function exists
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'get_employee_schedules';

-- =====================================================
-- CHECK 7: Recent Database Changes
-- =====================================================
SELECT 'CHECK 7: Recent Database Changes' as check_name;

-- Check recent changes to employee_schedules table
SELECT 
    'Recent schedule updates:' as info,
    COUNT(*) as count
FROM employee_schedules 
WHERE updated_at >= NOW() - INTERVAL '24 hours';

-- Check recent exchange request activities
SELECT 
    'Recent exchange activities:' as info,
    COUNT(*) as count
FROM schedule_exchange_requests 
WHERE created_at >= NOW() - INTERVAL '24 hours'
OR reviewed_at >= NOW() - INTERVAL '24 hours';

-- =====================================================
-- CHECK 8: Data Integrity Issues
-- =====================================================
SELECT 'CHECK 8: Data Integrity Issues' as check_name;

-- Check for orphaned exchange requests
SELECT 
    'Orphaned exchange requests:' as issue_type,
    COUNT(*) as count
FROM schedule_exchange_requests ser
LEFT JOIN employee_schedules s ON ser.schedule_id = s.id
WHERE s.id IS NULL;

-- Check for exchange requests with invalid user IDs
SELECT 
    'Invalid requester user IDs:' as issue_type,
    COUNT(*) as count
FROM schedule_exchange_requests ser
LEFT JOIN my_users u ON ser.requester_user_id = u.id
WHERE u.id IS NULL;

-- Check for exchange requests with invalid requested user IDs
SELECT 
    'Invalid requested user IDs:' as issue_type,
    COUNT(*) as count
FROM schedule_exchange_requests ser
LEFT JOIN my_users u ON ser.requested_user_id = u.id
WHERE u.id IS NULL;

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT 'SUMMARY: Database Investigation Complete' as summary;
SELECT 
    'Check the results above to identify the issue' as next_step,
    'Look for approved exchange requests and their corresponding schedule assignments' as focus,
    'Verify that assigned_user_id was updated correctly' as key_point;
