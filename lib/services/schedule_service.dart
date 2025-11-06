// ignore_for_file: file_names
import 'package:get/get.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class ScheduleService extends GetxService {
  static ScheduleService get to => Get.find();
  
  final SupabaseService _supabaseService = SupabaseService.to;

  // Create a new schedule
  Future<bool> createSchedule(ScheduleModel schedule) async {
    try {
      print('🔄 Creating schedule with data:');
      final scheduleData = schedule.toMap();
      print('📋 Schedule data: $scheduleData');
      
      await _supabaseService.insert('employee_schedules', scheduleData);
      print('✅ Schedule created successfully: ${schedule.title}');
      return true;
    } catch (e) {
      print('❌ Error creating schedule: $e');
      print('❌ Schedule data was: ${schedule.toMap()}');
      return false;
    }
  }

  // Get schedules for a specific user with timezone-aware status
  Future<List<ScheduleModel>> getSchedulesForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use the new timezone-aware RPC function
      final response = await _supabaseService.client?.rpc('get_schedules_with_timezone_status', params: {
        'p_user_id': userId,
        'p_date': startDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
      });

      print('DEBUG: Timezone-aware RPC response for user schedules: $response');
      print('DEBUG: Response type: ${response.runtimeType}');

      if (response != null && response['success'] == true) {
        // Check if schedules exist in the response
        if (response['schedules'] != null) {
          final schedulesData = List<Map<String, dynamic>>.from(response['schedules']);
          print('DEBUG: Found ${schedulesData.length} schedules with timezone status');
          print('DEBUG: Current UTC time: ${response['current_time_utc']}');
          print('DEBUG: Total schedules: ${response['total_schedules']}');
          print('DEBUG: Completed: ${response['completed_schedules']}, Active: ${response['active_schedules']}, Expired: ${response['expired_schedules']}');
          return schedulesData
              .map((data) => ScheduleModel.fromMap(data))
              .toList();
        } else {
          print('DEBUG: No schedules key in response, falling back to direct query');
          return await _getSchedulesForUserDirect(userId, startDate: startDate, endDate: endDate);
        }
      } else {
        print('DEBUG: RPC response is null, falling back to direct query');
        return await _getSchedulesForUserDirect(userId, startDate: startDate, endDate: endDate);
      }
    } catch (e) {
      print('❌ Error getting user schedules with RPC: $e');
      return await _getSchedulesForUserDirect(userId, startDate: startDate, endDate: endDate);
    }
  }

  // Fallback method for direct schedule fetching
  Future<List<ScheduleModel>> _getSchedulesForUserDirect(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? start.add(Duration(days: 7));
      
      final List<Map<String, dynamic>> schedulesData = await _supabaseService.select(
        'employee_schedules',
        eq: 'assigned_user_id',
        eqValue: userId,
        gte: 'start_date_time',
        gteValue: start.toIso8601String(),
        lte: 'start_date_time', 
        lteValue: end.toIso8601String(),
        orderBy: 'start_date_time',
      );

      return schedulesData
          .map((data) => ScheduleModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error getting user schedules (direct): $e');
      return [];
    }
  }

  // Get schedules for a specific date
  Future<List<ScheduleModel>> getSchedulesForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final List<Map<String, dynamic>> schedulesData = await _supabaseService.select(
        'employee_schedules',
        gte: 'start_date_time',
        gteValue: startOfDay.toIso8601String(),
        lte: 'start_date_time',
        lteValue: endOfDay.toIso8601String(),
        eq: 'is_active',
        eqValue: true,
        orderBy: 'start_date_time',
      );

      return schedulesData
          .map((data) => ScheduleModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error getting schedules for date: $e');
      return [];
    }
  }

  // Get schedules by department
  Future<List<ScheduleModel>> getSchedulesByDepartment(
    String department, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? start.add(Duration(days: 7));
      
      final List<Map<String, dynamic>> schedulesData = await _supabaseService.select(
        'employee_schedules',
        eq: 'department',
        eqValue: department,
        gte: 'start_date_time',
        gteValue: start.toIso8601String(),
        lte: 'start_date_time',
        lteValue: end.toIso8601String(),
        orderBy: 'start_date_time',
      );

      // Filter for active schedules
      return schedulesData
          .where((data) => data['is_active'] == true)
          .map((data) => ScheduleModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error getting schedules by department: $e');
      return [];
    }
  }

  // Update schedule status
  Future<bool> updateScheduleStatus(String scheduleId, String status) async {
    try {
      await _supabaseService.update(
        'employee_schedules',
        {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
        eq: 'id',
        eqValue: scheduleId,
      );
      print('✅ Schedule status updated to: $status');
      return true;
    } catch (e) {
      print('❌ Error updating schedule status: $e');
      return false;
    }
  }

  // Complete a schedule
  Future<bool> completeSchedule(String scheduleId, String actualUserId) async {
    try {
      await _supabaseService.update(
        'employee_schedules',
        {
          'status': 'completed',
          'actual_user_id': actualUserId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        eq: 'id',
        eqValue: scheduleId,
      );
      print('✅ Schedule completed');
      return true;
    } catch (e) {
      print('❌ Error completing schedule: $e');
      return false;
    }
  }

  // Cancel a schedule
  Future<bool> cancelSchedule(String scheduleId, String reason) async {
    try {
      await _supabaseService.update(
        'employee_schedules',
        {
          'status': 'cancelled',
          'notes': reason,
          'updated_at': DateTime.now().toIso8601String(),
        },
        eq: 'id',
        eqValue: scheduleId,
      );
      print('✅ Schedule cancelled');
      return true;
    } catch (e) {
      print('❌ Error cancelling schedule: $e');
      return false;
    }
  }

  // Check for schedule conflicts
  Future<bool> checkConflicts(
    String userId,
    DateTime startTime,
    DateTime endTime, {
    String? excludeScheduleId,
  }) async {
    try {
      // Use the SQL function we created
      final client = _supabaseService.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }
      
      final result = await client.rpc('check_schedule_conflict', params: {
        'p_assigned_user_id': userId,
        'p_start_time': startTime.toIso8601String(),
        'p_end_time': endTime.toIso8601String(),
        'p_exclude_schedule_id': excludeScheduleId,
      });

      return result as bool? ?? false;
    } catch (e) {
      print('❌ Error checking conflicts: $e');
      // Fallback to manual check
      return await _manualConflictCheck(userId, startTime, endTime, excludeScheduleId);
    }
  }

  // Manual conflict check fallback
  Future<bool> _manualConflictCheck(
    String userId,
    DateTime startTime,
    DateTime endTime,
    String? excludeScheduleId,
  ) async {
    try {
      final conflicts = await _supabaseService.select(
        'employee_schedules',
        eq: 'assigned_user_id',
        eqValue: userId,
      );

      for (final conflict in conflicts) {
        // Skip if not active or completed/cancelled
        if (conflict['is_active'] != true) continue;
        if (conflict['status'] == 'cancelled' || conflict['status'] == 'completed') continue;
        
        if (excludeScheduleId != null && conflict['id'] == excludeScheduleId) {
          continue;
        }

        final existingStart = DateTime.parse(conflict['start_date_time']);
        final existingEnd = DateTime.parse(conflict['end_date_time']);

        // Check for time overlap
        if ((startTime.isBefore(existingEnd) && endTime.isAfter(existingStart))) {
          return true; // Conflict found
        }
      }

      return false; // No conflicts
    } catch (e) {
      print('❌ Error in manual conflict check: $e');
      return false;
    }
  }

  // Get available employees for a time slot
  Future<List<UserModel>> getAvailableEmployees(
    DateTime startTime,
    DateTime endTime, {
    String? department,
  }) async {
    try {
      // First get all active users
      final List<Map<String, dynamic>> usersData = await _supabaseService.select(
        'my_users',
        eq: 'is_active',
        eqValue: true,
        orderBy: 'full_name',
      );

      List<UserModel> allUsers = usersData
          .map((data) => UserModel.fromMap(data))
          .where((user) => !user.isAdmin) // Exclude admins
          .where((user) => department == null || user.department == department)
          .toList();

      // Filter out users who have conflicts
      List<UserModel> availableUsers = [];
      for (UserModel user in allUsers) {
        bool hasConflict = await checkConflicts(user.uId, startTime, endTime);
        if (!hasConflict) {
          availableUsers.add(user);
        }
      }

      return availableUsers;
    } catch (e) {
      print('❌ Error getting available employees: $e');
      return [];
    }
  }

  // Get all schedules with pagination
  Future<List<ScheduleModel>> getAllSchedules({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final List<Map<String, dynamic>> schedulesData = await _supabaseService.select(
        'employee_schedules',
        eq: 'is_active',
        eqValue: true,
        orderBy: 'start_date_time',
        limit: limit,
      );

      // Apply manual offset if needed
      final filteredData = offset > 0 
          ? schedulesData.skip(offset).toList()
          : schedulesData;

      return filteredData
          .map((data) => ScheduleModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error getting all schedules: $e');
      return [];
    }
  }
}
