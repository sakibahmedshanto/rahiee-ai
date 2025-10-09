# 🔧 Schedule Visibility Fix - October 5, 2025

## ❌ **Problem:**
Schedules created on **October 5th** were **not appearing** on the employee side, even though:
- ✅ Admin could see and assign them
- ✅ They existed in the `employee_schedules` table
- ✅ They had `assigned_user_id` set correctly

---

## 🔍 **Root Cause:**

### **What Happened:**
1. **Multi-user schedule system** was implemented with a new `schedule_assignments` table
2. **RPC function** `get_schedules_with_attendance_status` was updated to query ONLY from `schedule_assignments` table (line 579-581 in `sql/multi_user_schedule_system.sql`)
3. **October 5 schedules** were created via admin panel but had **NO entries** in `schedule_assignments` table
4. **Result:** Employee RPC returned empty array → No schedules visible

### **Affected Schedules:**
- `"ai testing 1"` (Oct 5, 19:25-23:26) - assigned to `shantoo` but `assignment_count = 0`
- `"ml 2"` (Oct 5, 23:26-23:55) - assigned to `shantoo` but `assignment_count = 0`
- `"testing multi assign"` (Oct 2) - assigned to `robin` but `assignment_count = 0`

### **Why This Happened:**
The admin UI likely still uses the old method:
```dart
// Old method (single assignment)
INSERT INTO employee_schedules (assigned_user_id, ...)

// New method needed (multi-user)
INSERT INTO employee_schedules (...) THEN
INSERT INTO schedule_assignments (schedule_id, user_id, ...)
```

---

## ✅ **The Fix:**

### **1. Backfill Missing Assignments (Completed)**

**SQL Migration:** `sql/backfill_schedule_assignments.sql`

```sql
-- Backfilled 3 schedules
INSERT INTO schedule_assignments (schedule_id, user_id, ...)
FROM employee_schedules 
WHERE assigned_user_id IS NOT NULL
  AND NOT EXISTS (assignment for that user)
```

**Results:**
- ✅ 3 assignments created
- ✅ Oct 5 schedules now visible to `shantoo`
- ✅ Participant counts updated

### **2. Database Trigger (Prevention)**

**SQL Migration:** `sql/auto_create_schedule_assignment_trigger.sql`

**Function:** `auto_create_schedule_assignment()`
- Automatically creates `schedule_assignments` entry when schedule is created
- Triggers on `INSERT` and `UPDATE` of `assigned_user_id`
- Prevents this issue from happening again

```sql
CREATE TRIGGER trigger_auto_create_assignment_on_insert
    AFTER INSERT ON employee_schedules
    EXECUTE FUNCTION auto_create_schedule_assignment();
```

---

## 📊 **Verification:**

### **Before Fix:**
```sql
SELECT * FROM schedule_assignments WHERE schedule_id IN (oct_5_schedules);
-- Result: 0 rows
```

### **After Fix:**
```sql
SELECT * FROM schedule_assignments WHERE schedule_id IN (oct_5_schedules);
-- Result: 2 rows (both Oct 5 schedules assigned to shantoo)
```

### **RPC Test:**
```sql
SELECT get_schedules_with_attendance_status(
    '883d252d-83d7-4ce5-a1ef-f34e76f5189d', -- shantoo's ID
    '2025-10-05'
);
-- Result: Returns both "ai testing 1" and "ml 2" ✅
```

---

## 🔄 **App-Side Behavior:**

### **Employee Query Flow:**
1. **`UnifiedScheduleController.loadSchedulesForDate()`**
   ```dart
   final response = await client.rpc('get_schedules_with_attendance_status', {
     'p_employee_id': userId,
     'p_date': date,
   });
   ```

2. **RPC Function** (`get_schedules_with_attendance_status`):
   ```sql
   SELECT schedules 
   FROM employee_schedules s
   JOIN schedule_assignments sa ON s.id = sa.schedule_id
   WHERE sa.user_id = p_employee_id
     AND sa.is_active = true
     AND s.start_date_time::date = p_date
   ```

