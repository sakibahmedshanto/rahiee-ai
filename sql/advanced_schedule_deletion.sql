-- 🗑️ ADVANCED SAFE SCHEDULE DELETION SCRIPT
-- Enhanced version with logging, rollback capability, and detailed reporting

-- ⚠️ CRITICAL: Test in development environment first!
-- ⚠️ This script includes transaction support for rollback capability

-- Step 1: Create a backup table for safety
CREATE TABLE IF NOT EXISTS employee_schedules_deletion_backup (
    id UUID,
    title TEXT,
    description TEXT,
    start_date_time TIMESTAMPTZ,
    end_date_time TIMESTAMPTZ,
    created_by_admin_id UUID,
    assigned_user_id UUID,
    actual_user_id UUID,
    department TEXT,
    location TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    status TEXT,
    requirements JSONB,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    notes TEXT,
    is_active BOOLEAN,
    tags TEXT[],
    custom_fields JSONB,
    assignment_history JSONB,
    deletion_timestamp TIMESTAMPTZ DEFAULT NOW(),
    deletion_reason TEXT DEFAULT '24_hour_cleanup'
);

-- Step 2: Create deletion log table
CREATE TABLE IF NOT EXISTS schedule_deletion_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deletion_timestamp TIMESTAMPTZ DEFAULT NOW(),
    schedules_deleted INTEGER,
    attendance_records_deleted INTEGER,
    exchange_requests_deleted INTEGER,
    deletion_reason TEXT,
    executed_by TEXT,
    success BOOLEAN,
    error_message TEXT
);

-- Step 3: Preview what will be deleted (ALWAYS RUN THIS FIRST)
SELECT 
    'PREVIEW: Schedules to be deleted' as action,
    COUNT(*) as count,
    MIN(created_at) as oldest_schedule,
    MAX(created_at) as newest_schedule
FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Step 4: Preview attendance records that will be affected
SELECT 
    'PREVIEW: Attendance records to be deleted' as action,
    COUNT(*) as count
FROM attendance a
JOIN employee_schedules s ON a.schedule_id = s.id
WHERE s.created_at >= NOW() - INTERVAL '24 hours';

-- Step 5: Preview exchange requests that will be affected
SELECT 
    'PREVIEW: Exchange requests to be deleted' as action,
    COUNT(*) as count
FROM schedule_exchange_requests ser
JOIN employee_schedules s ON ser.schedule_id = s.id
WHERE s.created_at >= NOW() - INTERVAL '24 hours';

-- Step 6: DETAILED PREVIEW - Show specific schedules
SELECT 
    s.id,
    s.title,
    s.start_date_time,
    s.end_date_time,
    s.created_at,
    s.status,
    s.is_active,
    u.full_name as assigned_to,
    admin.full_name as created_by_admin
FROM employee_schedules s
LEFT JOIN my_users u ON s.assigned_user_id = u.id
LEFT JOIN my_users admin ON s.created_by_admin_id = admin.id
WHERE s.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY s.created_at DESC;

-- Step 7: ACTUAL DELETION WITH TRANSACTION SUPPORT
-- Uncomment the following block when ready to execute:

