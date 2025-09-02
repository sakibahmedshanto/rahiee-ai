// ignore_for_file: file_names, unused_field, body_might_complete_normally_nullable, unused_local_variable, non_constant_identifier_names, prefer_const_constructors
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../screens/auth_ui/sign_in_screen.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_constant.dart';

class ForgerPasswordController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;

  Future<void> ForgetPasswordMethod(String userEmail) async {
    try {
      EasyLoading.show(status: "Please wait");
      
      await _supabaseService.resetPassword(userEmail);
      
      Get.snackbar(
        "Request Sent Successfully",
        "Password reset link sent to $userEmail",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
      );
      
      Get.offAll(() => SignInScreen());
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        "Error",
        "$e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appScendoryColor,
        colorText: AppConstant.appTextColor,
      );
    }
  }
}
