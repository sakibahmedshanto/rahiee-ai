# Multi-User Schedule System - Quick Start Guide

## ✅ System is Ready!

The multi-user schedule system has been successfully implemented and is **ready to use**. All existing schedules have been automatically migrated, and the system is **backward compatible**.

## 🚀 What's New?

### For Admins
- **Assign multiple employees to a single schedule**
- **View all assigned users per schedule**
- **Remove users from schedules**
- **Set participant limits (min/max)**
- **Automatic conflict detection**

### For Employees
- **See only their assigned schedules (no change from user perspective)**
- **Mark attendance independently**
- **Multi-user indicator on schedule cards**

## 📋 How to Use (Admin Side)

### Step 1: Assign Multiple Users to a Schedule

```dart
// Import the service
import 'package:rahiee_ai/services/multi_user_schedule_service.dart';
import 'package:rahiee_ai/controllers/admin_controllers/admin_schedule_controller.dart';

// Using the controller
final controller = Get.find<AdminScheduleController>();

// Method 1: Using controller method (recommended)
await controller.assignMultipleUsersToSchedule(
  scheduleId: 'schedule-uuid',
  userIds: ['user1-uuid', 'user2-uuid', 'user3-uuid'],
  notes: 'Team assignment for project X',
);

// Method 2: Using service directly
final result = await MultiUserScheduleService.assignUsersToSchedule(
  scheduleId: 'schedule-uuid',
  userIds: ['user1-uuid', 'user2-uuid'],
  adminId: currentAdmin.id,
  notes: 'Assignment notes',
);
```

### Step 2: View Schedule with All Assigned Users

```dart
// Get schedule with assignments
final schedule = await controller.getScheduleWithAssignments('schedule-uuid');

if (schedule != null) {
  final assignedUsers = schedule['assigned_users'] as List;
  print('Total assigned: ${assignedUsers.length}');
  
  for (var user in assignedUsers) {
    print('${user['full_name']} (${user['department']})');
    print('Status: ${user['assignment_status']}');
    print('Assigned at: ${user['assigned_at']}');
  }
}
```

### Step 3: Get Available Users (No Conflicts)

```dart
// Get users who can be assigned to this schedule
final availableUsers = await controller.getAvailableUsersForSchedule(
  scheduleId: 'schedule-uuid',
  department: 'IT', // Optional filter
);

// Show in multi-select UI
for (var user in availableUsers) {
  print('${user['full_name']} - ${user['position']}');
}
```

### Step 4: Remove User from Schedule

```dart
await controller.removeUserFromSchedule(
  scheduleId: 'schedule-uuid',
  userId: 'user-uuid',
  reason: 'User requested schedule change',
);
```

## 🎨 UI Implementation Example

### Admin Schedule Form

```dart
// Add multi-user toggle
Obx(() => SwitchListTile(
  title: Text('Allow Multiple Users'),
  subtitle: Text('Enable multi-user assignment for this schedule'),
  value: controller.isMultiUserMode.value,
  onChanged: (value) => controller.toggleMultiUserMode(value),
));

// Show participant limits if multi-user
if (controller.isMultiUserMode.value) {
  Row(
    children: [
      Expanded(
        child: TextField(
          decoration: InputDecoration(labelText: 'Min Participants'),
          keyboardType: TextInputType.number,
          onChanged: (value) => minParticipants = int.tryParse(value),
        ),
      ),
      SizedBox(width: 16),
      Expanded(
        child: TextField(
          decoration: InputDecoration(labelText: 'Max Participants'),
          keyboardType: TextInputType.number,
          onChanged: (value) => maxParticipants = int.tryParse(value),
        ),
      ),
    ],
  ),
}

// User selection (multi-select)
ElevatedButton.icon(
  icon: Icon(Icons.people),
  label: Text('Select Users (${controller.selectedUsers.length})'),
  onPressed: () => _showUserSelectionDialog(),
);
```

### User Selection Dialog

