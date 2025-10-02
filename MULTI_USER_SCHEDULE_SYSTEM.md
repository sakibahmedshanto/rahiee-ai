# Multi-User Schedule Assignment System

## Overview

The Multi-User Schedule Assignment System allows administrators to assign multiple employees to a single schedule. Each assigned employee can independently mark their attendance for that schedule, making it perfect for:

- Team shifts
- Group projects
- Training sessions
- Meetings with multiple participants
- Collaborative work schedules

## Database Architecture

### New Table: `schedule_assignments`

This junction table creates a many-to-many relationship between schedules and users:

```sql
CREATE TABLE public.schedule_assignments (
    id UUID PRIMARY KEY,
    schedule_id UUID REFERENCES employee_schedules(id),
    user_id UUID REFERENCES my_users(id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    assigned_by_admin_id UUID REFERENCES my_users(id),
    status VARCHAR(50), -- active, removed, completed, reassigned
    notes TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(schedule_id, user_id)
);
```

### Updated Table: `employee_schedules`

Added columns to support multi-user functionality:

- `max_participants` INTEGER - Maximum number of users allowed (NULL = unlimited)
- `min_participants` INTEGER - Minimum number of users required
- `current_participants` INTEGER - Current count of active assigned users
- `is_multi_user` BOOLEAN - Flag indicating if schedule supports multiple users

## RPC Functions

### 1. `assign_users_to_schedule`

Assigns multiple users to a schedule with conflict detection.

**Parameters:**
- `p_schedule_id` UUID - The schedule to assign users to
- `p_user_ids` UUID[] - Array of user IDs to assign
- `p_admin_id` UUID - Admin making the assignment
- `p_notes` TEXT (optional) - Notes about the assignment

**Returns:**
```json
{
  "success": true,
  "assigned_count": 3,
  "failed_count": 0,
  "results": [
    {
      "user_id": "uuid",
      "success": true,
      "message": "User assigned successfully"
    }
  ]
}
```

**Features:**
- Verifies admin permissions
- Checks schedule is active
- Respects max_participants limit
- Handles conflicts gracefully
- Updates on conflict (re-activates removed assignments)

**Example Usage:**
```sql
SELECT assign_users_to_schedule(
  'schedule-uuid',
  ARRAY['user1-uuid', 'user2-uuid', 'user3-uuid']::UUID[],
  'admin-uuid',
  'Team assignment for Q4 project'
);
```

### 2. `remove_user_from_schedule`

Removes a user from a schedule assignment.

**Parameters:**
- `p_schedule_id` UUID - The schedule
- `p_user_id` UUID - User to remove
- `p_admin_id` UUID - Admin making the change
- `p_reason` TEXT (optional) - Reason for removal

**Returns:**
```json
{
  "success": true,
  "message": "User removed from schedule successfully"
}
```

**Example Usage:**
```sql
SELECT remove_user_from_schedule(
  'schedule-uuid',
  'user-uuid',
  'admin-uuid',
  'User requested schedule change'
);
```

### 3. `get_schedule_with_assignments`

Gets schedules with their assigned users.

**Parameters:**
- `p_schedule_id` UUID (optional) - Filter by specific schedule
- `p_date` DATE (optional) - Filter by date
- `p_department` VARCHAR (optional) - Filter by department

**Returns:**
```json
{
  "success": true,
  "schedules": [
    {
      "id": "schedule-uuid",
      "title": "Team Meeting",
      "start_date_time": "2025-10-05T09:00:00Z",
      "end_date_time": "2025-10-05T10:00:00Z",
      "current_participants": 3,
      "max_participants": 10,
      "assigned_users": [
        {
          "user_id": "uuid",
          "full_name": "John Doe",
          "email": "john@example.com",
          "department": "IT",
          "assignment_status": "active",
          "assigned_at": "2025-10-02T08:00:00Z"
        }
      ]
    }
  ],
  "total_count": 1
}
```

