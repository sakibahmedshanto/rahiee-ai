// ignore_for_file: file_names

import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'auth_controller/get_user_data_controller.dart';
import '../screens/landing_screen/landing_screen.dart';
import '../screens/auth_ui/welcome_screen.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;
  final SupabaseService _supabaseService = SupabaseService.to;
  final GetUserDataController getUserDataController = Get.put(GetUserDataController());
  
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  void _initializeApp() {
    Timer(const Duration(seconds: 3), () {
      _checkUserAuthentication();
    });
  }

  Future<void> _checkUserAuthentication() async {
    try {
      User? user = _supabaseService.currentUser;
      print('DEBUG: Checking user authentication in splash');
      print('DEBUG: Current user: ${user?.id}');
      print('DEBUG: Email confirmed: ${user?.emailConfirmedAt != null}');
      
      if (user != null) {
        print('DEBUG: User found, checking email verification');
        if (user.emailConfirmedAt != null) {
          print('DEBUG: Email verified, handling authenticated user');
          await _handleAuthenticatedUser(user);
        } else {
          print('DEBUG: Email not verified, navigating to welcome');
          _navigateToWelcome();
        }
      } else {
        print('DEBUG: No user found, navigating to welcome');
        _navigateToWelcome();
      }
    } catch (e) {
      print('Error checking authentication: $e');
      _navigateToWelcome();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleAuthenticatedUser(User user) async {
    try {
      print('DEBUG: Handling authenticated user: ${user.id}');
      UserModel? userModel = await getUserDataController.getUserModel(user.id);
      
      if (userModel != null) {
        print('DEBUG: UserModel loaded: ${userModel.fullName}');
        print('DEBUG: UserModel isAdmin: ${userModel.isAdmin}');
        
        if (userModel.isAdmin) {
          print('DEBUG: Navigating to admin screen from splash');
          _navigateToAdmin(userModel);
        } else {
          print('DEBUG: Navigating to landing screen');
          _navigateToLanding(userModel);
        }
      } else {
        print('DEBUG: No user model found, navigating to welcome');
        _navigateToWelcome();
      }
    } catch (e) {
      print('Error handling authenticated user: $e');
      _navigateToWelcome();
    }
  }

  void _navigateToAdmin(UserModel userModel) {
    Get.offAllNamed('/admin', arguments: userModel);
  }

  void _navigateToLanding(UserModel userModel) {
    Get.offAll(() => LandingScreen(userModel: userModel));
  }

  void _navigateToWelcome() {
    Get.offAll(() => const WelcomeScreen());
  }

  @override
  void onClose() {
    super.onClose();
  }
}
