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
      EasyLoading.show(status: "Please wait");
      
      // Create user account in Supabase Auth
      final AuthResponse response = await _supabaseService.signUpWithEmail(
        userEmail,
        userPassword,
        data: {
          'full_name': userName,
          'phone': userPhone,
        },
      );

      if (response.user != null) {
        // Create user profile in the users table
        UserModel userModel = UserModel(
          uId: response.user!.id,
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
        
        if (!success) {
          Get.snackbar("Error", "Failed to create user profile");
          return null;
        }
      }
      
      EasyLoading.dismiss();
      return response;
      
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        "Error",
        "$e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
      );
      return null;
    }
  }
}
