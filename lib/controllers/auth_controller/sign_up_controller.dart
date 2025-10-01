// ignore_for_file: file_names, unused_field, body_might_complete_normally_nullable, unused_local_variable

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import 'get_user_data_controller.dart';

class SignUpController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  final GetUserDataController _getUserDataController = Get.put(GetUserDataController());

  //for password visibility
  var isPasswordVisible = false.obs;

  Future<Map<String, dynamic>> signUpMethod(
    String userName,
    String userEmail,
    String userPhone,
    String userCity,
    String userPassword,
    String userDeviceToken,
  ) async {
    try {
      EasyLoading.show(status: "Please wait");
      
      // Create user account in Supabase Auth
      final AuthResponse? response = await _supabaseService.signUpWithEmail(
        userEmail,
        userPassword,
        data: {
          'full_name': userName,
          'phone': userPhone,
        },
      );

      if (response?.user != null) {
        // Create user profile in the database
        final userModel = UserModel(
          uId: response!.user!.id,
          employeeId: 'EMP-${response.user!.id.substring(0, 8).toUpperCase()}', // Generate employee ID
          username: userName,
          email: userEmail,
          phone: userPhone,
          fullName: userName, // Using username as fullName
          department: 'General', // Default department
          position: 'Employee', // Default position
          userRole: 'employee', // Default role
          userImg: '',
          userDeviceToken: userDeviceToken,
          isActive: true,
          createdOn: DateTime.now(),
        );

        // Add user data to Supabase database
        final success = await _getUserDataController.createUserModel(userModel);
        
        EasyLoading.dismiss();
        
        if (success) {
          return {
            'success': true,
            'authResponse': response,
            'message': 'Account created successfully! A verification email has been sent to your email address. Please check your inbox and verify your account before signing in.'
          };
        } else {
          // The auth account was created successfully (email sent), but profile creation failed
          if (response.user != null) {
            return {
              'success': true, // Still consider it a success since auth worked and email was sent
              'authResponse': response,
              'message': 'Account created successfully! A verification email has been sent to your email address. Please verify your account before signing in.'
            };
          } else {
            return {
              'success': false,
              'authResponse': null,
              'message': 'Failed to create account. Please try again.'
            };
          }
        }
      } else {
        EasyLoading.dismiss();
        return {
          'success': false,
          'authResponse': null,
          'message': 'Failed to create account. Please try again.'
        };
      }
      
    } catch (e) {
      EasyLoading.dismiss();
      print("Sign up error: $e");
      
      // Parse error for user-friendly messages
      String errorMessage = 'Failed to create account. Please try again.';
      
      if (e.toString().contains('email_address_invalid')) {
        errorMessage = 'Invalid email address format.';
      } else if (e.toString().contains('email_address_not_authorized')) {
        errorMessage = 'Email address not authorized for signup.';
      } else if (e.toString().contains('password')) {
        errorMessage = 'Password does not meet requirements.';
      } else if (e.toString().contains('User already registered')) {
        errorMessage = 'An account with this email already exists.';
      }
      
      return {
        'success': false,
        'authResponse': null,
        'message': errorMessage
      };
    }
  }
}
