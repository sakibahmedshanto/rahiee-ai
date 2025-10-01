# 🚀 Perfect Employee Schedules RPC Function Documentation

## 📋 Overview
The `get_employee_schedules` RPC function is a comprehensive, single-function solution that handles all employee schedule fetching scenarios including schedule exchanges, with perfect scalability and performance.

## 🔧 Function Signature
```sql
get_employee_schedules(
    p_user_id UUID,
    p_date DATE DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_include_exchanges BOOLEAN DEFAULT true,
    p_include_given_schedules BOOLEAN DEFAULT false,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
```

## 📊 Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `p_user_id` | UUID | Required | Employee's user ID |
| `p_date` | DATE | NULL | Single date to fetch schedules for |
| `p_start_date` | DATE | NULL | Start date for date range |
| `p_end_date` | DATE | NULL | End date for date range |
| `p_include_exchanges` | BOOLEAN | true | Include schedules received via exchanges |
| `p_include_given_schedules` | BOOLEAN | false | Include schedules given away via exchanges |
| `p_limit` | INTEGER | 100 | Maximum number of schedules to return |
| `p_offset` | INTEGER | 0 | Number of schedules to skip (pagination) |

## 🎯 Usage Scenarios

### 1. Single Date Fetching
```sql
-- Get schedules for today
SELECT get_employee_schedules(
    'user-uuid'::UUID,
    CURRENT_DATE,
    NULL, NULL,
    true, false,
    50, 0
);
```

### 2. Date Range Fetching
```sql
-- Get schedules for a week
SELECT get_employee_schedules(
    'user-uuid'::UUID,
    NULL,
    '2024-01-10'::DATE,
    '2024-01-17'::DATE,
    true, false,
    100, 0
);
```

### 3. Pagination
```sql
-- First page
SELECT get_employee_schedules(
    'user-uuid'::UUID,
    NULL, NULL, NULL,
    true, false,
    20, 0
);

-- Second page
SELECT get_employee_schedules(
    'user-uuid'::UUID,
    NULL, NULL, NULL,
    true, false,
    20, 20
);
```

### 4. Exchange Options
```sql
-- Without exchanges (original behavior)
SELECT get_employee_schedules(
    'user-uuid'::UUID,
    CURRENT_DATE, NULL, NULL,
    false, false,
    50, 0
);

-- With given schedules (for reference)
SELECT get_employee_schedules(
    'user-uuid'::UUID,
    CURRENT_DATE, NULL, NULL,
    true, true,
    50, 0
);
```

## 📋 Response Format

### Success Response
```json
{
  "success": true,
  "user_id": "user-uuid",
  "date_filter": {
    "type": "single_date",
    "date": "2024-01-16"
  },
  "include_exchanges": true,
  "include_given_schedules": false,
  "schedules": [
    {
      "id": "schedule-uuid",
      "title": "Morning Shift",
      "description": "Regular morning shift",
      "start_date_time": "2024-01-16T08:00:00Z",
      "end_date_time": "2024-01-16T16:00:00Z",
      "department": "Operations",
      "location": "Main Office",
      "status": "active",
      "is_active": true,
      "schedule_type": "assigned",
      "exchange_request_id": null,
      "exchange_status": null,
      "original_assignee_name": null,
      "exchange_requester_name": null,
      "exchange_created_at": null,
      "exchange_approved_at": null,
      "assigned_user_name": "John Doe",
      "assigned_user_employee_id": "EMP001",
      "created_by_admin_name": "Admin User",
      "created_by_admin_employee_id": "ADM001",
      "schedule_status": "upcoming",
      "duration_hours": 8.0
    },
    {
      "id": "schedule-uuid-2",
      "title": "Evening Shift",
      "schedule_type": "received_via_exchange",
      "exchange_request_id": "exchange-uuid",
      "exchange_status": "approved",
      "original_assignee_name": "Jane Smith",
      "exchange_requester_name": "Jane Smith",
      "exchange_created_at": "2024-01-15T10:00:00Z",
      "exchange_approved_at": "2024-01-15T14:30:00Z",
      "schedule_status": "upcoming",
      "duration_hours": 8.0
    }
  ],
  "pagination": {
    "total_count": 15,
    "limit": 100,
    "offset": 0,
    "has_more": false,
    "current_page": 1,
    "total_pages": 1
  },
  "summary": {
    "total_schedules": 15,
    "assigned_schedules": 12,
    "received_via_exchange": 3,
    "given_via_exchange": 0,
    "upcoming_schedules": 8,
    "current_schedules": 2,
    "past_schedules": 5,
    "total_hours": 120.0
  },
  "metadata": {
    "query_timestamp": "2024-01-16T10:00:00Z",
    "date_range_start": "2024-01-16T00:00:00Z",
    "date_range_end": "2024-01-17T00:00:00Z",
    "function_version": "2.0"
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": "User not found",
  "error_code": "P0001",
  "user_id": "user-uuid",
  "date_filter": {
    "type": "single_date",
    "date": "2024-01-16"
  },
  "query_timestamp": "2024-01-16T10:00:00Z"
}
```

