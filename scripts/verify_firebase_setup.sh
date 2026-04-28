#!/bin/bash

# Firebase Environment Setup Verification Script
# This script helps verify that your Firebase environment variables are set correctly

echo "🔧 Firebase Environment Setup Verification"
echo "=========================================="

# Get Supabase project URL
SUPABASE_URL=$(supabase status | grep "API URL" | awk '{print $3}')
SUPABASE_ANON_KEY=$(supabase status | grep "anon key" | awk '{print $3}')

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: Could not get Supabase URL or anon key"
    echo "Make sure Supabase is running locally with 'supabase start'"
    exit 1
fi

echo "📡 Supabase URL: $SUPABASE_URL"
echo "🔑 Using anon key: ${SUPABASE_ANON_KEY:0:20}..."

echo ""
echo "🧪 Testing Firebase Environment Variables..."
echo "============================================"

# Test 1: Check if environment variables are accessible
echo ""
echo "📋 Test 1: Environment Variables Check"
echo "-------------------------------------"

# This test will fail if environment variables are not set properly
curl -X POST "$SUPABASE_URL/functions/v1/send-notifications" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["test-user-1"],
    "type": "general",
    "title": "Environment Test",
    "body": "Testing Firebase environment setup"
  }' 2>/dev/null | jq '.' 2>/dev/null || echo "❌ Environment variables not set or Edge Function not accessible"

echo ""
echo "📝 Manual Environment Variable Check:"
echo "====================================="
echo "Please verify these are set in your Supabase project:"
echo ""
echo "✅ FIREBASE_PROJECT_ID=YOUR_GOOGLE_PROJECT_ID"
echo "✅ FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@YOUR_GOOGLE_PROJECT_ID.iam.gserviceaccount.com"
echo "✅ FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n"
echo ""
echo "🔍 To check your secrets:"
echo "supabase secrets list"
echo ""
echo "📖 To set secrets:"
echo "supabase secrets set FIREBASE_PROJECT_ID=YOUR_GOOGLE_PROJECT_ID"
echo "supabase secrets set FIREBASE_CLIENT_EMAIL=your-client-email"
echo "supabase secrets set FIREBASE_PRIVATE_KEY=\"your-private-key\""
echo ""
echo "🚀 After setting environment variables, redeploy the Edge Function:"
echo "supabase functions deploy send-notifications"
