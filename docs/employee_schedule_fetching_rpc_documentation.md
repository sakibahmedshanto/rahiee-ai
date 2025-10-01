# 🚀 Employee Schedule Fetching RPC Functions Documentation

## 📋 Overview
This document provides comprehensive documentation for the RPC-based employee schedule fetching system that handles schedule exchanges and transfers. The system ensures employees can see all their schedules, including those received through approved exchanges.

## 🔧 RPC Functions

### 1. `get_employee_schedules_with_exchanges(p_user_id UUID, p_date DATE, p_include_exchanges BOOLEAN)`
**Purpose**: Fetch all schedules for an employee including those received through exchanges.

**Parameters**:
- `p_user_id` (UUID) - Employee's user ID
- `p_date` (DATE) - Date to fetch schedules for
- `p_include_exchanges` (BOOLEAN, default: true) - Whether to include exchange information

**Returns**: JSON object with schedules and metadata

**Example Usage**:
```sql
-- Get schedules for a specific user on a specific date
SELECT get_employee_schedules_with_exchanges(
    'user-uuid-here'::UUID,
    '2024-01-16'::DATE,
    true
);
```

**Response Format**:
```json
{
  "success": true,
  "user_id": "user-uuid-here",
  "date": "2024-01-16",
  "include_exchanges": true,
  "schedules": [
    {
      "id": "schedule-uuid",
      "title": "Morning Shift",
      "start_date_time": "2024-01-16T08:00:00Z",
      "end_date_time": "2024-01-16T16:00:00Z",
      "schedule_type": "assigned",
      "exchange_request_id": null,
      "exchange_status": null,
      "original_assignee_name": null,
      "exchange_requester_name": null,
      "assigned_user_name": "John Doe",
      "assigned_user_employee_id": "EMP001",
      "created_by_admin_name": "Admin User",
      "department": "Operations",
      "location": "Main Office"
    },
    {
      "id": "schedule-uuid-2",
      "title": "Evening Shift",
      "start_date_time": "2024-01-16T16:00:00Z",
      "end_date_time": "2024-01-16T24:00:00Z",
      "schedule_type": "received_via_exchange",
      "exchange_request_id": "exchange-uuid",
      "exchange_status": "approved",
      "original_assignee_name": "Jane Smith",
      "exchange_requester_name": "Jane Smith",
      "assigned_user_name": "John Doe",
      "assigned_user_employee_id": "EMP001",
      "created_by_admin_name": "Admin User",
      "department": "Operations",
      "location": "Main Office"
    }
  ],
  "schedule_counts": {
    "total": 2,
    "assigned": 1,
    "received_via_exchange": 1,
    "given_via_exchange": 0
  }
}
```

**Schedule Types**:
- `assigned` - Directly assigned to the user
- `received_via_exchange` - Received through approved exchange
- `given_via_exchange` - Given away through approved exchange (for reference)

---

### 2. `get_employee_schedule_summary(p_user_id UUID, p_start_date DATE, p_end_date DATE)`
**Purpose**: Get schedule summary for a date range with exchange statistics.

**Parameters**:
- `p_user_id` (UUID) - Employee's user ID
- `p_start_date` (DATE) - Start date for summary
- `p_end_date` (DATE) - End date for summary

**Returns**: JSON object with daily schedule summaries

**Example Usage**:
```sql
-- Get schedule summary for a week
SELECT get_employee_schedule_summary(
    'user-uuid-here'::UUID,
    '2024-01-10'::DATE,
    '2024-01-17'::DATE
);
```

**Response Format**:
```json
{
  "success": true,
  "user_id": "user-uuid-here",
  "start_date": "2024-01-10",
  "end_date": "2024-01-17",
  "summary": [
    {
      "date": "2024-01-16",
      "total_schedules": 2,
      "assigned_schedules": 1,
      "received_schedules": 1,
      "given_schedules": 0,
      "total_hours": 16.0
    }
  ]
}
```

---

### 3. `check_schedule_exchange_eligibility(p_user_id UUID, p_schedule_id UUID)`
**Purpose**: Check if a user is eligible to exchange a specific schedule.

**Parameters**:
- `p_user_id` (UUID) - Employee's user ID
- `p_schedule_id` (UUID) - Schedule ID to check

**Returns**: JSON object with eligibility information

**Example Usage**:
```sql
-- Check if user can exchange a schedule
SELECT check_schedule_exchange_eligibility(
    'user-uuid-here'::UUID,
    'schedule-uuid-here'::UUID
);
```

**Response Format**:
```json
{
  "success": true,
  "eligibility": {
    "can_exchange": true,
    "reason": "Eligible for exchange",
    "schedule_info": {
      "id": "schedule-uuid",
      "title": "Morning Shift",
      "start_date_time": "2024-01-16T08:00:00Z",
      "end_date_time": "2024-01-16T16:00:00Z",
      "assigned_user_id": "user-uuid-here",
      "status": "active",
      "is_active": true,
      "created_at": "2024-01-15T10:00:00Z"
    },
    "user_info": {
      "id": "user-uuid-here",
      "full_name": "John Doe",
      "employee_id": "EMP001",
      "user_role": "employee",
      "is_active": true
    }
  }
}
```

