# 🗄️ Rahiee.AI Database Schema Reference

> **Quick reference for database structure and relationships**  
> **For complete documentation, see [DATABASE_COMPLETE_REFERENCE.md](DATABASE_COMPLETE_REFERENCE.md)**

---

## 📚 Documentation Index

- **[DATABASE_COMPLETE_REFERENCE.md](DATABASE_COMPLETE_REFERENCE.md)** - Complete tables, RPC functions, triggers, RLS policies, best practices
- **[RPC_QUICK_REFERENCE.md](RPC_QUICK_REFERENCE.md)** - Quick lookup for all RPC function signatures and examples
- **This file** - Quick schema reference and common mistakes to avoid

---

## 🔑 Primary Tables

### 1. `my_users` - User Management
- **Primary Key**: `id` (UUID)
- **Unique**: `email` (TEXT)
- **Purpose**: Stores all user accounts (employees, admins, managers, CEO)

### 2. `employee_schedules` - Schedule Definitions
- **Primary Key**: `id` (UUID)
- **Foreign Keys**: 
  - `created_by_admin_id` → `my_users.id`
  - `assigned_user_id` → `my_users.id` (legacy, for single-user compatibility)
- **Purpose**: Defines work schedules (supports both single and multi-user)

### 3. `schedule_assignments` - Multi-User Assignments (NEW)
- **Primary Key**: `id` (UUID)
- **Foreign Keys**: 
  - `schedule_id` → `employee_schedules.id` (CASCADE)
  - `user_id` → `my_users.id` (CASCADE)
  - `assigned_by_admin_id` → `my_users.id`
- **Unique**: `(schedule_id, user_id)`
- **Purpose**: Junction table for many-to-many schedule-to-user relationship

### 4. `attendance` - Attendance Records
- **Primary Key**: `id` (UUID)
- **Foreign Keys**:
  - `user_id` → `my_users.id` ⚠️ **USE THIS, NOT employee_id**
  - `schedule_id` → `employee_schedules.id`
- **Purpose**: Tracks employee check-ins/check-outs

### 5. `schedule_exchange_requests` - Schedule Exchange System
- **Primary Key**: `id` (UUID)
- **Foreign Keys**:
  - `schedule_id` → `employee_schedules.id`
  - `requester_user_id` → `my_users.id`
  - `requested_user_id` → `my_users.id`
  - `reviewed_by_admin_id` → `my_users.id`
- **Purpose**: Allows employees to request schedule swaps

---

## 🔧 Active RPC Functions

### 📅 Schedule Management
- `get_user_schedules_multi(p_employee_id, p_date)` - Fetch user schedules
- `get_schedules_with_attendance_status(p_employee_id, p_date)` - Schedules with attendance
- `assign_users_to_schedule(p_schedule_id, p_user_ids[], p_admin_id)` - Assign multiple users
- `remove_user_from_schedule(p_schedule_id, p_user_id, p_admin_id)` - Remove user
- `get_schedule_with_assignments(p_schedule_id)` - Get schedule with all users
- `get_available_users_for_schedule(p_schedule_id, p_start_time, p_end_time)` - Find available users

### 🔄 Schedule Exchange
- `create_schedule_exchange_request(...)` - Create exchange request
- `admin_manage_schedule_exchange_request(...)` - Approve/reject exchange
- `get_schedule_exchange_requests(...)` - List exchange requests
- `cancel_schedule_exchange_request(...)` - Cancel user's own request
- `check_schedule_conflict(...)` - Check for scheduling conflicts

### 📊 Attendance
- `check_in(p_user_id, p_schedule_id, p_latitude, p_longitude)` - Employee check-in
- `check_out(p_user_id, p_schedule_id, p_latitude, p_longitude)` - Employee check-out
- `get_schedule_attendance_status(...)` - Get attendance status
- `get_attendance_dashboard_summary(...)` - Dashboard metrics

**For detailed RPC documentation, see [RPC_QUICK_REFERENCE.md](RPC_QUICK_REFERENCE.md)**

---

## 🎬 Active Triggers

### `update_schedule_participant_count`
- **Table**: `schedule_assignments`
- **When**: AFTER INSERT, UPDATE, DELETE
- **Purpose**: Automatically updates `employee_schedules.current_participants` count
- **Why**: Maintains data consistency for multi-user schedules

### Attendance Triggers
- `calculate_attendance_metrics` - Auto-calculate work hours
- `validate_attendance_schedule` - Validate check-in/check-out
- `update_attendance_summaries` - Update summary tables
- `log_attendance_changes` - Audit trail

---

## ⚠️ Common Mistakes to Avoid

### 1. Database Field Mistakes

