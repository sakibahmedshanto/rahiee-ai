# 📚 Database Complete Reference Guide

> **Comprehensive documentation for Rahiee.AI database schema, tables, RPC functions, triggers, and best practices**

---

## 📖 Table of Contents

1. [Overview](#overview)
2. [Database Tables](#database-tables)
3. [RPC Functions](#rpc-functions)
4. [Triggers](#triggers)
5. [Row Level Security (RLS)](#row-level-security-rls)
6. [Best Practices](#best-practices)
7. [Common Operations](#common-operations)

---

## 🎯 Overview

The Rahiee.AI database is built on **Supabase (PostgreSQL)** and follows these key principles:

- **Multi-user schedule support**: Multiple employees can be assigned to a single schedule
- **Security first**: Row Level Security (RLS) enabled on all tables
- **RPC-based operations**: Complex operations use stored procedures for scalability
- **Audit trail**: Automatic tracking of creations, updates, and assignments
- **Real-time sync**: Flutter app uses Supabase real-time subscriptions

---

## 🗄️ Database Tables

### 1. `my_users` - User Management

**Purpose**: Stores all user accounts (employees, admins, managers, CEO)

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (generated) |
| `full_name` | TEXT | User's full name |
| `email` | TEXT | Unique email address |
| `employee_id` | TEXT | Company employee ID |
| `user_role` | TEXT | Role: 'employee', 'admin', 'manager', 'ceo' |
| `phone_number` | TEXT | Contact phone |
| `department` | TEXT | Department name |
| `is_active` | BOOLEAN | Account active status |
| `created_at` | TIMESTAMPTZ | Account creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Indexes**:
- Primary key on `id`
- Unique index on `email`
- Index on `user_role` for role-based queries

**RLS Policies**:
- Users can view all active users
- Users can update their own profile
- Admins can manage all users

**Why**: Central user management with role-based access control

---

### 2. `employee_schedules` - Schedule Definitions

**Purpose**: Defines work schedules that can be assigned to one or multiple employees

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (generated) |
| `title` | TEXT | Schedule title |
| `description` | TEXT | Schedule description |
| `start_date_time` | TIMESTAMPTZ | Schedule start time |
| `end_date_time` | TIMESTAMPTZ | Schedule end time |
| `created_by_admin_id` | UUID | Admin who created (FK to my_users) |
| `assigned_user_id` | UUID | Primary assignee (FK to my_users) |
| `department` | TEXT | Department for this schedule |
| `location` | TEXT | Work location |
| `latitude` | NUMERIC | Geolocation latitude |
| `longitude` | NUMERIC | Geolocation longitude |
| `status` | TEXT | 'active', 'completed', 'cancelled' |
| `is_active` | BOOLEAN | Active status |
| `is_multi_user` | BOOLEAN | Supports multiple users |
| `max_participants` | INTEGER | Max users (NULL = unlimited) |
| `min_participants` | INTEGER | Min users required |
| `current_participants` | INTEGER | Current assigned user count |
| `notes` | TEXT | Additional notes |
| `requirements` | TEXT | Job requirements |
| `tags` | TEXT[] | Search tags |
| `custom_fields` | JSONB | Additional custom data |
| `assignment_history` | JSONB | History of assignments |
| `created_at` | TIMESTAMPTZ | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Indexes**:
- Primary key on `id`
- Index on `created_by_admin_id`
- Index on `assigned_user_id`
- Index on `start_date_time` for date queries
- Index on `status` for status filtering

**RLS Policies**:
- Users can view their assigned schedules
- Admins can view/create/update all schedules

**Why**: 
- Stores schedule definitions separate from assignments
- Supports both single and multi-user schedules
- Tracks participant counts automatically via trigger
- Maintains audit history in `assignment_history`

---

### 3. `schedule_assignments` - Multi-User Assignments

**Purpose**: Junction table for many-to-many relationship between schedules and users

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (generated) |
| `schedule_id` | UUID | Schedule reference (FK to employee_schedules) |
| `user_id` | UUID | Assigned user (FK to my_users) |
| `assigned_at` | TIMESTAMPTZ | Assignment timestamp |
| `assigned_by_admin_id` | UUID | Admin who assigned (FK to my_users) |
| `status` | TEXT | 'active', 'removed', 'completed', 'reassigned' |
| `notes` | TEXT | Assignment notes |
| `is_active` | BOOLEAN | Active assignment |
| `created_at` | TIMESTAMPTZ | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Constraints**:
- UNIQUE(schedule_id, user_id) - One user per schedule
- ON DELETE CASCADE - Remove assignments if schedule/user deleted

**Indexes**:
- Primary key on `id`
- Index on `schedule_id`
- Index on `user_id`
- Index on `status`
- Partial index on active assignments

**RLS Policies**:
- Users can view their own assignments
- Admins can view/manage all assignments

**Why**: 
- Enables multiple employees per schedule
- Maintains assignment history
- Tracks who assigned whom and when
- Automatically updates participant counts via trigger

---

### 4. `attendance` - Attendance Records

**Purpose**: Tracks employee check-ins and check-outs for schedules

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (generated) |
| `schedule_id` | UUID | Schedule reference (FK to employee_schedules) |
| `user_id` | UUID | Employee (FK to my_users) |
| `check_in_time` | TIMESTAMPTZ | Check-in timestamp |
| `check_out_time` | TIMESTAMPTZ | Check-out timestamp |
| `check_in_latitude` | NUMERIC | Check-in location latitude |
| `check_in_longitude` | NUMERIC | Check-in location longitude |
| `check_out_latitude` | NUMERIC | Check-out location latitude |
| `check_out_longitude` | NUMERIC | Check-out location longitude |
| `status` | TEXT | 'checked_in', 'checked_out', 'absent' |
| `notes` | TEXT | Attendance notes |
| `work_duration_minutes` | INTEGER | Calculated work duration |
| `created_at` | TIMESTAMPTZ | Record creation |
| `updated_at` | TIMESTAMPTZ | Last update |

**Indexes**:
- Primary key on `id`
- Index on `schedule_id`
- Index on `user_id`
- Index on `check_in_time`

**RLS Policies**:
- Users can view their own attendance
- Users can create attendance for their schedules
- Admins can view all attendance

**Why**: 
- Independent attendance per user (supports multi-user schedules)
- Tracks geolocation for verification
- Calculates work duration automatically
- One attendance record per user per schedule

---

### 5. `schedule_exchange_requests` - Schedule Exchange System

**Purpose**: Allows employees to request schedule swaps with other employees

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (generated) |
| `schedule_id` | UUID | Schedule to exchange (FK to employee_schedules) |
| `requester_user_id` | UUID | User requesting exchange (FK to my_users) |
| `requested_user_id` | UUID | User requested to take over (FK to my_users) |
| `status` | TEXT | 'pending', 'approved', 'rejected', 'cancelled', 'expired' |
| `request_type` | TEXT | 'exchange', 'swap', 'transfer' |
| `request_reason` | TEXT | Why exchange is requested |
| `request_notes` | TEXT | Additional notes from requester |
| `admin_notes` | TEXT | Admin notes during review |
| `rejection_reason` | TEXT | Reason if rejected |
| `reviewed_by_admin_id` | UUID | Admin who reviewed (FK to my_users) |
| `reviewed_at` | TIMESTAMPTZ | Review timestamp |
| `expires_at` | TIMESTAMPTZ | Request expiration time |
| `created_at` | TIMESTAMPTZ | Request creation |
| `updated_at` | TIMESTAMPTZ | Last update |

**Indexes**:
- Primary key on `id`
- Index on `schedule_id`
- Index on `requester_user_id`
- Index on `requested_user_id`
- Index on `status`

**RLS Policies**:
- Users can view requests involving them
- Users can create exchange requests
- Admins can view/manage all requests

**Why**: 
- Enables flexible schedule management
- Admin approval required for security
- Tracks full audit trail
- Auto-expires old requests
- Updates `schedule_assignments` on approval

---

## ⚙️ RPC Functions

### 📅 Schedule Management

#### `get_user_schedules_multi(p_employee_id, p_date)`

**Purpose**: Fetch all schedules for a user on a specific date with multi-user support

**Parameters**:
- `p_employee_id` (UUID): User ID
- `p_date` (DATE): Date to fetch schedules for

**Returns**: JSON object with schedules array

**Example**:
```sql
SELECT get_user_schedules_multi('user-uuid-here', '2025-10-02');
```

**Used By**: Flutter app to load user schedules

**Why**: Handles both single-user and multi-user schedule assignments efficiently

---

#### `get_schedules_with_attendance_status(p_employee_id, p_date)`

**Purpose**: Fetch schedules with attendance status (checked in, checked out, etc.)

**Parameters**:
- `p_employee_id` (UUID): User ID
- `p_date` (DATE): Date to fetch schedules for

**Returns**: JSON with schedules and attendance data

**Example**:
```sql
SELECT get_schedules_with_attendance_status('user-uuid-here', '2025-10-02');
```

**Used By**: Flutter app home screen and schedule views

**Why**: Combines schedule and attendance data in a single query for better performance

---

#### `assign_users_to_schedule(p_schedule_id, p_user_ids, p_admin_id)`

**Purpose**: Assign multiple users to a schedule

**Parameters**:
- `p_schedule_id` (UUID): Schedule to assign to
- `p_user_ids` (UUID[]): Array of user IDs to assign
- `p_admin_id` (UUID): Admin performing the assignment

**Returns**: JSON with success status and assigned users

**Example**:
```sql
SELECT assign_users_to_schedule(
    'schedule-uuid',
    ARRAY['user1-uuid', 'user2-uuid']::UUID[],
    'admin-uuid'
);
```

**Used By**: Admin schedule creation/management

**Why**: 
- Ensures atomic assignment of multiple users
- Validates max_participants limit
- Checks for scheduling conflicts
- Updates participant counts automatically

---

#### `remove_user_from_schedule(p_schedule_id, p_user_id, p_admin_id)`

**Purpose**: Remove a user from a schedule assignment

**Parameters**:
- `p_schedule_id` (UUID): Schedule ID
- `p_user_id` (UUID): User to remove
- `p_admin_id` (UUID): Admin performing removal

**Returns**: JSON with success status

**Example**:
```sql
SELECT remove_user_from_schedule(
    'schedule-uuid',
    'user-uuid',
    'admin-uuid'
);
```

**Used By**: Admin schedule management

**Why**: 
- Safely removes user from multi-user schedule
- Updates participant count
- Maintains audit trail

---

#### `get_schedule_with_assignments(p_schedule_id)`

**Purpose**: Get complete schedule details with all assigned users

**Parameters**:
- `p_schedule_id` (UUID): Schedule ID

**Returns**: JSON with schedule data and assigned users array

**Example**:
```sql
SELECT get_schedule_with_assignments('schedule-uuid');
```

**Used By**: Admin schedule detail view

**Why**: Shows all users assigned to a schedule in one query

---

#### `get_available_users_for_schedule(p_schedule_id, p_start_time, p_end_time)`

**Purpose**: Find users available for a schedule (no conflicts)

**Parameters**:
- `p_schedule_id` (UUID): Schedule ID (NULL for new schedules)
- `p_start_time` (TIMESTAMPTZ): Schedule start
- `p_end_time` (TIMESTAMPTZ): Schedule end

**Returns**: JSON with array of available users

**Example**:
```sql
SELECT get_available_users_for_schedule(
    NULL,
    '2025-10-02 09:00:00+00',
    '2025-10-02 17:00:00+00'
);
```

**Used By**: Admin schedule creation, employee exchange requests

**Why**: 
- Prevents double-booking
- Filters only active employees
- Checks for scheduling conflicts

---

### 🔄 Schedule Exchange

#### `create_schedule_exchange_request(p_requester_user_id, p_schedule_id, p_requested_user_id, ...)`

**Purpose**: Employee creates a request to exchange their schedule with another employee

**Parameters**:
- `p_requester_user_id` (UUID): User requesting exchange
- `p_schedule_id` (UUID): Schedule to exchange
- `p_requested_user_id` (UUID): User to exchange with
- `p_request_reason` (TEXT): Reason for exchange
- `p_request_notes` (TEXT): Additional notes
- `p_request_type` (TEXT): 'exchange', 'swap', 'transfer'
- `p_expires_in_days` (INTEGER): Days until expiration

**Returns**: JSON with success status and request ID

**Example**:
```sql
SELECT create_schedule_exchange_request(
    'requester-uuid',
    'schedule-uuid',
    'requested-user-uuid',
    'Family emergency',
    NULL,
    'exchange',
    7
);
```

**Used By**: Employee schedule exchange screen

**Why**: 
- Validates requester is assigned to schedule
- Checks requested user is available
- Prevents self-exchange
- Sets expiration date automatically

---

#### `admin_manage_schedule_exchange_request(p_admin_id, p_request_id, p_action, ...)`

**Purpose**: Admin approves, rejects, or cancels an exchange request

**Parameters**:
- `p_admin_id` (UUID): Admin performing action
- `p_request_id` (UUID): Request to manage
- `p_action` (TEXT): 'approve', 'reject', 'cancel'
- `p_admin_notes` (TEXT): Admin notes
- `p_rejection_reason` (TEXT): Reason if rejecting

**Returns**: JSON with success status and message

**Example**:
```sql
SELECT admin_manage_schedule_exchange_request(
    'admin-uuid',
    'request-uuid',
    'approve',
    'Approved due to valid reason',
    NULL
);
```

**Used By**: Admin exchange request management

**Why**: 
- Validates admin permissions
- On approve: Updates `schedule_assignments` (removes requester, adds requested user)
- Maintains legacy `assigned_user_id` for backward compatibility
- Prevents conflicts
- Tracks full audit trail

---

#### `get_schedule_exchange_requests(p_user_id, p_status, p_request_type, p_limit, p_offset)`

**Purpose**: Fetch exchange requests with filtering

**Parameters**:
- `p_user_id` (UUID): Filter by user (NULL for all)
- `p_status` (TEXT): Filter by status (NULL for all)
- `p_request_type` (TEXT): Filter by type (NULL for all)
- `p_limit` (INTEGER): Result limit
- `p_offset` (INTEGER): Pagination offset

**Returns**: JSON with requests array and total count

**Example**:
```sql
-- Get all pending requests
SELECT get_schedule_exchange_requests(NULL, 'pending', NULL, 50, 0);

-- Get user's approved requests
SELECT get_schedule_exchange_requests('user-uuid', 'approved', NULL, 50, 0);
```

**Used By**: Admin exchange request screen, employee request history

**Why**: 
- Flexible filtering for different views
- Pagination support
- Returns complete request details with user names

---

#### `cancel_schedule_exchange_request(p_user_id, p_request_id, p_cancellation_reason)`

**Purpose**: User cancels their own pending exchange request

**Parameters**:
- `p_user_id` (UUID): User cancelling
- `p_request_id` (UUID): Request to cancel
- `p_cancellation_reason` (TEXT): Cancellation reason

**Returns**: JSON with success status

**Example**:
```sql
SELECT cancel_schedule_exchange_request(
    'user-uuid',
    'request-uuid',
    'No longer needed'
);
```

**Used By**: Employee exchange request management

**Why**: 
- Allows users to cancel their own requests
- Only works on pending requests
- Maintains audit trail

---

#### `check_schedule_conflict(p_user_id, p_start_time, p_end_time, p_exclude_schedule_id)`

**Purpose**: Check if user has scheduling conflicts in a time range

**Parameters**:
- `p_user_id` (UUID): User to check
- `p_start_time` (TIMESTAMPTZ): Start time
- `p_end_time` (TIMESTAMPTZ): End time
- `p_exclude_schedule_id` (UUID): Schedule to exclude from check

**Returns**: JSON with conflict status and conflicting schedules

**Example**:
```sql
SELECT check_schedule_conflict(
    'user-uuid',
    '2025-10-02 09:00:00+00',
    '2025-10-02 17:00:00+00',
    NULL
);
```

**Used By**: Schedule assignment, exchange validation

**Why**: 
- Prevents double-booking
- Checks against both `schedule_assignments` and legacy `assigned_user_id`
- Used internally by other RPC functions

---

### 📊 Attendance Management

#### `check_in(p_user_id, p_schedule_id, p_latitude, p_longitude)`

**Purpose**: Employee checks in to a schedule

**Parameters**:
- `p_user_id` (UUID): User checking in
- `p_schedule_id` (UUID): Schedule to check in to
- `p_latitude` (NUMERIC): Check-in location latitude
- `p_longitude` (NUMERIC): Check-in location longitude

**Returns**: JSON with success status and attendance ID

**Example**:
```sql
SELECT check_in(
    'user-uuid',
    'schedule-uuid',
    23.8103,
    90.4125
);
```

**Used By**: Employee schedule check-in

**Why**: 
- Creates attendance record
- Records geolocation
- Validates user is assigned
- Prevents duplicate check-ins

---

#### `check_out(p_user_id, p_schedule_id, p_latitude, p_longitude)`

**Purpose**: Employee checks out from a schedule

**Parameters**:
- `p_user_id` (UUID): User checking out
- `p_schedule_id` (UUID): Schedule to check out from
- `p_latitude` (NUMERIC): Check-out location latitude
- `p_longitude` (NUMERIC): Check-out location longitude

**Returns**: JSON with success status and work duration

**Example**:
```sql
SELECT check_out(
    'user-uuid',
    'schedule-uuid',
    23.8103,
    90.4125
);
```

**Used By**: Employee schedule check-out

**Why**: 
- Updates attendance record
- Records check-out location
- Calculates work duration
- Validates check-in exists

---

## 🎬 Triggers

### `update_schedule_participant_count`

**Type**: AFTER INSERT/UPDATE/DELETE trigger on `schedule_assignments`

**Purpose**: Automatically update `current_participants` count in `employee_schedules`

**Fires When**:
- New assignment created
- Assignment status changed
- Assignment deleted

**Logic**:
```sql
UPDATE employee_schedules
SET current_participants = (
    SELECT COUNT(*)
    FROM schedule_assignments
    WHERE schedule_id = X
    AND is_active = true
    AND status = 'active'
)
WHERE id = X;
```

**Why**: 
- Keeps participant count accurate
- No manual count updates needed
- Ensures data consistency
- Used for validating max_participants

---

## 🔒 Row Level Security (RLS)

All tables have RLS enabled with the following policies:

### `my_users`
- ✅ Users can view all active users
- ✅ Users can update their own profile
- ✅ Admins can manage all users

### `employee_schedules`
- ✅ Users can view schedules assigned to them
- ✅ Admins can view/create/update all schedules

### `schedule_assignments`
- ✅ Users can view their own assignments
- ✅ Admins can manage all assignments

### `attendance`
- ✅ Users can view their own attendance
- ✅ Users can create attendance for their schedules
- ✅ Admins can view all attendance

### `schedule_exchange_requests`
- ✅ Users can view requests involving them
- ✅ Users can create exchange requests
- ✅ Admins can view/manage all requests

**Why RLS**: 
- Data security at database level
- Even if app has bugs, data is protected
- Follows principle of least privilege

---

## 💡 Best Practices

### 1. Always Use RPC Functions for Complex Operations

❌ **DON'T**:
```dart
// Direct query for assigning users
await supabase
  .from('schedule_assignments')
  .insert({...});
```

✅ **DO**:
```dart
// Use RPC function
await supabase.rpc('assign_users_to_schedule', params: {...});
```

**Why**: RPCs handle validation, conflicts, and maintain data integrity

---

### 2. Check for Conflicts Before Assignment

Always use `check_schedule_conflict()` or `get_available_users_for_schedule()` before assignments

**Why**: Prevents double-booking

---

### 3. Use `schedule_assignments` for Multi-User Logic

For all multi-user schedule operations, query `schedule_assignments`, not just `assigned_user_id`

**Why**: `assigned_user_id` is legacy field, `schedule_assignments` is source of truth

---

### 4. Handle RPC Errors Gracefully

```dart
final result = await supabase.rpc('function_name', params: {...});

if (result['success'] == false) {
  // Handle error
  showError(result['error']);
} else {
  // Handle success
  processData(result['data']);
}
```

**Why**: RPCs return JSON with `success` field for consistent error handling

---

### 5. Always Specify Date Parameters in Correct Format

```dart
// Correct
final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
await supabase.rpc('get_user_schedules_multi', params: {
  'p_employee_id': userId,
  'p_date': date,
});
```

**Why**: Ensures date consistency and prevents timezone issues

---

## 🚀 Common Operations

### Creating a Multi-User Schedule

```sql
-- 1. Create schedule
INSERT INTO employee_schedules (title, description, start_date_time, end_date_time, created_by_admin_id, is_multi_user, max_participants)
VALUES ('Team Meeting', 'Weekly sync', '2025-10-02 10:00:00+00', '2025-10-02 11:00:00+00', 'admin-uuid', true, 5);

-- 2. Assign users via RPC
SELECT assign_users_to_schedule(
    'schedule-uuid',
    ARRAY['user1-uuid', 'user2-uuid', 'user3-uuid']::UUID[],
    'admin-uuid'
);
```

---

### Approving Schedule Exchange

```sql
-- Admin approves exchange
SELECT admin_manage_schedule_exchange_request(
    'admin-uuid',
    'request-uuid',
    'approve',
    'Approved',
    NULL
);

-- This automatically:
-- 1. Removes requester from schedule_assignments
-- 2. Adds requested user to schedule_assignments
-- 3. Updates current_participants
-- 4. Updates request status
```

---

### Checking User Availability

```sql
-- Find available users for a time slot
SELECT get_available_users_for_schedule(
    NULL,
    '2025-10-02 09:00:00+00',
    '2025-10-02 17:00:00+00'
);
```

---

## 🎯 Summary

**This database schema provides**:

✅ **Scalability**: RPC functions for complex operations  
✅ **Security**: RLS policies on all tables  
✅ **Flexibility**: Multi-user and single-user schedules  
✅ **Auditability**: Full history tracking  
✅ **Data Integrity**: Triggers maintain consistency  
✅ **Performance**: Proper indexing and optimized queries  

**For questions or issues, refer to this documentation first!** 📚

