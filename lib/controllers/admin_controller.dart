// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../utils/app_constant.dart';

class AdminController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  late UserModel adminUser;
  
  // Observable variables
  final isLoading = false.obs;
  final isLoadingUsers = false.obs;
  final allUsers = <UserModel>[].obs;
  final selectedUsers = <UserModel>[].obs;
  final selectedDate = DateTime.now().obs;
  final selectedStartTime = TimeOfDay.now().obs;
  final selectedEndTime = TimeOfDay.now().obs;
  final selectedDepartment = 'Restaurant'.obs;
  final userFilterDepartment = 'All'.obs;
  
  // Form variables
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();
  
  // Department options
  final departments = [
    'Restaurant',
    'Kitchen',
    'Management',
    'Cleaning',
    'Security',
    'Maintenance'
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllUsers();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void initializeWithUser(UserModel user) {
    print('DEBUG: AdminController initializing with user: ${user.fullName}');
    print('DEBUG: User role: ${user.userRole}');
    print('DEBUG: Is admin: ${user.isAdmin}');
    adminUser = user;
  }

  // Load all active users for schedule assignment
  Future<void> loadAllUsers() async {
    try {
      isLoadingUsers.value = true;
      print('DEBUG: Starting to load users from Supabase...');
      
      // Get all users from Supabase
      final List<Map<String, dynamic>> usersData = await _supabaseService.select(
        'my_users',
        orderBy: 'full_name',
      );
      
      print('DEBUG: Loaded ${usersData.length} documents from Supabase');
      
      final List<UserModel> users = [];
      for (final userData in usersData) {
        try {
          print('DEBUG: Processing user: ${userData['full_name']}');
          
          // Check if required fields exist
          if (userData['full_name'] == null || userData['user_role'] == null) {
            print('DEBUG: Skipping user - missing required fields');
            continue;
          }
          
          final user = UserModel.fromMap(userData);
          
          // Filter active non-admin users
          if (user.isActive && !user.isAdmin) {
            users.add(user);
            print('DEBUG: Added user: ${user.fullName} (${user.userRole})');
          } else {
            print('DEBUG: Filtered out user: ${user.fullName} (isActive: ${user.isActive}, isAdmin: ${user.isAdmin})');
          }
        } catch (e) {
          print('Error parsing user: $e');
          print('DEBUG: User data: $userData');
        }
      }
      
      // Sort users by department and then by name
      users.sort((a, b) {
        final deptComparison = a.department.compareTo(b.department);
        if (deptComparison != 0) return deptComparison;
        return a.fullName.compareTo(b.fullName);
      });
      
      allUsers.value = users;
      print('DEBUG: Successfully loaded ${users.length} valid users');
    } catch (e) {
      print('Error loading users: $e');
      Get.snackbar('Error', 'Failed to load users: $e');
    } finally {
      isLoadingUsers.value = false;
      print('DEBUG: Finished loading users');
    }
  }

  // Toggle user selection
  void toggleUserSelection(UserModel user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
  }

  // Check if user is selected
  bool isUserSelected(UserModel user) {
    return selectedUsers.contains(user);
  }

  // Set selected date
  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  // Set start time
  void setStartTime(TimeOfDay time) {
    selectedStartTime.value = time;
  }

  // Set end time
  void setEndTime(TimeOfDay time) {
    selectedEndTime.value = time;
  }

  // Set department
  void setDepartment(String department) {
    selectedDepartment.value = department;
  }

  // Create schedule for selected users
  Future<void> createSchedule() async {
    if (!_validateScheduleForm()) return;
    
    try {
      isLoading.value = true;
      
      for (final user in selectedUsers) {
        final startDateTime = DateTime(
          selectedDate.value.year,
          selectedDate.value.month,
          selectedDate.value.day,
          selectedStartTime.value.hour,
          selectedStartTime.value.minute,
        );
        
        final endDateTime = DateTime(
          selectedDate.value.year,
          selectedDate.value.month,
          selectedDate.value.day,
          selectedEndTime.value.hour,
          selectedEndTime.value.minute,
        );
        
        final scheduleData = {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'start_date_time': startDateTime.toIso8601String(),
          'end_date_time': endDateTime.toIso8601String(),
          'created_by_admin_id': adminUser.uId,
          'assigned_user_id': user.uId,
          'department': selectedDepartment.value,
          'location': locationController.text.trim(),
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'notes': notesController.text.trim(),
          'is_active': true,
        };
        
        await _supabaseService.insert('employee_schedules', scheduleData);
      }
      
      Get.snackbar(
        'Success', 
        'Schedule created for ${selectedUsers.length} employee(s)',
        snackPosition: SnackPosition.TOP,
      );
      
      _clearForm();
      
    } catch (e) {
      print('Error creating schedule: $e');
      Get.snackbar('Error', 'Failed to create schedule: $e');
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
    
    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Please enter a description');
      return false;
    }
    
    if (locationController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Please enter a location');
      return false;
    }
    
    if (selectedUsers.isEmpty) {
      Get.snackbar('Validation Error', 'Please select at least one employee');
      return false;
    }
    
    // Check if end time is after start time
    final startDateTime = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      selectedStartTime.value.hour,
      selectedStartTime.value.minute,
    );
    
    final endDateTime = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      selectedEndTime.value.hour,
      selectedEndTime.value.minute,
    );
    
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      Get.snackbar('Validation Error', 'End time must be after start time');
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
    selectedUsers.clear();
    selectedDate.value = DateTime.now();
    selectedStartTime.value = TimeOfDay.now();
    selectedEndTime.value = TimeOfDay.now();
    selectedDepartment.value = 'Restaurant';
  }

  // Logout functionality
  Future<void> onLogoutPressed() async {
    try {
      // Show loading indicator
      EasyLoading.show(status: "Logging out...");
      
      // Sign out from Supabase
      await _supabaseService.signOut();
      
      // Clear any cached user data
      allUsers.clear();
      selectedUsers.clear();
      
      // Reset form data
      selectedStartTime.value = TimeOfDay.now();
      selectedEndTime.value = TimeOfDay.now();
      selectedDate.value = DateTime.now();
      titleController.clear();
      descriptionController.clear();
      locationController.clear();
      notesController.clear();
      
      // Dismiss loading
      EasyLoading.dismiss();
      
      // Show success message
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.successColor,
        colorText: Colors.white,
        borderRadius: 15,
        margin: EdgeInsets.all(15),
      );
      
      // Navigate to welcome screen and clear navigation stack
      Get.offAllNamed('/welcome');
      
    } catch (e) {
      EasyLoading.dismiss();
      
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        borderRadius: 15,
        margin: EdgeInsets.all(15),
      );
      
      print('Logout error: $e');
    }
  }

  // Get users by department for easier selection
  List<UserModel> getUsersByDepartment(String department) {
    return allUsers.where((user) => user.department == department).toList();
  }

  // Get formatted date string
  String get formattedDate {
    final date = selectedDate.value;
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get formatted time string
  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Set user filter department
  void setUserFilterDepartment(String department) {
    userFilterDepartment.value = department;
  }

  // Select all filtered users
  void selectAllUsers(List<UserModel> users) {
    selectedUsers.clear();
    selectedUsers.addAll(users);
  }

  // Clear user selection
  void clearUserSelection() {
    selectedUsers.clear();
  }

  // Toggle user selection by user ID
  void toggleUserSelectionById(String userId) {
    final user = allUsers.firstWhereOrNull((u) => u.uId == userId);
    if (user != null) {
      toggleUserSelection(user);
    }
  }
}
