#!/bin/bash

# Manual test script for absence detection
# Usage: ./test_absence_detection.sh

echo "🧪 Testing Hourly Absence Detection System"
echo "=========================================="

# Check if SUPABASE_ANON_KEY is set
if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: SUPABASE_ANON_KEY environment variable not set"
    echo "Please set it with: export SUPABASE_ANON_KEY=your_key_here"
    exit 1
fi

echo "📡 Calling Supabase Edge Function..."

# Call the Edge Function
response=$(curl -s -X POST \
  "https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/hourly-absence-detection" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -w "\nHTTP_STATUS:%{http_code}")

# Extract response and status code
http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')

echo "Response Status: $http_status"
echo "Response Body:"
echo "$response_body" | jq '.'

# Check if the request was successful
if [ "$http_status" -eq 200 ]; then
    echo ""
    echo "✅ Test completed successfully!"
    
    # Extract and display key information
    absent_count=$(echo "$response_body" | jq -r '.absent_count // "N/A"')
    echo "📊 Absences detected: $absent_count"
    
    if [ "$absent_count" != "N/A" ] && [ "$absent_count" -gt 0 ]; then
        echo "⚠️  Found $absent_count absences - check your database!"
    else
        echo "✅ No new absences detected"
    fi
else
    echo ""
    echo "❌ Test failed with status: $http_status"
    exit 1
fi

echo ""
echo "🔍 To check the logs, run:"
echo "curl -X POST 'https://YOUR_SUPABASE_PROJECT_REF.supabase.co/rest/v1/rpc/get_absence_detection_history' \\"
echo "  -H 'Authorization: Bearer $SUPABASE_ANON_KEY' \\"
echo "  -H 'Content-Type: application/json'"

