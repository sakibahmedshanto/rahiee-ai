import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for admin schedule management operations
class AdminScheduleService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates a new schedule
  /// 
  /// Required parameters:
  /// - [adminId]: UUID of the admin creating the schedule
  /// - [title]: Schedule title 
  /// - [startDateTime]: Schedule start time
  /// - [endDateTime]: Schedule end time
  /// - [assignedUserId]: UUID of user assigned to this schedule
  /// - [department]: Department for this schedule
  /// - [location]: Location of the schedule
  /// 
  /// Optional parameters:
  /// - [description]: Additional description
  /// - [latitude], [longitude]: GPS coordinates
  /// - [requirements]: JSON object with special requirements
  /// - [notes]: Additional notes
  /// - [tags]: Array of tags
  /// - [customFields]: JSON object with custom fields
  static Future<Map<String, dynamic>> createSchedule({
    required String adminId,
    required String title,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String assignedUserId,
    required String department,
    required String location,
    String? description,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? requirements,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final response = await _supabase.rpc('admin_create_schedule', params: {
        'p_admin_id': adminId,
        'p_title': title,
        'p_start_date_time': startDateTime.toIso8601String(),
        'p_end_date_time': endDateTime.toIso8601String(),
        'p_assigned_user_id': assignedUserId,
        'p_department': department,
        'p_location': location,
        'p_description': description,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_requirements': requirements,
        'p_notes': notes,
        'p_tags': tags,
        'p_custom_fields': customFields,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response,
          'message': response['message'] ?? 'Schedule created successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to create schedule',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating schedule: $e',
      };
    }
  }

  /// Gets all schedules with filtering options
  /// 
  /// Parameters:
  /// - [adminId]: UUID of the admin requesting schedules
  /// - [startDate]: Filter schedules starting from this date
  /// - [endDate]: Filter schedules ending before this date
  /// - [department]: Filter by department (partial match)
  /// - [status]: Filter by status (active, completed, cancelled, etc.)
  /// - [assignedUserId]: Filter by assigned user
  static Future<Map<String, dynamic>> getSchedules({
    required String adminId,
    DateTime? startDate,
    DateTime? endDate,
    String? department,
    String? status,
    String? assignedUserId,
  }) async {
    try {
      final params = {
        'p_admin_id': adminId,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
        'p_department': department,
        'p_status': status,
        'p_assigned_user_id': assignedUserId,
      };
      
      final response = await _supabase.rpc('admin_get_schedules', params: params);

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['schedules'] ?? [],
          'totalCount': response['total_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to fetch schedules',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching schedules: $e',
      };
    }
  }

  /// Updates an existing schedule
  /// 
  /// Required parameters:
  /// - [adminId]: UUID of the admin updating the schedule
  /// - [scheduleId]: UUID of the schedule to update
  /// 
  /// Optional parameters (only provided fields will be updated):
  /// - All the same optional parameters as createSchedule
  static Future<Map<String, dynamic>> updateSchedule({
    required String adminId,
    required String scheduleId,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? assignedUserId,
    String? department,
    String? location,
    double? latitude,
    double? longitude,
    String? status,
    Map<String, dynamic>? requirements,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final response = await _supabase.rpc('admin_update_schedule', params: {
        'p_admin_id': adminId,
        'p_schedule_id': scheduleId,
        'p_title': title,
        'p_description': description,
        'p_start_date_time': startDateTime?.toIso8601String(),
        'p_end_date_time': endDateTime?.toIso8601String(),
        'p_assigned_user_id': assignedUserId,
        'p_department': department,
        'p_location': location,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_status': status,
        'p_requirements': requirements,
        'p_notes': notes,
        'p_tags': tags,
        'p_custom_fields': customFields,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Schedule updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to update schedule',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error updating schedule: $e',
      };
    }
  }

  /// Deletes or deactivates a schedule
  /// 
  /// Parameters:
  /// - [adminId]: UUID of the admin deleting the schedule
  /// - [scheduleId]: UUID of the schedule to delete
  /// - [softDelete]: If true, marks as inactive; if false, permanently deletes
  static Future<Map<String, dynamic>> deleteSchedule({
    required String adminId,
    required String scheduleId,
    bool softDelete = true,
  }) async {
    try {
      final response = await _supabase.rpc('admin_delete_schedule', params: {
        'p_admin_id': adminId,
        'p_schedule_id': scheduleId,
        'p_soft_delete': softDelete,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Schedule deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to delete schedule',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error deleting schedule: $e',
      };
    }
  }

  /// Gets available users for schedule assignment
  /// 
  /// Parameters:
  /// - [adminId]: UUID of the admin requesting users
  /// - [startDateTime]: Check availability from this time
  /// - [endDateTime]: Check availability until this time
  /// - [department]: Filter users by department
  static Future<Map<String, dynamic>> getAvailableUsers({
    required String adminId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? department,
  }) async {
    try {
      final params = {
        'p_admin_id': adminId,
        'p_start_date_time': startDateTime?.toIso8601String(),
        'p_end_date_time': endDateTime?.toIso8601String(),
        'p_department': department,
      };
      
      final response = await _supabase.rpc('admin_get_available_users', params: params);

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['users'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to fetch available users',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching available users: $e',
      };
    }
  }

  /// Checks if a user is available for a given time slot
  /// Uses existing check_schedule_conflict function
  static Future<Map<String, dynamic>> checkScheduleConflict({
    required String userId,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? excludeScheduleId,
  }) async {
    try {
      final response = await _supabase.rpc('check_schedule_conflict', params: {
        'user_id': userId,
        'start_time': startDateTime.toIso8601String(),
        'end_time': endDateTime.toIso8601String(),
        'exclude_schedule_id': excludeScheduleId,
      });

      return {
        'success': true,
        'hasConflict': response == true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error checking schedule conflict: $e',
      };
    }
  }
}