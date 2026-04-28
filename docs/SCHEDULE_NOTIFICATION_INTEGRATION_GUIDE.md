# Schedule Notification Integration Guide

## How to Integrate Notifications with Schedule Creation

When you create a schedule and assign users, add this notification call:

### In your schedule creation screen/controller:

```dart
import '../services/notification_integration_service.dart';

class YourScheduleCreationController extends GetxController {
  final NotificationIntegrationService _notificationService = Get.find<NotificationIntegrationService>();
  
  // After successfully creating schedule and assigning users:
  Future<void> createScheduleAndNotify() async {
    try {
      // 1. Create the schedule
      final scheduleResult = await AdminScheduleService.createSchedule(
        adminId: adminId,
        title: titleController.text,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        department: selectedDepartment,
        location: locationController.text,
        // ... other parameters
      );
      
      if (scheduleResult['success']) {
        final scheduleId = scheduleResult['schedule_id'];
        
        // 2. Assign users to schedule (your existing logic)
        final assignedUserIds = [/* list of user IDs */];
        
        // 3. Send notifications to assigned users
        await _notificationService.notifyScheduleAssignment(
          assignedUserIds: assignedUserIds,
          scheduleId: scheduleId,
          scheduleTitle: titleController.text,
          startTime: startDateTime,
          endTime: endDateTime,
          location: locationController.text,
          department: selectedDepartment,
        );
        
        Get.snackbar('Success', 'Schedule created and notifications sent!');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
```

### Example Usage in Different Scenarios:

#### 1. When Creating a Schedule:
```dart
await _notificationService.notifyScheduleAssignment(
  assignedUserIds: ['user1', 'user2', 'user3'],
  scheduleId: 'SCH-001',
  scheduleTitle: 'Morning Shift',
  startTime: DateTime(2024, 1, 15, 9, 0),
  endTime: DateTime(2024, 1, 15, 17, 0),
  location: 'Main Office',
  department: 'Engineering',
);
```

#### 2. When Updating a Schedule:
```dart
await _notificationService.notifyScheduleUpdate(
  assignedUserIds: assignedUserIds,
  scheduleId: scheduleId,
  scheduleTitle: 'Morning Shift',
  changes: 'Time changed from 9:00 AM to 10:00 AM',
);
```

#### 3. When Cancelling a Schedule:
```dart
await _notificationService.notifyScheduleCancellation(
  assignedUserIds: assignedUserIds,
  scheduleId: scheduleId,
  scheduleTitle: 'Morning Shift',
  reason: 'Facility maintenance',
);
```

## Integration Points

### File: `lib/screens/admin/schedule_creation_screen.dart` (or similar)

Add this after successful schedule creation:

```dart
// After schedule is created successfully
if (scheduleCreated) {
  // Send notifications
  final notificationService = Get.find<NotificationIntegrationService>();
  await notificationService.notifyScheduleAssignment(
    assignedUserIds: assignedUsers.map((u) => u.id).toList(),
    scheduleId: newScheduleId,
    scheduleTitle: scheduleTitle,
    startTime: startTime,
    endTime: endTime,
    location: location,
    department: department,
  );
}
```

## Important Notes

1. **Initialize Service**: Make sure to initialize the service in `main.dart`:
   ```dart
   Get.put(NotificationIntegrationService());
   ```

2. **Error Handling**: Notifications won't fail your schedule creation. They run in the background.

3. **Batch Processing**: The service handles multiple users efficiently.

4. **Personalization**: Each user gets a personalized notification with their name.

## Check-In/Checkout Integration

✅ **Already Integrated!**  
The `CameraCheckInController` now automatically sends notifications to admins when:
- An employee checks in
- An employee checks out
- Including work duration for checkout

No additional code needed for check-in/checkout notifications!


