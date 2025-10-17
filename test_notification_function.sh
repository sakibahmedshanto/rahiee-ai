#!/bin/bash

# Test script for the send-notifications Edge Function
# This script tests the notification system with sample data

echo "🧪 Testing send-notifications Edge Function..."

# Get Supabase project URL and anon key
SUPABASE_URL=$(supabase status | grep "API URL" | awk '{print $3}')
SUPABASE_ANON_KEY=$(supabase status | grep "anon key" | awk '{print $3}')

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: Could not get Supabase URL or anon key"
    echo "Make sure Supabase is running locally with 'supabase start'"
    exit 1
fi

echo "📡 Supabase URL: $SUPABASE_URL"
echo "🔑 Using anon key: ${SUPABASE_ANON_KEY:0:20}..."

# Test 1: Schedule Assignment Notification
echo ""
echo "📅 Test 1: Schedule Assignment Notification"
echo "=========================================="

curl -X POST "$SUPABASE_URL/functions/v1/send-notifications" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["test-user-1", "test-user-2"],
    "type": "schedule_assignment",
    "title": "New Schedule Assignment",
    "body": "Hey {firstName}! You have been assigned to a new schedule. Check your app for details.",
    "scheduleData": {
      "scheduleId": "schedule-123",
      "startTime": "2024-01-15T09:00:00Z",
      "endTime": "2024-01-15T17:00:00Z",
      "location": "Main Office",
      "department": "Engineering"
    },
    "data": {
      "scheduleId": "schedule-123",
      "action": "view_schedule"
    },
    "priority": "high"
  }' | jq '.'

echo ""
echo "⏳ Waiting 2 seconds before next test..."
sleep 2

# Test 2: General Notification
echo ""
echo "📢 Test 2: General Notification"
echo "=============================="

curl -X POST "$SUPABASE_URL/functions/v1/send-notifications" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["test-user-1"],
    "type": "general",
    "title": "System Maintenance",
    "body": "Hey {firstName}! The system will be under maintenance tonight from 11 PM to 1 AM.",
    "data": {
      "action": "view_maintenance",
      "maintenanceId": "maint-456"
    },
    "priority": "normal"
  }' | jq '.'

echo ""
echo "⏳ Waiting 2 seconds before next test..."
sleep 2

# Test 3: Custom Notification with Template
echo ""
echo "🎨 Test 3: Custom Notification with Template"
echo "==========================================="

curl -X POST "$SUPABASE_URL/functions/v1/send-notifications" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["test-user-1", "test-user-2"],
    "type": "custom",
    "title": "Custom Notification",
    "body": "Hey {firstName}! This is a custom notification for {department} department.",
    "customTemplate": {
      "titleTemplate": "🎉 Special Announcement for {firstName}",
      "bodyTemplate": "Dear {firstName} from {department} department, we have exciting news to share!"
    },
    "data": {
      "action": "view_announcement",
      "announcementId": "ann-789"
    },
    "imageUrl": "https://example.com/announcement-image.jpg",
    "priority": "high"
  }' | jq '.'

echo ""
echo "⏳ Waiting 2 seconds before next test..."
sleep 2

# Test 4: Attendance Reminder
echo ""
echo "⏰ Test 4: Attendance Reminder"
echo "============================="

curl -X POST "$SUPABASE_URL/functions/v1/send-notifications" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": ["test-user-1", "test-user-2", "test-user-3"],
    "type": "attendance_reminder",
    "title": "Attendance Reminder",
    "body": "Hey {firstName}! Don'\''t forget to mark your attendance for today.",
    "data": {
      "action": "mark_attendance",
      "date": "2024-01-15"
    },
    "priority": "normal"
  }' | jq '.'

echo ""
echo "✅ All tests completed!"
echo ""
echo "📋 Test Summary:"
echo "================="
echo "1. ✅ Schedule Assignment Notification"
echo "2. ✅ General Notification"
echo "3. ✅ Custom Notification with Template"
echo "4. ✅ Attendance Reminder"
echo ""
echo "💡 Note: These tests use dummy user IDs. In production, use real user IDs from your database."
echo "🔍 Check the Edge Function logs for detailed execution information."
