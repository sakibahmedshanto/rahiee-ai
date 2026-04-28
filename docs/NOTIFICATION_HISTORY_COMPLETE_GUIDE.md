# 📱 Notification History System - Complete Guide

## ✅ Implementation Complete!

Your notification system now includes **complete notification history** with industry best practices!

## 🎯 What's Been Implemented

### 1. **Database Table** (`notifications`)
Complete notification storage with all necessary columns:

#### Core Fields:
- `id` - Unique identifier
- `user_id` - User reference (FK to my_users)
- `title` - Notification title
- `body` - Notification content
- `image_url` - Optional image

#### Metadata:
- `type` - Notification type (schedule_assignment, general, etc.)
- `category` - Custom categorization
- `priority` - high, normal, low

#### Status Tracking:
- `status` - sent, delivered, read, failed
- `is_read` - Boolean flag
- `read_at` - Timestamp when read
- `sent_at` - When notification was sent
- `delivered_at` - Delivery confirmation
- `failed_reason` - Error details if failed

#### Action Data:
- `action_type` - Type of action (view_schedule, open_app, etc.)
- `action_data` - JSON data for the action

#### Grouping & Organization:
- `batch_id` - Groups notifications sent together
- `group_key` - Custom grouping
- `schedule_id` - Reference to schedule (if applicable)
- `schedule_data` - Schedule details as JSON

#### Lifecycle:
- `expires_at` - When notification expires
- `deleted_at` - Soft delete timestamp
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp

### 2. **Database Functions (RPC)**

#### `mark_notification_as_read(notification_id UUID)`
Mark a single notification as read.

```sql
SELECT mark_notification_as_read('notification-id-here');
```

#### `mark_all_notifications_as_read()`
Mark all user's notifications as read.

```sql
SELECT mark_all_notifications_as_read();
```

#### `get_unread_notification_count()`
Get count of unread notifications.

```sql
SELECT get_unread_notification_count();
```

### 3. **Edge Function Integration**
The `send-notifications` function now automatically:
- ✅ Sends push notification via FCM
- ✅ Saves notification to database
- ✅ Returns notification ID
- ✅ Groups notifications with batch ID
- ✅ Stores personalized content
- ✅ Includes action data and schedule info

### 4. **Flutter Services**

#### **NotificationModel** (`lib/models/notification_model.dart`)
Complete data model with:
- All database fields
- Helper methods (`isExpired`, `isActive`, `timeAgo`)
- JSON serialization
- Copy constructor

#### **NotificationHistoryService** (`lib/services/notification_history_service.dart`)
Comprehensive service with:
- Fetch notifications with pagination
- Realtime updates
- Mark as read (single/all)
- Delete notifications
- Filter by type/schedule
- Unread count tracking
- Statistics

### 5. **Row Level Security (RLS)**
✅ Users can only view their own notifications  
✅ Users can only update their own notifications  
✅ Service role can manage all notifications  

## 🚀 Usage Examples

### Send Notification (Auto-saves to DB)

```dart
final result = await NotificationService.to.sendScheduleAssignmentNotifications(
  userIds: ['user1', 'user2'],
  scheduleId: 'SCH-001',
  startTime: '09:00 AM',
  location: 'Main Office',
  actionType: 'view_schedule',  // Action to perform
  expiresInDays: 30,            // Notification expires in 30 days
);

print('Batch ID: ${result.batchId}');
print('Notification IDs: ${result.processedUsers.map((u) => u.notificationId)}');
```

### Fetch User's Notifications

```dart
// Initialize service (in main.dart or init)
Get.put(NotificationHistoryService());

// Fetch notifications
final notifications = await NotificationHistoryService.to.fetchNotifications();

// Get unread count
final unreadCount = await NotificationHistoryService.to.fetchUnreadCount();

// Access reactive variables
Obx(() => Text('Unread: ${NotificationHistoryService.to.unreadCount}'));
```

### Mark Notification as Read

```dart
await NotificationHistoryService.to.markAsRead(notificationId);
```

### Mark All as Read

```dart
final count = await NotificationHistoryService.to.markAllAsRead();
print('Marked $count notifications as read');
```

### Delete Notification

```dart
await NotificationHistoryService.to.deleteNotification(notificationId);
```

### Get Notifications by Type

```dart
final scheduleNotifications = await NotificationHistoryService.to
  .getNotificationsByType('schedule_assignment');
```

### Get Notifications for a Schedule

```dart
final scheduleNots = await NotificationHistoryService.to
  .getNotificationsBySchedule('SCH-001');
```

### Pagination (Load More)

```dart
// Initial load
await NotificationHistoryService.to.fetchNotifications();

// Load more
await NotificationHistoryService.to.loadMore();

// Refresh
await NotificationHistoryService.to.refresh();
```

### Realtime Updates

