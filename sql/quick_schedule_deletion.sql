-- 🗑️ QUICK SCHEDULE DELETION (24 HOURS)
-- Simple one-liner for confident users
-- ⚠️ Use only if you're sure about the deletion!

-- Quick preview (run this first):
SELECT COUNT(*) as schedules_to_delete FROM employee_schedules WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Quick deletion (uncomment when ready):
-- DELETE FROM employee_schedules WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Quick verification (run after deletion):
-- SELECT COUNT(*) as remaining_schedules FROM employee_schedules WHERE created_at >= NOW() - INTERVAL '24 hours';
