// ignore_for_file: file_names
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../utils/app_constant.dart';

class AdminController extends GetxController {
  // Observable variables
  final isLoading = false.obs;
  final users = <UserModel>[].obs;
  final departments = <String>[].obs;
  final positions = <String>[].obs;
  final selectedDate = DateTime.now().obs;
  final schedules = <ScheduleModel>[].obs;

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();

  // Selected values
  final selectedUser = Rxn<UserModel>();
  final selectedDepartment = RxString('');
  final selectedStartTime = Rxn<TimeOfDay>();
  final selectedEndTime = Rxn<TimeOfDay>();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Initialize admin data
  Future<void> _initializeData() async {
    await loadUsers();
    await loadTodaySchedules();
    _extractDepartmentsAndPositions();
  }

  // Load all active users
  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('fullName')
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
      Get.snackbar('Error', 'Failed to load users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load today's schedules
  Future<void> loadTodaySchedules() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('startDateTime')
          .get();
      
      final List<ScheduleModel> loadedSchedules = [];
      for (final doc in schedulesSnapshot.docs) {
        try {
          final schedule = ScheduleModel.fromFirestore(doc);
          loadedSchedules.add(schedule);
        } catch (e) {
          print('Error parsing schedule ${doc.id}: $e');
        }
      }
      
      schedules.value = loadedSchedules;
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  // Extract unique departments and positions from users
  void _extractDepartmentsAndPositions() {
    final uniqueDepartments = <String>{};
    final uniquePositions = <String>{};
    
    for (final user in users) {
      if (user.department.isNotEmpty) {
        uniqueDepartments.add(user.department);
      }
      if (user.position.isNotEmpty) {
        uniquePositions.add(user.position);
      }
    }
    
    departments.value = uniqueDepartments.toList()..sort();
    positions.value = uniquePositions.toList()..sort();
  }

  // Get users by department
  List<UserModel> getUsersByDepartment(String department) {
    return users.where((user) => user.department == department).toList();
  }

  // Get users by position
  List<UserModel> getUsersByPosition(String position) {
    return users.where((user) => user.position == position).toList();
  }

  // Set selected user
  void setSelectedUser(UserModel user) {
    selectedUser.value = user;
    selectedDepartment.value = user.department;
  }

  // Set selected date
  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  // Set selected start time
  void setSelectedStartTime(TimeOfDay time) {
    selectedStartTime.value = time;
  }

  // Set selected end time
  void setSelectedEndTime(TimeOfDay time) {
    selectedEndTime.value = time;
  }

  // Create new schedule
  Future<bool> createSchedule(String adminId) async {
    try {
      if (!_validateScheduleForm()) {
        return false;
      }

      isLoading.value = true;

      final startDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedStartTime.value!.hour,
        selectedStartTime.value!.minute,
      );

      final endDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedEndTime.value!.hour,
        selectedEndTime.value!.minute,
      );

      final schedule = ScheduleModel(
        scheduleId: '', // Will be set by Firestore
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        createdByAdminId: adminId,
        assignedUserId: selectedUser.value!.uId,
        department: selectedDepartment.value,
        location: locationController.text.trim(),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        isActive: true,
      );

      await FirebaseFirestore.instance
          .collection('schedules')
          .add(schedule.toFirestore());

      Get.snackbar(
        'Success',
        'Schedule created successfully for ${selectedUser.value!.fullName}',
        backgroundColor: AppConstant.successColor,
        colorText: Colors.white,
      );

      _clearForm();
      await loadTodaySchedules(); // Refresh schedules
      return true;
    } catch (e) {
      print('Error creating schedule: $e');
      Get.snackbar('Error', 'Failed to create schedule: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Validate schedule form
  bool _validateScheduleForm() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Please enter a title');
      return false;
    }

    if (selectedUser.value == null) {
      Get.snackbar('Validation Error', 'Please select a user');
      return false;
    }

    if (selectedStartTime.value == null) {
      Get.snackbar('Validation Error', 'Please select start time');
      return false;
    }

    if (selectedEndTime.value == null) {
      Get.snackbar('Validation Error', 'Please select end time');
      return false;
    }

    final startDateTime = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      selectedStartTime.value!.hour,
      selectedStartTime.value!.minute,
    );

    final endDateTime = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      selectedEndTime.value!.hour,
      selectedEndTime.value!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      Get.snackbar('Validation Error', 'End time must be after start time');
      return false;
    }

    if (locationController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Please enter a location');
      return false;
    }

    return true;
  }

  // Clear form
  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    notesController.clear();
    selectedUser.value = null;
    selectedDepartment.value = '';
    selectedStartTime.value = null;
    selectedEndTime.value = null;
    selectedDate.value = DateTime.now();
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

  // Format time for display
  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
