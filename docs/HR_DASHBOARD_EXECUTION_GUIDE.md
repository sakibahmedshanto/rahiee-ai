# 🚀 HR Dashboard - Safe Execution Guide

## ✅ Pre-Execution Verification Complete

**Database State Analysis**: See `DATABASE_STATE_ANALYSIS.md`

**Result**: ✅ **SAFE TO PROCEED** - No conflicts detected

---

## 📋 Execution Checklist

### **Before You Start**

- [x] Analyzed existing database schema
- [x] Verified no table name conflicts
- [x] Verified no deprecated logic exists
- [x] Confirmed `schedule_assignments` is active (not deprecated)
- [x] Confirmed no `daily_employee_summary` or `monthly_employee_summary` tables exist
- [x] Added `system_logs` table to SQL files

---

## 🎯 Execution Steps (IN ORDER)

### **Step 1: Create Tables** ⭐ START HERE

**File**: `sql/hr_dashboard_summary_system.sql`

**What it creates**:
1. `system_logs` - For monitoring (NEW)
2. `payment_transactions` - Payment tracking (NEW)
3. `user_lifetime_summary` - Employee lifetime stats (NEW)
4. `daily_attendance_summary` - Daily aggregations (NEW)
5. `weekly_attendance_summary` - Weekly aggregations (NEW)
6. `monthly_attendance_summary` - Monthly aggregations (NEW)

**How to execute**:
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Click "New Query"
4. Copy entire content of `sql/hr_dashboard_summary_system.sql`
5. Paste and click "Run"
6. Wait for "Success. No rows returned" message

**Expected time**: ~5 seconds

---

### **Step 2: Create Trigger Functions**

**File**: `sql/hr_dashboard_triggers.sql`

**What it creates**:
1. `update_user_lifetime_summary()` function + trigger on `attendance`
2. `update_daily_summary()` function + trigger on `attendance`
3. `update_payment_tracking()` function + trigger on `payment_transactions`

**How to execute**:
1. In Supabase SQL Editor
2. New Query
3. Copy entire content of `sql/hr_dashboard_triggers.sql`
4. Paste and Run

**Expected time**: ~3 seconds

---

### **Step 3: Create RPC Functions**

**File**: `sql/hr_dashboard_rpc_functions.sql`

**What it creates**:
1. `get_realtime_dashboard_stats()` - Dashboard data
2. `get_user_performance_summary()` - User stats
3. `get_department_analytics()` - Department breakdown
4. `get_payroll_summary()` - Monthly payroll
5. `generate_payment_transaction()` - Create payment
6. `approve_attendance_batch()` - Bulk approve
7. `update_weekly_summary()` - Weekly aggregation
8. `update_monthly_summary()` - Monthly aggregation  

**How to execute**:
1. In Supabase SQL Editor
2. New Query
3. Copy entire content of `sql/hr_dashboard_rpc_functions.sql`
4. Paste and Run

**Expected time**: ~5 seconds

---

### **Step 4: Setup pg_cron Jobs**

**File**: `sql/hr_dashboard_pg_cron_jobs.sql`

**What it creates**:
1. `update-weekly-summary` job (runs daily at 1 AM)
2. `update-monthly-summary` job (runs 1st & 15th at 2 AM)
3. `cleanup-old-summaries` job (runs monthly at 3 AM)
4. `cleanup_old_summaries()` function

**How to execute**:
1. In Supabase SQL Editor
2. New Query
3. Copy entire content of `sql/hr_dashboard_pg_cron_jobs.sql`
4. Paste and Run

**Expected time**: ~2 seconds

---

### **Step 5: Enable Realtime**

**Required for live dashboard updates!**

1. Open Supabase Dashboard
2. Navigate to: **Database → Replication**
3. Find and enable realtime for these tables:
   - ✅ `daily_attendance_summary`
   - ✅ `user_lifetime_summary`
   - ✅ `weekly_attendance_summary`
   - ✅ `monthly_attendance_summary`
   - ✅ `payment_transactions`

4. Click "Save" or "Enable" for each

**Expected time**: ~2 minutes

---

## ✅ Verification Queries

After execution, run these queries to verify everything is working:

### **1. Check Tables Created**

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND (table_name LIKE '%summary%' OR table_name = 'payment_transactions' OR table_name = 'system_logs')
ORDER BY table_name;
```

**Expected result**: 6 tables
- `daily_attendance_summary`
- `monthly_attendance_summary`
- `payment_transactions`
- `system_logs`
- `user_lifetime_summary`
- `weekly_attendance_summary`

---

### **2. Check Triggers Created**

```sql
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name LIKE '%summary%' OR trigger_name LIKE '%payment%'
ORDER BY trigger_name;
```

**Expected result**: 3 triggers
- `trg_update_daily_summary` on `attendance`
- `trg_update_payment_tracking` on `payment_transactions`
- `trg_update_user_lifetime_summary` on `attendance`

---

### **3. Check RPC Functions Created**

```sql
SELECT proname as function_name
FROM pg_proc 
WHERE proname LIKE '%summary%' OR proname LIKE '%payroll%' OR proname LIKE '%payment%' OR proname LIKE '%dashboard%'
ORDER BY proname;
```

**Expected result**: 9+ functions including:
- `approve_attendance_batch`
- `cleanup_old_summaries`
- `generate_payment_transaction`
- `get_department_analytics`
- `get_payroll_summary`
- `get_realtime_dashboard_stats`
- `get_user_performance_summary`
- `update_monthly_summary`
- `update_weekly_summary`

---

### **4. Check pg_cron Jobs**

```sql
SELECT jobname, schedule, active 
FROM cron.job 
WHERE jobname LIKE '%summary%' OR jobname LIKE '%cleanup%'
ORDER BY jobname;
```

**Expected result**: 3 jobs
- `cleanup-old-summaries` - `0 3 1 * *` - active: true
- `update-monthly-summary` - `0 2 1,15 * *` - active: true
- `update-weekly-summary` - `0 1 * * *` - active: true

---

### **5. Test Dashboard Function**

```sql
SELECT get_realtime_dashboard_stats();
```

**Expected result**: JSON with today/week/month stats (values may be zero if no attendance data yet)

---

## 🧪 Test the System

### **Test 1: Create Attendance and See Auto-Update**

```sql
-- Assume you have a user_id and schedule_id

