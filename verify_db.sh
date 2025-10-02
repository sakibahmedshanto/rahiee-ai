#!/bin/bash

SUPABASE_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaWdudG9va3htaGVhb3JlcWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NDMxODUsImV4cCI6MjA3MjExOTE4NX0.QsL6A6hxmWxnhVQiV6Euy217eUwFtGkza_CBf2Vcd4I"

echo "🔍 Checking table structure..."
echo ""

# Try to get count with exact count header
echo "1. Attendance table count:"
curl -s "${SUPABASE_URL}/rest/v1/attendance?select=count" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Prefer: count=exact"

echo ""
echo ""

echo "2. Users table count:"
curl -s "${SUPABASE_URL}/rest/v1/my_users?select=count" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Prefer: count=exact"

echo ""
echo ""

echo "3. Schedules count:"
curl -s "${SUPABASE_URL}/rest/v1/employee_schedules?select=count" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Prefer: count=exact"

echo ""