**Eligibility Reasons**:
- `Eligible for exchange` - User can exchange the schedule
- `Schedule not found` - Schedule doesn't exist
- `User not found` - User doesn't exist
- `User not assigned to this schedule` - User doesn't own the schedule
- `Schedule is not active` - Schedule status is not active
- `Schedule is inactive` - Schedule is soft deleted
- `User is inactive` - User account is inactive
- `Schedule has already started` - Schedule is in the past

## 🛡️ Security Features

### Access Control
- All functions use `SECURITY DEFINER` for proper access control
- Functions can only be called by authorized users
- User ID validation ensures users only see their own schedules

### Data Integrity
- Comprehensive error handling with detailed error messages
- Transaction safety for complex queries
- Proper validation of user and schedule existence

## 📊 Database Schema Requirements

### Required Tables
- `employee_schedules` - Main schedule table
- `schedule_exchange_requests` - Exchange request tracking
- `my_users` - User information

### Required Columns
- `employee_schedules.assigned_user_id` - Current assignee
- `schedule_exchange_requests.requester_user_id` - Who requested exchange
- `schedule_exchange_requests.requested_user_id` - Who was requested
- `schedule_exchange_requests.status` - Exchange status

## 🚀 Flutter Integration

### Service Layer Integration
```dart
// In your Flutter service
Future<Map<String, dynamic>> getEmployeeSchedulesWithExchanges(String userId, DateTime date) async {
  final response = await _supabase.rpc('get_employee_schedules_with_exchanges', params: {
    'p_user_id': userId,
    'p_date': date.toIso8601String().split('T')[0],
    'p_include_exchanges': true,
  });
  return response;
}

Future<Map<String, dynamic>> getEmployeeScheduleSummary(String userId, DateTime startDate, DateTime endDate) async {
  final response = await _supabase.rpc('get_employee_schedule_summary', params: {
    'p_user_id': userId,
    'p_start_date': startDate.toIso8601String().split('T')[0],
    'p_end_date': endDate.toIso8601String().split('T')[0],
  });
  return response;
}

Future<Map<String, dynamic>> checkScheduleExchangeEligibility(String userId, String scheduleId) async {
  final response = await _supabase.rpc('check_schedule_exchange_eligibility', params: {
    'p_user_id': userId,
    'p_schedule_id': scheduleId,
  });
  return response;
}
```

### Controller Integration
```dart
// In your controller
Future<void> loadSchedulesForDate(DateTime date) async {
  try {
    final response = await getEmployeeSchedulesWithExchanges(currentUserId, date);
    
    if (response['success'] == true && response['schedules'] != null) {
      final schedulesData = List<Map<String, dynamic>>.from(response['schedules']);
      
      final List<ScheduleModel> loadedSchedules = [];
      for (final scheduleData in schedulesData) {
        final schedule = ScheduleModel.fromMap(scheduleData);
        loadedSchedules.add(schedule);
      }
      
      schedules.value = loadedSchedules;
      
      // Log schedule counts for debugging
      if (response['schedule_counts'] != null) {
        final counts = response['schedule_counts'];
        print('Schedule counts - Assigned: ${counts['assigned']}, Received: ${counts['received_via_exchange']}, Given: ${counts['given_via_exchange']}');
      }
    }
  } catch (e) {
    print('Error loading schedules: $e');
  }
}
```

### UI Integration
```dart
// In your UI, you can show schedule type
Widget buildScheduleCard(Map<String, dynamic> scheduleData) {
  final scheduleType = scheduleData['schedule_type'];
  final isExchange = scheduleType == 'received_via_exchange';
  
  return Card(
    child: ListTile(
      title: Text(scheduleData['title']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${scheduleData['start_date_time']} - ${scheduleData['end_date_time']}'),
          if (isExchange) ...[
            Text('🔄 Received via exchange from ${scheduleData['original_assignee_name']}'),
            Text('Exchange Status: ${scheduleData['exchange_status']}'),
          ],
        ],
      ),
    ),
  );
}
```

## 🧪 Testing

### Test Script Features
- Function existence verification
- Parameter validation testing
- Error handling verification
- Performance analysis
- Integration testing with real data

### Running Tests
1. Execute `sql/test_employee_schedule_fetching_rpc.sql` in Supabase
2. Review all test results
3. Check performance metrics
4. Verify error handling

## ⚠️ Important Notes

### Performance Considerations
- Functions use optimized queries with proper indexes
- Complex UNION queries may be slower for large datasets
- Consider pagination for date range queries

### Error Handling
- All functions return success/error status
- Detailed error messages for debugging
- Graceful fallback to direct queries in Flutter

### Data Consistency
- Functions handle soft-deleted schedules (`is_active = true`)
- Only approved exchanges are included
- Proper user validation

## 🔄 Migration from Direct Queries

### Before (Direct Queries)
```sql
-- Only shows directly assigned schedules
SELECT * FROM employee_schedules 
WHERE assigned_user_id = 'user-id' 
AND start_date_time >= 'date'
```

### After (RPC Functions)
```sql
-- Shows all schedules including exchanges
SELECT get_employee_schedules_with_exchanges('user-id', 'date', true);
```

This RPC-based approach provides comprehensive schedule fetching that handles the complexity of schedule exchanges while maintaining performance and security!
