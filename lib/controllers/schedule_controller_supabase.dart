// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class ScheduleController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString selectedDate = DateTime.now().toString().split(' ')[0].obs;
  final RxString currentView = 'role'.obs;
  final RxString errorMessage = ''.obs;
  
  // Data storage
  final RxList<ScheduleModel> allSchedules = <ScheduleModel>[].obs;
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxMap<String, List<ScheduleModel>> schedulesByRole = <String, List<ScheduleModel>>{}.obs;
  final RxMap<String, List<ScheduleModel>> schedulesByDepartment = <String, List<ScheduleModel>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadSchedulesForDate(DateTime.now());
  }

  // Get current schedules based on view
  Map<String, List<ScheduleModel>> get currentSchedules {
    return currentView.value == 'role' ? schedulesByRole : schedulesByDepartment;
  }

  void toggleView() {
    currentView.value = currentView.value == 'role' ? 'department' : 'role';
    _organizeSchedules();
  }

  Future<void> loadSchedulesForDate(DateTime date) async {
    try {
      isLoading(true);
      errorMessage('');

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print('DEBUG: Loading schedules for date: $date');

      final scheduleData = await _supabaseService.select(
        'employee_schedules',
        eq: 'status',
        eqValue: 'active',
        gte: 'start_date_time',
        gteValue: startOfDay.toIso8601String(),
        lte: 'start_date_time',
        lteValue: endOfDay.toIso8601String(),
        orderBy: 'start_date_time',
      );

      print('DEBUG: Supabase response: $scheduleData');

      allSchedules.clear();
      
      if (scheduleData.isNotEmpty) {
        for (var scheduleMap in scheduleData) {
          try {
            final schedule = ScheduleModel.fromMap(scheduleMap);
            allSchedules.add(schedule);
          } catch (e) {
            print('DEBUG: Error parsing schedule: $e');
          }
        }
      }

      selectedDate.value = date.toString().split(' ')[0];
      _organizeSchedules();
      
      print('DEBUG: Loaded ${allSchedules.length} schedules');

    } catch (e) {
      print('DEBUG: Error loading schedules: $e');
      errorMessage('Failed to load schedules: $e');
      
      // Show user-friendly error message
      Get.snackbar(
        'Error Loading Schedules',
        'Unable to load schedules. Please check your connection and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadUsers() async {
    try {
      print('DEBUG: Loading users from Supabase...');

      final userData = await _supabaseService.select(
        'my_users',
        eq: 'is_active',
        eqValue: true,
        orderBy: 'full_name',
      );

      print('DEBUG: Users response: $userData');

      allUsers.clear();
      
      if (userData.isNotEmpty) {
        for (var userMap in userData) {
          try {
            final user = UserModel.fromMap(userMap);
            // Filter out admin users for schedule display
            if (!user.isAdmin) {
              allUsers.add(user);
            }
          } catch (e) {
            print('DEBUG: Error parsing user: $e');
          }
        }
      }

      print('DEBUG: Loaded ${allUsers.length} users');

    } catch (e) {
      print('DEBUG: Error loading users: $e');
      errorMessage('Failed to load users: $e');
    }
  }

  void _organizeSchedules() {
    schedulesByRole.clear();
    schedulesByDepartment.clear();

    for (var schedule in allSchedules) {
      // Find the user for this schedule
      final user = allUsers.firstWhereOrNull((u) => u.uId == schedule.assignedUserId);
      
      if (user != null) {
        // Organize by role
        final role = user.position.isNotEmpty ? user.position : 'Unassigned';
        if (!schedulesByRole.containsKey(role)) {
          schedulesByRole[role] = [];
        }
        schedulesByRole[role]!.add(schedule);

        // Organize by department
        final department = schedule.department.isNotEmpty ? schedule.department : (user.department.isNotEmpty ? user.department : 'General');
        if (!schedulesByDepartment.containsKey(department)) {
          schedulesByDepartment[department] = [];
        }
        schedulesByDepartment[department]!.add(schedule);
      }
    }

    print('DEBUG: Organized by role: ${schedulesByRole.keys}');
    print('DEBUG: Organized by department: ${schedulesByDepartment.keys}');
  }

  Future<void> refresh() async {
    await loadUsers();
    await loadSchedulesForDate(DateTime.parse(selectedDate.value));
  }

  void previousDay() {
    final currentDate = DateTime.parse(selectedDate.value);
    final previousDate = currentDate.subtract(const Duration(days: 1));
    loadSchedulesForDate(previousDate);
  }

  void nextDay() {
    final currentDate = DateTime.parse(selectedDate.value);
    final nextDate = currentDate.add(const Duration(days: 1));
    loadSchedulesForDate(nextDate);
  }

  String getFormattedDate() {
    final date = DateTime.parse(selectedDate.value);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // Helper method to get user by ID
  UserModel? getUserById(String userId) {
    return allUsers.firstWhereOrNull((user) => user.uId == userId);
  }

  // Helper method to format time
  String formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Helper method to get time range
  String getTimeRange(ScheduleModel schedule) {
    final startTime = formatTime(schedule.startDateTime);
    final endTime = formatTime(schedule.endDateTime);
    return '$startTime - $endTime';
  }
}
