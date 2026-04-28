#!/bin/bash

SUPABASE_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaWdudG9va3htaGVhb3JlcWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NDMxODUsImV4cCI6MjA3MjExOTE4NX0.QsL6A6hxmWxnhVQiV6Euy217eUwFtGkza_CBf2Vcd4I"

echo "🔍 Checking Rahiee.AI Database..."
echo ""

# Check users
echo "1. Users in database:"
curl -s "${SUPABASE_URL}/rest/v1/my_users?select=id,full_name,email,user_role&limit=10" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | python3 -m json.tool

echo ""
echo ""

# Check attendance records
echo "2. Attendance records:"
curl -s "${SUPABASE_URL}/rest/v1/attendance?select=*&limit=10" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | python3 -m json.tool

echo ""
echo ""

# Check schedules
echo "3. Schedules:"
curl -s "${SUPABASE_URL}/rest/v1/employee_schedules?select=id,title,assigned_user_id,start_date_time,status&limit=5" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | python3 -m json.tool