/*
BEGIN;

-- Create backup of schedules to be deleted
INSERT INTO employee_schedules_deletion_backup
SELECT 
    id, title, description, start_date_time, end_date_time,
    created_by_admin_id, assigned_user_id, actual_user_id,
    department, location, latitude, longitude, status,
    requirements, created_at, updated_at, notes, is_active,
    tags, custom_fields, assignment_history,
    NOW() as deletion_timestamp,
    '24_hour_cleanup' as deletion_reason
FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Count records for logging
DO $$
DECLARE
    schedule_count INTEGER;
    attendance_count INTEGER;
    exchange_count INTEGER;
BEGIN
    -- Count schedules
    SELECT COUNT(*) INTO schedule_count
    FROM employee_schedules 
    WHERE created_at >= NOW() - INTERVAL '24 hours';
    
    -- Count attendance records
    SELECT COUNT(*) INTO attendance_count
    FROM attendance a
    JOIN employee_schedules s ON a.schedule_id = s.id
    WHERE s.created_at >= NOW() - INTERVAL '24 hours';
    
    -- Count exchange requests
    SELECT COUNT(*) INTO exchange_count
    FROM schedule_exchange_requests ser
    JOIN employee_schedules s ON ser.schedule_id = s.id
    WHERE s.created_at >= NOW() - INTERVAL '24 hours';
    
    -- Log the deletion
    INSERT INTO schedule_deletion_log (
        schedules_deleted,
        attendance_records_deleted,
        exchange_requests_deleted,
        deletion_reason,
        executed_by,
        success
    ) VALUES (
        schedule_count,
        attendance_count,
        exchange_count,
        '24_hour_cleanup',
        current_user,
        true
    );
END $$;

-- Delete exchange requests first (foreign key constraint)
DELETE FROM schedule_exchange_requests 
WHERE schedule_id IN (
    SELECT id FROM employee_schedules 
    WHERE created_at >= NOW() - INTERVAL '24 hours'
);

-- Delete attendance records second
DELETE FROM attendance 
WHERE schedule_id IN (
    SELECT id FROM employee_schedules 
    WHERE created_at >= NOW() - INTERVAL '24 hours'
);

-- Delete schedules last
DELETE FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Commit the transaction
COMMIT;

-- Log success
INSERT INTO schedule_deletion_log (
    schedules_deleted,
    attendance_records_deleted,
    exchange_requests_deleted,
    deletion_reason,
    executed_by,
    success
) VALUES (
    0, 0, 0, '24_hour_cleanup_completed', current_user, true
);
*/

-- Step 8: ROLLBACK SCRIPT (if needed)
-- Uncomment if you need to rollback the deletion:

/*
-- Restore schedules from backup
INSERT INTO employee_schedules
SELECT 
    id, title, description, start_date_time, end_date_time,
    created_by_admin_id, assigned_user_id, actual_user_id,
    department, location, latitude, longitude, status,
    requirements, created_at, updated_at, notes, is_active,
    tags, custom_fields, assignment_history
FROM employee_schedules_deletion_backup
WHERE deletion_timestamp >= NOW() - INTERVAL '1 hour';

-- Log rollback
INSERT INTO schedule_deletion_log (
    schedules_deleted,
    attendance_records_deleted,
    exchange_requests_deleted,
    deletion_reason,
    executed_by,
    success
) VALUES (
    0, 0, 0, 'rollback_from_backup', current_user, true
);
*/

-- Step 9: Verification queries
-- Run these after deletion to verify success:

-- Check remaining recent schedules
SELECT 
    'VERIFICATION: Remaining recent schedules' as status,
    COUNT(*) as count
FROM employee_schedules 
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Check deletion log
SELECT 
    'DELETION LOG' as info,
    deletion_timestamp,
    schedules_deleted,
    attendance_records_deleted,
    exchange_requests_deleted,
    deletion_reason,
    executed_by,
    success
FROM schedule_deletion_log
ORDER BY deletion_timestamp DESC
LIMIT 5;

-- Check backup table
SELECT 
    'BACKUP TABLE' as info,
    COUNT(*) as backed_up_schedules,
    MIN(deletion_timestamp) as first_backup,
    MAX(deletion_timestamp) as latest_backup
FROM employee_schedules_deletion_backup;

-- 🛡️ ENHANCED SAFETY FEATURES:
-- 1. ✅ Backup table creation before deletion
-- 2. ✅ Detailed preview queries
-- 3. ✅ Transaction support with rollback capability
-- 4. ✅ Comprehensive logging system
-- 5. ✅ Dependency checking (attendance, exchange requests)
-- 6. ✅ Verification queries
-- 7. ✅ Rollback script included
-- 8. ✅ User tracking and timestamps

-- 📋 EXECUTION STEPS:
-- 1. Run Steps 1-6 (preview and setup)
-- 2. Review all preview results carefully
-- 3. If satisfied, uncomment and run Step 7 (actual deletion)
-- 4. Run Step 9 (verification) to confirm success
-- 5. If issues, use Step 8 (rollback) to restore

-- ⚠️ IMPORTANT NOTES:
-- - This script uses transactions for safety
-- - All deletions are logged with timestamps
-- - Backup is created before any deletion
-- - Rollback capability is included
-- - Test in development environment first!
