// ignore_for_file: file_names

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'auth_controller/get_user_data_controller.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/landing_screen/landing_screen.dart';
import '../screens/auth_ui/welcome_screen.dart';

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;
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
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        await _handleAuthenticatedUser(user);
      } else {
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
      var userData = await getUserDataController.getUserData(user.uid);
      UserModel? userModel = await getUserDataController.getUserModel(user.uid);

      if (userData.isNotEmpty && userData[0]['userRole'] == "admin") {
        _navigateToAdmin();
      } else if (userModel != null) {
        _navigateToLanding(userModel);
      } else {
        _navigateToWelcome();
      }
    } catch (e) {
      print('Error handling authenticated user: $e');
      _navigateToWelcome();
    }
  }

  void _navigateToAdmin() {
    Get.offAll(() => const AdminScreen());
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
