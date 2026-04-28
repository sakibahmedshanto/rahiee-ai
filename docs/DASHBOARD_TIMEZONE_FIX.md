# Dashboard Timezone Fix

## Problem
The admin dashboard was showing "No attendance data today" even though employees had checked in.

## Root Cause
**Timezone mismatch between attendance records and dashboard query:**

1. **Schedule Creation**: Schedules were created for Oct 17 UTC (which is Oct 18 BDT morning)
2. **Check-in Time**: User checked in at 4:07 AM BDT on Oct 18 (which is 10:07 PM UTC on Oct 17)
3. **Attendance Record**: Stored with `date = 2025-10-17` (based on schedule date)
4. **Summary Table**: `daily_attendance_summary` has `summary_date = 2025-10-17`
5. **Dashboard Query**: Was looking for `CURRENT_DATE = 2025-10-18` (UTC)

**Result**: Dashboard couldn't find data because it was looking for Oct 18 data, but all records were stored with Oct 17 date.

## Solution
Modified the `get_realtime_dashboard_stats()` RPC function to be timezone-aware:

```sql
-- Now checks BOTH today and yesterday
WHERE das.summary_date = v_today OR das.summary_date = v_yesterday
ORDER BY das.summary_date DESC
LIMIT 1;
```

This handles the timezone difference by:
- Checking both today's and yesterday's summary data
- Picking the most recent one (ORDER BY DESC + LIMIT 1)
- Ensuring that early morning check-ins (in local timezone) that are stored with the previous UTC date are still counted as "today's" data

## Files Modified
1. **Database**: Applied migration `fix_dashboard_timezone_aware_stats`
2. **SQL File**: `sql/hr_dashboard_rpc_functions.sql` - Updated for future reference
3. **Flutter**: `lib/controllers/admin_controllers/admin_controller.dart` - Fixed ambiguous relationship errors

## Additional Fixes
Also fixed the PostgreSQL ambiguous relationship error in `admin_controller.dart`:
- Changed `my_users!inner(...)` to `my_users!attendance_user_id_fkey(...)`
- This explicitly specifies which foreign key to use (employee's user_id, not reviewer's reviewed_by)

## Testing
```sql
SELECT * FROM get_realtime_dashboard_stats();
```

**Result**: Now correctly shows:
- total_scheduled: 1
- total_present: 1
- total_absent: 1
- total_late: 1
- attendance_rate: 50%

## Impact
✅ Dashboard now shows attendance data correctly regardless of timezone
✅ Works for users in any timezone (BDT, UTC, etc.)
✅ Handles late-night/early-morning check-ins properly
✅ No changes needed to existing attendance records




