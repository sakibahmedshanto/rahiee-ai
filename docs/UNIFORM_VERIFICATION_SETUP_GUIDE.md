# 📸 Uniform Verification System - Complete Setup Guide

This guide walks you through implementing the uniform verification system with camera check-in for your Rahiee.AI attendance app.

---

## 🎯 System Overview

### **How It Works:**
1. **Employee taps "Check In"** → Camera screen opens
2. **Takes selfie** → Photo sent to Edge Function
3. **AI processes image** → Google Vision API analyzes photo
4. **Uniform detected?**
   - ✅ **Yes (>50% confidence)** → Auto check-in
   - ❌ **No** → Prompt: "No uniform detected. Continue anyway?"
5. **Photo stored** → Supabase Storage (`attendance-photos` bucket)
6. **Results saved** → Database columns track verification data

---

## ✅ Prerequisites Checklist

- [x] Supabase project created
- [x] Google Cloud Project created
- [x] Vision API enabled
- [x] Service account created with JSON key
- [x] Billing enabled on Google Cloud
- [x] Edge Function deployed (`verify-uniform`)
- [x] Storage bucket created (`attendance-photos`)
- [x] Database columns added to `attendance` table
- [x] Flutter dependencies installed

---

## 🗂️ File Structure

```
lib/
├── services/
│   ├── uniform_verification_service.dart  ← Calls Edge Function
│   ├── photo_storage_service.dart         ← Handles Supabase Storage
│   └── attendance_management_service.dart ← Updated with uniform data
├── screens/
│   └── attendance_screen/
│       └── camera_check_in_screen.dart    ← Camera UI
├── controllers/
│   ├── camera_check_in_controller.dart    ← Check-in logic
│   └── unified_schedule_controller.dart   ← Updated to use camera
└── config/
    └── api_config.dart                    ← API endpoints

supabase/
└── functions/
    └── verify-uniform/
        └── index.ts                       ← Edge Function code

sql/
├── add_uniform_verification_columns.sql   ← Database migration
└── setup_storage_bucket_and_policies.sql  ← Storage RLS policies
```

---

## 📦 Step 1: Install Flutter Dependencies

Run this command in your project root:

```bash
flutter pub add camera image_picker path_provider http
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  camera: ^0.11.0+2
  image_picker: ^1.1.2
  path_provider: ^2.1.4
  http: ^1.2.2
```

Then run:
```bash
flutter pub get
```

---

## 🗄️ Step 2: Database Setup

### 2.1 Add Columns to `attendance` Table

Run the SQL migration:

```bash
# Navigate to your project
cd /Users/sakibahmed/tanainent/Rahiee.AI/rahiee_ai

# Apply the migration
supabase db execute --file sql/add_uniform_verification_columns.sql
```

Or execute via Supabase Dashboard → SQL Editor:
```sql
-- See: sql/add_uniform_verification_columns.sql
```

### 2.2 Verify Columns

Check that these columns exist in `attendance` table:
- `check_in_photo_url` (TEXT)
- `check_in_photo_path` (TEXT)
- `wearing_uniform` (BOOLEAN)
- `uniform_confidence` (NUMERIC)
- `uniform_detection_data` (JSONB)
- `photo_verified_at` (TIMESTAMPTZ)
- `verification_attempts` (INTEGER)

---

## 🪣 Step 3: Storage Bucket Setup

### 3.1 Create Bucket

1. Go to **Supabase Dashboard** → **Storage**
2. Click **"New bucket"**
3. Settings:
   - **Name:** `attendance-photos`
   - **Public:** ❌ **NO** (keep private)
   - **File size limit:** `5 MB`
   - **Allowed MIME types:** `image/jpeg, image/png, image/jpg`
4. Click **Create bucket**

### 3.2 Apply RLS Policies

Execute the SQL:

```bash
supabase db execute --file sql/setup_storage_bucket_and_policies.sql
```

Or via SQL Editor (see `sql/setup_storage_bucket_and_policies.sql`)

---

## ☁️ Step 4: Deploy Edge Function

### 4.1 Ensure Supabase CLI is Installed

```bash
# Check if installed
supabase --version

# If not installed (macOS):
brew install supabase/tap/supabase

# Other platforms:
# https://supabase.com/docs/guides/cli/getting-started
```

### 4.2 Login and Link Project

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_SUPABASE_PROJECT_REF
```

### 4.3 Set Google Cloud Credentials as Secret

```bash
# Set the credentials as an environment variable
supabase secrets set GOOGLE_CLOUD_CREDENTIALS="$(cat 'google vision api/YOUR_GOOGLE_PROJECT_ID-2bd981448940.json')"
```

### 4.4 Deploy the Edge Function

```bash
# Deploy
supabase functions deploy verify-uniform

# Expected output:
# ✅ Deployed Function verify-uniform
# URL: https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/verify-uniform
```

### 4.5 Test the Edge Function

```bash
# Make it executable
chmod +x test_uniform_function.sh

# Run test
./test_uniform_function.sh
```

**Expected response:**
```json
{
  "success": true,
  "wearing_uniform": false,
  "confidence": 0,
  "message": "No person detected in image..."
}
```

---

## 📱 Step 5: Flutter App Configuration

### 5.1 Update Edge Function URL

Already configured in `lib/services/uniform_verification_service.dart`:

```dart
static const String _edgeFunctionUrl = 
    'https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/verify-uniform';