**Example Usage:**
```sql
-- Get all schedules for today with assignments
SELECT get_schedule_with_assignments(NULL, CURRENT_DATE, NULL);

-- Get specific schedule with assignments
SELECT get_schedule_with_assignments('schedule-uuid', NULL, NULL);

-- Get all IT department schedules for a date
SELECT get_schedule_with_assignments(NULL, '2025-10-05', 'IT');
```

### 4. `get_available_users_for_schedule`

Gets users available to be assigned to a schedule (no conflicts).

**Parameters:**
- `p_schedule_id` UUID - The schedule
- `p_department` VARCHAR (optional) - Filter by department

**Returns:**
```json
{
  "success": true,
  "available_users": [
    {
      "id": "uuid",
      "employee_id": "EMP001",
      "full_name": "Jane Smith",
      "email": "jane@example.com",
      "department": "IT",
      "position": "Developer"
    }
  ],
  "schedule_time": {
    "start": "2025-10-05T09:00:00Z",
    "end": "2025-10-05T10:00:00Z"
  }
}
```

**Filtering Logic:**
- Active employees only
- Employee role (not admins unless needed)
- Not already assigned to this schedule
- No conflicting schedules at the same time
- Optional department filter

**Example Usage:**
```sql
-- Get all available users for a schedule
SELECT get_available_users_for_schedule('schedule-uuid', NULL);

-- Get available users from IT department only
SELECT get_available_users_for_schedule('schedule-uuid', 'IT');
```

### 5. `get_user_schedules_multi`

Gets all schedules assigned to a user (with attendance info).

**Parameters:**
- `p_user_id` UUID - The user
- `p_date` DATE (default: CURRENT_DATE) - Filter by date
- `p_include_attendance` BOOLEAN (default: true) - Include attendance data

**Returns:**
```json
{
  "error": false,
  "schedules": [
    {
      "id": "uuid",
      "title": "Morning Shift",
      "start_date_time": "2025-10-05T09:00:00Z",
      "end_date_time": "2025-10-05T17:00:00Z",
      "is_multi_user": true,
      "current_participants": 5,
      "assignment_notes": "Team lead for this shift",
      "attendance_id": "attendance-uuid",
      "has_checked_in": true,
      "check_in_time": "2025-10-05T09:02:00Z",
      "attendance_status": "pending_checkout",
      "can_check_out": true
    }
  ],
  "total_schedules": 1
}
```

**Example Usage:**
```sql
-- Get user's schedules for today with attendance
SELECT get_user_schedules_multi('user-uuid', CURRENT_DATE, true);

-- Get user's schedules for a date without attendance
SELECT get_user_schedules_multi('user-uuid', '2025-10-05', false);
```

### 6. `get_schedules_with_attendance_status` (Updated)

**Backward Compatibility:** This existing RPC now internally calls `get_user_schedules_multi`, maintaining backward compatibility with existing Flutter code.

## Flutter Integration

### Service: `MultiUserScheduleService`

Located in `lib/services/multi_user_schedule_service.dart`

#### Assign Multiple Users

```dart
final result = await MultiUserScheduleService.assignUsersToSchedule(
  scheduleId: 'schedule-uuid',
  userIds: ['user1-uuid', 'user2-uuid', 'user3-uuid'],
  adminId: currentAdmin.id,
  notes: 'Team assignment for Q4 project',
);

if (result['success']) {
  print('Assigned ${result['assigned_count']} users');
  print('Failed ${result['failed_count']} users');
}
```

#### Remove User from Schedule

```dart
final result = await MultiUserScheduleService.removeUserFromSchedule(
  scheduleId: 'schedule-uuid',
  userId: 'user-uuid',
  adminId: currentAdmin.id,
  reason: 'User requested schedule change',
);
```

#### Get Schedule with Assignments

```dart
final result = await MultiUserScheduleService.getScheduleWithAssignments(
  scheduleId: 'schedule-uuid',
  date: DateTime.now(),
  department: 'IT',
);

if (result['success']) {
  final schedules = result['schedules'] as List;
  for (var schedule in schedules) {
    print('Schedule: ${schedule['title']}');
    print('Assigned users: ${schedule['assigned_users'].length}');
  }
}
```

