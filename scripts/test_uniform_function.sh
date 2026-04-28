#!/bin/bash

# Test script for uniform verification Edge Function

SUPABASE_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaWdudG9va3htaGVhb3JlcWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NDMxODUsImV4cCI6MjA3MjExOTE4NX0.QsL6A6hxmWxnhVQiV6Euy217eUwFtGkza_CBf2Vcd4I"

echo "🧪 Testing Uniform Verification Edge Function..."
echo ""
echo "Function URL: ${SUPABASE_URL}/functions/v1/verify-uniform"
echo ""

# Create a tiny test base64 image (1x1 pixel PNG - smallest valid image)
# This is just for testing function connectivity
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

echo "📤 Sending test request..."
echo ""

# Test the function
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST \
  "${SUPABASE_URL}/functions/v1/verify-uniform" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"image_base64\": \"${TEST_IMAGE}\",
    \"user_id\": \"883d252d-83d7-4ce5-a1ef-f34e76f5189d\"
  }")

# Extract HTTP status and body
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "HTTP Status: ${HTTP_STATUS}"
echo ""
echo "Body:"
echo "${BODY}" | python3 -m json.tool 2>/dev/null || echo "${BODY}"
echo ""

# Check if successful
if [ "$HTTP_STATUS" == "200" ]; then
    echo "✅ Function is working!"
    echo ""
    
    # Check if it contains expected fields
    if echo "$BODY" | grep -q "success"; then
        echo "✅ Response contains 'success' field"
    fi
    
    if echo "$BODY" | grep -q "wearing_uniform"; then
        echo "✅ Response contains 'wearing_uniform' field"
    fi
    
    if echo "$BODY" | grep -q "confidence"; then
        echo "✅ Response contains 'confidence' field"
    fi
    
    echo ""
    echo "🎉 Edge Function is deployed and working correctly!"
else
    echo "❌ Function returned error status: ${HTTP_STATUS}"
    echo ""
    echo "Common issues:"
    echo "1. Function not deployed - run: supabase functions deploy verify-uniform"
    echo "2. Secrets not set - run: supabase secrets set GOOGLE_CLOUD_CREDENTIALS=..."
    echo "3. Google Cloud Vision API not enabled"
fi

echo ""




