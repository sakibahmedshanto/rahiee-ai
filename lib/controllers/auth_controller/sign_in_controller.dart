// ignore_for_file: file_names, unused_field, body_might_complete_normally_nullable, unused_local_variable
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class SignInController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.to;
  
  //for password visibility
  var isPasswordVisible = false.obs;

  Future<Map<String, dynamic>> signInMethod(String userEmail, String userPassword) async {
    try {
      EasyLoading.show(status: "Please wait");
      
      final AuthResponse? response = await _supabaseService.signInWithEmail(
        userEmail,
        userPassword,
      );
      
      EasyLoading.dismiss();
      
      if (response?.user != null) {
        // Check if email is verified
        if (response!.user!.emailConfirmedAt != null) {
          return {
            'success': true,
            'authResponse': response,
            'message': 'Login successful!'
          };
        } else {
          return {
            'success': false,
            'authResponse': response,
            'message': 'Please verify your email address first. Check your inbox (including spam folder) for the verification email and click the verification link before signing in.'
          };
        }
      } else {
        return {
          'success': false,
          'authResponse': null,
          'message': 'Invalid email or password.'
        };
      }
    } catch (e) {
      EasyLoading.dismiss();
      print("Sign in error: $e");
      
      // Parse error for user-friendly messages
      String errorMessage = 'Login failed. Please try again.';
      
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Please verify your email address first. Check your inbox (including spam folder) for the verification email.';
      } else if (e.toString().contains('email_address_invalid')) {
        errorMessage = 'Invalid email address format.';
      } else if (e.toString().contains('too_many_requests')) {
        errorMessage = 'Too many login attempts. Please wait a few minutes before trying again.';
      } else if (e.toString().contains('signups_disabled')) {
        errorMessage = 'Account registration is currently disabled. Please contact support.';
      }
      
      return {
        'success': false,
        'authResponse': null,
        'message': errorMessage
      };
    }
  }
}