```dart
// Automatically subscribes on init
// Notifications list updates automatically when new notifications arrive
Obx(() => ListView.builder(
  itemCount: NotificationHistoryService.to.notifications.length,
  itemBuilder: (context, index) {
    final notification = NotificationHistoryService.to.notifications[index];
    return ListTile(
      title: Text(notification.title),
      subtitle: Text(notification.body),
      trailing: notification.isRead 
        ? null 
        : Icon(Icons.circle, color: Colors.blue, size: 12),
    );
  },
));
```

## 📱 Example Notification Panel UI

```dart
class NotificationsScreen extends StatelessWidget {
  final notificationService = Get.find<NotificationHistoryService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          'Notifications (${notificationService.unreadCount.value})'
        )),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: () => notificationService.markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationService.refresh(),
        child: Obx(() {
          if (notificationService.isLoading.value && 
              notificationService.notifications.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (notificationService.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notificationService.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationService.notifications[index];
              
              return Dismissible(
                key: Key(notification.id),
                onDismissed: (_) => 
                  notificationService.deleteNotification(notification.id),
                background: Container(color: Colors.red),
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead 
                        ? Colors.grey 
                        : Colors.blue,
                      child: Icon(
                        _getIconForType(notification.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead 
                          ? FontWeight.normal 
                          : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body),
                        SizedBox(height: 4),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: notification.isRead 
                      ? null 
                      : Icon(Icons.circle, color: Colors.blue, size: 12),
                    onTap: () {
                      if (!notification.isRead) {
                        notificationService.markAsRead(notification.id);
                      }
                      _handleNotificationTap(notification);
                    },
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'schedule_assignment':
        return Icons.calendar_today;
      case 'schedule_update':
        return Icons.update;
      case 'attendance_reminder':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle notification action based on action_type
    switch (notification.actionType) {
      case 'view_schedule':
        if (notification.scheduleId != null) {
          Get.toNamed('/schedule/${notification.scheduleId}');
        }
        break;
      case 'open_app':
        // Just mark as read, already handled
        break;
      default:
        // Custom handling
        break;
    }
  }
}
```

## 🎯 Test Example

```bash
# Send notification with database storage
curl -X POST "https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["user-id-1", "user-id-2"],
    "type": "schedule_assignment",
    "title": "New Schedule",
    "body": "Hey {firstName}! Check your new schedule.",
    "scheduleData": {
      "scheduleId": "SCH-001",
      "startTime": "09:00 AM",
      "location": "Main Office"
    },
    "actionType": "view_schedule",
    "expiresInDays": 30,
    "priority": "high"
  }'
```

**Response:**
```json
{
  "success": true,
  "sentCount": 2,
  "failedCount": 0,
  "errors": [],
  "batchId": "abc-123-def-456",
  "processedUsers": [
    {
      "userId": "user-id-1",
      "userName": "John Doe",
      "success": true,
      "notificationId": "notif-id-1"
    },
    {
      "userId": "user-id-2",
      "userName": "Jane Smith",
      "success": true,
      "notificationId": "notif-id-2"
    }
  ]
}
```

## 📊 Database Query Examples

### Get all unread notifications for a user
```sql
SELECT * FROM notifications
WHERE user_id = 'user-id'
  AND is_read = FALSE
  AND deleted_at IS NULL
ORDER BY created_at DESC;
```

### Get notifications by batch
```sql
SELECT * FROM notifications
WHERE batch_id = 'batch-id'
ORDER BY created_at DESC;
```

### Get notification statistics
```sql
SELECT 
  type,
  COUNT(*) as total,
  SUM(CASE WHEN is_read THEN 1 ELSE 0 END) as read_count,
  SUM(CASE WHEN is_read THEN 0 ELSE 1 END) as unread_count
FROM notifications
WHERE user_id = 'user-id'
  AND deleted_at IS NULL
GROUP BY type;
```

## 🎨 Features Summary

### ✅ What's Working:
1. **Push Notifications** - Send via FCM
2. **Database Storage** - Auto-save all notifications
3. **Notification History** - View past notifications
4. **Unread Tracking** - Badge counts
5. **Mark as Read** - Single or bulk
6. **Soft Delete** - Remove without losing data
7. **Pagination** - Load more efficiently
8. **Realtime Updates** - Live notification updates
9. **Filtering** - By type, schedule, etc.
10. **Action Handling** - Deep linking support
11. **Expiration** - Auto-expire old notifications
12. **Batch Processing** - Group related notifications
13. **Personalization** - Custom content per user
14. **Statistics** - Analytics and insights

### 🔒 Security:
- ✅ Row Level Security (RLS) enabled
- ✅ Users can only see their own notifications
- ✅ Secure RPC functions
- ✅ Service role for admin operations

### 📈 Performance:
- ✅ Indexed for fast queries
- ✅ Pagination for large datasets
- ✅ Efficient realtime subscriptions
- ✅ Batch processing for multiple users

## 🎊 That's It!

You now have a **complete, production-ready notification system** with:
- Push notifications via FCM
- Complete notification history
- Industry best practices
- Beautiful UI components
- Real-time updates
- Full CRUD operations

**Everything is ready to use!** 🚀


