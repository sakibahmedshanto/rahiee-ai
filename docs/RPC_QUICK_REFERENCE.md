# 🚀 RPC Functions Quick Reference

> **Fast lookup guide for all RPC functions in Rahiee.AI**

---

## 📋 Quick Index

- [Schedule Management](#-schedule-management)
- [Schedule Exchange](#-schedule-exchange)
- [Attendance](#-attendance)

---

## 📅 Schedule Management

### `get_user_schedules_multi(p_employee_id, p_date)`
**Purpose**: Fetch user schedules for a specific date  
**Returns**: JSON with schedules array  
```sql
SELECT get_user_schedules_multi('user-uuid', '2025-10-02');
```

### `get_schedules_with_attendance_status(p_employee_id, p_date)`
**Purpose**: Fetch schedules with attendance data  
**Returns**: JSON with schedules + attendance status  
```sql
SELECT get_schedules_with_attendance_status('user-uuid', '2025-10-02');
```

### `assign_users_to_schedule(p_schedule_id, p_user_ids[], p_admin_id)`
**Purpose**: Assign multiple users to a schedule  
**Returns**: JSON with success + assigned users  
```sql
SELECT assign_users_to_schedule(
    'schedule-uuid',
    ARRAY['user1', 'user2']::UUID[],
    'admin-uuid'
);
```

### `remove_user_from_schedule(p_schedule_id, p_user_id, p_admin_id)`
**Purpose**: Remove user from schedule  
**Returns**: JSON with success status  
```sql
SELECT remove_user_from_schedule('schedule-uuid', 'user-uuid', 'admin-uuid');
```

### `get_schedule_with_assignments(p_schedule_id)`
**Purpose**: Get schedule with all assigned users  
**Returns**: JSON with schedule + users array  
```sql
SELECT get_schedule_with_assignments('schedule-uuid');
```

### `get_available_users_for_schedule(p_schedule_id, p_start_time, p_end_time)`
**Purpose**: Find users available for schedule (no conflicts)  
**Returns**: JSON with available users array  
```sql
SELECT get_available_users_for_schedule(
    NULL,
    '2025-10-02 09:00:00+00',
    '2025-10-02 17:00:00+00'
);
```

---

## 🔄 Schedule Exchange

### `create_schedule_exchange_request(...)`
**Purpose**: Create schedule exchange request  
**Returns**: JSON with success + request_id  
```sql
SELECT create_schedule_exchange_request(
    'requester-uuid',
    'schedule-uuid',
    'requested-user-uuid',
    'Reason',
    'Notes',
    'exchange',
    7
);
```

**Parameters**:
- `p_requester_user_id` (UUID)
- `p_schedule_id` (UUID)
- `p_requested_user_id` (UUID)
- `p_request_reason` (TEXT)
- `p_request_notes` (TEXT)
- `p_request_type` (TEXT): 'exchange' | 'swap' | 'transfer'
- `p_expires_in_days` (INTEGER)

### `admin_manage_schedule_exchange_request(...)`
**Purpose**: Approve/reject/cancel exchange request  
**Returns**: JSON with success + message  
```sql
SELECT admin_manage_schedule_exchange_request(
    'admin-uuid',
    'request-uuid',
    'approve',
    'Admin notes',
    NULL
);
```

**Parameters**:
- `p_admin_id` (UUID)
- `p_request_id` (UUID)
- `p_action` (TEXT): 'approve' | 'reject' | 'cancel'
- `p_admin_notes` (TEXT)
- `p_rejection_reason` (TEXT)

### `get_schedule_exchange_requests(...)`
**Purpose**: List exchange requests with filters  
**Returns**: JSON with requests array + total  
```sql
-- All pending requests
SELECT get_schedule_exchange_requests(NULL, 'pending', NULL, 50, 0);

-- User's requests
SELECT get_schedule_exchange_requests('user-uuid', NULL, NULL, 50, 0);
```

**Parameters**:
- `p_user_id` (UUID) - NULL for all
- `p_status` (TEXT) - NULL for all
- `p_request_type` (TEXT) - NULL for all
- `p_limit` (INTEGER)
- `p_offset` (INTEGER)

### `cancel_schedule_exchange_request(p_user_id, p_request_id, p_cancellation_reason)`
**Purpose**: User cancels their own pending request  
**Returns**: JSON with success status  
```sql
SELECT cancel_schedule_exchange_request(
    'user-uuid',
    'request-uuid',
    'No longer needed'
);
```

### `check_schedule_conflict(p_user_id, p_start_time, p_end_time, p_exclude_schedule_id)`
**Purpose**: Check for scheduling conflicts  
**Returns**: JSON with conflict status + conflicting schedules  
```sql
SELECT check_schedule_conflict(
    'user-uuid',
    '2025-10-02 09:00:00+00',
    '2025-10-02 17:00:00+00',
    NULL
);
```

---

## 📊 Attendance

### `check_in(p_user_id, p_schedule_id, p_latitude, p_longitude)`
**Purpose**: Employee check-in  
**Returns**: JSON with success + attendance_id  
```sql
SELECT check_in('user-uuid', 'schedule-uuid', 23.8103, 90.4125);
```

### `check_out(p_user_id, p_schedule_id, p_latitude, p_longitude)`
**Purpose**: Employee check-out  
**Returns**: JSON with success + work_duration  
```sql
SELECT check_out('user-uuid', 'schedule-uuid', 23.8103, 90.4125);
```

---

## 🎨 Flutter Usage Examples

### Load User Schedules
```dart
final response = await supabase.rpc(
  'get_schedules_with_attendance_status',
  params: {
    'p_employee_id': userId,
    'p_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  },
);

if (response['error'] == false) {
  final schedules = response['schedules'] as List;
  // Process schedules
}
```

### Create Exchange Request
```dart
final result = await supabase.rpc(
  'create_schedule_exchange_request',
  params: {
    'p_requester_user_id': currentUserId,
    'p_schedule_id': scheduleId,
    'p_requested_user_id': selectedUserId,
    'p_request_reason': reason,
    'p_request_notes': notes,
    'p_request_type': 'exchange',
    'p_expires_in_days': 7,
  },
);

if (result['success'] == true) {
  // Show success message
}
```

### Assign Multiple Users
```dart
final result = await supabase.rpc(
  'assign_users_to_schedule',
  params: {
    'p_schedule_id': scheduleId,
    'p_user_ids': selectedUserIds, // List<String>
    'p_admin_id': adminId,
  },
);

if (result['success'] == true) {
  // Users assigned successfully
}
```

### Approve Exchange Request
```dart
final result = await supabase.rpc(
  'admin_manage_schedule_exchange_request',
  params: {
    'p_admin_id': adminId,
    'p_request_id': requestId,
    'p_action': 'approve',
    'p_admin_notes': notes,
    'p_rejection_reason': null,
  },
);

if (result['success'] == true) {
  // Show success message
  // Refresh schedule list
}
```

---

## ⚠️ Important Notes

### Error Handling
All RPCs return JSON with `success` field:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {...}
}
```

Or on error:
```json
{
  "success": false,
  "error": "Error message here"
}
```

### Date Formats
- **Date**: `'YYYY-MM-DD'` (e.g., `'2025-10-02'`)
- **Timestamp**: `'YYYY-MM-DD HH:MM:SS+TZ'` (e.g., `'2025-10-02 09:00:00+00'`)

### UUID Arrays
When passing UUID arrays in SQL:
```sql
ARRAY['uuid1', 'uuid2']::UUID[]
```

In Flutter (Supabase Dart):
```dart
params: {
  'p_user_ids': ['uuid1', 'uuid2'], // List<String>
}
```

---

## 📚 Full Documentation

For detailed explanations, table schemas, and best practices, see:
- [DATABASE_COMPLETE_REFERENCE.md](DATABASE_COMPLETE_REFERENCE.md)

---

**Last Updated**: October 2, 2025

