import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing schedule exchange requests
class ScheduleExchangeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates a new schedule exchange request
  static Future<Map<String, dynamic>> createExchangeRequest({
    required String requesterUserId,
    required String scheduleId,
    required String requestedUserId,
    String? requestReason,
    String? requestNotes,
    String requestType = 'exchange',
    int expiresInDays = 7,
  }) async {
    try {
      final response = await _supabase.rpc('create_schedule_exchange_request', params: {
        'p_requester_user_id': requesterUserId,
        'p_schedule_id': scheduleId,
        'p_requested_user_id': requestedUserId,
        'p_request_reason': requestReason,
        'p_request_notes': requestNotes,
        'p_request_type': requestType,
        'p_expires_in_days': expiresInDays,
      });

      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create exchange request: $e',
      };
    }
  }

  /// Admin manages exchange request (approve/reject/cancel)
  static Future<Map<String, dynamic>> manageExchangeRequest({
    required String adminId,
    required String requestId,
    required String action, // 'approve', 'reject', 'cancel'
    String? adminNotes,
    String? rejectionReason,
  }) async {
    try {
      final response = await _supabase.rpc('admin_manage_schedule_exchange_request', params: {
        'p_admin_id': adminId,
        'p_request_id': requestId,
        'p_action': action,
        'p_admin_notes': adminNotes,
        'p_rejection_reason': rejectionReason,
      });

      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to $action exchange request: $e',
      };
    }
  }

  /// Gets exchange requests with filtering
  static Future<Map<String, dynamic>> getExchangeRequests({
    String? userId,
    String? status,
    String? requestType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('DEBUG: getExchangeRequests called with userId: $userId, status: $status, requestType: $requestType');
      
      final response = await _supabase.rpc('get_schedule_exchange_requests', params: {
        'p_user_id': userId,
        'p_status': status,
        'p_request_type': requestType,
        'p_limit': limit,
        'p_offset': offset,
      });

      print('DEBUG: RPC response: $response');
      return response;
    } catch (e) {
      print('DEBUG: RPC error: $e');
      return {
        'success': false,
        'error': 'Failed to fetch exchange requests: $e',
      };
    }
  }

  /// User cancels their own exchange request
  static Future<Map<String, dynamic>> cancelExchangeRequest({
    required String userId,
    required String requestId,
    String? cancellationReason,
  }) async {
    try {
      final response = await _supabase.rpc('cancel_schedule_exchange_request', params: {
        'p_user_id': userId,
        'p_request_id': requestId,
        'p_cancellation_reason': cancellationReason,
      });

      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to cancel exchange request: $e',
      };
    }
  }

  /// Gets available users for exchange (users without conflicts)
  static Future<Map<String, dynamic>> getAvailableUsersForExchange({
    required String scheduleId,
    required String requesterUserId,
  }) async {
    try {
      print('DEBUG: Getting available users for exchange - scheduleId: $scheduleId, requesterUserId: $requesterUserId');
      
      // First get the schedule details
      final scheduleResponse = await _supabase
          .from('employee_schedules')
          .select('start_date_time, end_date_time, department')
          .eq('id', scheduleId)
          .single();

      print('DEBUG: Schedule details: $scheduleResponse');

      // Get all active users except the requester
      final usersResponse = await _supabase
          .from('my_users')
          .select('id, full_name, employee_id, email, department, position, user_role')
          .eq('is_active', true)
          .eq('user_role', 'employee')  // Only show employee users, not admins
          .neq('id', requesterUserId)
          .order('full_name');

      print('DEBUG: Found ${usersResponse.length} active employee users (excluding requester)');

      // Get users who have conflicts during the schedule time using schedule_assignments
      final conflictingAssignmentsResponse = await _supabase
          .from('schedule_assignments')
          .select('''
            user_id,
            schedule_id,
            employee_schedules!inner(
              start_date_time,
              end_date_time,
              is_active,
              status
            )
          ''')
          .eq('is_active', true)
          .eq('employee_schedules.is_active', true)
          .eq('employee_schedules.status', 'active')
          .lte('employee_schedules.start_date_time', scheduleResponse['end_date_time'])
          .gte('employee_schedules.end_date_time', scheduleResponse['start_date_time']);

      print('DEBUG: Found ${conflictingAssignmentsResponse.length} conflicting schedule assignments');

      // Extract conflicting user IDs
      final conflictingUserIds = conflictingAssignmentsResponse
          .map((assignment) => assignment['user_id'])
          .toSet();

      // Filter users who don't have conflicts
      final availableUsers = <Map<String, dynamic>>[];
      
      for (final user in usersResponse) {
        if (!conflictingUserIds.contains(user['id'])) {
          availableUsers.add({
            'id': user['id'],
            'full_name': user['full_name'],
            'employee_id': user['employee_id'],
            'email': user['email'],
            'department': user['department'],
            'position': user['position'],
            'is_available': true,
          });
        }
      }

      print('DEBUG: Found ${availableUsers.length} available employee users for exchange');

      // If no users found due to conflicts, show all employee users as fallback
      if (availableUsers.isEmpty && usersResponse.isNotEmpty) {
        print('DEBUG: No employee users available due to conflicts, showing all employee users as fallback');
        for (final user in usersResponse) {
          availableUsers.add({
            'id': user['id'],
            'full_name': user['full_name'],
            'employee_id': user['employee_id'],
            'email': user['email'],
            'department': user['department'],
            'position': user['position'],
            'is_available': false, // Mark as potentially conflicting
          });
        }
      }

      return {
        'success': true,
        'data': availableUsers,
      };
    } catch (e) {
      print('DEBUG: Error getting available users: $e');
      return {
        'success': false,
        'error': 'Failed to get available users: $e',
      };
    }
  }

  /// Gets exchange request statistics for admin dashboard
  static Future<Map<String, dynamic>> getExchangeRequestStats({
    required String adminId,
  }) async {
    try {
      final response = await _supabase.rpc('get_schedule_exchange_requests', params: {
        'p_user_id': null, // Get all requests
        'p_status': null,
        'p_request_type': null,
        'p_limit': 1000, // Get all for stats
        'p_offset': 0,
      });

      if (!response['success']) {
        return response;
      }

      final requests = List<Map<String, dynamic>>.from(response['requests']);
      
      // Calculate statistics
      final stats = {
        'total_requests': requests.length,
        'pending_requests': requests.where((r) => r['request_details']?['status'] == 'pending').length,
        'approved_requests': requests.where((r) => r['request_details']?['status'] == 'approved').length,
        'rejected_requests': requests.where((r) => r['request_details']?['status'] == 'rejected').length,
        'cancelled_requests': requests.where((r) => r['request_details']?['status'] == 'cancelled').length,
        'expired_requests': requests.where((r) => r['request_details']?['status'] == 'expired').length,
      };

      return {
        'success': true,
        'stats': stats,
        'recent_requests': requests.take(10).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get exchange request stats: $e',
      };
    }
  }

  /// Test function to get all employee users (for debugging)
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      print('DEBUG: Getting all employee users for testing');
      
      final usersResponse = await _supabase
          .from('my_users')
          .select('id, full_name, employee_id, email, department, position, is_active, user_role')
          .eq('is_active', true)
          .eq('user_role', 'employee')  // Only employee users
          .order('full_name');

      print('DEBUG: Found ${usersResponse.length} active employee users');

      return {
        'success': true,
        'data': usersResponse,
        'count': usersResponse.length,
      };
    } catch (e) {
      print('DEBUG: Error getting all users: $e');
      return {
        'success': false,
        'error': 'Failed to get users: $e',
      };
    }
  }
}
