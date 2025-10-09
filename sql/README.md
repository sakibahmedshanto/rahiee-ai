# 📁 SQL Directory - Database Migration Scripts

> **All database migration and setup scripts for Rahiee.AI**

---

## 📋 Active SQL Files

### Core System Files

#### 1. `multi_user_schedule_system.sql` ⭐
**Purpose**: Core migration for multi-user schedule assignment system

**What it does**:
- Creates `schedule_assignments` junction table
- Migrates existing data from `employee_schedules`
- Adds multi-user columns (`is_multi_user`, `max_participants`, `current_participants`)
- Creates `update_schedule_participant_count` trigger
- Defines multi-user RPC functions

**When to run**: Initial setup or when setting up multi-user features

**Order**: Run this FIRST before other schedule-related scripts

---

#### 2. `schedule_exchange_functions.sql` ⭐
**Purpose**: Schedule exchange system for employees to swap shifts

**What it does**:
- Creates `schedule_exchange_requests` table
- Defines exchange RPC functions:
  - `create_schedule_exchange_request()`
  - `admin_manage_schedule_exchange_request()`
  - `get_schedule_exchange_requests()`
  - `cancel_schedule_exchange_request()`
  - `check_schedule_conflict()`
- Sets up RLS policies

**When to run**: After `multi_user_schedule_system.sql`

**Order**: Run SECOND

---

#### 3. `update_schedule_exchange_for_multi_user.sql` ⭐
**Purpose**: Updates exchange logic to work with multi-user schedules

**What it does**:
- Drops old exchange functions
- Updates `create_schedule_exchange_request()` to check `schedule_assignments`
- Updates `admin_manage_schedule_exchange_request()` to:
  - Remove requester from `schedule_assignments`
  - Add requested user to `schedule_assignments`
  - Maintain backward compatibility

**When to run**: After both `multi_user_schedule_system.sql` AND `schedule_exchange_functions.sql`

**Order**: Run THIRD

---

#### 4. `attendance_functions.sql`
**Purpose**: Attendance management RPC functions

**What it does**:
- Defines `check_in()` RPC
- Defines `check_out()` RPC
- Handles geolocation tracking
- Calculates work duration

**When to run**: After schedule system is set up

**Order**: Run FOURTH

---

#### 5. `comprehensive_attendance_system.sql`
**Purpose**: Complete attendance system with triggers and policies

**What it does**:
- Creates attendance table (if not exists)
- Sets up attendance triggers
- Defines attendance-related RPC functions
- Configures RLS policies

**When to run**: After `attendance_functions.sql`

**Order**: Run FIFTH

---

### Utility Files

#### `cleanup_unused_rpcs.sql` 🧹
**Purpose**: Removes old/unused RPC functions from database

**What it does**:
- Drops obsolete schedule fetching RPCs
- Drops unused deletion RPCs
- Lists active functions after cleanup

**When to run**: After all main scripts, for database cleanup

**Order**: Run LAST (optional, for cleanup)

---

#### `test_multi_user_schedule_system.sql` 🧪
**Purpose**: Test script to verify multi-user system works

**What it does**:
- Creates test schedules
- Tests user assignments
- Validates trigger functionality
- Checks RPC functions

**When to run**: After system setup, for testing

**Order**: Run for testing only (not in production)

---

## 🚀 Setup Order (Fresh Database)

```bash
# 1. Core multi-user system
psql -d your_db -f multi_user_schedule_system.sql

# 2. Exchange system
psql -d your_db -f schedule_exchange_functions.sql

# 3. Update exchange for multi-user
psql -d your_db -f update_schedule_exchange_for_multi_user.sql

# 4. Attendance functions
psql -d your_db -f attendance_functions.sql

# 5. Complete attendance system
psql -d your_db -f comprehensive_attendance_system.sql

# 6. (Optional) Cleanup unused RPCs
psql -d your_db -f cleanup_unused_rpcs.sql

# 7. (Optional) Run tests
psql -d your_db -f test_multi_user_schedule_system.sql
```

---

## 🔧 Using Supabase Dashboard

If using Supabase web interface:

1. Go to **SQL Editor**
2. Copy contents of each file
3. Run in the order specified above
4. Check for errors after each execution

---

## ⚠️ Important Notes

### Dependencies
- `update_schedule_exchange_for_multi_user.sql` requires both:
  - `multi_user_schedule_system.sql` (for `schedule_assignments` table)
  - `schedule_exchange_functions.sql` (for exchange system)

### Data Migration
- `multi_user_schedule_system.sql` automatically migrates existing data
- No manual data migration needed
- Backup your database before running migrations!

### Backward Compatibility
- All scripts maintain backward compatibility
- `assigned_user_id` in `employee_schedules` is preserved
- Old code will continue to work

### Re-running Scripts
- Most scripts use `CREATE OR REPLACE FUNCTION`
- Safe to re-run if needed
- `CREATE TABLE IF NOT EXISTS` prevents duplicate tables

---

## 🗑️ Removed Files (Cleaned Up)

These files were removed as they're no longer needed:

- ❌ `employee_schedule_fetching_rpc.sql` - Replaced by `get_user_schedules_multi()`
- ❌ `get_employee_schedules_rpc.sql` - Replaced by `get_user_schedules_multi()`
- ❌ `schedule_deletion_rpc_functions.sql` - Not used in production
- ❌ `safe_schedule_deletion.sql` - Not used in production
- ❌ `advanced_schedule_deletion.sql` - Not used in production
- ❌ `quick_schedule_deletion.sql` - Not used in production
- ❌ `investigate_exchange_issue.sql` - Debugging script (fixed)
- ❌ `verify_schedule_exchange_fix.sql` - Verification script (issue fixed)
- ❌ `comprehensive_schedule_exchange_fix.sql` - Old fix (superseded)
- ❌ All test files for removed features

---

## 📚 Documentation

For complete database documentation:
- **[../docs/DATABASE_COMPLETE_REFERENCE.md](../docs/DATABASE_COMPLETE_REFERENCE.md)** - Complete reference
- **[../docs/RPC_QUICK_REFERENCE.md](../docs/RPC_QUICK_REFERENCE.md)** - Quick RPC lookup
- **[../docs/database_schema.md](../docs/database_schema.md)** - Schema overview

---

## 🆘 Troubleshooting

### "Function already exists" error
- This is usually safe to ignore if using `CREATE OR REPLACE FUNCTION`
- If it's a new function with different parameters, drop the old one first

### "Table already exists" error
- Check if you've already run the script
- Scripts use `IF NOT EXISTS` to prevent this

### "Column already exists" error
- Check if you've already run the migration
- Scripts use `IF NOT EXISTS` for column additions

### "Relation does not exist" error
- You're missing a prerequisite table
- Run scripts in the correct order (see above)

---

## ✅ Verification

After running all scripts, verify setup:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'my_users', 
    'employee_schedules', 
    'schedule_assignments', 
    'attendance', 
    'schedule_exchange_requests'
);

-- Check RPC functions exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'get_user_schedules_multi',
    'assign_users_to_schedule',
    'create_schedule_exchange_request',
    'admin_manage_schedule_exchange_request',
    'check_in',
    'check_out'
);

-- Check trigger exists
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name = 'update_schedule_participant_count';
```

All queries should return results!

---

**Last Updated**: October 2, 2025