```

### 5.2 Request Camera Permissions

#### **Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<manifest ...>
    <!-- Add these permissions BEFORE <application> tag -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    
    <application ...>
        ...
    </application>
</manifest>
```

#### **iOS** (`ios/Runner/Info.plist`):

```xml
<dict>
    <!-- Add these entries -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to verify your uniform during check-in</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo library access to select check-in photos</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Microphone access is optional for video capture</string>
</dict>
```

---

## 🧪 Step 6: Test the System

### 6.1 Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### 6.2 Test Check-In Flow

1. **Login as employee**
2. **Navigate to Schedule screen**
3. **Tap on a schedule** → "Check In" button
4. **Camera should open** (CameraCheckInScreen)
5. **Take a selfie** or choose from gallery
6. **Tap "Verify & Check In"**
7. **Expected:**
   - Loading indicator: "Verifying uniform..."
   - If uniform detected: ✅ "Checked in successfully! Uniform verified."
   - If no uniform: ⚠️ Dialog with "Continue anyway?" option

### 6.3 Verify Data Storage

**Check Database:**
```sql
SELECT 
    id, 
    user_id, 
    check_in_photo_url,
    wearing_uniform,
    uniform_confidence,
    verification_attempts
FROM attendance
WHERE check_in_photo_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;
```

**Check Storage:**
- Go to **Supabase Dashboard** → **Storage** → **attendance-photos**
- Look for: `checkin/{user_id}/{timestamp}.jpg`

---

## 🔧 Troubleshooting

### Issue 1: Camera Not Opening

**Error:** `Camera permission denied`

**Fix:**
```dart
// The app will automatically request permission
// If denied, check:
// - Android: Settings > Apps > Rahiee AI > Permissions > Camera
// - iOS: Settings > Rahiee AI > Camera
```

### Issue 2: Edge Function Error 500

**Error:** `"message": "Failed to decode base64"`

**Fix:**
```bash
# Redeploy with latest code
supabase functions deploy verify-uniform

# Check logs
supabase functions logs verify-uniform --follow
```

### Issue 3: "No Person Detected"

**Cause:** Photo doesn't contain a clear person

**Fix:** Tell user to:
- Face the camera directly
- Ensure good lighting
- Show upper body clearly

### Issue 4: Storage Upload Fails

**Error:** `Failed to upload photo`

**Fix:**
```sql
-- Check RLS policies
SELECT * FROM storage.policies WHERE bucket_id = 'attendance-photos';

-- Re-apply policies
-- Run: sql/setup_storage_bucket_and_policies.sql
```

### Issue 5: Low Confidence Score

**Cause:** Generic AI can't identify your specific uniform

**Solution:** Use generic detection for MVP, then:
1. Collect 400-500 uniform photos
2. Train a custom AutoML Vision model
3. Replace Vision API endpoint in Edge Function

---

## 📊 Monitoring & Analytics

### Check Edge Function Usage

```bash
# View real-time logs
supabase functions logs verify-uniform --follow

# View recent errors
supabase functions logs verify-uniform --tail 50
```

### Track Verification Success Rate

```sql
SELECT 
    DATE(check_in_time) as date,
    COUNT(*) as total_checkins,
    SUM(CASE WHEN wearing_uniform = true THEN 1 ELSE 0 END) as uniform_verified,
    AVG(uniform_confidence) as avg_confidence
FROM attendance
WHERE check_in_photo_url IS NOT NULL
GROUP BY DATE(check_in_time)
ORDER BY date DESC
LIMIT 30;
```

---

## 💰 Cost Estimation

### Google Vision API Pricing:
- **First 1,000 requests/month:** FREE
- **After:** $1.50 per 1,000 images

### Example (100 employees × 2 check-ins/day):
- **Monthly requests:** ~6,000
- **Cost:** ~$8/month
- **Free tier covers:** ~500 check-ins (about 2.5 days)

### Supabase Storage:
- **Included:** 1 GB storage
- **Average photo size:** ~500 KB
- **Capacity:** ~2,000 photos in free tier

---

## 🚀 Next Steps (Future Enhancements)

### 1. **Train Custom AutoML Model**
   - Collect 400-500 uniform photos from employees
   - Train Google AutoML Vision model
   - Update Edge Function with custom model ID
   - **Expected accuracy:** 90-95%

### 2. **Add Check-Out Photo**
   - Implement same flow for check-out
   - Store in `check_out_photo_url` column

### 3. **Admin Photo Review**
   - Add admin panel to review flagged photos
   - Manual override for false negatives

### 4. **Offline Support**
   - Store photos locally when offline
   - Queue for upload when online

### 5. **Face Recognition** (Advanced)
   - Verify employee identity with face match
   - Prevent buddy punching

---

## 📝 Summary

✅ **Backend Complete:**
- Database columns added
- Storage bucket configured
- Edge Function deployed
- Google Vision API integrated

✅ **Frontend Complete:**
- Camera screen built
- Uniform verification flow implemented
- Check-in updated with photo capture

✅ **System Ready:**
- Employees can now check in with selfie verification
- AI analyzes uniform presence
- Photos and results stored in database

---

## 🆘 Support

If you encounter issues:
1. Check **Troubleshooting** section above
2. View Edge Function logs: `supabase functions logs verify-uniform`
3. Test with `./test_uniform_function.sh`
4. Verify database columns with SQL query
5. Check storage policies in Supabase Dashboard

---

**🎉 Congratulations! Your uniform verification system is ready!**

Employees can now check in with AI-powered uniform verification! 🚀




