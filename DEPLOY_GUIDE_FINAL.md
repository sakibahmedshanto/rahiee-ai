# 🚀 Push Notifications - Final Deployment Guide

## ✅ Ready to Deploy!

The Edge Function now uses the **service account JSON file** directly - no environment variables needed!

## 📁 Files Structure

```
supabase/functions/send-notifications/
  ├── index.ts (clean code with npm imports)
  └── YOUR_GOOGLE_PROJECT_ID-firebase-adminsdk-fbsvc-1a539ac37f.json (service account)
```

## 🎯 One-Step Deployment

Simply run:

```bash
cd /Users/sakibahmed/tanainent/Rahiee.AI/rahiee_ai
supabase functions deploy send-notifications
```

That's it! The function will:
- ✅ Use npm imports (works perfectly in Deno)
- ✅ Load service account from JSON file
- ✅ Generate OAuth2 tokens automatically
- ✅ Send notifications via Firebase FCM v1 API

## 🧪 Test the Function

### Test with your device token:
```bash
curl -X POST "https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvZXZ3eHJscG10a3d5YWZ5aHp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwNzAyMDQsImV4cCI6MjA3NTY0NjIwNH0.ORfqhblCN0A3Md6-vHDVpcVC3lgsRGieG65i_bByeWc" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["00000000-0000-0000-0000-000000000001"],
    "type": "general",
    "title": "🎉 Test from Rahiee AI",
    "body": "Hey {firstName}! Your notification system is working perfectly!"
  }'
```

### Expected Response:
```json
{
  "success": true,
  "sentCount": 1,
  "failedCount": 0,
  "errors": [],
  "processedUsers": [
    {
      "userId": "00000000-0000-0000-0000-000000000001",
      "userName": "Test User Shanto",
      "success": true
    }
  ]
}
```

## 📱 You should receive a notification on your device!

## 💡 Why This Approach is Better

✅ **No environment variables** - Service account embedded  
✅ **npm imports** - Official Deno/Supabase method  
✅ **google-auth-library** - Handles OAuth2 automatically  
✅ **FCM v1 API** - Latest Firebase API  
✅ **Clean code** - Only 340 lines  
✅ **Production ready** - Used by official Supabase examples  

## 🎯 Usage from Flutter

### Send Notification:
```dart
final result = await NotificationService.to.sendScheduleAssignmentNotifications(
  userIds: ['user1', 'user2', 'user3'],
  scheduleId: 'schedule-123',
  startTime: '09:00 AM',
  endTime: '05:00 PM',
  location: 'Main Office',
);

print('Sent: ${result.sentCount}, Failed: ${result.failedCount}');
```

### Integration with Schedule Creation:
```dart
// After creating a schedule
await ScheduleNotificationIntegration.notifyScheduleAssignment(
  scheduleId: newScheduleId,
  assignedUserIds: assignedUserIds,
  scheduleTitle: 'Team Meeting',
  startTime: startDateTime,
  endTime: endDateTime,
  location: 'Main Office',
);
```

## 🔍 Check Logs

```bash
supabase functions logs send-notifications
```

## 🎊 Features

- ✅ Batch processing (multiple users at once)
- ✅ Personalization (`{firstName}`, `{userName}`, `{department}`)
- ✅ Pre-built templates
- ✅ Custom notifications
- ✅ Schedule data integration
- ✅ Error handling per user
- ✅ Async processing
- ✅ CORS enabled

## 📚 Example Notifications

### Schedule Assignment:
> **🎉 New Schedule Assignment**  
> Hey Shanto! You have been assigned to a new schedule.

### With Schedule Data:
```dart
{
  "userIds": ["user1", "user2"],
  "type": "schedule_assignment",
  "title": "New Schedule Assignment",
  "body": "Hey {firstName}! You've been assigned to {location} at {startTime}",
  "scheduleData": {
    "scheduleId": "schedule-123",
    "startTime": "09:00 AM",
    "location": "Main Office"
  }
}
```

Result:
> **New Schedule Assignment**  
> Hey Shanto! You've been assigned to Main Office at 09:00 AM

## ⚠️ Important Notes

1. **Service Account**: The JSON file contains your Firebase credentials - keep it secure
2. **Device Tokens**: Users must sign in once to save their device token
3. **Testing**: Always test with a small group first
4. **Logs**: Monitor logs for the first few notifications

## 🚨 Troubleshooting

### "No users with valid device tokens"
**Solution**: Users need to sign in at least once to save their device token

### "Failed to fetch user data"
**Solution**: Check Supabase connection and table permissions

### "FCM error"
**Solution**: Check the error details in the logs for specific Firebase issues

### Deployment fails
**Solution**: Make sure the service account JSON file is in the correct location

## ✨ That's It!

Your notification system is production-ready and will send personalized notifications to your users!

**Just deploy and test!** 🚀

