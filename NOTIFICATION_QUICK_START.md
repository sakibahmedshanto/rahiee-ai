# 🚀 Push Notifications - Quick Start Guide

## ✨ Send Your First Notification

### From Flutter App:

```dart
// Get the notification service
final notificationService = Get.find<NotificationService>();

// Send to specific users
final result = await notificationService.sendScheduleAssignmentNotifications(
  userIds: ['user-id-1', 'user-id-2'],
  scheduleId: 'schedule-123',
  startTime: '2024-01-15T09:00:00Z',
  endTime: '2024-01-15T17:00:00Z',
  location: 'Main Office',
);

// Check results
print('✅ Sent: ${result.sentCount}');
print('❌ Failed: ${result.failedCount}');
```

### Integration with Schedule Creation:

```dart
// After creating a schedule in your admin panel
await ScheduleNotificationIntegration.notifyScheduleAssignment(
  scheduleId: newScheduleId,
  assignedUserIds: assignedUserIds,
  scheduleTitle: 'Team Meeting',
  startTime: scheduleStartTime,
  endTime: scheduleEndTime,
  location: 'Conference Room A',
);
```

## 📋 Available Methods

### 1. Schedule Notifications
```dart
// Assignment
sendScheduleAssignmentNotifications()

// Update
sendScheduleUpdateNotifications()

// Cancellation
sendScheduleCancellationNotifications()
```

### 2. General Notifications
```dart
// To specific users
sendGeneralNotifications(userIds: [...])

// To department
getUserIdsByDepartment('Engineering')

// To role
getUserIdsByRole('employee')

// To all active users
getAllActiveUserIds()
```

### 3. Custom Notifications
```dart
sendCustomNotifications(
  userIds: userIds,
  title: 'Custom Title',
  body: 'Custom message with {firstName} and {department}',
  data: {'customField': 'value'},
  imageUrl: 'https://example.com/image.jpg',
)
```

## 🎯 Personalization Placeholders

Use these in your title and body:
- `{firstName}` - User's first name
- `{userName}` - User's full name
- `{email}` - User's email
- `{department}` - User's department
- `{scheduleId}` - Schedule ID
- `{startTime}` - Schedule start time
- `{endTime}` - Schedule end time
- `{location}` - Schedule location

Example:
```dart
body: 'Hey {firstName}! You have been assigned to {location} at {startTime}'
// Becomes: "Hey Shanto! You have been assigned to Main Office at 09:00 AM"
```

## ⚡ Quick Examples

### Notify Department
```dart
await ScheduleNotificationIntegration.notifyDepartment(
  department: 'Engineering',
  title: 'Department Update',
  body: 'Hey {firstName}! Important update for {department} team.',
);
```

### Notify All Users
```dart
await ScheduleNotificationIntegration.notifyAllUsers(
  title: 'System Maintenance',
  body: 'Hey {firstName}! System will be down tonight at 11 PM.',
);
```

### Attendance Reminder
```dart
await ScheduleNotificationIntegration.notifyAttendanceReminder(
  userIds: userIds,
  customMessage: 'Hey {firstName}! Don't forget to mark attendance.',
);
```

## 🔧 Edge Function Details

**URL**: `https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications`

**Method**: POST

**Headers**:
- `Authorization: Bearer YOUR_ANON_KEY`
- `Content-Type: application/json`

**Body**:
```json
{
  "userIds": ["user-id-1", "user-id-2"],
  "type": "schedule_assignment",
  "title": "Notification Title",
  "body": "Notification body with {firstName}",
  "priority": "high",
  "data": {"key": "value"}
}
```

## 📊 Response Format

```json
{
  "success": true,
  "sentCount": 2,
  "failedCount": 0,
  "errors": [],
  "processedUsers": [
    {"userId": "user-1", "success": true},
    {"userId": "user-2", "success": true}
  ]
}
```

## 🎉 That's It!

Your notification system is ready to use. Just call the methods and the system handles:
- ✅ Fetching user data and device tokens
- ✅ Personalizing messages for each user
- ✅ Sending notifications asynchronously
- ✅ Error handling and reporting

**For detailed documentation, see**: `NOTIFICATION_SYSTEM_COMPLETE_GUIDE.md`
