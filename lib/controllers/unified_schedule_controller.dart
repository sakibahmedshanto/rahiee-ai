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
    return hasCheckedIn.value && 
           activeSchedule.value?.scheduleId == schedule.scheduleId;
  }

  // Check if user can check in for a schedule (not already checked in for another schedule)
  bool canCheckInForSchedule(ScheduleModel schedule) {
    final isToday = selectedDate.value.year == DateTime.now().year &&
                   selectedDate.value.month == DateTime.now().month &&
                   selectedDate.value.day == DateTime.now().day;
    
    return isToday && (!hasCheckedIn.value || hasCheckedOut.value);
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
    await Future.wait([
      _loadTodayAttendance(),
      loadSchedulesForDate(selectedDate.value),
    ]);
  }

  Future<void> _loadTodayAttendance() async {
    try {
      if (currentUser.value == null) return;
      
      // Get attendance for the specific date directly from database
      final response = await _supabaseService.client
        .from('attendance')
        .select('*')
        .eq('user_id', currentUser.value!.uId)
        .gte('check_in_time', selectedDate.value.toIso8601String().split('T')[0])
        .lt('check_in_time', DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day + 1).toIso8601String().split('T')[0])
        .order('check_in_time', ascending: false)
        .limit(1);
      
      if (response.isNotEmpty) {
        final attendance = response.first;
        hasCheckedIn.value = true;
        hasCheckedOut.value = attendance['check_out_time'] != null;
        currentAttendanceId.value = attendance['attendance_id'];
        
        if (attendance['check_in_time'] != null) {
          checkInTime.value = DateTime.parse(attendance['check_in_time']);
        }
        
        if (attendance['check_out_time'] != null) {
          checkOutTime.value = DateTime.parse(attendance['check_out_time']);
        }
        
        // Calculate total hours if checked out
        if (attendance['total_working_hours'] != null) {
          final duration = Duration(seconds: attendance['total_working_hours']);
          totalHours.value = duration.inHours.toDouble() + (duration.inMinutes % 60) / 60.0;
        }
        
        // Find the active schedule if exists
        if (attendance['schedule_id'] != null) {
          _findActiveSchedule(attendance['schedule_id']);
        }
      } else {
        _resetAttendanceStatus();
      }
    } catch (e) {
      print('Error loading attendance: $e');
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
  }

  Future<void> _findActiveSchedule(String scheduleId) async {
    try {
      final schedule = schedules.firstWhereOrNull(
        (s) => s.scheduleId == scheduleId,
      );
      activeSchedule.value = schedule;
    } catch (e) {
      print('Error finding active schedule: $e');
    }
  }

  Future<void> loadSchedulesForDate(DateTime date) async {
    try {
      if (currentUser.value == null) return;
      
      isLoading.value = true;
      
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
      
    } catch (e) {
      print('Error loading schedules: $e');
      Get.snackbar(
        'Error',
        'Failed to load schedules: $e',
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkInForSchedule(ScheduleModel schedule) async {
    try {
      isCheckingIn.value = true;
      
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
        // Update attendance status immediately
        hasCheckedIn.value = true;
        currentAttendanceId.value = result['attendance_id'];
        checkInTime.value = DateTime.now();
        
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

  Future<void> checkOut() async {
    try {
      isCheckingOut.value = true;
      
      if (currentAttendanceId.value == null) {
        throw Exception('No active attendance record found');
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