#### Get Available Users

```dart
final result = await MultiUserScheduleService.getAvailableUsersForSchedule(
  scheduleId: 'schedule-uuid',
  department: 'IT',
);

if (result['success']) {
  final availableUsers = result['available_users'] as List;
  // Show these users in a multi-select UI
}
```

## Admin UI Implementation

### Creating/Editing Schedules with Multiple Users

1. **Toggle Multi-User Mode:**
   - Add a checkbox "Allow multiple users"
   - If enabled, show participant limits (min/max)

2. **User Selection:**
   - Use multi-select dropdown or checkbox list
   - Show only available users (no conflicts)
   - Display user info: name, department, position

3. **Current Assignments:**
   - Show list of assigned users
   - Option to remove individual users
   - Show assignment status and date

4. **Validation:**
   - Minimum participants requirement
   - Maximum participants limit
   - Schedule conflict detection

### Example UI Flow:

```dart
// 1. Create schedule
final scheduleId = await AdminScheduleService.createSchedule(...);

// 2. Get available users
final availableResult = await MultiUserScheduleService.getAvailableUsersForSchedule(
  scheduleId: scheduleId,
);

// 3. Show multi-select UI with available users
final selectedUserIds = await showUserSelectionDialog(
  availableUsers: availableResult['available_users'],
);

// 4. Assign selected users
final assignResult = await MultiUserScheduleService.assignUsersToSchedule(
  scheduleId: scheduleId,
  userIds: selectedUserIds,
  adminId: currentAdmin.id,
);
```

## Employee UI Implementation

### Viewing Schedules

Employees see **only their assigned schedules**. No changes needed to existing UI - the RPC functions handle this automatically.

```dart
// This already works - just uses new backend
final schedules = await scheduleService.getSchedulesForUser(
  userId: currentUser.id,
  startDate: DateTime.now(),
);
```

### Schedule Display

For multi-user schedules, show:
- 👥 Multi-user indicator icon
- "X of Y participants" badge
- Option to view other assigned users (if desired)

```dart
if (schedule.isMultiUser) {
  Text('👥 ${schedule.currentParticipants} of ${schedule.maxParticipants ?? "∞"} assigned');
}
```

### Attendance

Each user marks their **own attendance** independently:
- Check-in creates attendance record linked to user + schedule
- Check-out updates same attendance record
- Other users' attendance doesn't affect yours

## Migration

The migration automatically:
1. ✅ Creates `schedule_assignments` table
2. ✅ Migrates existing schedule assignments
3. ✅ Adds new columns to `employee_schedules`
4. ✅ Creates all RPC functions
5. ✅ Sets up RLS policies
6. ✅ Maintains backward compatibility

**No data loss** - all existing schedules are preserved and migrated to the new system.

## Benefits

1. **Flexibility:** One schedule can have multiple assigned employees
2. **Scalability:** Handle team shifts and group schedules efficiently
3. **Independence:** Each employee tracks their own attendance
4. **Backward Compatible:** Existing single-user schedules still work
5. **Conflict Detection:** Prevents double-booking automatically
6. **Admin Control:** Full visibility and management of assignments

## Testing

### Test Scenarios:

1. **Create multi-user schedule:**
   - Assign 3 users to one schedule
   - Verify all 3 see the schedule
   - Each user checks in/out independently

2. **Conflict detection:**
   - Create overlapping schedules
   - Verify conflicted users don't appear in available list

3. **Max participants:**
   - Set max to 5
   - Try to assign 6 users
   - Verify 6th user is rejected

4. **Remove user:**
   - Remove user from multi-user schedule
   - Verify they no longer see it
   - Verify participant count decreases

5. **Backward compatibility:**
   - Verify single-user schedules still work
   - Existing Flutter code should work unchanged

## Future Enhancements

- Waiting list for full schedules
- User self-assignment to open schedules
- Team/group-based assignments
- Schedule swapping between multi-user schedules
- Attendance summary per schedule (all users)
- Capacity planning and reports

