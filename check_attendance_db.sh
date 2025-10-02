#!/bin/bash

SUPABASE_URL="https://YOUR_SUPABASE_PROJECT_REF.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaWdudG9va3htaGVhb3JlcWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NDMxODUsImV4cCI6MjA3MjExOTE4NX0.QsL6A6hxmWxnhVQiV6Euy217eUwFtGkza_CBf2Vcd4I"

echo "📊 Checking attendance table structure and data..."
echo ""

# Check table schema
echo "Table columns:"
curl -s "${SUPABASE_URL}/rest/v1/attendance?select=*&limit=0" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" 2>&1 | head -20

echo ""
echo ""

# Get sample records with schedule join
echo "Sample records (with schedule info):"
curl -s "${SUPABASE_URL}/rest/v1/attendance?select=*,schedule:employee_schedules(title,location)&limit=3" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" | python3 -m json.tool

echo ""

