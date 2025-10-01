import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/schedule_exchange_service.dart';

/// Controller for managing schedule exchange requests
class ScheduleExchangeController extends GetxController {
  // Observable variables
  var exchangeRequests = <Map<String, dynamic>>[].obs;
  var availableUsers = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isCreatingRequest = false.obs;
  var isManagingRequest = false.obs;
  
  // Filter variables
  var selectedStatus = Rxn<String>();
  var selectedRequestType = Rxn<String>();
  var selectedUserId = Rxn<String>();
  
  // Statistics
  var exchangeStats = <String, dynamic>{}.obs;
  
  // Current user ID (get from Supabase auth)
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    loadExchangeRequests();
  }

  /// Loads exchange requests with current filters
  Future<void> loadExchangeRequests({
    String? userId,
    String? status,
    String? requestType,
    bool isAdmin = false,
  }) async {
    isLoading.value = true;
    try {
      final result = await ScheduleExchangeService.getExchangeRequests(
        userId: isAdmin ? null : (userId ?? _currentUserId),
        status: status ?? selectedStatus.value,
        requestType: requestType ?? selectedRequestType.value,
        limit: 50,
        offset: 0,
      );

      if (result['success']) {
        exchangeRequests.value = List<Map<String, dynamic>>.from(result['requests']);
        print('DEBUG: Loaded ${exchangeRequests.length} exchange requests');
        if (exchangeRequests.isNotEmpty) {
          print('DEBUG: First request: ${exchangeRequests.first}');
        }
      } else {
        print('DEBUG: Failed to load exchange requests: ${result['error']}');
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load exchange requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates a new exchange request
  Future<Map<String, dynamic>> createExchangeRequest({
    required String scheduleId,
    required String requestedUserId,
    String? requestReason,
    String? requestNotes,
    String requestType = 'exchange',
    int expiresInDays = 7,
  }) async {
    if (_currentUserId == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    isCreatingRequest.value = true;
    try {
      final result = await ScheduleExchangeService.createExchangeRequest(
        requesterUserId: _currentUserId!,
        scheduleId: scheduleId,
        requestedUserId: requestedUserId,
        requestReason: requestReason,
        requestNotes: requestNotes,
        requestType: requestType,
        expiresInDays: expiresInDays,
      );

      if (result['success']) {
        await loadExchangeRequests(); // Refresh the list
      }
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create exchange request: $e',
      };
    } finally {
      isCreatingRequest.value = false;
    }
  }

  /// Admin manages exchange request (approve/reject/cancel)
  Future<void> manageExchangeRequest({
    required String requestId,
    required String action,
    String? adminNotes,
    String? rejectionReason,
    bool isAdmin = false,
  }) async {
    if (_currentUserId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return;
    }

    isManagingRequest.value = true;
    try {
      final result = await ScheduleExchangeService.manageExchangeRequest(
        adminId: _currentUserId!,
        requestId: requestId,
        action: action,
        adminNotes: adminNotes,
        rejectionReason: rejectionReason,
      );

      if (result['success']) {
        Get.snackbar(
          'Success', 
          result['message'],
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        await loadExchangeRequests(isAdmin: isAdmin); // Refresh the list
        
        // If approved, also refresh schedule data for affected users
        if (action == 'approve') {
          // Trigger schedule refresh for both users
          // This will be handled by the individual schedule controllers
          print('DEBUG: Schedule exchange approved - schedules should be refreshed');
        }
      } else {
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to $action exchange request: $e');
    } finally {
      isManagingRequest.value = false;
    }
  }

  /// User cancels their own exchange request
  Future<void> cancelExchangeRequest({
    required String requestId,
    String? cancellationReason,
  }) async {
    if (_currentUserId == null) {
      Get.snackbar('Error', 'User not authenticated');
      return;
    }

    try {
      final result = await ScheduleExchangeService.cancelExchangeRequest(
        userId: _currentUserId!,
        requestId: requestId,
        cancellationReason: cancellationReason,
      );

      if (result['success']) {
        Get.snackbar(
          'Success', 
          result['message'],
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        await loadExchangeRequests(); // Refresh the list
      } else {
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel exchange request: $e');
    }
  }

  /// Loads available users for exchange
  Future<void> loadAvailableUsersForExchange({
    required String scheduleId,
  }) async {
    try {
      print('DEBUG: Controller loading available users for scheduleId: $scheduleId');
      print('DEBUG: Current user ID: $_currentUserId');
      
      final result = await ScheduleExchangeService.getAvailableUsersForExchange(
        scheduleId: scheduleId,
        requesterUserId: _currentUserId!,
      );

      print('DEBUG: Service result: $result');

      if (result['success']) {
        availableUsers.value = List<Map<String, dynamic>>.from(result['data']);
        print('DEBUG: Loaded ${availableUsers.length} available users');
        if (availableUsers.isNotEmpty) {
          print('DEBUG: First available user: ${availableUsers.first}');
        }
      } else {
        print('DEBUG: Service returned error: ${result['error']}');
        Get.snackbar('Error', result['error']);
        availableUsers.value = [];
      }
    } catch (e) {
      print('DEBUG: Controller error loading users: $e');
      Get.snackbar('Error', 'Failed to load available users: $e');
      availableUsers.value = [];
    }
  }

  /// Loads exchange request statistics (for admin)
  Future<void> loadExchangeStats() async {
    if (_currentUserId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return;
    }

    try {
      final result = await ScheduleExchangeService.getExchangeRequestStats(
        adminId: _currentUserId!,
      );

      if (result['success']) {
        exchangeStats.value = result['stats'];
      } else {
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load exchange stats: $e');
    }
  }

  /// Filter methods
  void setStatusFilter(String? status, {bool isAdmin = false}) {
    selectedStatus.value = status;
    loadExchangeRequests(isAdmin: isAdmin);
  }

  void setRequestTypeFilter(String? requestType, {bool isAdmin = false}) {
    selectedRequestType.value = requestType;
    loadExchangeRequests(isAdmin: isAdmin);
  }

  void setUserFilter(String? userId, {bool isAdmin = false}) {
    selectedUserId.value = userId;
    loadExchangeRequests(isAdmin: isAdmin);
  }

  void clearFilters({bool isAdmin = false}) {
    selectedStatus.value = null;
    selectedRequestType.value = null;
    selectedUserId.value = null;
    loadExchangeRequests(isAdmin: isAdmin);
  }

  /// Utility methods
  List<Map<String, dynamic>> get pendingRequests =>
      exchangeRequests.where((r) => r['request_details']?['status'] == 'pending').toList();

  List<Map<String, dynamic>> get approvedRequests =>
      exchangeRequests.where((r) => r['request_details']?['status'] == 'approved').toList();

  List<Map<String, dynamic>> get rejectedRequests =>
      exchangeRequests.where((r) => r['request_details']?['status'] == 'rejected').toList();

  List<Map<String, dynamic>> get cancelledRequests =>
      exchangeRequests.where((r) => r['request_details']?['status'] == 'cancelled').toList();

  List<Map<String, dynamic>> get expiredRequests =>
      exchangeRequests.where((r) => r['request_details']?['status'] == 'expired').toList();

  int get totalRequests => exchangeRequests.length;
  int get totalPendingRequests => pendingRequests.length;
  int get totalApprovedRequests => approvedRequests.length;
  int get totalRejectedRequests => rejectedRequests.length;
  int get totalCancelledRequests => cancelledRequests.length;
  int get totalExpiredRequests => expiredRequests.length;

  /// Check if user can create exchange request for a schedule
  bool canCreateExchangeRequest(Map<String, dynamic> schedule) {
    // Check if schedule hasn't started yet
    final startTime = DateTime.parse(schedule['start_date_time']);
    if (startTime.isBefore(DateTime.now())) {
      return false;
    }

    // Check if user is the assigned user
    if (schedule['assigned_user_id'] != _currentUserId) {
      return false;
    }

    // Check if schedule is active
    if (schedule['status'] != 'active' || schedule['is_active'] != true) {
      return false;
    }

    return true;
  }

  /// Get status color for UI
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'expired':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon for UI
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.help_outline;
    }
  }
}

