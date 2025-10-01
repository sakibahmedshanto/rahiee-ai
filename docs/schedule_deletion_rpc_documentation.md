# 🚀 Schedule Deletion RPC Functions Documentation

## 📋 Overview
This document provides comprehensive documentation for the scalable RPC-based schedule deletion system. All functions use `SECURITY DEFINER` for proper access control and return JSON responses for easy integration.

## 🔧 RPC Functions

### 1. `preview_schedule_deletion(p_hours_back INTEGER)`
**Purpose**: Preview what schedules will be deleted without actually deleting them.

**Parameters**:
- `p_hours_back` (INTEGER, default: 24) - Number of hours back to look for schedules

**Returns**: JSON object with preview data

**Example Usage**:
```sql
-- Preview schedules from last 24 hours
SELECT preview_schedule_deletion(24);

-- Preview schedules from last 48 hours
SELECT preview_schedule_deletion(48);
```

**Response Format**:
```json
{
  "success": true,
  "preview_data": {
    "hours_back": 24,
    "schedules_to_delete": 15,
    "attendance_records_affected": 8,
    "exchange_requests_affected": 3,
    "oldest_schedule": "2024-01-15T10:30:00Z",
    "newest_schedule": "2024-01-16T09:15:00Z",
    "deletion_timestamp": "2024-01-16T10:00:00Z"
  }
}
```

---

### 2. `get_schedules_for_deletion(p_hours_back INTEGER, p_limit INTEGER, p_offset INTEGER)`
**Purpose**: Get detailed list of schedules that will be deleted with pagination.

**Parameters**:
- `p_hours_back` (INTEGER, default: 24) - Number of hours back to look
- `p_limit` (INTEGER, default: 100) - Maximum number of records to return
- `p_offset` (INTEGER, default: 0) - Number of records to skip

**Returns**: JSON object with detailed schedule information

**Example Usage**:
```sql
-- Get first 50 schedules from last 24 hours
SELECT get_schedules_for_deletion(24, 50, 0);

-- Get next 50 schedules
SELECT get_schedules_for_deletion(24, 50, 50);
```

**Response Format**:
```json
{
  "success": true,
  "schedules": [
    {
      "id": "uuid-here",
      "title": "Morning Shift",
      "start_date_time": "2024-01-16T08:00:00Z",
      "end_date_time": "2024-01-16T16:00:00Z",
      "created_at": "2024-01-15T14:30:00Z",
      "status": "active",
      "is_active": true,
      "assigned_user_name": "John Doe",
      "assigned_user_id": "EMP001",
      "created_by_admin": "Admin User",
      "department": "Operations",
      "location": "Main Office"
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "has_more": true
  }
}
```

---

### 3. `safe_delete_schedules(p_hours_back INTEGER, p_create_backup BOOLEAN, p_executed_by TEXT)`
**Purpose**: Safely delete schedules with optional backup creation.

**Parameters**:
- `p_hours_back` (INTEGER, default: 24) - Number of hours back to delete
- `p_create_backup` (BOOLEAN, default: true) - Whether to create backup
- `p_executed_by` (TEXT, default: 'system') - Who executed the deletion

**Returns**: JSON object with deletion summary

**Example Usage**:
```sql
-- Delete schedules from last 24 hours with backup
SELECT safe_delete_schedules(24, true, 'admin_user');

-- Delete schedules from last 48 hours without backup
SELECT safe_delete_schedules(48, false, 'system_cleanup');
```

**Response Format**:
```json
{
  "success": true,
  "deletion_summary": {
    "schedules_deleted": 15,
    "attendance_records_deleted": 8,
    "exchange_requests_deleted": 3,
    "backup_created": true,
    "backup_records": 15,
    "hours_back": 24,
    "executed_by": "admin_user",
    "deletion_timestamp": "2024-01-16T10:00:00Z"
  }
}
```

---

### 4. `restore_schedules_from_backup(p_hours_back INTEGER, p_executed_by TEXT)`
**Purpose**: Restore schedules from backup table.

**Parameters**:
- `p_hours_back` (INTEGER, default: 24) - Number of hours back to restore
- `p_executed_by` (TEXT, default: 'system') - Who executed the restoration

**Returns**: JSON object with restoration summary