-- 1. Insert a test attendance record
INSERT INTO attendance (
    user_id, 
    schedule_id, 
    date, 
    status, 
    check_in_time,
    net_work_hours,
    total_amount
) VALUES (
    'YOUR_USER_ID'::UUID,
    'YOUR_SCHEDULE_ID'::UUID,
    CURRENT_DATE,
    'completed',
    NOW(),
    8.0,
    800.00
);

-- 2. Check if user_lifetime_summary was auto-updated
SELECT * FROM user_lifetime_summary WHERE user_id = 'YOUR_USER_ID'::UUID;

-- 3. Check if daily_attendance_summary was auto-updated
SELECT * FROM daily_attendance_summary WHERE summary_date = CURRENT_DATE;
```

**Expected**: Both summaries should have data automatically!

---

### **Test 2: Test Real-Time in Flutter**

```dart
// In your Flutter app
final stream = supabase
    .from('daily_attendance_summary')
    .stream(primaryKey: ['id'])
    .eq('summary_date', DateTime.now().toString().split(' ')[0])
    .listen((data) {
      print('Real-time update received: $data');
    });

// Now insert/update attendance in database
// You should see console log within 100ms!
```

---

## 🎉 Success Indicators

After successful execution, you should have:

- ✅ 6 new tables in database
- ✅ 3 triggers attached to attendance/payment tables
- ✅ 9+ new RPC functions
- ✅ 3 scheduled pg_cron jobs
- ✅ Realtime enabled for 5 tables
- ✅ Auto-updating summaries on attendance changes
- ✅ Live dashboard data via `get_realtime_dashboard_stats()`

---

## 🚨 Troubleshooting

### **Problem: "Table already exists" error**

**Solution**: Tables use `CREATE TABLE IF NOT EXISTS`, so this shouldn't happen. If it does:
```sql
-- Check if table exists
SELECT * FROM payment_transactions LIMIT 1;

-- If it works, the table was already created (that's OK!)
```

---

### **Problem: "Trigger already exists" error**

**Solution**: Triggers use `DROP TRIGGER IF EXISTS` before creating, so this shouldn't happen. If it does:
```sql
-- Drop manually
DROP TRIGGER IF EXISTS trg_update_user_lifetime_summary ON attendance;
DROP TRIGGER IF EXISTS trg_update_daily_summary ON attendance;
DROP TRIGGER IF EXISTS trg_update_payment_tracking ON payment_transactions;

-- Then re-run hr_dashboard_triggers.sql
```

---

### **Problem: "Function already exists" error**

**Solution**: Functions use `CREATE OR REPLACE FUNCTION`, so this shouldn't happen. Safe to ignore if it's our functions.

---

### **Problem: Realtime not working**

**Check**:
1. Supabase Dashboard → Database → Replication → Verify tables are enabled
2. In Flutter, ensure you're subscribed to the correct table
3. Test by manually inserting data and watching console

---

## 📚 Next Steps After Execution

1. ✅ Read `HR_DASHBOARD_COMPLETE_GUIDE.md` for Flutter integration
2. ✅ Build dashboard UI using examples provided
3. ✅ Test with real attendance data
4. ✅ Monitor pg_cron execution logs
5. ✅ Set up payment processing workflow

---

## 📞 Support Queries

If you encounter issues, run this diagnostic:

```sql
-- Complete diagnostic report
SELECT 'Tables' as type, COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
AND (table_name LIKE '%summary%' OR table_name = 'payment_transactions' OR table_name = 'system_logs')

UNION ALL

SELECT 'Triggers', COUNT(*)
FROM information_schema.triggers
WHERE trigger_name LIKE '%summary%' OR trigger_name LIKE '%payment%'

UNION ALL

SELECT 'Functions', COUNT(*)
FROM pg_proc
WHERE proname LIKE '%summary%' OR proname LIKE '%payroll%' OR proname LIKE '%payment%' OR proname LIKE '%dashboard%'

UNION ALL

SELECT 'Cron Jobs', COUNT(*)
FROM cron.job
WHERE jobname LIKE '%summary%' OR jobname LIKE '%cleanup%';
```

**Expected counts**: 6, 3, 9+, 3

---

**Total Execution Time**: ~15-20 minutes (including verification)

**Ready to execute? Start with Step 1!** 🚀

