// ignore_for_file: file_names, unused_field, body_might_complete_normally_nullable, unused_local_variable
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class SignInController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  
  //for password visibility
  var isPasswordVisible = false.obs;

  Future<AuthResponse?> signInMethod(String userEmail, String userPassword) async {
    try {
      EasyLoading.show(status: "Please wait");
      
      final AuthResponse response = await _supabaseService.signInWithEmail(
        userEmail,
        userPassword,
      );
      
      EasyLoading.dismiss();
      return response;
    } catch (e) {
      EasyLoading.dismiss();
      // Remove duplicate error message - let UI handle error display
      print("Sign in error: $e"); // Log for debugging
      return null;
    }
  }
}
