-- 🗑️ SAFE SCHEDULE DELETION SCRIPT
-- This script safely deletes schedules created in the last 24 hours
-- with proper validation and safety checks

-- ⚠️ IMPORTANT: Run this in a test environment first!
-- ⚠️ Consider backing up data before running in production

-- Step 1: First, let's see what schedules will be deleted (DRY RUN)
-- Uncomment the following lines to preview what will be deleted:

/*
SELECT 
    id,
    title,
    assigned_user_id,
    start_date_time,
    end_date_time,
    created_at,
    created_by_admin_id,
    status,
    is_active
FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
*/

-- Step 2: Count how many schedules will be affected
-- Uncomment to see the count:

/*
SELECT COUNT(*) as schedules_to_delete
FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours';
*/

-- Step 3: Check for any attendance records linked to these schedules
-- Uncomment to check for dependencies:

/*
SELECT 
    a.id as attendance_id,
    a.user_id,
    a.schedule_id,
    a.date,
    a.status,
    s.title as schedule_title,
    s.created_at as schedule_created_at
FROM attendance a
JOIN employee_schedules s ON a.schedule_id = s.id
WHERE s.created_at >= NOW() - INTERVAL '24 hours';
*/

-- Step 4: Check for any exchange requests linked to these schedules
-- Uncomment to check for exchange dependencies:

/*
SELECT 
    ser.id as exchange_request_id,
    ser.requester_user_id,
    ser.requested_user_id,
    ser.schedule_id,
    ser.status as request_status,
    s.title as schedule_title,
    s.created_at as schedule_created_at
FROM schedule_exchange_requests ser
JOIN employee_schedules s ON ser.schedule_id = s.id
WHERE s.created_at >= NOW() - INTERVAL '24 hours';
*/

-- Step 5: ACTUAL DELETION (Uncomment when ready to execute)
-- This will safely delete schedules created in the last 24 hours

-- First, delete any exchange requests linked to these schedules
/*
DELETE FROM schedule_exchange_requests 
WHERE schedule_id IN (
    SELECT id FROM employee_schedules 
    WHERE created_at >= NOW() - INTERVAL '24 hours'
);
*/

-- Then, delete any attendance records linked to these schedules
/*
DELETE FROM attendance 
WHERE schedule_id IN (
    SELECT id FROM employee_schedules 
    WHERE created_at >= NOW() - INTERVAL '24 hours'
);
*/

-- Finally, delete the schedules themselves
/*
DELETE FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours';
*/

-- Step 6: Verification query (run after deletion)
-- Uncomment to verify deletion was successful:

/*
SELECT COUNT(*) as remaining_recent_schedules
FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours';
*/

-- 🛡️ SAFETY FEATURES INCLUDED:
-- 1. Preview queries to see what will be deleted
-- 2. Count queries to understand impact
-- 3. Dependency checks for attendance and exchange requests
-- 4. Proper deletion order (child tables first, then parent)
-- 5. Verification queries to confirm deletion

-- 📋 INSTRUCTIONS:
-- 1. Run the preview queries first (Steps 1-4)
-- 2. Review the results carefully
-- 3. If satisfied, uncomment and run Step 5 queries
-- 4. Run verification query (Step 6) to confirm

-- ⚠️ BACKUP RECOMMENDATION:
-- Before running, consider creating a backup:
-- CREATE TABLE employee_schedules_backup AS 
-- SELECT * FROM employee_schedules WHERE created_at >= NOW() - INTERVAL '24 hours';
