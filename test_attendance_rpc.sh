#!/bin/bash

# Supabase connection details
SUPABASE_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaWdudG9va3htaGVhb3JlcWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NDMxODUsImV4cCI6MjA3MjExOTE4NX0.QsL6A6hxmWxnhVQiV6Euy217eUwFtGkza_CBf2Vcd4I"

echo "============================================"
echo "🔍 Testing Attendance Table & RPC Function"
echo "============================================"
echo ""

echo "1️⃣ Checking attendance table records..."
echo "----------------------------------------"

curl -s "$SUPABASE_URL/rest/v1/attendance?select=id,user_id,schedule_id,status,check_in_time,check_out_time&limit=5" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  | python3 -m json.tool || echo "[]"

echo ""
echo ""

echo "2️⃣ Counting total attendance records..."
echo "----------------------------------------"

TOTAL=$(curl -s "$SUPABASE_URL/rest/v1/attendance?select=count" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Prefer: count=exact")

echo "Total records: $TOTAL"

echo ""
echo ""

echo "3️⃣ Testing RPC function..."
echo "----------------------------------------"

# Test with a dummy UUID
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/get_user_attendance_history" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "p_user_id": "00000000-0000-0000-0000-000000000000",
    "p_status": null,
    "p_start_date": null,
    "p_end_date": null,
    "p_limit": 5,
    "p_offset": 0
  }' | python3 -m json.tool 2>&1

echo ""
echo ""
echo "============================================"
echo "✅ Test Complete"
echo "============================================"

