# Schedule Management System Documentation

## Overview
The Rahiee AI schedule management system allows admins to create, manage, and track employee schedules with conflict detection and comprehensive functionality.

## Database Setup

### 1. Run the SQL Script
Execute `schedule_table_setup.sql` in your Supabase SQL Editor to create:
- `employee_schedules` table with all required fields
- Proper indexes for performance
- Row Level Security (RLS) policies
- Helper functions for conflict detection
- Automatic timestamp updates

### 2. Database Schema
```sql
employee_schedules:
- id (UUID, Primary Key)
- title (VARCHAR(255)) - Schedule title
- description (TEXT) - Detailed description
- start_date_time (TIMESTAMPTZ) - When schedule starts
- end_date_time (TIMESTAMPTZ) - When schedule ends
- created_by_admin_id (UUID) - Admin who created it
- assigned_user_id (UUID) - Employee assigned to schedule
- actual_user_id (UUID) - Who actually performed the task
- department (VARCHAR(100)) - Department classification
- location (VARCHAR(255)) - Work location
- latitude/longitude (DECIMAL) - GPS coordinates
- status (VARCHAR(50)) - 'active', 'completed', 'cancelled', 'reassigned'
- requirements (JSONB) - ML requirements, uniform checks, etc.
- notes (TEXT) - Additional notes
- is_active (BOOLEAN) - Soft delete flag
- tags (TEXT[]) - Categorization tags
- custom_fields (JSONB) - Future extensibility
- assignment_history (JSONB) - Change tracking
- created_at/updated_at (TIMESTAMPTZ) - Timestamps
```

## Code Architecture

### Services
- **SupabaseService**: Core database operations
- **ScheduleService**: Schedule-specific operations with conflict detection

### Controllers
- **ScheduleController**: Manages schedule display and filtering
- **AdminController**: Handles schedule creation and management

### Models
- **ScheduleModel**: Main schedule data model
- **UserModel**: Employee information

## Usage Examples

### 1. Create a Schedule
```dart
final scheduleService = ScheduleService.to;

final schedule = ScheduleModel(
  scheduleId: '', // Auto-generated
  title: 'Morning Kitchen Shift',
  description: 'Prepare breakfast menu',
  startDateTime: DateTime(2025, 9, 1, 8, 0),
  endDateTime: DateTime(2025, 9, 1, 12, 0),
  createdByAdminId: adminUserId,
  assignedUserId: employeeUserId,
  department: 'Kitchen',
  location: 'Main Kitchen',
  status: 'active',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  isActive: true,
);

bool success = await scheduleService.createSchedule(schedule);
```

### 2. Check for Conflicts
```dart
bool hasConflict = await scheduleService.checkConflicts(
  userId,
  startTime,
  endTime,
);

if (hasConflict) {
  print('Schedule conflict detected!');
}
```

### 3. Get Employee Schedules
```dart
List<ScheduleModel> schedules = await scheduleService.getSchedulesForUser(
  userId,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 7)),
);
```

### 4. Get Available Employees
```dart
List<UserModel> availableEmployees = await scheduleService.getAvailableEmployees(
  startTime,
  endTime,
  department: 'Kitchen', // Optional filter
);
```

### 5. Update Schedule Status
```dart
// Complete a schedule
await scheduleService.completeSchedule(scheduleId, actualUserId);

// Cancel a schedule
await scheduleService.cancelSchedule(scheduleId, 'Employee called in sick');

// Update status
await scheduleService.updateScheduleStatus(scheduleId, 'completed');
```

## Key Features

### 1. Conflict Detection
- Automatic detection of overlapping schedules
- Uses SQL function for performance
- Fallback to manual checking if needed

### 2. Security
- Row Level Security (RLS) enabled
- Users can only see relevant schedules
- Admins have full access
- Service role for system operations

### 3. Performance
- Optimized indexes on frequently queried fields
- Efficient date range queries
- Pagination support for large datasets

### 4. Flexibility
- JSONB fields for custom requirements
- Tag system for categorization
- Assignment history tracking
- GPS coordinates for location-based features

## Admin Functions

### Create Schedule
```dart
// In AdminController
final adminController = Get.find<AdminController>();
await adminController.createSchedule(
  title: 'Evening Cleaning',
  description: 'Deep clean restaurant',
  selectedUsers: [user1, user2],
  startDateTime: startTime,
  endDateTime: endTime,
);
```

### View Schedules
```dart
// In ScheduleController
final scheduleController = Get.find<ScheduleController>();
await scheduleController.loadSchedulesForDate(selectedDate);

// Access organized schedules
Map<String, List<ScheduleDisplayModel>> byRole = scheduleController.schedulesByRole;
Map<String, List<ScheduleDisplayModel>> byDept = scheduleController.schedulesByDepartment;
```

## Database Functions

### 1. check_schedule_conflict()
Checks for time overlaps between schedules for the same user.

### 2. get_employee_schedules()
Returns formatted schedule data for a specific employee.

### 3. get_schedules_by_department()
Returns all schedules for a department within a date range.

## Error Handling

All service methods include comprehensive error handling:
- Try-catch blocks for all database operations
- Meaningful error messages
- Fallback mechanisms for critical functions
- Logging for debugging

## Future Enhancements

1. **Push Notifications**: Schedule reminders and updates
2. **Real-time Updates**: Live schedule changes using Supabase realtime
3. **Recurring Schedules**: Template-based recurring assignments
4. **Mobile GPS**: Location verification for schedule completion
5. **Analytics**: Schedule efficiency and completion metrics

## Testing

1. Create the database table using the SQL script
2. Test basic CRUD operations through the UI
3. Verify conflict detection works correctly
4. Check RLS policies prevent unauthorized access
5. Test with multiple users and departments

## Troubleshooting

### Common Issues

1. **RLS Policy Errors**: Ensure user is properly authenticated
2. **Conflict Detection**: Check date/time formats are correct
3. **Missing Schedules**: Verify `is_active = true` filter
4. **Permission Denied**: Check user role and policies

### Debug Commands
```dart
// Test database connection
await SupabaseService.to.testDatabaseConnection();

// Check conflict function
final result = await SupabaseService.to.client.rpc('check_schedule_conflict', params: {
  'p_assigned_user_id': userId,
  'p_start_time': startTime.toIso8601String(),
  'p_end_time': endTime.toIso8601String(),
});
```

This schedule management system provides a robust foundation for employee scheduling with room for future enhancements and scalability.
