// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_controller/google_sign_in_controller.dart';
import '../screens/auth_ui/sign_in_screen.dart';

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
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permissions');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional notification permissions');
      } else {
        print('User declined or has not accepted notification permissions');
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  void onGoogleSignInPressed() {
    googleSignInController.signInWithGoogle();
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