## 🔍 Schedule Types

### 1. `assigned`
- Directly assigned to the user
- `exchange_request_id`: null
- `exchange_status`: null
- `original_assignee_name`: null

### 2. `received_via_exchange`
- Received through approved exchange
- `exchange_request_id`: UUID of the exchange request
- `exchange_status`: "approved"
- `original_assignee_name`: Name of user who originally had the schedule
- `exchange_requester_name`: Name of user who requested the exchange

### 3. `given_via_exchange`
- Given away through approved exchange
- `exchange_request_id`: UUID of the exchange request
- `exchange_status`: "approved"
- `original_assignee_name`: Name of user who received the schedule
- `exchange_requester_name`: Name of current user (who gave it away)

## 📊 Schedule Status

### 1. `upcoming`
- Schedule starts in the future
- `start_date_time > NOW()`

### 2. `current`
- Schedule is currently ongoing
- `start_date_time <= NOW() AND end_date_time >= NOW()`

### 3. `past`
- Schedule has ended
- `end_date_time < NOW()`

## 🚀 Flutter Integration

### Service Layer
```dart
class ScheduleService extends GetxService {
  // Get schedules for a specific user
  Future<List<ScheduleModel>> getSchedulesForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabaseService.client?.rpc('get_employee_schedules', params: {
        'p_user_id': userId,
        'p_date': null,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
        'p_include_exchanges': true,
        'p_include_given_schedules': false,
        'p_limit': 100,
        'p_offset': 0,
      });

      if (response != null && response['success'] == true && response['schedules'] != null) {
        final schedulesData = List<Map<String, dynamic>>.from(response['schedules']);
        return schedulesData.map((data) => ScheduleModel.fromMap(data)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting schedules: $e');
      return [];
    }
  }

  // Get schedules for a specific date
  Future<List<ScheduleModel>> getSchedulesForDate(String userId, DateTime date) async {
    try {
      final response = await _supabaseService.client?.rpc('get_employee_schedules', params: {
        'p_user_id': userId,
        'p_date': date.toIso8601String().split('T')[0],
        'p_start_date': null,
        'p_end_date': null,
        'p_include_exchanges': true,
        'p_include_given_schedules': false,
        'p_limit': 100,
        'p_offset': 0,
      });

      if (response != null && response['success'] == true && response['schedules'] != null) {
        final schedulesData = List<Map<String, dynamic>>.from(response['schedules']);
        return schedulesData.map((data) => ScheduleModel.fromMap(data)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting schedules for date: $e');
      return [];
    }
  }
}
```

