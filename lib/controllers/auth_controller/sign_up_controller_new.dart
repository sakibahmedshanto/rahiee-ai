// ignore_for_file: file_names, unused_field, body_might_complete_normally_nullable, unused_local_variable

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_constant.dart';
import 'get_user_data_controller.dart';

class SignUpController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  final GetUserDataController _getUserDataController = Get.put(GetUserDataController());

  //for password visibility
  var isPasswordVisible = false.obs;

  Future<AuthResponse?> signUpMethod(
    String userName,
    String userEmail,
    String userPhone,
    String userCity,
    String userPassword,
    String userDeviceToken,
  ) async {
    try {
      EasyLoading.show(status: "Creating account...");
      
      // Create user account in Supabase Auth
      final AuthResponse response = await _supabaseService.signUpWithEmail(
        userEmail,
        userPassword,
        data: {
          'full_name': userName,
          'phone': userPhone,
          'city': userCity,
        },
      );

      if (response.user != null) {
        // For email confirmation workflow, we'll create the user profile during sign-in
        // This prevents issues with unconfirmed users having profiles
        
        EasyLoading.dismiss();
        
        // Show success message based on email confirmation status
        if (response.user!.emailConfirmedAt == null) {
          Get.snackbar(
            "Success", 
            "Account created! Please check your email to verify your account before signing in.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstant.appMainColor,
            colorText: AppConstant.appTextColor,
            duration: Duration(seconds: 5),
          );
        } else {
          // If email is already confirmed (instant confirmation), create profile now
          try {
            UserModel userModel = UserModel(
              uId: response.user!.id,
              employeeId: 'EMP-${response.user!.id.substring(0, 8).toUpperCase()}',
              username: userName,
              email: userEmail,
              phone: userPhone,
              fullName: userName,
              department: 'General',
              position: 'Employee',
              userRole: 'employee',
              userImg: null,
              userDeviceToken: userDeviceToken.isNotEmpty ? userDeviceToken : null,
              isActive: true,
              createdOn: DateTime.now(),
              workLocation: userCity.isNotEmpty ? userCity : null,
              biometricEnabled: false,
              notificationsEnabled: true,
              preferredLanguage: 'en',
              leaveBalance: 30,
              totalCoverageGiven: 0,
              totalCoverageReceived: 0,
              attendanceRate: 100.0,
            );

            final success = await _getUserDataController.createUserModel(userModel);
            
            if (success) {
              Get.snackbar(
                "Success", 
                "Account created successfully! You can now sign in.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppConstant.appMainColor,
                colorText: AppConstant.appTextColor,
              );
            } else {
              print('Warning: User profile creation failed during signup, will be created during sign-in');
              Get.snackbar(
                "Success", 
                "Account created! Your profile will be set up when you first sign in.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppConstant.appMainColor,
                colorText: AppConstant.appTextColor,
              );
            }
          } catch (e) {
            print('Error creating user profile during signup: $e');
            Get.snackbar(
              "Success", 
              "Account created! Your profile will be set up when you first sign in.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppConstant.appMainColor,
              colorText: AppConstant.appTextColor,
            );
          }
        }
      } else {
        EasyLoading.dismiss();
        Get.snackbar(
          "Error", 
          "Failed to create account. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstant.appScendoryColor,
          colorText: AppConstant.appTextColor,
        );
        return null;
      }
      
      return response;
      
    } on AuthException catch (authError) {
      EasyLoading.dismiss();
      String errorMessage = "Authentication failed";
      
      // Handle specific auth errors
      switch (authError.message) {
        case 'User already registered':
          errorMessage = "An account with this email already exists";
          break;
        case 'Password should be at least 6 characters':
          errorMessage = "Password must be at least 6 characters long";
          break;
        case 'Unable to validate email address: invalid format':
          errorMessage = "Please enter a valid email address";
          break;
        case 'Signup is disabled':
          errorMessage = "Account registration is currently disabled";
          break;
        default:
          errorMessage = authError.message;
      }
      
      Get.snackbar(
        "Signup Error",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
      );
      return null;
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        "Error",
        "An unexpected error occurred: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
      );
      return null;
    }
  }
}
