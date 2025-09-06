// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_swap_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class ScheduleSwapService extends GetxService {
  static ScheduleSwapService get to => Get.find();
  
  final SupabaseService _supabaseService = SupabaseService.to;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable lists for real-time updates
  final RxList<ScheduleSwapModel> allSwapRequests = <ScheduleSwapModel>[].obs;
  final RxList<ScheduleSwapModel> mySwapRequests = <ScheduleSwapModel>[].obs;
  final RxList<ScheduleSwapModel> pendingForMe = <ScheduleSwapModel>[].obs;
  final RxList<ScheduleCoverageModel> allCoverageRequests = <ScheduleCoverageModel>[].obs;
  final RxList<ScheduleCoverageModel> myCoverageRequests = <ScheduleCoverageModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _setupRealtimeSubscriptions();
  }

  void _setupRealtimeSubscriptions() {
    // Subscribe to schedule swap requests changes
    _supabase
        .channel('schedule_swap_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedule_swap_requests',
          callback: (payload) {
            _handleSwapRequestChange(payload);
          },
        )
        .subscribe();

    // Subscribe to schedule coverage requests changes
    _supabase
        .channel('schedule_coverage_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedule_coverage_requests',
          callback: (payload) {
            _handleCoverageRequestChange(payload);
          },
        )
        .subscribe();
  }

  void _handleSwapRequestChange(PostgresChangePayload payload) {
    try {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          if (payload.newRecord.isNotEmpty) {
            final newSwap = ScheduleSwapModel.fromMap(payload.newRecord);
            _addOrUpdateSwapRequest(newSwap);
          }
          break;
        case PostgresChangeEvent.update:
          if (payload.newRecord.isNotEmpty) {
            final updatedSwap = ScheduleSwapModel.fromMap(payload.newRecord);
            _addOrUpdateSwapRequest(updatedSwap);
          }
          break;
        case PostgresChangeEvent.delete:
          if (payload.oldRecord.isNotEmpty) {
            final deletedId = payload.oldRecord['id']?.toString();
            if (deletedId != null) {
              _removeSwapRequest(deletedId);
            }
          }
          break;
        case PostgresChangeEvent.all:
          // Handle all events case if needed
          break;
      }
    } catch (e) {
      print('Error handling swap request change: $e');
    }
  }

  void _handleCoverageRequestChange(PostgresChangePayload payload) {
    try {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          if (payload.newRecord.isNotEmpty) {
            final newCoverage = ScheduleCoverageModel.fromMap(payload.newRecord);
            _addOrUpdateCoverageRequest(newCoverage);
          }
          break;
        case PostgresChangeEvent.update:
          if (payload.newRecord.isNotEmpty) {
            final updatedCoverage = ScheduleCoverageModel.fromMap(payload.newRecord);
            _addOrUpdateCoverageRequest(updatedCoverage);
          }
          break;
        case PostgresChangeEvent.delete:
          if (payload.oldRecord.isNotEmpty) {
            final deletedId = payload.oldRecord['id']?.toString();
            if (deletedId != null) {
              _removeCoverageRequest(deletedId);
            }
          }
          break;
        case PostgresChangeEvent.all:
          // Handle all events case if needed
          break;
      }
    } catch (e) {
      print('Error handling coverage request change: $e');
    }
  }

  void _addOrUpdateSwapRequest(ScheduleSwapModel swapRequest) {
    final index = allSwapRequests.indexWhere((item) => item.id == swapRequest.id);
    if (index != -1) {
      allSwapRequests[index] = swapRequest;
    } else {
      allSwapRequests.add(swapRequest);
    }
    _updateFilteredSwapLists();
  }

  void _removeSwapRequest(String id) {
    allSwapRequests.removeWhere((item) => item.id == id);
    _updateFilteredSwapLists();
  }

  void _addOrUpdateCoverageRequest(ScheduleCoverageModel coverageRequest) {
    final index = allCoverageRequests.indexWhere((item) => item.id == coverageRequest.id);
    if (index != -1) {
      allCoverageRequests[index] = coverageRequest;
    } else {
      allCoverageRequests.add(coverageRequest);
    }
    _updateFilteredCoverageLists();
  }

  void _removeCoverageRequest(String id) {
    allCoverageRequests.removeWhere((item) => item.id == id);
    _updateFilteredCoverageLists();
  }

  void _updateFilteredSwapLists() {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId != null) {
      mySwapRequests.value = allSwapRequests
          .where((swap) => swap.requestingEmployeeId == currentUserId)
          .toList();
      pendingForMe.value = allSwapRequests
          .where((swap) => 
              swap.targetEmployeeId == currentUserId && 
              swap.status == 'pending')
          .toList();
    }
  }

  void _updateFilteredCoverageLists() {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId != null) {
      myCoverageRequests.value = allCoverageRequests
          .where((coverage) => coverage.requestingEmployeeId == currentUserId)
          .toList();
    }
  }

  // Create a new schedule swap request
  Future<String?> createScheduleSwapRequest({
    required String originalScheduleId,
    required String targetEmployeeId,
    String? targetScheduleId,
    String swapType = 'direct',
    String? reason,
    double compensation = 0.0,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc('create_schedule_swap_request', params: {
        'p_original_schedule_id': originalScheduleId,
        'p_requesting_employee_id': currentUserId,
        'p_target_employee_id': targetEmployeeId,
        'p_target_schedule_id': targetScheduleId,
        'p_swap_type': swapType,
        'p_reason': reason,
        'p_compensation': compensation,
      });

      return response as String?;
    } catch (e) {
      print('Error creating schedule swap request: $e');
      throw Exception('Failed to create swap request: $e');
    }
  }

  // Process (approve/reject) a schedule swap request
  Future<bool> processScheduleSwapRequest({
    required String swapRequestId,
    required String action, // 'approve' or 'reject'
    String? notes,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Determine approver type based on the request
      final swapRequest = allSwapRequests.firstWhereOrNull(
        (swap) => swap.id == swapRequestId,
      );

      if (swapRequest == null) {
        throw Exception('Swap request not found');
      }

      String approverType;
      if (swapRequest.requestingEmployeeId == currentUserId) {
        approverType = 'employee';
      } else if (swapRequest.targetEmployeeId == currentUserId) {
        approverType = 'target';
      } else {
        // Check if user is admin
        // For now, assume admin role check - this should be implemented in SupabaseService
        approverType = 'admin';
      }

      final response = await _supabase.rpc('process_schedule_swap_request', params: {
        'p_swap_request_id': swapRequestId,
        'p_approver_id': currentUserId,
        'p_approver_type': approverType,
        'p_action': action,
        'p_notes': notes,
      });

      return response as bool? ?? false;
    } catch (e) {
      print('Error processing schedule swap request: $e');
      throw Exception('Failed to process swap request: $e');
    }
  }

  // Load swap requests for current user
  Future<void> loadMySwapRequests() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return;

      final response = await _supabase
          .from('schedule_swap_requests')
          .select('''
            *,
            original_schedule:employee_schedules!original_schedule_id(title, start_date_time, end_date_time),
            requesting_employee:my_users!requesting_employee_id(full_name, employee_id),
            target_employee:my_users!target_employee_id(full_name, employee_id)
          ''')
          .or('requesting_employee_id.eq.$currentUserId,target_employee_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      final swapRequests = (response as List)
          .map((data) => ScheduleSwapModel.fromMap(data))
          .toList();

      allSwapRequests.value = swapRequests;
      _updateFilteredSwapLists();
    } catch (e) {
      print('Error loading swap requests: $e');
      throw Exception('Failed to load swap requests: $e');
    }
  }

  // Load all swap requests (for admin)
  Future<void> loadAllSwapRequests() async {
    try {
      final response = await _supabase
          .from('schedule_swap_requests')
          .select('''
            *,
            original_schedule:employee_schedules!original_schedule_id(title, start_date_time, end_date_time),
            requesting_employee:my_users!requesting_employee_id(full_name, employee_id),
            target_employee:my_users!target_employee_id(full_name, employee_id)
          ''')
          .order('created_at', ascending: false);

      final swapRequests = (response as List)
          .map((data) => ScheduleSwapModel.fromMap(data))
          .toList();

      allSwapRequests.value = swapRequests;
      _updateFilteredSwapLists();
    } catch (e) {
      print('Error loading all swap requests: $e');
      throw Exception('Failed to load swap requests: $e');
    }
  }

  // Create a schedule coverage request
  Future<String?> createScheduleCoverageRequest({
    required String scheduleId,
    required String reason,
    String coverageType = 'full',
    DateTime? startTime,
    DateTime? endTime,
    double? compensationRate,
    int emergencyPriority = 0,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final coverageRequest = ScheduleCoverageModel(
        id: '',
        scheduleId: scheduleId,
        requestingEmployeeId: currentUserId,
        coverageType: coverageType,
        status: 'open',
        coverageStartTime: startTime,
        coverageEndTime: endTime,
        compensationRate: compensationRate,
        emergencyPriority: emergencyPriority,
        reason: reason,
        requiresAdminApproval: emergencyPriority > 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 48)),
      );

      final response = await _supabase
          .from('schedule_coverage_requests')
          .insert(coverageRequest.toMap())
          .select()
          .single();

      return response['id'] as String?;
    } catch (e) {
      print('Error creating coverage request: $e');
      throw Exception('Failed to create coverage request: $e');
    }
  }

  // Accept a coverage request
  Future<bool> acceptCoverageRequest(String coverageRequestId) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('schedule_coverage_requests')
          .update({
            'covering_employee_id': currentUserId,
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', coverageRequestId);

      return true;
    } catch (e) {
      print('Error accepting coverage request: $e');
      throw Exception('Failed to accept coverage request: $e');
    }
  }

  // Get available employees for schedule swap (excluding current employee and conflicted employees)
  Future<List<UserModel>> getAvailableEmployeesForSwap({
    required String scheduleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase.rpc('get_available_employees', params: {
        'p_schedule_start': startTime.toIso8601String(),
        'p_schedule_end': endTime.toIso8601String(),
        'p_exclude_user_id': currentUserId,
      });

      return (response as List)
          .map((data) => UserModel.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting available employees: $e');
      return [];
    }
  }

  // Get swap request details with full information
  Future<Map<String, dynamic>?> getSwapRequestDetails(String swapRequestId) async {
    try {
      final response = await _supabase
          .from('schedule_swap_requests')
          .select('''
            *,
            original_schedule:employee_schedules!original_schedule_id(*),
            target_schedule:employee_schedules!target_schedule_id(*),
            requesting_employee:my_users!requesting_employee_id(*),
            target_employee:my_users!target_employee_id(*),
            admin_approver:my_users!approved_by_admin(*)
          ''')
          .eq('id', swapRequestId)
          .single();

      return response;
    } catch (e) {
      print('Error getting swap request details: $e');
      return null;
    }
  }

  // Get statistics for dashboard
  Future<Map<String, int>> getSwapStatistics() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return {};

      final response = await _supabase.rpc('get_user_swap_statistics', params: {
        'p_user_id': currentUserId,
      });

      return Map<String, int>.from(response);
    } catch (e) {
      print('Error getting swap statistics: $e');
      return {};
    }
  }

  // Cancel a swap request (only by requester)
  Future<bool> cancelSwapRequest(String swapRequestId) async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('schedule_swap_requests')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', swapRequestId)
          .eq('requesting_employee_id', currentUserId);

      return true;
    } catch (e) {
      print('Error cancelling swap request: $e');
      throw Exception('Failed to cancel swap request: $e');
    }
  }

  // Get pending swap requests count for current user
  int get pendingSwapRequestsCount {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return 0;
    
    return allSwapRequests.where((swap) => 
        (swap.requestingEmployeeId == currentUserId || swap.targetEmployeeId == currentUserId) &&
        swap.status == 'pending'
    ).length;
  }

  // Get swap requests that need action from current user
  List<ScheduleSwapModel> get swapRequestsNeedingAction {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return [];
    
    return allSwapRequests.where((swap) {
      if (swap.status != 'pending') return false;
      
      // Check if current user needs to approve
      if (swap.requestingEmployeeId == currentUserId && !swap.approvedByEmployee) return true;
      if (swap.targetEmployeeId == currentUserId && !swap.approvedByTarget) return true;
      
      return false;
    }).toList();
  }
}
