# 🚀 Execute HR Dashboard - Manual Steps

## ⚠️ Important Notice

Since MCP Supabase tools are currently unavailable and Supabase CLI doesn't support direct file execution, please follow these **manual execution steps** in your Supabase Dashboard.

---

## 📋 Execution Steps

### **Step 1: Open Supabase SQL Editor**

1. Go to: https://supabase.com/dashboard/project/YOUR_SUPABASE_PROJECT_REF
2. Click **"SQL Editor"** in the left sidebar
3. Click **"New Query"** button

---

### **Step 2: Execute Tables Creation** ⭐ START HERE

**File to copy**: `sql/hr_dashboard_summary_system.sql`

**Instructions**:
1. Open the file: `sql/hr_dashboard_summary_system.sql`
2. Copy the **entire content** (Cmd+A, Cmd+C)
3. Paste into Supabase SQL Editor
4. Click **"Run"** button (or Cmd+Enter)
5. Wait for success message

**Expected output**: `Success. No rows returned`

**What it creates**:
- ✅ `system_logs` table
- ✅ `payment_transactions` table
- ✅ `user_lifetime_summary` table
- ✅ `daily_attendance_summary` table
- ✅ `weekly_attendance_summary` table
- ✅ `monthly_attendance_summary` table

---

### **Step 3: Execute Trigger Functions**

**File to copy**: `sql/hr_dashboard_triggers.sql`

**Instructions**:
1. Click "New Query" in SQL Editor
2. Open file: `sql/hr_dashboard_triggers.sql`
3. Copy entire content
4. Paste and Run

**Expected output**: `Success. No rows returned`

**What it creates**:
- ✅ `update_user_lifetime_summary()` function + trigger
- ✅ `update_daily_summary()` function + trigger  
- ✅ `update_payment_tracking()` function + trigger

---

### **Step 4: Execute RPC Functions**

**File to copy**: `sql/hr_dashboard_rpc_functions.sql`

**Instructions**:
1. Click "New Query"
2. Open file: `sql/hr_dashboard_rpc_functions.sql`
3. Copy entire content
4. Paste and Run

**Expected output**: `Success. No rows returned`

**What it creates**:
- ✅ `get_realtime_dashboard_stats()` RPC
- ✅ `get_user_performance_summary()` RPC
- ✅ `get_department_analytics()` RPC
- ✅ `get_payroll_summary()` RPC
- ✅ `generate_payment_transaction()` RPC
- ✅ `approve_attendance_batch()` RPC
- ✅ `update_weekly_summary()` RPC
- ✅ `update_monthly_summary()` RPC

---

### **Step 5: Setup pg_cron Jobs**

**File to copy**: `sql/hr_dashboard_pg_cron_jobs.sql`

**Instructions**:
1. Click "New Query"
2. Open file: `sql/hr_dashboard_pg_cron_jobs.sql`
3. Copy entire content
4. Paste and Run

**Expected output**: Success messages for each scheduled job

**What it creates**:
- ✅ `update-weekly-summary` cron job
- ✅ `update-monthly-summary` cron job
- ✅ `cleanup-old-summaries` cron job
- ✅ `cleanup_old_summaries()` function

---

### **Step 6: Enable Realtime**

1. In Supabase Dashboard, go to: **Database → Replication**
2. Scroll down to **"Tables"** section
3. Enable realtime for:
   - ✅ `daily_attendance_summary`
   - ✅ `user_lifetime_summary`
   - ✅ `weekly_attendance_summary`
   - ✅ `monthly_attendance_summary`
   - ✅ `payment_transactions`
4. Click "Save" after enabling each

---

## ✅ Verification Queries

After completing all steps, run these verification queries:

### **Verify Tables**

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND (table_name LIKE '%summary%' OR table_name IN ('payment_transactions', 'system_logs'))
ORDER BY table_name;
```

**Expected**: 6 tables listed

---

### **Verify Triggers**

```sql
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name LIKE '%summary%' OR trigger_name LIKE '%payment%'
ORDER BY trigger_name;
```

**Expected**: 3 triggers listed

---

### **Verify RPC Functions**

```sql
SELECT proname as function_name
FROM pg_proc 
WHERE proname IN (
    'get_realtime_dashboard_stats',
    'get_user_performance_summary',
    'get_department_analytics',
    'get_payroll_summary',
    'generate_payment_transaction',
    'approve_attendance_batch',
    'update_weekly_summary',
    'update_monthly_summary',
    'cleanup_old_summaries'
)
ORDER BY proname;
```

**Expected**: 9 functions listed

---

### **Verify pg_cron Jobs**

```sql
SELECT jobname, schedule, active 
FROM cron.job 
WHERE jobname LIKE '%summary%' OR jobname LIKE '%cleanup%'
ORDER BY jobname;
```

**Expected**: 3 jobs listed

---

### **Test Dashboard Function**

```sql
SELECT get_realtime_dashboard_stats();
```

**Expected**: JSON output with today/week/month data (may have zeros if no attendance data yet)

---

## 🧪 Test the Auto-Update System

### **Test Real-Time Triggers**

Run this test to see if triggers auto-update summaries:

```sql
-- 1. Check current state
SELECT * FROM daily_attendance_summary WHERE summary_date = CURRENT_DATE;
-- Should be empty or have data

