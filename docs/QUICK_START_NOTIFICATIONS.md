# 🚀 Quick Start: Notification System

## Send Your First Notification

### From Flutter App:

```dart
// 1. Get the service
final notificationService = Get.find<NotificationIntegrationService>();

// 2. Send a simple notification
await notificationService.sendCustomNotification(
  userIds: ['user-id-here'],
  title: '👋 Hello!',
  body: 'Hey {firstName}! Welcome to the notification system.',
);
```

---

## Common Use Cases

### 1. **Notify Employee About New Schedule**
```dart
await notificationService.notifyScheduleAssignment(
  assignedUserIds: employeeIds,
  scheduleId: schedule.id,
  scheduleTitle: 'Morning Shift',
  startTime: startDateTime,
  endTime: endDateTime,
  location: 'Main Office',
  department: 'Sales',
);
```

### 2. **Send Check-In Alert to Admins**
```dart
await notificationService.notifyAdminsCheckIn(
  adminIds: await notificationService.getAdminAndHRUserIds(),
  employeeId: currentUser.id,
  employeeName: currentUser.fullName,
  location: 'Office Building A',
  checkInTime: DateTime.now(),
);
```

### 3. **Broadcast to All Users**
```dart
// Get all user IDs
final response = await supabase
    .from('my_users')
    .select('id')
    .eq('is_active', true);
    
final userIds = response.map((u) => u['id'] as String).toList();

// Send notification
await notificationService.sendCustomNotification(
  userIds: userIds,
  title: '📢 Company Announcement',
  body: 'Hey {firstName}! We have an important update for you.',
);
```

---

## View Notifications in App

### Access Notification History:
```dart
final historyService = Get.find<NotificationHistoryService>();

// Get all notifications
final notifications = historyService.notifications;

// Get unread count
final unreadCount = historyService.unreadCount.value;

// Mark as read
await historyService.markAsRead(notificationId);

// Refresh
await historyService.refresh();
```

---

## Test Notification (cURL)

```bash
curl -X POST "https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["YOUR_USER_ID"],
    "type": "general",
    "title": "Test",
    "body": "Hey {firstName}! Testing notifications.",
    "priority": "high"
  }'
```

---

## Personalization Variables

Use these in your `title` or `body`:

- `{firstName}` - User's first name
- `{userName}` - User's full name
- `{email}` - User's email
- `{department}` - User's department
- `{scheduleTitle}` - Schedule name
- `{startTime}` - Schedule start time
- `{endTime}` - Schedule end time
- `{location}` - Schedule location

**Example:**
```dart
body: 'Hey {firstName}! Your shift at {location} starts at {startTime}.'
// Result: "Hey John! Your shift at Main Office starts at 09:00 AM."
```

---

## Check Database

```sql
-- See recent notifications
SELECT id, user_id, title, body, is_read, created_at 
FROM public.notifications 
ORDER BY created_at DESC 
LIMIT 10;

-- Get unread count for a user
SELECT public.get_unread_notification_count();

-- Mark all as read for a user
SELECT public.mark_all_notifications_as_read();
```

---

## Troubleshooting

### No notifications received?
1. Check device token is saved:
   ```sql
   SELECT id, email, user_device_token 
   FROM my_users 
   WHERE id = 'YOUR_USER_ID';
   ```

2. Check notification was saved:
   ```sql
   SELECT * FROM notifications 
   WHERE user_id = 'YOUR_USER_ID' 
   ORDER BY created_at DESC LIMIT 5;
   ```

3. Check Edge Function logs:
   ```bash
   supabase functions logs send-notifications
   ```

### App not showing notifications?
1. Ensure services are registered in `main.dart`
2. Check `NotificationHistoryService` is initialized
3. Verify user is authenticated

---

## 🎯 You're All Set!

The notification system is **fully operational** and ready to use. Start sending notifications from anywhere in your Flutter app!

**Need Help?** Check `NOTIFICATION_SYSTEM_COMPLETE.md` for detailed documentation.


