import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for multi-user schedule management operations
/// Handles assigning multiple users to a single schedule
class MultiUserScheduleService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Assigns multiple users to a schedule
  /// 
  /// Parameters:
  /// - [scheduleId]: UUID of the schedule
  /// - [userIds]: List of user UUIDs to assign
  /// - [adminId]: UUID of the admin making the assignment
  /// - [notes]: Optional notes about the assignment
  static Future<Map<String, dynamic>> assignUsersToSchedule({
    required String scheduleId,
    required List<String> userIds,
    required String adminId,
    String? notes,
  }) async {
    try {
      final response = await _supabase.rpc('assign_users_to_schedule', params: {
        'p_schedule_id': scheduleId,
        'p_user_ids': userIds,
        'p_admin_id': adminId,
        'p_notes': notes,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'assigned_count': response['assigned_count'] ?? 0,
          'failed_count': response['failed_count'] ?? 0,
          'results': response['results'] ?? [],
          'message': 'Successfully assigned ${response['assigned_count']} user(s) to schedule',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to assign users to schedule',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error assigning users to schedule: $e',
      };
    }
  }

  /// Removes a user from a schedule
  /// 
  /// Parameters:
  /// - [scheduleId]: UUID of the schedule
  /// - [userId]: UUID of the user to remove
  /// - [adminId]: UUID of the admin making the change
  /// - [reason]: Optional reason for removal
  static Future<Map<String, dynamic>> removeUserFromSchedule({
    required String scheduleId,
    required String userId,
    required String adminId,
    String? reason,
  }) async {
    try {
      final response = await _supabase.rpc('remove_user_from_schedule', params: {
        'p_schedule_id': scheduleId,
        'p_user_id': userId,
        'p_admin_id': adminId,
        'p_reason': reason,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'User removed from schedule successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to remove user from schedule',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error removing user from schedule: $e',
      };
    }
  }

  /// Gets schedules with their assigned users
  /// 
  /// Parameters:
  /// - [scheduleId]: Optional UUID of specific schedule
  /// - [date]: Optional date to filter schedules
  /// - [department]: Optional department to filter schedules
  static Future<Map<String, dynamic>> getScheduleWithAssignments({
    String? scheduleId,
    DateTime? date,
    String? department,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (scheduleId != null) params['p_schedule_id'] = scheduleId;
      if (date != null) params['p_date'] = date.toIso8601String().split('T')[0];
      if (department != null) params['p_department'] = department;

      final response = await _supabase.rpc('get_schedule_with_assignments', params: params);

      if (response['success'] == true) {
        return {
          'success': true,
          'schedules': response['schedules'] ?? [],
          'total_count': response['total_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to get schedules',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting schedules with assignments: $e',
        'schedules': [],
        'total_count': 0,
      };
    }
  }

  /// Gets available users for schedule assignment
  /// Filters out users who are already assigned or have conflicting schedules
  /// 
  /// Parameters:
  /// - [scheduleId]: UUID of the schedule
  /// - [department]: Optional department filter
  static Future<Map<String, dynamic>> getAvailableUsersForSchedule({
    required String scheduleId,
    String? department,
  }) async {
    try {
      final params = {
        'p_schedule_id': scheduleId,
        if (department != null) 'p_department': department,
      };

      final response = await _supabase.rpc('get_available_users_for_schedule', params: params);

      if (response['success'] == true) {
        return {
          'success': true,
          'available_users': response['available_users'] ?? [],
          'schedule_time': response['schedule_time'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to get available users',
          'available_users': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting available users: $e',
        'available_users': [],
      };
    }
  }

  /// Gets all schedule assignments for a specific schedule
  /// 
  /// Parameters:
  /// - [scheduleId]: UUID of the schedule
  static Future<Map<String, dynamic>> getScheduleAssignments({
    required String scheduleId,
  }) async {
    try {
      final response = await _supabase
          .from('schedule_assignments')
          .select('''
            *,
            user:my_users!user_id (
              id,
              employee_id,
              full_name,
              email,
              department,
              position,
              user_img
            )
          ''')
          .eq('schedule_id', scheduleId)
          .eq('is_active', true)
          .order('assigned_at', ascending: true);

      return {
        'success': true,
        'assignments': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting schedule assignments: $e',
        'assignments': [],
      };
    }
  }

  /// Gets all schedules a user is assigned to
  /// 
  /// Parameters:
  /// - [userId]: UUID of the user
  /// - [date]: Optional date to filter schedules
  static Future<Map<String, dynamic>> getUserAssignments({
    required String userId,
    DateTime? date,
  }) async {
    try {
      var query = _supabase
          .from('schedule_assignments')
          .select('''
            *,
            schedule:employee_schedules!schedule_id (
              id,
              title,
              description,
              start_date_time,
              end_date_time,
              location,
              department,
              status,
              is_multi_user,
              current_participants,
              max_participants
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('status', 'active');

      if (date != null) {
        // Filter by date on the schedule
        // Note: This is a client-side filter since we can't easily filter JSON in Supabase
        final response = await query;
        final filteredResponse = response.where((assignment) {
          final schedule = assignment['schedule'];
          if (schedule == null) return false;
          final startDateTime = DateTime.parse(schedule['start_date_time']);
          return startDateTime.year == date.year &&
              startDateTime.month == date.month &&
              startDateTime.day == date.day;
        }).toList();

        return {
          'success': true,
          'assignments': filteredResponse,
        };
      }

      final response = await query;
      return {
        'success': true,
        'assignments': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting user assignments: $e',
        'assignments': [],
      };
    }
  }

  /// Updates an assignment's notes or status
  /// 
  /// Parameters:
  /// - [scheduleId]: UUID of the schedule
  /// - [userId]: UUID of the user
  /// - [notes]: Optional updated notes
  /// - [status]: Optional updated status
  static Future<Map<String, dynamic>> updateAssignment({
    required String scheduleId,
    required String userId,
    String? notes,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (notes != null) updates['notes'] = notes;
      if (status != null) updates['status'] = status;

      await _supabase
          .from('schedule_assignments')
          .update(updates)
          .eq('schedule_id', scheduleId)
          .eq('user_id', userId);

      return {
        'success': true,
        'message': 'Assignment updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error updating assignment: $e',
      };
    }
  }
}

