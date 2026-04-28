# Uniform Verification System - Deployment Guide

## 🚀 Quick Deployment Steps

### Step 1: Install Supabase CLI

```bash
# Install via Homebrew (macOS)
brew install supabase/tap/supabase

# Or via npm
npm install -g supabase

# Verify installation
supabase --version
```

### Step 2: Login to Supabase

```bash
cd /Users/sakibahmed/tanainent/Rahiee.AI/rahiee_ai
supabase login
```

This will open your browser - login with your Supabase account.

### Step 3: Link Your Project

```bash
supabase link --project-ref YOUR_SUPABASE_PROJECT_REF
```

### Step 4: Set Google Cloud Credentials as Secret

You need to set your Google Cloud credentials as a secret in Supabase.

**IMPORTANT**: Copy your entire JSON file content (all 14 lines) first!

```bash
# Set the Google credentials as a secret
supabase secrets set GOOGLE_CLOUD_CREDENTIALS='{"type":"service_account","project_id":"YOUR_GOOGLE_PROJECT_ID","private_key_id":"YOUR_PRIVATE_KEY_ID","private_key":"-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n","client_email":"YOUR_VISION_SERVICE_ACCOUNT_EMAIL","client_id":"YOUR_VISION_CLIENT_ID","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/rahiee-attendance-vision%40YOUR_GOOGLE_PROJECT_ID.iam.gserviceaccount.com","universe_domain":"googleapis.com"}'
```

**IMPORTANT**: Make sure to copy the ENTIRE JSON on ONE LINE with NO line breaks inside the JSON!

### Step 5: Deploy the Edge Function

```bash
supabase functions deploy verify-uniform
```

Wait for deployment (30-60 seconds).

### Step 6: Verify Deployment

```bash
# Get function URL
supabase functions list
```

You should see:
```
verify-uniform | https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/verify-uniform
```

### Step 7: Test the Function

Create a test file `test-uniform.sh`:

```bash
#!/bin/bash

# Get your Supabase anon key from dashboard
SUPABASE_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co"
ANON_KEY="your-anon-key-here"

# Test with a sample base64 image
# (You'll need a real base64 encoded image for actual testing)
curl -X POST \
  "${SUPABASE_URL}/functions/v1/verify-uniform" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "image_base64": "iVBORw0KGgoAAAANSUhEUg...(base64 image)...",
    "user_id": "test-user-id"
  }'
```

## 📝 What Was Created

### 1. Database Changes
- ✅ 11 new columns in `attendance` table
- ✅ Indices for performance
- ✅ Comments for documentation

### 2. Storage Setup
- ✅ `attendance-photos` bucket created
- ✅ RLS policies for security
- ✅ Folder structure: `checkin/{user_id}/`, `checkout/{user_id}/`

### 3. Edge Function
- ✅ `verify-uniform` function
- ✅ Google Cloud Vision API integration
- ✅ JWT authentication
- ✅ Uniform detection logic

## 🔧 Configuration Files

### Edge Function Structure
```
supabase/functions/
└── verify-uniform/
    └── index.ts       // Main Edge Function
```

### Environment Variables
```
GOOGLE_CLOUD_CREDENTIALS  // Set via: supabase secrets set
```

## 🧪 Testing

### Test with cURL:

```bash
# Get your keys from: https://supabase.com/dashboard/project/YOUR_SUPABASE_PROJECT_REF/settings/api

SUPABASE_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co"
ANON_KEY="your-anon-key"

# Convert an image to base64 first
base64 -i test_uniform_photo.jpg -o test_image.txt

# Test the function
curl -X POST \
  "${SUPABASE_URL}/functions/v1/verify-uniform" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d @- << EOF
{
  "image_base64": "$(cat test_image.txt)",
  "user_id": "883d252d-83d7-4ce5-a1ef-f34e76f5189d"
}
EOF
```

### Expected Response:

```json
{
  "success": true,
  "wearing_uniform": true,
  "confidence": 85,
  "message": "✅ Uniform verified! Detected: Clothing (95.0%), Shirt (88.0%), Professional (82.0%)",
  "detection_data": { ... }
}
```

## ⚠️ Troubleshooting

### Error: "GOOGLE_CLOUD_CREDENTIALS not configured"
**Solution**: Run the `supabase secrets set` command again.

### Error: "Failed to run sql query"
**Solution**: Policies already exist. You can ignore this or drop and recreate.

### Error: "Vision API failed"
**Solution**: 
1. Verify Google Cloud Vision API is enabled
2. Check service account has correct permissions
3. Verify JSON credentials are valid

### Error: "No person detected"
**Solution**: Image quality issue - user needs to retake photo with better lighting.

## 📊 Next Steps

After deployment, you need to:
1. ✅ Create Flutter camera screen
2. ✅ Integrate with Edge Function
3. ✅ Handle verification flow
4. ✅ Upload photos to storage
5. ✅ Update attendance records

## 🎯 Cost Estimate

- Google Cloud Vision: $1.50 per 1,000 images
- 100 employees × 2 check-ins/day = 200 requests/day = 6,000/month
- **Cost: ~$9/month for Vision API**
- Supabase Edge Functions: Free tier (500K requests/month)
- Storage: ~$0.021/GB/month

**Total: ~$10-12/month for 100 employees**

---

Ready to deploy? Run these commands! 🚀




