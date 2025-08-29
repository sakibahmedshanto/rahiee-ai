// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminController extends GetxController {
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
      print('DEBUG: Starting to load users from Firestore...');
      
      // Simplified query to avoid index requirement
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      print('DEBUG: Loaded ${usersSnapshot.docs.length} documents from Firestore');
      
      final List<UserModel> users = [];
      for (final doc in usersSnapshot.docs) {
        try {
          final userData = doc.data();
          print('DEBUG: Processing user document: ${doc.id}');
          print('DEBUG: User data keys: ${userData.keys.toList()}');
          
          // Check if required fields exist
          if (!userData.containsKey('fullName') || !userData.containsKey('userRole')) {
            print('DEBUG: Skipping user ${doc.id} - missing required fields');
            continue;
          }
          
          final user = UserModel.fromMap(userData);
          
          // Filter in app instead of in query to avoid index requirement
          if (user.isActive && !user.isAdmin) {
            users.add(user);
            print('DEBUG: Added user: ${user.fullName} (${user.userRole})');
          } else {
            print('DEBUG: Filtered out user: ${user.fullName} (isActive: ${user.isActive}, isAdmin: ${user.isAdmin})');
          }
        } catch (e) {
          print('Error parsing user ${doc.id}: $e');
          print('DEBUG: User data: ${doc.data()}');
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
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (final user in selectedUsers) {
        final scheduleData = {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'startDateTime': Timestamp.fromDate(
            DateTime(
              selectedDate.value.year,
              selectedDate.value.month,
              selectedDate.value.day,
              selectedStartTime.value.hour,
              selectedStartTime.value.minute,
            ),
          ),
          'endDateTime': Timestamp.fromDate(
            DateTime(
              selectedDate.value.year,
              selectedDate.value.month,
              selectedDate.value.day,
              selectedEndTime.value.hour,
              selectedEndTime.value.minute,
            ),
          ),
          'createdByAdminId': adminUser.uId,
          'assignedUserId': user.uId,
          'department': selectedDepartment.value,
          'location': locationController.text.trim(),
          'status': 'active',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'notes': notesController.text.trim(),
          'isActive': true,
        };
        
        final docRef = FirebaseFirestore.instance.collection('schedules').doc();
        batch.set(docRef, scheduleData);
      }
      
      await batch.commit();
      
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
  void onLogoutPressed() {
    Get.offAllNamed('/sign-in');
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
