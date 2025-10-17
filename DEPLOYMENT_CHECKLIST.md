# ✅ Deployment Checklist

## Pre-Deployment (Already Done ✅)
- [x] Edge Function code written (`send-notifications/index.ts`)
- [x] FCM service integrated in Flutter app
- [x] Device token saving on sign-in
- [x] Notification service created
- [x] Database table with `user_device_token` field
- [x] Documentation completed

## Your Manual Deployment Steps

### □ Step 1: Get Firebase Server Key
1. Go to: https://console.firebase.google.com/project/YOUR_GOOGLE_PROJECT_ID/settings/cloudmessaging
2. Find "Project credentials" section
3. Copy the **Server key** (starts with `AAAA...`)
4. Save it somewhere safe

### □ Step 2: Set Environment Variable
Run in terminal:
```bash
cd /Users/sakibahmed/tanainent/Rahiee.AI/rahiee_ai
supabase secrets set FIREBASE_SERVER_KEY="YOUR_KEY_FROM_STEP_1"
```

Verify it was set:
```bash
supabase secrets list
```
You should see `FIREBASE_SERVER_KEY` listed.

### □ Step 3: Deploy the Function
```bash
supabase functions deploy send-notifications
```

Wait for success message:
```
✓ Deployed Functions on project YOUR_SUPABASE_PROJECT_REF: send-notifications
```

### □ Step 4: Test the Function
Replace `YOUR_USER_ID` with a real user ID from your database:
```bash
curl -X POST "https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvZXZ3eHJscG10a3d5YWZ5aHp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwNzAyMDQsImV4cCI6MjA3NTY0NjIwNH0.ORfqhblCN0A3Md6-vHDVpcVC3lgsRGieG65i_bByeWc" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["YOUR_USER_ID"],
    "type": "general",
    "title": "Test Notification",
    "body": "Hey {firstName}! Testing the notification system."
  }'
```

Expected response:
```json
{
  "success": true,
  "sentCount": 1,
  "failedCount": 0
}
```

### □ Step 5: Test from Flutter App
In your Flutter app:
```dart
final result = await Get.find<NotificationService>().sendGeneralNotifications(
  userIds: ['your-user-id'],
  title: 'Test from Flutter',
  body: 'Hey {firstName}! This works!',
);
print('Result: ${result.sentCount} sent');
```

### □ Step 6: Integrate with Schedule Creation
In your admin schedule creation code:
```dart
// After creating schedule successfully
await ScheduleNotificationIntegration.notifyScheduleAssignment(
  scheduleId: newScheduleId,
  assignedUserIds: assignedUserIds,
  scheduleTitle: 'Team Meeting',
  startTime: startDateTime,
  endTime: endDateTime,
  location: 'Main Office',
);
```

## Post-Deployment Verification

### □ Check Logs
```bash
supabase functions logs send-notifications
```

### □ Verify User Has Device Token
Check in Supabase dashboard:
```sql
SELECT id, full_name, user_device_token 
FROM my_users 
WHERE user_device_token IS NOT NULL
LIMIT 10;
```

### □ Test Different Notification Types
- [ ] Schedule assignment
- [ ] Schedule update
- [ ] General notification
- [ ] Department notification
- [ ] Custom notification

## Troubleshooting Guide

| Issue | Solution |
|-------|----------|
| "FIREBASE_SERVER_KEY not set" | Run Step 2 again |
| "Invalid server key" | Get new key from Firebase Console |
| "No users with device tokens" | Users need to sign in once |
| "Failed to fetch user data" | Check Supabase connection |
| Function not deploying | Check for syntax errors in index.ts |

## Success Criteria

✅ Edge function deployed successfully  
✅ Test notification received on device  
✅ No errors in function logs  
✅ Users can receive notifications  
✅ Schedule notifications working  

## Next Steps After Deployment

1. Monitor function logs for first few days
2. Collect user feedback on notifications
3. Adjust notification content/timing as needed
4. Set up notification preferences (optional)
5. Add notification history (optional)

## Support Resources

- **Edge Function**: `supabase/functions/send-notifications/index.ts`
- **Deployment Guide**: `DEPLOY_NOTIFICATIONS_GUIDE.md`
- **Quick Start**: `NOTIFICATION_QUICK_START.md`
- **Full Documentation**: `NOTIFICATION_SYSTEM_COMPLETE_GUIDE.md`
- **Supabase Dashboard**: https://supabase.com/dashboard/project/koevwxrlpmtkwyafyhzy
- **Firebase Console**: https://console.firebase.google.com/project/YOUR_GOOGLE_PROJECT_ID

---

**Follow these steps in order, and you'll have a working notification system!** 🚀

