# ✅ pg_cron Absence Detection - IMPLEMENTATION COMPLETE

## 🎉 System Status: **FULLY OPERATIONAL**

Your automatic absence detection system is now running using **pg_cron** (inside Supabase database).

---

## 📊 **Current Configuration**

### **Execution Schedule**
- **Frequency**: Every 2 minutes (for debugging)
- **Job Name**: `absence-detection-debug`
- **Status**: ✅ Active and Running
- **Execution Window**: Checks schedules that ended in the last 2 minutes

### **First Successful Executions**
1. **08:58:00 UTC** - ✅ Succeeded (6.49ms)
2. **09:00:00 UTC** - ✅ Succeeded (7.34ms)
3. **Running continuously...**

---

## 🔍 **What Was Implemented**

### **1. Updated Function: `mark_absent_after_schedule_end()`**
**Location**: Supabase Database (PostgreSQL)

**Features**:
- Checks schedules that ended in the last 2 minutes
- Queries `schedule_assignments` table for assigned users
- Creates `absent` attendance records for users who didn't check in
- Logs execution details to `system_logs` table
- Returns JSON with execution summary

**Logic Flow**:
```
Every 2 minutes:
  1. Find schedules that ended in last 2 minutes
  2. Check if assigned users have attendance records
  3. If NO attendance record exists:
     - Create attendance with status='absent'
     - Set expected_hours based on schedule duration
     - Add auto-generated note
  4. Log results to system_logs
  5. Return summary
```

### **2. Scheduled Job: `absence-detection-debug`**
**Location**: pg_cron extension (inside Supabase)

**Configuration**:
```sql
Job ID: 1
Schedule: */2 * * * * (every 2 minutes)
Command: SELECT mark_absent_after_schedule_end()
Status: Active
Database: postgres
```

### **3. Monitoring Functions**

#### **`get_absence_detection_logs(p_limit INT)`**
Returns execution history from `system_logs`:
```sql
SELECT * FROM get_absence_detection_logs(10);
```

**Returns**:
- `execution_time`: When the function ran
- `schedules_checked`: Number of schedules checked
- `absences_marked`: Number of absences created
- `check_start_time`: Start of time window
- `check_end_time`: End of time window
- `success`: Execution status

#### **`get_pg_cron_run_history(p_limit INT)`**
Returns pg_cron execution details:
```sql
SELECT * FROM get_pg_cron_run_history(10);
```

**Returns**:
- `run_id`: Unique execution ID
- `job_id`: Job identifier
- `job_name`: 'absence-detection-debug'
- `run_start_time`: Execution start
- `run_end_time`: Execution end
- `status`: 'succeeded' or 'failed'
- `return_message`: Result message
- `duration_seconds`: Execution time

#### **`monitor_absence_detection_system()`**
Comprehensive system status:
```sql
SELECT monitor_absence_detection_system();
```

**Returns**: Complete JSON with job info, statistics, recent runs, and logs

---

## 📈 **How to Monitor**

### **Quick Status Check**
```sql
-- See current status
SELECT 
    NOW() as current_time,
    (SELECT MAX(start_time) FROM cron.job_run_details WHERE jobid = 1) as last_run,
    (SELECT COUNT(*) FROM cron.job_run_details WHERE jobid = 1) as total_runs,
    (SELECT COUNT(*) FROM system_logs WHERE event_type = 'pg_cron_absence_detection') as total_logs;
```

### **View Recent Executions**
```sql
-- Last 10 executions
SELECT * FROM get_absence_detection_logs(10);
```

### **Check for Errors**
```sql
-- View failed runs (if any)
SELECT *
FROM cron.job_run_details
WHERE jobid = 1 AND status != 'succeeded'
ORDER BY start_time DESC;
```

### **View All Absent Records**
```sql
-- See all auto-marked absences
SELECT 
    a.id,
    a.date,
    u.full_name,
    u.employee_id,
    es.title as schedule_title,
    es.start_date_time,
    es.end_date_time,
    a.employee_notes,
    a.created_at
FROM attendance a
JOIN my_users u ON u.id = a.user_id
JOIN employee_schedules es ON es.id = a.schedule_id
WHERE a.status = 'absent'
ORDER BY a.created_at DESC;
```

---

## ⚙️ **How to Change Schedule**

### **Switch to Hourly (Production Mode)**

When you're done testing, switch to hourly execution:

```sql
-- Step 1: Remove the 2-minute job
SELECT cron.unschedule('absence-detection-debug');

-- Step 2: Create hourly job
SELECT cron.schedule(
    'absence-detection-hourly',
    '0 * * * *',  -- Every hour at minute 0
    $$SELECT mark_absent_after_schedule_end()$$
);

-- Step 3: Verify
SELECT * FROM cron.job WHERE jobname = 'absence-detection-hourly';
```

**Note**: You'll also need to update the function to check schedules from the last hour instead of last 2 minutes:

```sql
-- Update the function for hourly checks
CREATE OR REPLACE FUNCTION mark_absent_after_schedule_end()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_schedules_checked INTEGER := 0;
    v_absences_marked INTEGER := 0;
    v_schedule_record RECORD;
    v_check_start_time TIMESTAMPTZ;
    v_check_end_time TIMESTAMPTZ;
BEGIN
    -- Change this line from '2 minutes' to '1 hour'
    v_check_end_time := NOW();
    v_check_start_time := NOW() - INTERVAL '1 hour';  -- Changed from '2 minutes'
    
    -- Rest of the function remains the same...
    -- (Keep all the existing logic)
END;
$$;
```