❌ **WRONG:**
```sql
-- Using employee_id as FK
SELECT * FROM attendance WHERE employee_id = 'uuid-here';

-- Trying to use my_users.user_id
SELECT id FROM my_users WHERE user_id = 'uuid-here';
```

✅ **CORRECT:**
```sql
-- Use user_id (UUID) as FK
SELECT * FROM attendance WHERE user_id = 'uuid-here';

-- my_users primary key is 'id', not 'user_id'
SELECT id FROM my_users WHERE id = 'uuid-here';
```

### 2. Multi-User Schedule Mistakes

❌ **WRONG:**
   ```sql
-- Only checking assigned_user_id for multi-user schedules
SELECT * FROM employee_schedules 
WHERE assigned_user_id = 'user-uuid';
```

✅ **CORRECT:**
   ```sql
-- Check schedule_assignments for multi-user schedules
SELECT es.* FROM employee_schedules es
JOIN schedule_assignments sa ON es.id = sa.schedule_id
WHERE sa.user_id = 'user-uuid'
AND sa.is_active = true
AND sa.status = 'active';

-- Or use the RPC function (RECOMMENDED)
SELECT get_user_schedules_multi('user-uuid', '2025-10-02');
```

### 3. Direct Query vs RPC

❌ **WRONG:**
```dart
// Direct insert without validation
await supabase.from('schedule_assignments').insert({...});
```

✅ **CORRECT:**
```dart
// Use RPC for complex operations
await supabase.rpc('assign_users_to_schedule', params: {...});
```

**Why**: RPCs handle validation, conflicts, and maintain data integrity

### 4. Date Format Mistakes

❌ **WRONG:**
```dart
// Wrong date format
params: {'p_date': '10/02/2025'}  // American format
params: {'p_date': DateTime.now().toString()}  // Includes time
```

✅ **CORRECT:**
```dart
// ISO date format YYYY-MM-DD
params: {'p_date': DateFormat('yyyy-MM-dd').format(DateTime.now())}
```

---

## 🔒 Row Level Security (RLS)

All tables have RLS enabled:

- **Users** can view/update their own data
- **Employees** can view their assigned schedules and attendance
- **Admins** can view/manage all data

**See [DATABASE_COMPLETE_REFERENCE.md](DATABASE_COMPLETE_REFERENCE.md) for detailed RLS policies**

---

## 🚀 Quick Start Examples

### Load User Schedules
```dart
final response = await supabase.rpc(
  'get_schedules_with_attendance_status',
  params: {
    'p_employee_id': userId,
    'p_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  },
);
```

### Assign Multiple Users to Schedule
```dart
final result = await supabase.rpc(
  'assign_users_to_schedule',
  params: {
    'p_schedule_id': scheduleId,
    'p_user_ids': ['user1-uuid', 'user2-uuid'],
    'p_admin_id': adminId,
  },
);
```

### Create Exchange Request
```dart
final result = await supabase.rpc(
  'create_schedule_exchange_request',
  params: {
    'p_requester_user_id': currentUserId,
    'p_schedule_id': scheduleId,
    'p_requested_user_id': selectedUserId,
    'p_request_reason': 'Reason here',
    'p_request_notes': null,
    'p_request_type': 'exchange',
    'p_expires_in_days': 7,
  },
);
```

**For more examples, see [RPC_QUICK_REFERENCE.md](RPC_QUICK_REFERENCE.md)**

---

## 📖 Table Relationship Summary

```
my_users (users)
    ↓
    ├─→ employee_schedules (schedules)
    │       ↓
    │       ├─→ schedule_assignments (multi-user mapping)
    │       │       ↓
    │       │       └─→ attendance (check-ins/check-outs)
    │       │
    │       └─→ schedule_exchange_requests (exchange system)
    │
    └─→ attendance (direct relationship)
```

---

## 🎯 Key Points

1. **Always use RPCs** for complex operations (assignments, exchanges, check-ins)
2. **`schedule_assignments`** is the source of truth for multi-user schedules
3. **`assigned_user_id`** in `employee_schedules` is for legacy/single-user compatibility
4. **All foreign keys** point to `my_users.id` (UUID), never `employee_id` (TEXT)
5. **Date parameters** should be in `YYYY-MM-DD` format
6. **Error handling**: All RPCs return JSON with `success` field

---

## 📚 Full Documentation

For complete details on:
- Table schemas with all columns
- RPC function parameters and return values
- Triggers and their logic
- RLS policies
- Best practices
- Common operations

**See [DATABASE_COMPLETE_REFERENCE.md](DATABASE_COMPLETE_REFERENCE.md)**

For quick RPC lookups:

**See [RPC_QUICK_REFERENCE.md](RPC_QUICK_REFERENCE.md)**

---

**Last Updated**: October 2, 2025
