import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';
import '../services/attendance_management_service.dart';
import '../services/location_permission_service.dart';
import '../utils/app_constant.dart';

class UnifiedScheduleController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;
  final LocationPermissionService _locationService = LocationPermissionService.to;

  // Observable variables
  final isLoading = false.obs;
  final isCheckingIn = false.obs;
  final isCheckingOut = false.obs;
  final selectedDate = DateTime.now().obs;
  final schedules = <ScheduleModel>[].obs;
  final currentUser = Rxn<UserModel>();
  
  // Attendance status
  final hasCheckedIn = false.obs;
  final hasCheckedOut = false.obs;
  final checkInTime = Rxn<DateTime>();
  final checkOutTime = Rxn<DateTime>();
  final totalHours = 0.0.obs;
  final currentAttendanceId = Rxn<String>();
  final activeSchedule = Rxn<ScheduleModel>();
  
  // Store attendance status for each schedule
  final scheduleAttendanceStatus = <String, Map<String, dynamic>>{}.obs;
  
  // Additional computed properties for UI
  List<ScheduleModel> get todaySchedules => schedules.where((schedule) {
    final selectedDate = this.selectedDate.value;
    final scheduleDate = schedule.startDateTime;
    return scheduleDate.year == selectedDate.year &&
           scheduleDate.month == selectedDate.month &&
           scheduleDate.day == selectedDate.day;
  }).toList();
  
  Rx<AttendanceModel?> get todayAttendance => Rx<AttendanceModel?>(null); // Will be implemented with attendance data
  RxBool get isCheckedIn => hasCheckedIn;
  
  // Check if a schedule is currently active
  bool isCurrentSchedule(ScheduleModel schedule) {
    final now = DateTime.now();
    return now.isAfter(schedule.startDateTime) && now.isBefore(schedule.endDateTime);
  }

  // Check if user is checked in for a specific schedule
  bool isCheckedInForSchedule(ScheduleModel schedule) {
    final status = scheduleAttendanceStatus[schedule.scheduleId];
    return status != null && (status['has_checked_in'] ?? false);
  }

  // Check if user is checked out for a specific schedule
  bool isCheckedOutForSchedule(ScheduleModel schedule) {
    final status = scheduleAttendanceStatus[schedule.scheduleId];
    return status != null && (status['has_checked_out'] ?? false);
  }

  // Check if schedule is completed
  bool isScheduleCompleted(ScheduleModel schedule) {
    final status = scheduleAttendanceStatus[schedule.scheduleId];
    return status != null && 
           (status['has_checked_in'] ?? false) && 
           (status['has_checked_out'] ?? false);
  }

  // Get attendance status for a schedule
  Map<String, dynamic>? getScheduleAttendanceStatus(ScheduleModel schedule) {
    return scheduleAttendanceStatus[schedule.scheduleId];
  }

  // Check if user can check in for a schedule
  bool canCheckInForSchedule(ScheduleModel schedule) {
    final isToday = selectedDate.value.year == DateTime.now().year &&
                   selectedDate.value.month == DateTime.now().month &&
                   selectedDate.value.day == DateTime.now().day;
    
    if (!isToday) return false;
    
    final status = scheduleAttendanceStatus[schedule.scheduleId];
    return status == null || !(status['has_checked_in'] ?? false);
  }

  // Check if user can check out for a schedule
  bool canCheckOutForSchedule(ScheduleModel schedule) {
    final status = scheduleAttendanceStatus[schedule.scheduleId];
    return status != null && 
           (status['has_checked_in'] ?? false) && 
           !(status['has_checked_out'] ?? false);
  }

  // Get work status text for a schedule
  String getScheduleWorkStatus(ScheduleModel schedule) {
    final status = scheduleAttendanceStatus[schedule.scheduleId];
    if (status == null) return 'Not Started';
    
    final hasCheckedIn = status['has_checked_in'] ?? false;
    final hasCheckedOut = status['has_checked_out'] ?? false;
    
    if (hasCheckedIn && hasCheckedOut) {
      return 'Completed';
    } else if (hasCheckedIn) {
      return 'In Progress';
    } else {
      return 'Not Started';
    }
  }

  // Check if user should be asked to check out (has any active attendance)
  bool get hasActiveAttendance {
    for (final status in scheduleAttendanceStatus.values) {
      if ((status['has_checked_in'] ?? false) && !(status['has_checked_out'] ?? false)) {
        return true;
      }
    }
    return false;
  }

  // Get the active schedule (if any)
  ScheduleModel? get currentActiveSchedule {
    for (final schedule in schedules) {
      final status = scheduleAttendanceStatus[schedule.scheduleId];
      if (status != null && 
          (status['has_checked_in'] ?? false) && 
          !(status['has_checked_out'] ?? false)) {
        return schedule;
      }
    }
    return null;
  }
  
  // Date navigation methods
  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
    refreshData();
  }
  
  void nextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
    refreshData();
  }
  
  // Check if selected date is today
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

  Future<void> _initializeData() async {
    await _loadCurrentUser();
    await refreshData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Get current user from Supabase auth
      final user = _supabaseService.currentUser;
      if (user != null) {
        final userData = await _supabaseService.select(
          'my_users',
          eq: 'id',
          eqValue: user.id,
        );
        
        if (userData.isNotEmpty) {
          currentUser.value = UserModel.fromMap(userData.first);
        }
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> refreshData() async {
    // Load schedules first, then attendance status will be loaded automatically
    await loadSchedulesForDate(selectedDate.value);
  }

  Future<void> _loadCurrentAttendanceStatus() async {
    try {
      if (currentUser.value == null) return;
      
      // Load attendance status for all schedules for the selected date
      final response = await _attendanceService.getSchedulesWithAttendanceStatus(
        date: selectedDate.value,
        employeeId: currentUser.value!.uId,
      );
      
      print('DEBUG: Schedules with attendance response: $response');
      
      if (response['error'] != true && response['schedules'] != null) {
        final List<dynamic> schedulesData = response['schedules'];
        
        // Clear previous status
        scheduleAttendanceStatus.clear();
        hasCheckedIn.value = false;
        hasCheckedOut.value = false;
        currentAttendanceId.value = null;
        activeSchedule.value = null;
        
        // Process each schedule's attendance status
        for (final scheduleData in schedulesData) {
          final scheduleId = scheduleData['schedule_id']?.toString();
          if (scheduleId != null) {
            scheduleAttendanceStatus[scheduleId] = Map<String, dynamic>.from(scheduleData);
            
            // Update global status for backward compatibility (use most recent active attendance)
            if (scheduleData['has_checked_in'] == true) {
              hasCheckedIn.value = true;
              if (scheduleData['attendance_id'] != null) {
                currentAttendanceId.value = scheduleData['attendance_id'].toString();
              }
              
              if (scheduleData['check_in_time'] != null) {
                checkInTime.value = DateTime.parse(scheduleData['check_in_time']);
              }
              
              // If this schedule is not checked out, it's the active one
              if (scheduleData['has_checked_out'] != true) {
                hasCheckedOut.value = false;
                // Find the corresponding schedule model
                final schedule = schedules.firstWhereOrNull(
                  (s) => s.scheduleId == scheduleId
                );
                if (schedule != null) {
                  activeSchedule.value = schedule;
                }
              } else if (scheduleData['check_out_time'] != null) {
                checkOutTime.value = DateTime.parse(scheduleData['check_out_time']);
              }
            }
          }
        }
        
        // If all checked-in schedules are also checked out, update global status
        bool allCompleted = true;
        bool hasAnyCheckedIn = false;
        for (final status in scheduleAttendanceStatus.values) {
          if (status['has_checked_in'] == true) {
            hasAnyCheckedIn = true;
            if (status['has_checked_out'] != true) {
              allCompleted = false;
              break;
            }
          }
        }
        
        if (hasAnyCheckedIn && allCompleted) {
          hasCheckedOut.value = true;
          activeSchedule.value = null;
        }
        
      } else {
        print('DEBUG: Error loading attendance status: ${response['message']}');
        // Reset status on error
        _resetAttendanceStatus();
      }
      
    } catch (e) {
      print('Error loading current attendance status: $e');
      // Reset status on error
      _resetAttendanceStatus();
    }
  }

  void _resetAttendanceStatus() {
    hasCheckedIn.value = false;
    hasCheckedOut.value = false;
    checkInTime.value = null;
    checkOutTime.value = null;
    totalHours.value = 0.0;
    currentAttendanceId.value = null;
    activeSchedule.value = null;
    scheduleAttendanceStatus.clear();
  }

  // Helper methods for UI state
  bool shouldShowCheckIn(ScheduleModel schedule) {
    // Show check-in if:
    // 1. User hasn't checked in today
    // 2. Current time is within schedule time
    if (hasCheckedIn.value) return false;
    
    final now = DateTime.now();
    return now.isAfter(schedule.startDateTime.subtract(Duration(minutes: 30))) &&
           now.isBefore(schedule.endDateTime);
  }

  bool shouldShowCheckOut() {
    // Show check-out if user has checked in but not checked out
    return hasCheckedIn.value && !hasCheckedOut.value;
  }

  bool shouldShowWorkSummary() {
    // Show work summary if user has both checked in and checked out
    return hasCheckedIn.value && hasCheckedOut.value;
  }

  String getAttendanceStatusText() {
    if (shouldShowWorkSummary()) {
      return 'Work Session Completed';
    } else if (shouldShowCheckOut()) {
      return 'Currently Working';
    } else {
      return 'Ready to Check In';
    }
  }

  String getWorkDurationText() {
    if (checkInTime.value != null && checkOutTime.value != null) {
      final duration = checkOutTime.value!.difference(checkInTime.value!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } else if (checkInTime.value != null && !hasCheckedOut.value) {
      final duration = DateTime.now().difference(checkInTime.value!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m (ongoing)';
    }
    return '0h 0m';
  }

  Future<void> loadSchedulesForDate(DateTime date) async {
    try {
      if (currentUser.value == null) return;
      
      isLoading.value = true;
      
      print('DEBUG: Loading schedules for date: ${date.toIso8601String()}');
      print('DEBUG: Current user ID: ${currentUser.value!.uId}');
      
      // Use the RPC function to get schedules with attendance status
      final response = await _supabaseService.client?.rpc('get_schedules_with_attendance_status', params: {
        'p_employee_id': currentUser.value!.uId,
        'p_date': date.toIso8601String().split('T')[0],
      });

      print('DEBUG: RPC response: $response');
      print('DEBUG: Response type: ${response.runtimeType}');

      if (response != null) {
        if (response['schedules'] != null) {
          final schedulesData = List<Map<String, dynamic>>.from(response['schedules']);
          print('DEBUG: Found ${schedulesData.length} schedules in response');
          
          final List<ScheduleModel> loadedSchedules = [];
          for (final scheduleData in schedulesData) {
            try {
              final schedule = ScheduleModel.fromMap(scheduleData);
              loadedSchedules.add(schedule);
              print('DEBUG: Loaded schedule: ${schedule.title} at ${schedule.startDateTime}');
            } catch (e) {
              print('ERROR: Failed to parse schedule: $e');
              print('ERROR: Schedule data was: $scheduleData');
            }
          }
          
          schedules.value = loadedSchedules;
          print('DEBUG: Successfully loaded ${loadedSchedules.length} schedules');
        } else {
          print('DEBUG: No schedules in response, falling back to direct query');
          await _loadSchedulesForDateDirect(date);
        }
      } else {
        print('DEBUG: RPC response is null, falling back to direct query');
        await _loadSchedulesForDateDirect(date);
      }
      
      // After loading schedules, load their attendance status
      await _loadCurrentAttendanceStatus();
      
    } catch (e) {
      print('ERROR: Exception loading schedules: $e');
      await _loadSchedulesForDateDirect(date);
    } finally {
      isLoading.value = false;
    }
  }

  // Fallback method for direct schedule fetching
  Future<void> _loadSchedulesForDateDirect(DateTime date) async {
    try {
      print('DEBUG: Using fallback direct query for schedules');
      
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final List<Map<String, dynamic>> schedulesData = await _supabaseService.select(
        'employee_schedules',
        gte: 'start_date_time',
        gteValue: startOfDay.toIso8601String(),
        lte: 'start_date_time',
        lteValue: endOfDay.toIso8601String(),
        eq: 'assigned_user_id',
        eqValue: currentUser.value!.uId,
        orderBy: 'start_date_time',
      );
      
      final List<ScheduleModel> loadedSchedules = [];
      for (final scheduleData in schedulesData) {
        try {
          final schedule = ScheduleModel.fromMap(scheduleData);
          loadedSchedules.add(schedule);
        } catch (e) {
          print('Error parsing schedule: $e');
        }
      }
      
      schedules.value = loadedSchedules;
      print('DEBUG: Fallback loaded ${loadedSchedules.length} schedules');
      
      // After loading schedules, load their attendance status
      await _loadCurrentAttendanceStatus();
      
    } catch (e) {
      print('Error loading schedules (fallback): $e');
      Get.snackbar(
        'Error',
        'Failed to load schedules: $e',
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
      );
    }
  }

  Future<void> checkInForSchedule(ScheduleModel schedule) async {
    try {
      isCheckingIn.value = true;
      
      // First check if user can check in for this schedule
      final canCheckIn = await _attendanceService.canCheckInForSchedule(
        scheduleId: schedule.scheduleId,
        date: selectedDate.value,
      );
      
      if (canCheckIn['error'] == true || canCheckIn['can_check_in'] != true) {
        Get.snackbar(
          'Cannot Check In',
          canCheckIn['message'] ?? 'Unable to check in for this schedule',
          backgroundColor: AppConstant.warningColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking you in...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Get current location
      final location = await _locationService.getCurrentLocation();
      
      final result = await _attendanceService.clockIn(
        scheduleId: schedule.scheduleId,
        latitude: location?.latitude ?? 0.0,
        longitude: location?.longitude ?? 0.0,
        address: 'Work Location',
      );

      Get.back(); // Close loading dialog

      if (result['success'] == true) {
        // Success feedback
        Get.snackbar(
          'Success! 🎉',
          'You have successfully checked in for ${schedule.title}',
          backgroundColor: AppConstant.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
        
        // Refresh data to update UI
        await refreshData();
        
        // Show important reminder
        _showCheckOutReminder();
        
      } else {
        throw Exception(result['message'] ?? 'Check-in failed');
      }
      
    } catch (e) {
      Get.back(); // Close loading dialog if open
      
      Get.snackbar(
        'Check-in Failed ❌',
        e.toString(),
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isCheckingIn.value = false;
    }
  }

  Future<void> checkOutForSchedule(ScheduleModel schedule) async {
    try {
      isCheckingOut.value = true;
      
      // Get attendance status for this specific schedule
      final attendanceStatus = scheduleAttendanceStatus[schedule.scheduleId];
      if (attendanceStatus == null || attendanceStatus['attendance_id'] == null) {
        Get.snackbar(
          'Error',
          'No active attendance found for this schedule',
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
        );
        return;
      }
      
      final attendanceId = attendanceStatus['attendance_id'].toString();
      
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking you out...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Get current location
      final location = await _locationService.getCurrentLocation();
      
      final result = await _attendanceService.clockOut(
        attendanceId: attendanceId,
        latitude: location?.latitude ?? 0.0,
        longitude: location?.longitude ?? 0.0,
        address: 'Work Location',
      );

      Get.back(); // Close loading dialog

      if (result['success'] == true) {
        final hours = result['total_hours']?.toDouble() ?? 0.0;
        
        // Success feedback with work summary
        Get.snackbar(
          'Great Work! 🎉',
          'You completed ${schedule.title} - ${hours.toStringAsFixed(2)} hours worked',
          backgroundColor: AppConstant.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
        
        // Refresh data to update UI
        await refreshData();
        
      } else {
        throw Exception(result['message'] ?? 'Check-out failed');
      }
      
    } catch (e) {
      print('Error checking out: $e');
      Get.snackbar(
        'Error',
        'Failed to check out: $e',
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isCheckingOut.value = false;
    }
  }

  Future<void> checkOut() async {
    try {
      isCheckingOut.value = true;
      
      print('DEBUG: Attempting checkout with currentAttendanceId: ${currentAttendanceId.value}');
      print('DEBUG: hasCheckedIn: ${hasCheckedIn.value}');
      print('DEBUG: hasCheckedOut: ${hasCheckedOut.value}');
      
      if (currentAttendanceId.value == null) {
        // Try to reload current attendance status before failing
        await _loadCurrentAttendanceStatus();
        
        if (currentAttendanceId.value == null) {
          throw Exception('No active attendance record found. Please check in first.');
        }
      }
      
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking you out...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Get current location
      final location = await _locationService.getCurrentLocation();
      
      final result = await _attendanceService.clockOut(
        attendanceId: currentAttendanceId.value!,
        latitude: location?.latitude ?? 0.0,
        longitude: location?.longitude ?? 0.0,
        address: 'Work Location',
      );

      Get.back(); // Close loading dialog

      if (result['success'] == true) {
        final hours = result['total_hours']?.toDouble() ?? 0.0;
        
        // Update attendance status immediately
        hasCheckedOut.value = true;
        checkOutTime.value = DateTime.now();
        totalHours.value = hours;
        
        // Success feedback with work summary
        Get.snackbar(
          'Great Work! 🎉',
          'You worked ${hours.toStringAsFixed(2)} hours today',
          backgroundColor: AppConstant.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
        
        // Refresh data
        await refreshData();
        
      } else {
        throw Exception(result['message'] ?? 'Check-out failed');
      }
      
    } catch (e) {
      Get.back(); // Close loading dialog if open
      
      Get.snackbar(
        'Check-out Failed ❌',
        e.toString(),
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isCheckingOut.value = false;
    }
  }

  void _showCheckOutReminder() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            SizedBox(width: 8),
            Text('Important Reminder'),
          ],
        ),
        content: const Text(
          'Don\'t forget to check out when you finish your shift! '
          'This ensures accurate tracking of your work hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadSchedulesForDate(date);
  }

  bool canCheckIn() {
    return !hasCheckedIn.value && schedules.isNotEmpty;
  }

  bool canCheckOut() {
    return hasCheckedIn.value && !hasCheckedOut.value;
  }

  String getWorkingStatus() {
    if (hasCheckedOut.value) {
      return 'Work Completed';
    } else if (hasCheckedIn.value) {
      return 'Currently Working';
    } else {
      return 'Not Started';
    }
  }

  Color getStatusColor() {
    if (hasCheckedOut.value) {
      return AppConstant.successColor;
    } else if (hasCheckedIn.value) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
}