**Example Usage**:
```sql
-- Restore schedules from last 24 hours
SELECT restore_schedules_from_backup(24, 'admin_user');

-- Restore schedules from last 48 hours
SELECT restore_schedules_from_backup(48, 'system_restore');
```

**Response Format**:
```json
{
  "success": true,
  "restoration_summary": {
    "schedules_restored": 15,
    "hours_back": 24,
    "executed_by": "admin_user",
    "restoration_timestamp": "2024-01-16T10:30:00Z"
  }
}
```

---

### 5. `get_deletion_log(p_limit INTEGER, p_offset INTEGER)`
**Purpose**: Get deletion log history with pagination.

**Parameters**:
- `p_limit` (INTEGER, default: 50) - Maximum number of records to return
- `p_offset` (INTEGER, default: 0) - Number of records to skip

**Returns**: JSON object with deletion log

**Example Usage**:
```sql
-- Get last 20 deletion logs
SELECT get_deletion_log(20, 0);

-- Get next 20 deletion logs
SELECT get_deletion_log(20, 20);
```

**Response Format**:
```json
{
  "success": true,
  "logs": [
    {
      "id": "uuid-here",
      "deletion_timestamp": "2024-01-16T10:00:00Z",
      "schedules_deleted": 15,
      "attendance_records_deleted": 8,
      "exchange_requests_deleted": 3,
      "deletion_reason": "RPC_deletion_24_hours",
      "executed_by": "admin_user",
      "success": true,
      "error_message": null
    }
  ],
  "pagination": {
    "total_count": 25,
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

## 🛡️ Security Features

### Access Control
- All functions use `SECURITY DEFINER` for proper access control
- Functions can only be called by authorized users
- All operations are logged with user tracking

### Transaction Safety
- All deletion operations use transactions
- Automatic rollback on errors
- Comprehensive error handling and logging

### Backup System
- Automatic backup creation before deletion
- Backup table with full schedule data
- Restoration capability from backup

## 📊 Database Tables

### `schedule_deletion_log`
Tracks all deletion operations with:
- Timestamp and user information
- Counts of deleted records
- Success/failure status
- Error messages

### `employee_schedules_deletion_backup`
Stores backup copies of deleted schedules with:
- Full schedule data
- Deletion timestamp and reason
- User who executed deletion

## 🚀 Usage Examples

### Basic Workflow
```sql
-- 1. Preview what will be deleted
SELECT preview_schedule_deletion(24);

-- 2. Get detailed list
SELECT get_schedules_for_deletion(24, 100, 0);

-- 3. Execute deletion with backup
SELECT safe_delete_schedules(24, true, 'admin_user');

-- 4. Check deletion log
SELECT get_deletion_log(10, 0);
```

### Error Handling
```sql
-- All functions return success/error status
SELECT safe_delete_schedules(24, true, 'admin_user');

-- Check for errors in response
-- If success = false, check error field
```

### Restoration
```sql
-- Restore from backup if needed
SELECT restore_schedules_from_backup(24, 'admin_user');
```

## ⚠️ Important Notes

1. **Always preview before deletion** using `preview_schedule_deletion()`
2. **Use transactions** - all functions handle transactions automatically
3. **Check logs** after operations using `get_deletion_log()`
4. **Backup is recommended** - set `p_create_backup = true`
5. **Test in development** before production use

## 🔧 Integration with Flutter

### Service Layer Integration
```dart
// In your Flutter service
Future<Map<String, dynamic>> previewScheduleDeletion(int hoursBack) async {
  final response = await _supabase.rpc('preview_schedule_deletion', params: {
    'p_hours_back': hoursBack,
  });
  return response;
}

Future<Map<String, dynamic>> deleteSchedules(int hoursBack, bool createBackup, String executedBy) async {
  final response = await _supabase.rpc('safe_delete_schedules', params: {
    'p_hours_back': hoursBack,
    'p_create_backup': createBackup,
    'p_executed_by': executedBy,
  });
  return response;
}
```

### Error Handling
```dart
try {
  final result = await deleteSchedules(24, true, 'admin_user');
  if (result['success']) {
    // Handle success
    print('Deleted ${result['deletion_summary']['schedules_deleted']} schedules');
  } else {
    // Handle error
    print('Error: ${result['error']}');
  }
} catch (e) {
  print('Exception: $e');
}
```

This RPC-based approach provides better scalability, security, and maintainability compared to direct SQL queries!