-- 2. Get a real user_id and schedule_id from your database
SELECT id as user_id FROM my_users LIMIT 1;
SELECT id as schedule_id FROM employee_schedules LIMIT 1;

-- 3. Insert a test attendance record (REPLACE the UUIDs with real ones from step 2)
INSERT INTO attendance (
    user_id, 
    schedule_id, 
    date, 
    status, 
    check_in_time,
    net_work_hours,
    total_amount,
    wearing_uniform,
    is_late
) VALUES (
    'PASTE_USER_ID_HERE'::UUID,
    'PASTE_SCHEDULE_ID_HERE'::UUID,
    CURRENT_DATE,
    'completed',
    NOW(),
    8.0,
    800.00,
    true,
    false
);

-- 4. Check if daily_attendance_summary was AUTO-UPDATED
SELECT * FROM daily_attendance_summary WHERE summary_date = CURRENT_DATE;
-- Should now have data! This proves triggers are working! ✅

-- 5. Check if user_lifetime_summary was AUTO-UPDATED
SELECT * FROM user_lifetime_summary WHERE user_id = 'PASTE_USER_ID_HERE'::UUID;
-- Should have lifetime stats! ✅
```

---

## 🚨 Common Issues & Fixes

### **Issue: "relation already exists"**

**Meaning**: Table was already created

**Fix**: Skip that step or run:
```sql
DROP TABLE IF EXISTS table_name CASCADE;
-- Then re-run the creation script
```

---

### **Issue: "trigger already exists"**

**Meaning**: Trigger was already created

**Fix**: Triggers use `DROP TRIGGER IF EXISTS`, so this shouldn't happen. If it does:
```sql
DROP TRIGGER IF EXISTS trigger_name ON table_name;
-- Then re-run the trigger script
```

---

### **Issue: "function already exists"**

**Meaning**: Function was already created

**Fix**: Functions use `CREATE OR REPLACE FUNCTION`, so this is actually fine! Continue to next step.

---

### **Issue: "extension pg_cron does not exist"**

**Meaning**: pg_cron extension not enabled

**Fix**:
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
-- Then re-run the pg_cron jobs script
```

---

## 📊 Expected Final State

After successful execution:

```
✅ 6 new tables created
✅ 3 triggers active on attendance/payment tables
✅ 9 RPC functions available
✅ 3 pg_cron jobs scheduled
✅ 5 tables have realtime enabled
✅ Triggers auto-update summaries when attendance changes
✅ Dashboard function returns live data
```

---

## 🎉 Success Confirmation

Run this final diagnostic:

```sql
SELECT 
    'Tables' as type, 
    COUNT(*) as count,
    '6 expected' as expected
FROM information_schema.tables
WHERE table_schema = 'public'
AND (table_name LIKE '%summary%' OR table_name IN ('payment_transactions', 'system_logs'))

UNION ALL

SELECT 
    'Triggers', 
    COUNT(*),
    '3 expected'
FROM information_schema.triggers
WHERE trigger_name LIKE '%summary%' OR trigger_name LIKE '%payment%'

UNION ALL

SELECT 
    'Functions', 
    COUNT(*),
    '9+ expected'
FROM pg_proc
WHERE proname LIKE '%summary%' OR proname LIKE '%payroll%' OR proname LIKE '%payment%' OR proname LIKE '%dashboard%'

UNION ALL

SELECT 
    'Cron Jobs', 
    COUNT(*),
    '3 expected'
FROM cron.job
WHERE jobname LIKE '%summary%' OR jobname LIKE '%cleanup%';
```

**All counts should match expected values!** ✅

---

## 📞 Next Steps

Once everything is verified:

1. ✅ Check `HR_DASHBOARD_COMPLETE_GUIDE.md` for Flutter integration
2. ✅ Build dashboard UI with real-time subscriptions
3. ✅ Test with actual attendance data
4. ✅ Monitor pg_cron job execution
5. ✅ Set up payment processing workflow

---

**Total Time**: 15-20 minutes for complete setup

**Note**: Since MCP tools are unavailable, these manual steps are the recommended approach. Each step is straightforward - just copy SQL and run in Supabase dashboard.

🚀 **Start with Step 1 above!**

