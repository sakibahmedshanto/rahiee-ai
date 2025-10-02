import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_schedule_service.dart';
import '../../services/multi_user_schedule_service.dart';

/// Controller for admin schedule management operations
class AdminScheduleController extends GetxController {
  // Observable variables
  var schedules = <Map<String, dynamic>>[].obs;
  var availableUsers = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isCreatingSchedule = false.obs;
  var isUpdatingSchedule = false.obs;
  var isMultiUserMode = false.obs;  // Toggle for multi-user schedules
  var selectedUsers = <String>[].obs;  // Selected user IDs for multi-user assignment
  
  // Filter variables
  var selectedDepartment = Rxn<String>();
  var selectedStatus = Rxn<String>();
  var selectedUserId = Rxn<String>();
  var startDateFilter = Rxn<DateTime>();
  var endDateFilter = Rxn<DateTime>();

  // Current admin ID (get from Supabase auth)
  String? get _adminId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    // Load initial data
    loadSchedules();
    loadAvailableUsers();
  }

  /// Loads all schedules with current filters
  Future<void> loadSchedules() async {
    if (_adminId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return;
    }

    isLoading.value = true;
    try {
      final result = await AdminScheduleService.getSchedules(
        adminId: _adminId!,
        startDate: startDateFilter.value,
        endDate: endDateFilter.value,
        department: selectedDepartment.value,
        status: selectedStatus.value,
        assignedUserId: selectedUserId.value,
      );

      if (result['success']) {
        schedules.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load schedules: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates a new schedule and returns result with schedule ID
  Future<Map<String, dynamic>> createSchedule({
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
    if (_adminId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return {'success': false, 'error': 'Admin not authenticated'};
    }

    isCreatingSchedule.value = true;
    try {
      final result = await AdminScheduleService.createSchedule(
        adminId: _adminId!,
        title: title,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        assignedUserId: assignedUserId,
        department: department,
        location: location,
        description: description,
        latitude: latitude,
        longitude: longitude,
        requirements: requirements,
        notes: notes,
        tags: tags,
        customFields: customFields,
      );

      if (result['success']) {
        Get.snackbar(
          'Success', 
          result['message'],
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        await loadSchedules(); // Refresh the list
        
        // Return the full result including schedule_id from the RPC response
        return {
          'success': true,
          'schedule_id': result['data']?['schedule_id'],
          'message': result['message'],
        };
      } else {
        Get.snackbar('Error', result['error']);
        return {'success': false, 'error': result['error']};
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create schedule: $e');
      return {'success': false, 'error': 'Failed to create schedule: $e'};
    } finally {
      isCreatingSchedule.value = false;
    }
  }

  /// Updates an existing schedule
  Future<void> updateSchedule({
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
    if (_adminId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return;
    }

    isUpdatingSchedule.value = true;
    try {
      final result = await AdminScheduleService.updateSchedule(
        adminId: _adminId!,
        scheduleId: scheduleId,
        title: title,
        description: description,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        assignedUserId: assignedUserId,
        department: department,
        location: location,
        latitude: latitude,
        longitude: longitude,
        status: status,
        requirements: requirements,
        notes: notes,
        tags: tags,
        customFields: customFields,
      );

      if (result['success']) {
        Get.snackbar(
          'Success', 
          result['message'],
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        await loadSchedules(); // Refresh the list
      } else {
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update schedule: $e');
    } finally {
      isUpdatingSchedule.value = false;
    }
  }

  /// Deletes a schedule (soft delete by default)
  Future<void> deleteSchedule(String scheduleId, {bool softDelete = true}) async {
    if (_adminId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return;
    }

    try {
      final result = await AdminScheduleService.deleteSchedule(
        adminId: _adminId!,
        scheduleId: scheduleId,
        softDelete: softDelete,
      );

      if (result['success']) {
        Get.snackbar(
          'Success', 
          result['message'],
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        await loadSchedules(); // Refresh the list
      } else {
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete schedule: $e');
    }
  }

  /// Loads available users for assignment
  Future<void> loadAvailableUsers({
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? department,
  }) async {
    if (_adminId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return;
    }

    try {
      final result = await AdminScheduleService.getAvailableUsers(
        adminId: _adminId!,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        department: department,
      );

      if (result['success']) {
        availableUsers.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        Get.snackbar('Error', result['error']);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load available users: $e');
    }
  }

  /// Checks for schedule conflicts
  Future<bool> checkScheduleConflict({
    required String userId,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? excludeScheduleId,
  }) async {
    try {
      final result = await AdminScheduleService.checkScheduleConflict(
        userId: userId,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        excludeScheduleId: excludeScheduleId,
      );

      if (result['success']) {
        return result['hasConflict'] ?? false;
      } else {
        Get.snackbar('Error', result['error']);
        return true; // Assume conflict if error occurs
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to check conflicts: $e');
      return true; // Assume conflict if error occurs
    }
  }

  /// Filter methods
  void setDepartmentFilter(String? department) {
    selectedDepartment.value = department;
    loadSchedules();
  }

  void setStatusFilter(String? status) {
    selectedStatus.value = status;
    loadSchedules();
  }

  void setUserFilter(String? userId) {
    selectedUserId.value = userId;
    loadSchedules();
  }

  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    startDateFilter.value = startDate;
    endDateFilter.value = endDate;
    loadSchedules();
  }

  void clearFilters() {
    selectedDepartment.value = null;
    selectedStatus.value = null;
    selectedUserId.value = null;
    startDateFilter.value = null;
    endDateFilter.value = null;
    loadSchedules();
  }

  /// Utility methods
  List<Map<String, dynamic>> get activeSchedules =>
      schedules.where((s) => s['status'] == 'active' && s['is_active'] == true).toList();

  List<Map<String, dynamic>> get upcomingSchedules =>
      schedules.where((s) => 
        DateTime.parse(s['start_date_time']).isAfter(DateTime.now()) &&
        s['status'] == 'active'
      ).toList();

  List<Map<String, dynamic>> get ongoingSchedules =>
      schedules.where((s) {
        final start = DateTime.parse(s['start_date_time']);
        final end = DateTime.parse(s['end_date_time']);
        final now = DateTime.now();
        return start.isBefore(now) && end.isAfter(now) && s['status'] == 'active';
      }).toList();

  int get totalSchedules => schedules.length;
  int get totalActiveSchedules => activeSchedules.length;
  int get totalUpcomingSchedules => upcomingSchedules.length;
  int get totalOngoingSchedules => ongoingSchedules.length;

  // ============================================================================
  // MULTI-USER SCHEDULE METHODS
  // ============================================================================

  /// Assigns multiple users to a schedule
  Future<bool> assignMultipleUsersToSchedule({
    required String scheduleId,
    required List<String> userIds,
    String? notes,
  }) async {
    if (_adminId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return false;
    }

    isLoading.value = true;
    try {
      final result = await MultiUserScheduleService.assignUsersToSchedule(
        scheduleId: scheduleId,
        userIds: userIds,
        adminId: _adminId!,
        notes: notes,
      );

      if (result['success']) {
        Get.snackbar(
          'Success',
          'Assigned ${result['assigned_count']} user(s) to schedule',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Reload schedules to reflect changes
        await loadSchedules();
        return true;
      } else {
        Get.snackbar('Error', result['error']);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign users: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Removes a user from a schedule
  Future<bool> removeUserFromSchedule({
    required String scheduleId,
    required String userId,
    String? reason,
  }) async {
    if (_adminId == null) {
      Get.snackbar('Error', 'Admin not authenticated');
      return false;
    }

    isLoading.value = true;
    try {
      final result = await MultiUserScheduleService.removeUserFromSchedule(
        scheduleId: scheduleId,
        userId: userId,
        adminId: _adminId!,
        reason: reason,
      );

      if (result['success']) {
        Get.snackbar(
          'Success',
          result['message'],
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Reload schedules to reflect changes
        await loadSchedules();
        return true;
      } else {
        Get.snackbar('Error', result['error']);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove user: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Gets schedule with all assigned users
  Future<Map<String, dynamic>?> getScheduleWithAssignments(String scheduleId) async {
    try {
      final result = await MultiUserScheduleService.getScheduleWithAssignments(
        scheduleId: scheduleId,
      );

      if (result['success']) {
        final schedulesList = result['schedules'] as List;
        if (schedulesList.isNotEmpty) {
          return schedulesList.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load schedule details: $e');
      return null;
    }
  }

  /// Gets available users for a schedule (no conflicts)
  Future<List<Map<String, dynamic>>> getAvailableUsersForSchedule({
    required String scheduleId,
    String? department,
  }) async {
    try {
      final result = await MultiUserScheduleService.getAvailableUsersForSchedule(
        scheduleId: scheduleId,
        department: department,
      );

      if (result['success']) {
        return List<Map<String, dynamic>>.from(result['available_users']);
      } else {
        Get.snackbar('Error', result['error']);
        return [];
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load available users: $e');
      return [];
    }
  }

  /// Gets all assignments for a specific schedule
  Future<List<Map<String, dynamic>>> getScheduleAssignments(String scheduleId) async {
    try {
      final result = await MultiUserScheduleService.getScheduleAssignments(
        scheduleId: scheduleId,
      );

      if (result['success']) {
        return List<Map<String, dynamic>>.from(result['assignments']);
      } else {
        Get.snackbar('Error', result['error']);
        return [];
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load assignments: $e');
      return [];
    }
  }

  /// Toggles multi-user mode
  void toggleMultiUserMode(bool value) {
    isMultiUserMode.value = value;
    if (!value) {
      selectedUsers.clear();
    }
  }

  /// Toggles user selection for multi-user assignment
  void toggleUserSelection(String userId) {
    if (selectedUsers.contains(userId)) {
      selectedUsers.remove(userId);
    } else {
      selectedUsers.add(userId);
    }
  }

  /// Clears selected users
  void clearSelectedUsers() {
    selectedUsers.clear();
  }

  /// Checks if a user is selected
  bool isUserSelected(String userId) {
    return selectedUsers.contains(userId);
  }
}