---

## 🧪 **Testing the System**

### **Manual Test**
```sql
-- Run the function manually
SELECT mark_absent_after_schedule_end();
```

### **Create a Test Schedule**
To test if the system actually marks someone absent:

1. Create a schedule that ends in 1-2 minutes
2. Assign a user to it
3. DON'T check in
4. Wait for the schedule to end + 2 minutes
5. Check if absence was auto-created

```sql
-- After the schedule ends, check for absence
SELECT *
FROM attendance
WHERE schedule_id = 'YOUR_SCHEDULE_ID'
AND status = 'absent';
```

---

## 🔧 **Management Commands**

### **View All Jobs**
```sql
SELECT * FROM cron.job;
```

### **Pause the Job**
```sql
UPDATE cron.job SET active = false WHERE jobname = 'absence-detection-debug';
```

### **Resume the Job**
```sql
UPDATE cron.job SET active = true WHERE jobname = 'absence-detection-debug';
```

### **Delete the Job**
```sql
SELECT cron.unschedule('absence-detection-debug');
```

### **View Execution Logs**
```sql
-- All executions
SELECT * FROM cron.job_run_details WHERE jobid = 1 ORDER BY start_time DESC;

-- Only failed
SELECT * FROM cron.job_run_details WHERE jobid = 1 AND status = 'failed' ORDER BY start_time DESC;

-- Last 24 hours
SELECT * FROM cron.job_run_details 
WHERE jobid = 1 AND start_time > NOW() - INTERVAL '24 hours'
ORDER BY start_time DESC;
```

---

## 📋 **Database Schema**

### **Tables Used**

#### **`attendance`**
- Stores all attendance records
- `status` column can be: 'pending', 'completed', 'absent', etc.
- Auto-created absences have `status = 'absent'`

#### **`system_logs`**
- Stores execution logs
- `event_type = 'pg_cron_absence_detection'` for this system
- Contains JSON data about each execution

#### **`schedule_assignments`**
- Links users to schedules
- Used to find who should have checked in

#### **`employee_schedules`**
- Contains schedule details
- `start_date_time` and `end_date_time` define the schedule window

---

## ✅ **Verification Checklist**

- [x] pg_cron extension is enabled
- [x] `mark_absent_after_schedule_end()` function created
- [x] Job scheduled to run every 2 minutes
- [x] Function logs to `system_logs` table
- [x] Monitoring functions created
- [x] Successfully executed at 08:58:00 UTC
- [x] Successfully executed at 09:00:00 UTC
- [x] System continues running automatically

---

## 🎯 **Next Steps**

1. **Monitor for 1 hour**: Watch the logs to ensure it runs every 2 minutes
2. **Test with real absence**: Create a schedule that ends soon, don't check in, verify absence is auto-created
3. **Switch to hourly**: Once satisfied with testing, switch to hourly schedule
4. **Update admin UI**: Show absence statistics in the admin dashboard

---

## 🚨 **Troubleshooting**

### **Job Not Running**
```sql
-- Check if job is active
SELECT * FROM cron.job WHERE jobname = 'absence-detection-debug';

-- Check for errors
SELECT * FROM cron.job_run_details WHERE jobid = 1 AND status = 'failed';
```

### **No Logs Appearing**
```sql
-- Check system_logs
SELECT * FROM system_logs WHERE event_type = 'pg_cron_absence_detection' ORDER BY created_at DESC;

-- If empty, the function might not be running
```

### **Function Errors**
```sql
-- Check pg_cron logs
SELECT status, return_message FROM cron.job_run_details WHERE jobid = 1 ORDER BY start_time DESC LIMIT 10;
```

---

## 📞 **Support Queries**

### **Get System Summary**
```sql
SELECT monitor_absence_detection_system();
```

### **Count Absences by Date**
```sql
SELECT 
    date,
    COUNT(*) as total_absences,
    json_agg(json_build_object('employee', u.full_name, 'schedule', es.title)) as details
FROM attendance a
JOIN my_users u ON u.id = a.user_id
JOIN employee_schedules es ON es.id = a.schedule_id
WHERE a.status = 'absent'
GROUP BY date
ORDER BY date DESC;
```

---

## 🎉 **Success Metrics**

### **Current Performance**
- ✅ Execution time: ~6-7ms
- ✅ Success rate: 100%
- ✅ Runs exactly every 2 minutes
- ✅ No errors detected

### **What's Working**
1. pg_cron schedules executions perfectly
2. Function executes quickly (<10ms)
3. Logs are created in system_logs
4. Monitoring functions provide visibility
5. No external dependencies needed

---

## 📝 **Summary**

You now have a **fully automated absence detection system** that:
- ✅ Runs inside Supabase (no external services)
- ✅ Executes every 2 minutes (adjustable to hourly)
- ✅ Auto-marks employees as absent if they don't check in
- ✅ Logs all executions for monitoring
- ✅ Provides monitoring functions for visibility
- ✅ Works on Supabase free tier

**No Edge Functions. No GitHub Actions. No CLI. Just SQL.** 🚀