3. **Fallback** (if RPC fails):
   ```dart
   _loadSchedulesForDateDirect() {
     SELECT * FROM employee_schedules
     WHERE assigned_user_id = userId
       AND start_date_time >= date
   }
   ```

### **Issue:**
The fallback was **never triggered** because RPC succeeded but returned empty array (not an error).

---

## 🛡️ **Prevention Measures:**

### **1. Database Trigger (Automatic)**
- ✅ Installed and active
- Creates assignment automatically when schedule is created
- No admin code changes needed

### **2. Admin UI Update (Recommended)**
Update admin schedule creation to explicitly use multi-user system:

```dart
// Current (implicit single assignment)
await createSchedule(assigned_user_id: userId);

// Better (explicit multi-user)
await createSchedule(...);
await assignUsersToSchedule(scheduleId, [userId]);
```

### **3. Monitoring Query**
Run periodically to catch orphaned schedules:

```sql
-- Find schedules with assigned_user_id but no assignments
SELECT 
    es.id,
    es.title,
    es.start_date_time,
    es.assigned_user_id,
    u.full_name,
    (SELECT COUNT(*) FROM schedule_assignments sa WHERE sa.schedule_id = es.id) as assignment_count
FROM employee_schedules es
JOIN my_users u ON es.assigned_user_id = u.id
WHERE es.assigned_user_id IS NOT NULL
  AND es.status = 'active'
  AND NOT EXISTS (
      SELECT 1 FROM schedule_assignments sa 
      WHERE sa.schedule_id = es.id 
        AND sa.user_id = es.assigned_user_id
        AND sa.is_active = true
  );
```

Expected result: **0 rows** (if trigger is working correctly)

---

## 📝 **Files Changed:**

### **SQL Migrations:**
1. ✅ `sql/backfill_schedule_assignments.sql` - Backfilled missing assignments
2. ✅ `sql/auto_create_schedule_assignment_trigger.sql` - Prevention trigger

### **Documentation:**
3. ✅ `SCHEDULE_VISIBILITY_FIX_SUMMARY.md` - This file

---

## 🧪 **Testing Checklist:**

- [x] **Database backfill completed** (3 assignments created)
- [x] **Trigger installed** (auto-creates assignments on INSERT/UPDATE)
- [x] **RPC test passed** (shantoo sees Oct 5 schedules)
- [ ] **App test** (employee logs in and sees Oct 5 schedules)
- [ ] **Admin test** (create new schedule → verify assignment auto-created)
- [ ] **Monitoring** (run orphan check query → expect 0 rows)

---

## 📞 **Support:**

If schedules still don't appear:

1. **Check RPC logs:**
   ```dart
   print('DEBUG: RPC response: $response');
   ```

2. **Check assignment exists:**
   ```sql
   SELECT * FROM schedule_assignments 
   WHERE schedule_id = 'SCHEDULE_ID' 
     AND user_id = 'USER_ID';
   ```

3. **Check RLS policies:**
   ```sql
   SELECT * FROM schedule_assignments 
   WHERE user_id = auth.uid(); -- Must return rows
   ```

4. **Verify trigger is active:**
   ```sql
   SELECT * FROM pg_trigger 
   WHERE tgname LIKE 'trigger_auto_create%';
   ```

---

## ✅ **Status: RESOLVED**

- ✅ **Issue:** October 5 schedules not visible to employees
- ✅ **Root Cause:** Missing entries in `schedule_assignments` table
- ✅ **Fix:** Backfilled assignments + installed prevention trigger
- ✅ **Verified:** RPC returns schedules correctly
- ⏳ **Next:** Test in app to confirm visibility

---

**Date Fixed:** October 5, 2025  
**Fixed By:** AI Assistant  
**Severity:** High (blocked employee check-ins)  
**Impact:** 3 schedules affected (2 on Oct 5, 1 on Oct 2)  
**Status:** ✅ Resolved

---

**Test the app now!** Login as `shantoo` (sakibahmed21@iut-dhaka.edu) and navigate to October 5 schedules. You should see:
- 📅 **"ai testing 1"** (19:25-23:26)
- 📅 **"ml 2"** (23:26-23:55)

Both should show "Check In" buttons! 🎉




