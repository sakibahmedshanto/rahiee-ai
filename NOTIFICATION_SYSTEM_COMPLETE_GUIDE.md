# Push Notification System - Complete Implementation

## Overview
This document describes the complete push notification system implemented for the Rahiee AI app using Firebase Cloud Messaging (FCM) and Supabase Edge Functions. The system provides batch processing, personalization, and flexible notification templates.

## Architecture

### Components
1. **FCM Service** (`lib/services/fcm_service.dart`) - Handles device token management
2. **Edge Function** (`supabase/functions/send-notifications/index.ts`) - Processes notifications server-side
3. **Notification Service** (`lib/services/notification_service.dart`) - Flutter client for calling Edge Function
4. **Integration Examples** (`lib/services/schedule_notification_integration.dart`) - Usage examples

### Flow
```
Flutter App → NotificationService → Edge Function → Firebase Admin SDK → FCM → User Devices
```

## Features

### ✅ **Batch Processing**
- Send notifications to multiple users simultaneously
- Efficient database lookups for device tokens
- Asynchronous processing for better performance

### ✅ **Personalization**
- Dynamic content replacement with user data
- Placeholders: `{firstName}`, `{userName}`, `{email}`, `{department}`
- Schedule-specific placeholders: `{startTime}`, `{endTime}`, `{location}`

### ✅ **Flexible Templates**
- Pre-built templates for common scenarios
- Custom template overrides
- Future-proof design with optional parameters

### ✅ **Multiple Notification Types**
- Schedule Assignment
- Schedule Update
- Schedule Cancellation
- Attendance Reminder
- General Notifications
- Custom Notifications

## Setup Instructions

### 1. Environment Variables
Set these environment variables in your Supabase project:

```bash
FIREBASE_PROJECT_ID=YOUR_FIREBASE_PROJECT_ID
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email
```

### 2. Firebase Service Account
1. Go to Firebase Console → Project Settings → Service Accounts
2. Generate a new private key
3. Use the values from the JSON file for environment variables

### 3. Database Setup
The `my_users` table should have the `user_device_token` field:
```sql
ALTER TABLE my_users ADD COLUMN user_device_token TEXT;
```

## Usage Examples

### Basic Usage
```dart
// Initialize the service
final notificationService = Get.find<NotificationService>();

// Send schedule assignment notifications
final result = await notificationService.sendScheduleAssignmentNotifications(
  userIds: ['user1', 'user2', 'user3'],
  scheduleId: 'schedule-123',
  startTime: '2024-01-15T09:00:00Z',
  endTime: '2024-01-15T17:00:00Z',
  location: 'Main Office',
  department: 'Engineering',
);

print('Sent: ${result.sentCount}, Failed: ${result.failedCount}');
```

### Advanced Usage with Custom Templates
```dart
final result = await notificationService.sendCustomNotifications(
  userIds: ['user1', 'user2'],
  title: 'Custom Notification',
  body: 'Hey {firstName}! This is a custom message for {department} department.',
  customTemplate: CustomNotificationTemplate(
    titleTemplate: '🎉 Special Announcement for {firstName}',
    bodyTemplate: 'Dear {firstName} from {department}, we have exciting news!',
  ),
  scheduleData: ScheduleNotificationData(
    scheduleId: 'schedule-456',
    startTime: '2024-01-15T10:00:00Z',
    location: 'Conference Room A',
  ),
  data: {
    'action': 'view_details',
    'customId': 'custom-789',
  },
  imageUrl: 'https://example.com/image.jpg',
  priority: 'high',
);
```

### Integration with Schedule Creation
```dart
// After creating a schedule, notify assigned users
await ScheduleNotificationIntegration.notifyScheduleAssignment(
  scheduleId: newScheduleId,
  assignedUserIds: ['user1', 'user2', 'user3'],
  scheduleTitle: 'Team Meeting',
  startTime: DateTime.now().add(Duration(hours: 2)),
  endTime: DateTime.now().add(Duration(hours: 3)),
  location: 'Conference Room A',
  department: 'Engineering',
);
```

## Edge Function API

### Endpoint
```
POST /functions/v1/send-notifications
```

### Request Body
```typescript
interface NotificationRequest {
  userIds: string[];                    // Required: Array of user IDs
  type: 'schedule_assignment' | 'schedule_update' | 'schedule_cancellation' | 'attendance_reminder' | 'general' | 'custom';
  title: string;                        // Required: Notification title
  body: string;                         // Required: Notification body
  data?: Record<string, any>;           // Optional: Custom data payload
  imageUrl?: string;                    // Optional: Image URL
  scheduleData?: {                      // Optional: Schedule-specific data
    scheduleId?: string;
    startTime?: string;
    endTime?: string;
    location?: string;
    department?: string;
  };
  priority?: 'high' | 'normal' | 'low'; // Optional: Notification priority
  customTemplate?: {                    // Optional: Custom template overrides
    titleTemplate?: string;
    bodyTemplate?: string;
  };
}
```

