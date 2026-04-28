# Firebase Environment Setup Guide for Rahiee AI

## Project Information
- **Project ID**: `YOUR_GOOGLE_PROJECT_ID`
- **Project Number**: `YOUR_FIREBASE_SENDER_ID`
- **Package Name**: `com.tanainent.rahieeai`
- **Supabase URL**: `https://koevwxrlpmtkwyafyhzy.supabase.co`

## Step-by-Step Setup Instructions

### 1. Get Firebase Service Account Credentials

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select project: `YOUR_GOOGLE_PROJECT_ID`

2. **Navigate to Service Accounts**
   - Click on the gear icon (⚙️) → **Project Settings**
   - Go to **Service Accounts** tab
   - Click **"Generate new private key"**
   - Download the JSON file

3. **Extract Required Values**
   From the downloaded JSON file, you'll need:
   ```json
   {
     "project_id": "YOUR_GOOGLE_PROJECT_ID",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@YOUR_GOOGLE_PROJECT_ID.iam.gserviceaccount.com"
   }
   ```

### 2. Set Environment Variables in Supabase

#### Option A: Using Supabase CLI (Recommended)

```bash
# Set the environment variables
supabase secrets set FIREBASE_PROJECT_ID=YOUR_GOOGLE_PROJECT_ID

# Replace with your actual client email from the JSON file
supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@YOUR_GOOGLE_PROJECT_ID.iam.gserviceaccount.com

# Replace with your actual private key (keep the quotes and \n characters)
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
```

#### Option B: Using Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/koevwxrlpmtkwyafyhzy
2. Navigate to **Settings** → **Edge Functions**
3. Add these secrets:
   - **Name**: `FIREBASE_PROJECT_ID`, **Value**: `YOUR_GOOGLE_PROJECT_ID`
   - **Name**: `FIREBASE_CLIENT_EMAIL`, **Value**: `firebase-adminsdk-xxxxx@YOUR_GOOGLE_PROJECT_ID.iam.gserviceaccount.com`
   - **Name**: `FIREBASE_PRIVATE_KEY`, **Value**: `-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n`

### 3. Verify Setup

```bash
# Check if secrets are set
supabase secrets list

# Run verification script
./verify_firebase_setup.sh
```

### 4. Redeploy Edge Function

After setting the environment variables, redeploy the Edge Function:

```bash
supabase functions deploy send-notifications
```

### 5. Test the Setup

```bash
# Run the notification test
./test_notification_function.sh
```

## Expected Output

When everything is set up correctly, you should see:

```json
{
  "success": true,
  "sentCount": 2,
  "failedCount": 0,
  "errors": [],
  "processedUsers": [
    {"userId": "test-user-1", "success": true},
    {"userId": "test-user-2", "success": true}
  ]
}
```

## Troubleshooting

### Common Issues

#### 1. "Firebase environment variables not set"
- **Solution**: Make sure all three environment variables are set correctly
- **Check**: `supabase secrets list`

#### 2. "Invalid private key"
- **Solution**: Ensure the private key includes the `\n` characters
- **Format**: `"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"`

#### 3. "Permission denied"
- **Solution**: Check Firebase service account permissions
- **Ensure**: Service account has "Firebase Admin SDK Administrator Service Agent" role

#### 4. "Project not found"
- **Solution**: Verify `FIREBASE_PROJECT_ID=YOUR_GOOGLE_PROJECT_ID` is set correctly

### Debug Commands

```bash
# Check Edge Function logs
supabase functions logs send-notifications

# Check secrets
supabase secrets list

# Test with minimal payload
curl -X POST "https://koevwxrlpmtkwyafyhzy.supabase.co/functions/v1/send-notifications" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"userIds":["test"],"type":"general","title":"Test","body":"Test"}'
```

## Security Notes

- **Never commit** the Firebase service account JSON file to version control
- **Use environment variables** for all sensitive data
- **Rotate keys** periodically for security
- **Limit permissions** to only what's needed

## Next Steps

Once the environment is set up:

1. **Test with real user IDs** from your database
2. **Integrate with schedule creation** in your admin panel
3. **Set up monitoring** for notification success rates
4. **Configure notification channels** for Android

## Support

If you encounter issues:
1. Check the Edge Function logs: `supabase functions logs send-notifications`
2. Verify environment variables: `supabase secrets list`
3. Test Firebase connectivity with the verification script
4. Check Firebase Console for any project-level issues
