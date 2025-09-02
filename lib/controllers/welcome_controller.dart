// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller/google_sign_in_controller.dart';
import '../screens/auth_ui/sign_in_screen.dart';
import '../utils/app_constant.dart';

class WelcomeController extends GetxController with GetTickerProviderStateMixin {
  final GoogleSignInController googleSignInController = Get.put(GoogleSignInController());
  
  late AnimationController animationController;
  late AnimationController pulseController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> pulseAnimation;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _requestNotificationPermissions();
  }

  void _initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    
    scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));
    
    pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    animationController.forward();
  }

  Future<void> _requestNotificationPermissions() async {
    // For Supabase projects, you can implement push notifications using:
    // 1. FCM (Firebase Cloud Messaging) as a separate service
    // 2. Supabase Edge Functions with push notification providers
    // 3. Third-party notification services
    
    // For now, we'll skip notification permissions during migration
    // TODO: Implement notification system with Supabase Edge Functions
    try {
      print('Notification permissions will be implemented with Supabase Edge Functions');
    } catch (e) {
      print('Error with notification setup: $e');
    }
  }

  void onGoogleSignInPressed() async {
    bool success = await googleSignInController.signInWithGoogle();
    if (!success) {
      Get.snackbar(
        'Error',
        'Failed to sign in with Google. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        borderRadius: 15,
        margin: EdgeInsets.all(15),
      );
    }
  }

  void onGetStartedPressed() {
    Get.to(() => const SignInScreen(), transition: Transition.rightToLeft);
  }

  @override
  void onClose() {
    animationController.dispose();
    pulseController.dispose();
    super.onClose();
  }
}