```dart
Future<void> _showUserSelectionDialog() async {
  // Get available users
  final availableUsers = await controller.getAvailableUsersForSchedule(
    scheduleId: schedule.id,
  );

  Get.dialog(
    AlertDialog(
      title: Text('Select Users'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableUsers.length,
          itemBuilder: (context, index) {
            final user = availableUsers[index];
            final userId = user['id'] as String;
            
            return Obx(() => CheckboxListTile(
              title: Text(user['full_name']),
              subtitle: Text('${user['department']} - ${user['position']}'),
              value: controller.isUserSelected(userId),
              onChanged: (selected) {
                controller.toggleUserSelection(userId);
              },
            ));
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            // Assign selected users
            controller.assignMultipleUsersToSchedule(
              scheduleId: schedule.id,
              userIds: controller.selectedUsers,
            );
          },
          child: Text('Assign (${controller.selectedUsers.length})'),
        ),
      ],
    ),
  );
}
```

### View Assigned Users

```dart
// In schedule details screen
FutureBuilder(
  future: controller.getScheduleAssignments(schedule.id),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final assignments = snapshot.data as List<Map<String, dynamic>>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Users (${assignments.length})',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...assignments.map((assignment) {
          final user = assignment['user'];
          return ListTile(
            leading: CircleAvatar(
              child: Text(user['full_name'][0]),
            ),
            title: Text(user['full_name']),
            subtitle: Text('${user['department']} - ${user['position']}'),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                // Remove user
                controller.removeUserFromSchedule(
                  scheduleId: schedule.id,
                  userId: user['id'],
                  reason: 'Admin removed',
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  },
)
```

## 👤 Employee Side

### Display Multi-User Schedule

```dart
// In schedule card widget
if (schedule.isMultiUser ?? false) {
  Row(
    children: [
      Icon(Icons.people, size: 16, color: Colors.blue),
      SizedBox(width: 4),
      Text(
        '${schedule.currentParticipants} of ${schedule.maxParticipants ?? "∞"} assigned',
        style: TextStyle(fontSize: 12, color: Colors.blue),
      ),
    ],
  );
}
```

### Attendance (No Changes Needed!)

The existing attendance system works automatically! Each user marks their own attendance:

```dart
// Existing check-in logic works as is
await controller.checkInForSchedule(schedule);

// Existing check-out logic works as is
await controller.checkOutFromSchedule(schedule);
```

## 🧪 Testing

Run the test script to verify everything is working:

```bash
# Execute the test SQL
# In Supabase dashboard > SQL Editor:
# Copy and paste contents of sql/test_multi_user_schedule_system.sql
```

Or use the Supabase MCP:

```dart
// Test assigning users
final testResult = await MultiUserScheduleService.assignUsersToSchedule(
  scheduleId: 'test-schedule-id',
  userIds: ['user1-id', 'user2-id'],
  adminId: 'admin-id',
  notes: 'Test assignment',
);
print('Test result: ${testResult['success']}');
print('Assigned: ${testResult['assigned_count']} users');
```

## 📊 Database Functions Reference

| Function | Purpose |
|----------|---------|
| `assign_users_to_schedule()` | Assign multiple users to a schedule |
| `remove_user_from_schedule()` | Remove a user from a schedule |
| `get_schedule_with_assignments()` | Get schedule with all assigned users |
| `get_available_users_for_schedule()` | Get users available for assignment |
| `get_user_schedules_multi()` | Get user's schedules (with multi-user support) |
| `get_schedules_with_attendance_status()` | Backward compatible employee schedule fetch |

## 🔄 Migration Notes

- ✅ All existing schedules automatically migrated
- ✅ Existing single-user schedules still work
- ✅ No code changes needed in employee app
- ✅ Attendance system works unchanged
- ✅ Schedule exchange system compatible

## ⚠️ Important Notes

1. **Conflict Detection**: The system automatically prevents assigning users who have conflicting schedules at the same time.

2. **Participant Limits**: Set `max_participants` to limit the number of users. Leave as NULL for unlimited.

3. **Backward Compatibility**: Existing code that uses single-user schedules continues to work without modification.

4. **Attendance Independence**: Each user's attendance is tracked separately, even on multi-user schedules.

5. **RLS Policies**: Users can only see their own assignments. Admins can see and manage all assignments.

## 📚 Full Documentation

For complete documentation, see: `MULTI_USER_SCHEDULE_SYSTEM.md`

## 🎉 You're Ready!

The system is fully functional and ready for production use. Start by:

1. ✅ Testing in the admin panel
2. ✅ Creating a multi-user schedule
3. ✅ Assigning 2-3 employees
4. ✅ Verifying each employee sees the schedule
5. ✅ Having each employee mark attendance independently

**Happy scheduling! 🚀**

