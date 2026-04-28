# How to Get Firebase Server Key

## Step 1: Go to Firebase Console
1. Open https://console.firebase.google.com/
2. Select your project: **YOUR_GOOGLE_PROJECT_ID**

## Step 2: Navigate to Project Settings
1. Click on the **gear icon** (⚙️) next to "Project Overview"
2. Select **Project settings**

## Step 3: Go to Cloud Messaging Tab
1. In the Project settings page, click on the **Cloud Messaging** tab
2. Scroll down to find the **Server key** section

## Step 4: Copy the Server Key
1. You should see a field labeled **Server key**
2. Copy the entire key (it looks like: `AAAAxxxxxxx:APA91bxxxxxxxxxxxxx...`)

## Step 5: Set it as Environment Variable
Once you have the key, run this command:

```bash
supabase secrets set FIREBASE_SERVER_KEY="YOUR_SERVER_KEY_HERE"
```

Replace `YOUR_SERVER_KEY_HERE` with the actual server key you copied.

## ⚠️ Important Notes:
- The Server Key is different from the API key
- Keep it secret and never commit it to version control
- The key will be used for server-to-server communication with FCM

## Alternative: Use Firebase Cloud Messaging API (v1)
If you can't find the Server Key (it's being deprecated), you can:
1. Enable **Firebase Cloud Messaging API (v1)** in Google Cloud Console
2. Use service account credentials instead (which we already have)

Let me know once you have the server key, and I'll help you set it up!