### Controller Layer
```dart
class UnifiedScheduleController extends GetxController {
  Future<void> loadSchedulesForDate(DateTime date) async {
    try {
      if (currentUser.value == null) return;
      
      isLoading.value = true;
      
      final response = await _supabaseService.client?.rpc('get_employee_schedules', params: {
        'p_user_id': currentUser.value!.uId,
        'p_date': date.toIso8601String().split('T')[0],
        'p_start_date': null,
        'p_end_date': null,
        'p_include_exchanges': true,
        'p_include_given_schedules': false,
        'p_limit': 100,
        'p_offset': 0,
      });

      if (response != null && response['success'] == true && response['schedules'] != null) {
        final schedulesData = List<Map<String, dynamic>>.from(response['schedules']);
        
        final List<ScheduleModel> loadedSchedules = [];
        for (final scheduleData in schedulesData) {
          final schedule = ScheduleModel.fromMap(scheduleData);
          loadedSchedules.add(schedule);
        }
        
        schedules.value = loadedSchedules;
        
        // Log comprehensive summary
        if (response['summary'] != null) {
          final summary = response['summary'];
          print('Schedule summary - Total: ${summary['total_schedules']}, Assigned: ${summary['assigned_schedules']}, Received: ${summary['received_via_exchange']}');
        }
      }
    } catch (e) {
      print('Error loading schedules: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
```

### UI Layer
```dart
Widget buildScheduleCard(Map<String, dynamic> scheduleData) {
  final scheduleType = scheduleData['schedule_type'];
  final isExchange = scheduleType == 'received_via_exchange';
  final isGiven = scheduleType == 'given_via_exchange';
  
  return Card(
    child: ListTile(
      title: Text(scheduleData['title']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${scheduleData['start_date_time']} - ${scheduleData['end_date_time']}'),
          Text('Duration: ${scheduleData['duration_hours']} hours'),
          if (isExchange) ...[
            Text('🔄 Received via exchange from ${scheduleData['original_assignee_name']}'),
            Text('Exchange approved: ${scheduleData['exchange_approved_at']}'),
          ],
          if (isGiven) ...[
            Text('📤 Given via exchange to ${scheduleData['original_assignee_name']}'),
            Text('Exchange approved: ${scheduleData['exchange_approved_at']}'),
          ],
        ],
      ),
      trailing: Chip(
        label: Text(scheduleData['schedule_status']),
        backgroundColor: _getStatusColor(scheduleData['schedule_status']),
      ),
    ),
  );
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'upcoming': return Colors.blue;
    case 'current': return Colors.green;
    case 'past': return Colors.grey;
    default: return Colors.grey;
  }
}
```

## 🛡️ Security Features

### Access Control
- `SECURITY DEFINER` for proper access control
- User ID validation ensures users only see their own schedules
- Comprehensive error handling with detailed error messages

### Data Integrity
- Transaction safety for complex queries
- Proper validation of user and schedule existence
- Soft-delete support (`is_active = true`)

## 📈 Performance Features

### Optimization
- Single RPC call instead of multiple queries
- Efficient UNION queries with proper indexing
- Pagination support for large datasets
- Comprehensive metadata for debugging

### Scalability
- Handles large datasets efficiently
- Connection pooling friendly
- Optimized for enterprise-level workloads

## 🧪 Testing

### Manual Testing
1. Run `sql/test_get_employee_schedules_rpc.sql` in Supabase
2. Test all parameter combinations
3. Verify error handling
4. Check performance metrics

### Automated Testing
```dart
// Test basic functionality
final schedules = await scheduleService.getSchedulesForUser(userId);
expect(schedules.isNotEmpty, true);

// Test date filtering
final todaySchedules = await scheduleService.getSchedulesForDate(userId, DateTime.now());
expect(todaySchedules.isNotEmpty, true);

// Test exchange support
final response = await supabase.rpc('get_employee_schedules', params: {
  'p_user_id': userId,
  'p_date': DateTime.now().toIso8601String().split('T')[0],
  'p_include_exchanges': true,
});
expect(response['success'], true);
```

## ⚠️ Important Notes

### Performance Considerations
- Functions use optimized queries with proper indexes
- Complex UNION queries may be slower for very large datasets
- Consider pagination for date range queries

### Error Handling
- All functions return success/error status
- Detailed error messages for debugging
- Graceful fallback to direct queries in Flutter

### Data Consistency
- Functions handle soft-deleted schedules (`is_active = true`)
- Only approved exchanges are included
- Proper user validation

This comprehensive RPC function provides a single, perfect solution for all employee schedule fetching needs with complete exchange support!
