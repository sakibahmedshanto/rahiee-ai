// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_constant.dart';

class LandingController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  late UserModel userModel;
  final RxBool isLoading = false.obs;

  void initializeWithUser(UserModel user) {
    userModel = user;
    
    // Check if user is admin and redirect to admin screen
    if (userModel.isAdmin) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed('/admin', arguments: userModel);
      });
    }
  }
  Future<void> onLogoutPressed() async {
    try {
      // Show loading indicator
      EasyLoading.show(status: "Logging out...");
      
      // Sign out from Supabase
      await _supabaseService.signOut();
      
      // Dismiss loading
      EasyLoading.dismiss();
      
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
      
    } catch (e) {
      EasyLoading.dismiss();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Error',
          'Failed to logout. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
          borderRadius: 15,
          margin: EdgeInsets.all(15),
        );
      });
      
      print('Logout error: $e');
    }
  }

  String get welcomeMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String get userDisplayName {
    return userModel.fullName.isNotEmpty ? userModel.fullName : userModel.username;
  }

  String get userPosition {
    return userModel.position;
  }

  String get userDepartment {
    return userModel.department;
  }

  String get userRole {
    return userModel.userRole.toUpperCase();
  }

  String get userEmployeeId {
    return userModel.employeeId;
  }

  String get userEmail {
    return userModel.email;
  }

  String get userPhone {
    return userModel.phone;
  }

  String? get userImage {
    return userModel.userImg;
  }

  // Admin checking methods
  bool get isAdmin => userModel.isAdmin;
  bool get isCEO => userModel.isCEO;
  bool get isManager => userModel.isManager;
  bool get isEmployee => userModel.isEmployee;

  // Navigation methods
  void onAttendancePressed() {
    Get.snackbar('Attendance', 'Attendance feature coming soon');
  }

  void onSchedulePressed() {
    Get.snackbar('Schedule', 'Already on schedule screen');
  }

  void onProfilePressed() {
    Get.snackbar('Profile', 'Profile feature coming soon');
  }

  void onSettingsPressed() {
    Get.snackbar('Settings', 'Settings feature coming soon');
  }
}
