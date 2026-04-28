import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/attendance_management_service.dart';
import '../screens/attendance_screen/camera_check_in_screen.dart';
import '../utils/app_constant.dart';
import '../utils/timezone_utils.dart';

/// Clean, efficient schedule controller with optimized performance
class ScheduleController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;

  // Core observables
  final isLoading = false.obs;
  final selectedDate = DateTime.now().obs;
  final schedules = <ScheduleModel>[].obs;
  final currentUser = Rxn<UserModel>();
  
  // Check-in status
  final currentCheckInStatus = <String, dynamic>{}.obs;
  final hasActiveCheckIn = false.obs;
  final activeSchedule = Rxn<ScheduleModel>();
  
  // UI state
  final isRefreshing = false.obs;
  
  // Computed properties
  List<ScheduleModel> get todaySchedules => schedules.where((schedule) {
    final selected = selectedDate.value;
    final scheduleDate = schedule.startDateTime;
    return scheduleDate.year == selected.year &&
           scheduleDate.month == selected.month &&
           scheduleDate.day == selected.day;
  }).toList();
  
  bool get isToday {
    final today = DateTime.now();
    final selected = selectedDate.value;
    return today.year == selected.year &&
           today.month == selected.month &&
           today.day == selected.day;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  /// Initialize data efficiently
  Future<void> _initializeData() async {
    await _loadCurrentUser();
    await _loadCurrentCheckInStatus();
    await _loadSchedulesForDate(selectedDate.value);
  }

  /// Load current user
  Future<void> _loadCurrentUser() async {
    try {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final userData = await _supabaseService.client
            ?.from('my_users')
            .select('*')
            .eq('id', user.id)
            .single();
        
        if (userData != null) {
          currentUser.value = UserModel.fromMap(userData);
        }
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  /// Load current check-in status efficiently
  Future<void> _loadCurrentCheckInStatus() async {
    try {
      if (currentUser.value == null) return;
      
      final status = await _attendanceService.getCurrentCheckInStatus();
      currentCheckInStatus.value = status ?? {};
      hasActiveCheckIn.value = currentCheckInStatus['has_active_checkin'] == true;
      
      // Set active schedule if there's an active check-in
      if (hasActiveCheckIn.value && currentCheckInStatus['schedule_id'] != null) {
        final scheduleId = currentCheckInStatus['schedule_id'];
        final schedule = schedules.firstWhereOrNull((s) => s.scheduleId == scheduleId);
        activeSchedule.value = schedule;
      }
      
      print('🔍 Current check-in status: $currentCheckInStatus');
    } catch (e) {
      print('Error loading check-in status: $e');
      currentCheckInStatus.value = {};
      hasActiveCheckIn.value = false;
    }
  }

  /// Load schedules for a specific date (optimized)
  Future<void> _loadSchedulesForDate(DateTime date) async {
    try {
      if (currentUser.value == null) return;
      
      isLoading.value = true;
      
      print('📅 Loading schedules for: ${TimezoneUtils.formatDate(date)}');
      
      // Use optimized RPC call
      final response = await _supabaseService.client?.rpc('get_schedules_with_timezone_status', params: {
        'p_user_id': currentUser.value!.uId,
        'p_date': date.toIso8601String().split('T')[0],
      });

      if (response != null && response['schedules'] != null) {
        final schedulesData = List<Map<String, dynamic>>.from(response['schedules']);
        
        final List<ScheduleModel> loadedSchedules = [];
        for (final scheduleData in schedulesData) {
          try {
            final schedule = ScheduleModel.fromMap(scheduleData);
            loadedSchedules.add(schedule);
            print('✅ Loaded: ${schedule.title} at ${TimezoneUtils.formatTime12Hour(schedule.startDateTime)}');
          } catch (e) {
            print('❌ Error parsing schedule: $e');
          }
        }
        
        schedules.value = loadedSchedules;
        print('📊 Loaded ${loadedSchedules.length} schedules');
      } else {
        schedules.value = [];
        print('📭 No schedules found');
      }
      
    } catch (e) {
      print('❌ Error loading schedules: $e');
      schedules.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    if (isRefreshing.value) return; // Prevent multiple refreshes
    
    isRefreshing.value = true;
    try {
      await _loadCurrentCheckInStatus();
      await _loadSchedulesForDate(selectedDate.value);
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Navigate to previous day
  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
    _loadSchedulesForDate(selectedDate.value);
  }

  /// Navigate to next day
  void nextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
    _loadSchedulesForDate(selectedDate.value);
  }

  /// Navigate to today
  void goToToday() {
    selectedDate.value = DateTime.now();
    _loadSchedulesForDate(selectedDate.value);
  }

  /// Handle schedule tap
  void onScheduleTap(ScheduleModel schedule) {
    if (schedule.isCompleted == true) {
      _showCompletedScheduleDialog(schedule);
    } else if (schedule.isExpired == true) {
      _showExpiredScheduleDialog(schedule);
    } else if (schedule.canCheckIn == true) {
      _handleCheckIn(schedule);
    } else if (schedule.canCheckOut == true) {
      _handleCheckOut(schedule);
    } else if (hasActiveCheckIn.value && schedule.hasCheckedIn != true) {
      _showBlockedCheckInDialog(schedule);
    }
  }

  /// Handle check-in
  void _handleCheckIn(ScheduleModel schedule) {
    if (hasActiveCheckIn.value) {
      _showBlockedCheckInDialog(schedule);
      return;
    }
    
    Get.to(() => CameraCheckInScreen(
      scheduleId: schedule.scheduleId,
      scheduleTitle: schedule.title,
      onCheckInComplete: () async {
        await refreshData();
        Get.back();
      },
    ));
  }

  /// Handle check-out
  void _handleCheckOut(ScheduleModel schedule) {
    if (activeSchedule.value?.scheduleId == schedule.scheduleId) {
      Get.to(() => CameraCheckInScreen(
        scheduleId: schedule.scheduleId,
        scheduleTitle: schedule.title,
        onCheckInComplete: () async {
          await refreshData();
          Get.back();
        },
      ), arguments: {
        'attendanceId': schedule.attendanceId,
      });
    }
  }

  /// Show completed schedule dialog
  void _showCompletedScheduleDialog(ScheduleModel schedule) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppConstant.successColor),
            const SizedBox(width: 8),
            const Text('Schedule Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${schedule.title} has been completed successfully.'),
            const SizedBox(height: 8),
            if (schedule.checkInTime != null && schedule.checkOutTime != null) ...[
              Text('Check-in: ${TimezoneUtils.formatTime12Hour(schedule.checkInTime)}'),
              Text('Check-out: ${TimezoneUtils.formatTime12Hour(schedule.checkOutTime)}'),
              Text('Duration: ${schedule.actualDurationHours?.toStringAsFixed(1) ?? '0.0'}h'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show expired schedule dialog
  void _showExpiredScheduleDialog(ScheduleModel schedule) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule_outlined, color: AppConstant.errorColor),
            const SizedBox(width: 8),
            const Text('Schedule Expired'),
          ],
        ),
        content: Text('${schedule.title} has expired and is no longer available for check-in.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show blocked check-in dialog
  void _showBlockedCheckInDialog(ScheduleModel schedule) {
    final activeScheduleTitle = activeSchedule.value?.title ?? 'another schedule';
    
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: AppConstant.warningColor),
            const SizedBox(width: 8),
            const Text('Already Checked In'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You are already checked in for $activeScheduleTitle.'),
            const SizedBox(height: 8),
            Text('Please check out from your current schedule before checking in to a new one.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Get schedule status color
  Color getScheduleStatusColor(ScheduleModel schedule) {
    if (schedule.isCompleted == true) return AppConstant.successColor;
    if (schedule.isExpired == true) return AppConstant.errorColor;
    if (schedule.canCheckOut == true) return AppConstant.warningColor;
    if (schedule.canCheckIn == true) return AppConstant.primaryColor;
    return AppConstant.textSecondary;
  }

  /// Get schedule status text
  String getScheduleStatusText(ScheduleModel schedule) {
    if (schedule.isCompleted == true) return 'Completed';
    if (schedule.isExpired == true) return 'Expired';
    if (schedule.canCheckOut == true) return 'Check Out';
    if (schedule.canCheckIn == true) return 'Check In';
    return 'Not Available';
  }

  /// Get schedule status icon
  IconData getScheduleStatusIcon(ScheduleModel schedule) {
    if (schedule.isCompleted == true) return Icons.check_circle;
    if (schedule.isExpired == true) return Icons.schedule_outlined;
    if (schedule.canCheckOut == true) return Icons.exit_to_app;
    if (schedule.canCheckIn == true) return Icons.login;
    return Icons.schedule;
  }
}