### Response
```typescript
interface NotificationResult {
  success: boolean;
  sentCount: number;
  failedCount: number;
  errors: string[];
  processedUsers: Array<{
    userId: string;
    success: boolean;
    error?: string;
  }>;
}
```

## Testing

### Run Test Script
```bash
./test_notification_function.sh
```

### Manual Testing
```bash
curl -X POST "YOUR_SUPABASE_URL/functions/v1/send-notifications" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["user-id-1", "user-id-2"],
    "type": "schedule_assignment",
    "title": "New Schedule",
    "body": "Hey {firstName}! You have a new schedule assignment.",
    "scheduleData": {
      "scheduleId": "schedule-123",
      "startTime": "2024-01-15T09:00:00Z",
      "location": "Main Office"
    }
  }'
```

## Personalization Placeholders

### User Data Placeholders
- `{firstName}` - User's first name
- `{userName}` - User's full name
- `{email}` - User's email address
- `{department}` - User's department

### Schedule Data Placeholders
- `{scheduleId}` - Schedule ID
- `{startTime}` - Schedule start time
- `{endTime}` - Schedule end time
- `{location}` - Schedule location
- `{scheduleDepartment}` - Schedule department

## Notification Templates

### Schedule Assignment
```
Title: "New Schedule Assignment"
Body: "Hey {firstName}! You have been assigned to a new schedule. Check your app for details."
```

### Schedule Update
```
Title: "Schedule Updated"
Body: "Hey {firstName}! Your schedule has been updated. Please check the new details."
```

### Schedule Cancellation
```
Title: "Schedule Cancelled"
Body: "Hey {firstName}! Your schedule has been cancelled. Please check for alternative assignments."
```

### Attendance Reminder
```
Title: "Attendance Reminder"
Body: "Hey {firstName}! Don't forget to mark your attendance for today."
```

## Error Handling

### Common Errors
1. **No device tokens found** - Users haven't granted notification permissions
2. **Invalid user IDs** - User IDs don't exist in database
3. **Firebase configuration** - Missing or incorrect Firebase credentials
4. **Network issues** - Connection problems with FCM

### Error Response Example
```json
{
  "success": false,
  "sentCount": 0,
  "failedCount": 3,
  "errors": [
    "User John Doe: Invalid device token",
    "User Jane Smith: Device token expired"
  ],
  "processedUsers": [
    {"userId": "user1", "success": false, "error": "Invalid device token"},
    {"userId": "user2", "success": false, "error": "Device token expired"},
    {"userId": "user3", "success": false, "error": "Network timeout"}
  ]
}
```

## Performance Considerations

### Batch Processing
- Process up to 1000 users per request
- Asynchronous processing prevents timeouts
- Database queries are optimized with batch lookups

### Rate Limiting
- FCM has rate limits (default: 1000 messages/second)
- Edge Function handles rate limiting gracefully
- Failed notifications are retried automatically

### Caching
- Device tokens are cached in memory
- User data is fetched in batches
- Template processing is optimized

## Security

### Authentication
- Edge Function requires Supabase authentication
- Service role key used for database access
- Firebase Admin SDK handles FCM authentication

### Data Privacy
- Only necessary user data is fetched
- Device tokens are not logged
- Personal data is processed securely

## Monitoring and Logging

### Edge Function Logs
- All notification attempts are logged
- Success/failure rates are tracked
- Error details are captured

### Flutter App Logs
- Device token registration is logged
- Notification service calls are logged
- Error handling is comprehensive

## Future Enhancements

### Planned Features
- [ ] Rich notifications with images and actions
- [ ] Scheduled notifications (send at specific time)
- [ ] Notification history tracking
- [ ] User notification preferences
- [ ] Topic-based subscriptions
- [ ] Analytics and reporting
- [ ] A/B testing for notification content

### Extensibility
- Easy to add new notification types
- Template system supports custom formats
- Data payload can include any custom fields
- Priority system supports different urgency levels

## Troubleshooting

### Common Issues

#### 1. Notifications Not Received
- Check if user granted notification permissions
- Verify device token is saved in database
- Check Firebase project configuration
- Review Edge Function logs

#### 2. Edge Function Errors
- Verify environment variables are set
- Check Firebase service account permissions
- Review Supabase logs for database errors
- Test with smaller user batches

#### 3. Personalization Not Working
- Check placeholder syntax (`{firstName}` not `{first_name}`)
- Verify user data exists in database
- Test with simple templates first
- Review template processing logs

### Debug Commands
```bash
# Check Edge Function logs
supabase functions logs send-notifications

# Test with curl
curl -X POST "YOUR_URL/functions/v1/send-notifications" \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"userIds":["test"],"type":"general","title":"Test","body":"Test message"}'

# Check database for device tokens
supabase db query "SELECT id, full_name, user_device_token FROM my_users WHERE user_device_token IS NOT NULL LIMIT 5;"
```

## Conclusion

This notification system provides a robust, scalable, and flexible solution for sending push notifications in the Rahiee AI app. It supports batch processing, personalization, and multiple notification types while maintaining high performance and reliability.

The system is designed to be future-proof and easily extensible, allowing for new notification types and features to be added without major architectural changes.
