# ⚡ Quick Deploy - 3 Steps

## 1️⃣ Get Firebase Server Key
```
Firebase Console → Project Settings → Cloud Messaging → Copy "Server key"
```

## 2️⃣ Set Environment Variable
```bash
supabase secrets set FIREBASE_SERVER_KEY="YOUR_KEY_HERE"
```

## 3️⃣ Deploy
```bash
supabase functions deploy send-notifications
```

## ✅ Test
```bash
curl -X POST "https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvZXZ3eHJscG10a3d5YWZ5aHp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwNzAyMDQsImV4cCI6MjA3NTY0NjIwNH0.ORfqhblCN0A3Md6-vHDVpcVC3lgsRGieG65i_bByeWc" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["00000000-0000-0000-0000-000000000001"],
    "type": "general",
    "title": "Test",
    "body": "Hey {firstName}! Test notification."
  }'
```

## 🎯 Done!
Your notification system is live and ready to use.

See `DEPLOY_NOTIFICATIONS_GUIDE.md` for detailed instructions.

