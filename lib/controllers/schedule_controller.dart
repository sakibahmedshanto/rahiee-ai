// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';

class ScheduleController extends GetxController {
  // Observable variables
  final isLoading = false.obs;
  final selectedDate = DateTime.now().obs;
  final schedules = <ScheduleModel>[].obs;
  final users = <UserModel>[].obs;
  final schedulesByRole = <String, List<ScheduleDisplayModel>>{}.obs;
  final schedulesByDepartment = <String, List<ScheduleDisplayModel>>{}.obs;
  final currentView = 'role'.obs; // 'role' or 'department'

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  // Initialize data with proper loading order
  Future<void> _initializeData() async {
    // Load users first, then schedules
    await loadUsers();
    await loadSchedulesForDate(selectedDate.value);
  }

  // Load schedules for selected date
  Future<void> loadSchedulesForDate(DateTime date) async {
    try {
      isLoading.value = true;
      
      // Firebase query with composite index for optimal performance
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      print('DEBUG: Loading schedules for date: ${date.toIso8601String()}');
      
      // Optimized query using Firebase composite index
      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'active')
          .get();
      
      print('DEBUG: Loaded ${schedulesSnapshot.docs.length} filtered schedules from Firestore');
      
      final List<ScheduleModel> loadedSchedules = [];
      for (final doc in schedulesSnapshot.docs) {
        try {
          final schedule = ScheduleModel.fromFirestore(doc);
          loadedSchedules.add(schedule);
          print('DEBUG: Added schedule: ${schedule.title}');
        } catch (e) {
          print('Error parsing schedule ${doc.id}: $e');
        }
      }
      
      print('DEBUG: Successfully loaded ${loadedSchedules.length} schedules for the selected date');
      
      schedules.value = loadedSchedules;
      _organizeSchedules();
      
    } catch (e) {
      print('Error loading schedules: $e');
      
      // If index is still building, show helpful message
      if (e.toString().contains('failed-precondition') && e.toString().contains('index')) {
        Get.snackbar(
          'Index Building', 
          'Firebase index is still being built. Please wait a few minutes and try again.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      } else {
        Get.snackbar('Error', 'Failed to load schedules: $e');
      }
      
      schedules.value = [];
      _organizeSchedules();
    } finally {
      isLoading.value = false;
    }
  }

  // Load users data
  Future<void> loadUsers() async {
    try {
      // Firebase query to get all active users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();
      
      final List<UserModel> loadedUsers = [];
      for (final doc in usersSnapshot.docs) {
        try {
          final user = UserModel.fromMap(doc.data());
          loadedUsers.add(user);
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
        }
      }
      
      users.value = loadedUsers;
    } catch (e) {
      print('Error loading users: $e');
      users.value = [];
      Get.snackbar('Error', 'Failed to load users: $e');
    }
  }

  // Organize schedules by both role and department
  void _organizeSchedules() {
    _organizeSchedulesByRole();
    _organizeSchedulesByDepartment();
  }

  // Organize schedules by role
  void _organizeSchedulesByRole() {
    final Map<String, List<ScheduleDisplayModel>> organized = {};
    
    for (final schedule in schedules) {
      final user = users.firstWhereOrNull((u) => u.uId == schedule.assignedUserId);
      if (user != null) {
        final role = user.position; // Using position as role
        
        if (!organized.containsKey(role)) {
          organized[role] = [];
        }
        
        organized[role]!.add(
          ScheduleDisplayModel(
            schedule: schedule,
            user: user,
          ),
        );
      }
    }
    
    // Sort roles (Bartender first, then alphabetically)
    final sortedKeys = organized.keys.toList()
      ..sort((a, b) {
        if (a == 'Bartender') return -1;
        if (b == 'Bartender') return 1;
        return a.compareTo(b);
      });
    
    final sortedMap = <String, List<ScheduleDisplayModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = organized[key]!;
    }
    
    schedulesByRole.value = sortedMap;
  }

  // Organize schedules by department
  void _organizeSchedulesByDepartment() {
    final Map<String, List<ScheduleDisplayModel>> organized = {};
    
    for (final schedule in schedules) {
      final user = users.firstWhereOrNull((u) => u.uId == schedule.assignedUserId);
      if (user != null) {
        final department = schedule.department; // Using schedule department
        
        if (!organized.containsKey(department)) {
          organized[department] = [];
        }
        
        organized[department]!.add(
          ScheduleDisplayModel(
            schedule: schedule,
            user: user,
          ),
        );
      }
    }
    
    // Sort departments alphabetically
    final sortedKeys = organized.keys.toList()..sort();
    
    final sortedMap = <String, List<ScheduleDisplayModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = organized[key]!;
    }
    
    schedulesByDepartment.value = sortedMap;
  }

  // Toggle between role and department view
  void toggleView() {
    currentView.value = currentView.value == 'role' ? 'department' : 'role';
  }

  // Get current organized schedules based on view
  Map<String, List<ScheduleDisplayModel>> get currentSchedules {
    return currentView.value == 'role' ? schedulesByRole : schedulesByDepartment;
  }

  // Change selected date
  void changeDate(DateTime newDate) {
    selectedDate.value = newDate;
    loadSchedulesForDate(newDate);
  }

  // Navigate to previous day
  void previousDay() {
    final newDate = selectedDate.value.subtract(const Duration(days: 1));
    changeDate(newDate);
  }

  // Navigate to next day
  void nextDay() {
    final newDate = selectedDate.value.add(const Duration(days: 1));
    changeDate(newDate);
  }

  // Format date for display
  String get formattedDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    final date = selectedDate.value;
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    
    return '$weekday, $month ${date.day}';
  }

  // Refresh schedules
  Future<void> refreshSchedules() async {
    await loadSchedulesForDate(selectedDate.value);
  }
}

// Helper class for displaying schedule with user info
class ScheduleDisplayModel {
  final ScheduleModel schedule;
  final UserModel user;

  ScheduleDisplayModel({
    required this.schedule,
    required this.user,
  });

  String get timeRange {
    final start = schedule.startDateTime;
    final end = schedule.endDateTime;
    
    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    
    return '$startTime am - $endTime pm';
  }
}
