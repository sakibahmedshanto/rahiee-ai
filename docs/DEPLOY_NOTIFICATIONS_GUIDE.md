# 🚀 Push Notifications Deployment Guide

## Prerequisites
- Firebase project: **YOUR_GOOGLE_PROJECT_ID**
- Supabase project connected
- Supabase CLI installed

## Step 1: Get Firebase Server Key

### Option A: Firebase Console (Legacy API Key)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **YOUR_GOOGLE_PROJECT_ID**
3. Click **⚙️ Settings** → **Project settings**
4. Go to **Cloud Messaging** tab
5. Scroll to **Project credentials** section
6. Copy the **Server key** (starts with `AAAA...`)

### Option B: If Server Key Not Available
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **YOUR_GOOGLE_PROJECT_ID**
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **API Key**
5. Copy the API key

## Step 2: Set Environment Variable

Run this command in your project directory:

```bash
supabase secrets set FIREBASE_SERVER_KEY="YOUR_SERVER_KEY_HERE"
```

Replace `YOUR_SERVER_KEY_HERE` with the actual key from Step 1.

### Verify the secret was set:
```bash
supabase secrets list
```

You should see `FIREBASE_SERVER_KEY` in the list.

## Step 3: Deploy the Edge Function

```bash
cd /Users/sakibahmed/tanainent/Rahiee.AI/rahiee_ai
supabase functions deploy send-notifications
```

Wait for the deployment to complete.

## Step 4: Test the Function

### Using curl:
```bash
curl -X POST "https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvZXZ3eHJscG10a3d5YWZ5aHp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwNzAyMDQsImV4cCI6MjA3NTY0NjIwNH0.ORfqhblCN0A3Md6-vHDVpcVC3lgsRGieG65i_bByeWc" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["YOUR_USER_ID"],
    "type": "general",
    "title": "Test Notification",
    "body": "Hey {firstName}! This is a test."
  }'
```

### Using Flutter:
```dart
final result = await Get.find<NotificationService>().sendGeneralNotifications(
  userIds: ['user-id-here'],
  title: 'Test Notification',
  body: 'Hey {firstName}! This is a test notification.',
);
```

## Step 5: Verify Success

### Check Response:
A successful response looks like:
```json
{
  "success": true,
  "sentCount": 1,
  "failedCount": 0,
  "errors": [],
  "processedUsers": [
    {
      "userId": "...",
      "userName": "...",
      "success": true
    }
  ]
}
```

### Check Logs:
```bash
supabase functions logs send-notifications
```

## Troubleshooting

### Error: "FIREBASE_SERVER_KEY not set"
**Solution**: Run Step 2 again to set the environment variable.

### Error: "Invalid server key"
**Solution**: 
1. Verify the key is correct
2. Make sure you copied the entire key
3. Try regenerating the key in Firebase Console

### Error: "No users with valid device tokens"
**Solution**: 
1. Make sure users have signed in at least once
2. Check the `my_users` table for `user_device_token` values
3. Verify FCM is properly initialized in the Flutter app

### Error: "Failed to fetch user data"
**Solution**: 
1. Check Supabase database is accessible
2. Verify `my_users` table exists
3. Check RLS policies allow reading user data

## Usage Examples

### 1. Schedule Assignment Notification
```dart
await NotificationService.to.sendScheduleAssignmentNotifications(
  userIds: ['user1', 'user2'],
  scheduleId: 'schedule-123',
  startTime: '09:00 AM',
  endTime: '05:00 PM',
  location: 'Main Office',
);
```

### 2. General Announcement
```dart
final allUserIds = await NotificationService.to.getAllActiveUserIds();
await NotificationService.to.sendGeneralNotifications(
  userIds: allUserIds,
  title: 'System Update',
  body: 'Hey {firstName}! The system will be updated tonight.',
);
```

### 3. Department Notification
```dart
final engineeringUsers = await NotificationService.to.getUserIdsByDepartment('Engineering');
await NotificationService.to.sendCustomNotifications(
  userIds: engineeringUsers,
  title: 'Team Meeting',
  body: 'Hey {firstName}! Team meeting at 3 PM in Conference Room A.',
);
```

## File Structure

```
supabase/
└── functions/
    └── send-notifications/
        └── index.ts  (clean, production-ready code)
```

## Key Features

✅ **Batch Processing**: Send to multiple users at once  
✅ **Personalization**: Use `{firstName}`, `{userName}`, `{department}`, etc.  
✅ **Templates**: Pre-built templates for common scenarios  
✅ **Error Handling**: Detailed error reporting per user  
✅ **Async**: Non-blocking notification delivery  
✅ **CORS Enabled**: Works from any client  

## Important Notes

1. **Device Tokens**: Users must sign in once to save their device token
2. **Firebase Server Key**: Keep it secret, never commit to git
3. **Rate Limits**: Firebase has rate limits (check Firebase documentation)
4. **Testing**: Test with a small group before sending to all users
5. **Logs**: Monitor function logs for issues

## Next Steps

1. Test with your device token
2. Integrate into schedule creation workflow
3. Set up monitoring and alerts
4. Add notification history tracking (optional)
5. Implement notification preferences (optional)

## Support

- Supabase Dashboard: https://supabase.com/dashboard/project/koevwxrlpmtkwyafyhzy
- Firebase Console: https://console.firebase.google.com/project/YOUR_GOOGLE_PROJECT_ID
- Function Logs: `supabase functions logs send-notifications`

---

**That's it! Your notification system is ready to use.** 🎉

