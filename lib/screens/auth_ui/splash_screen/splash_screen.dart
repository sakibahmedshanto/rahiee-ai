// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_constant.dart';
import '../../../controllers/splash_controller.dart';
import 'components/animated_logo.dart';
import 'components/animated_loading_text.dart';
import 'components/splash_bottom_content.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller (logic will run automatically)
    Get.put(SplashController());
    
    return Scaffold(
      backgroundColor: AppConstant.appScendoryColor,
      appBar: AppBar(
        backgroundColor: AppConstant.appScendoryColor,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 70),
          
          // Animated Logo Component
          const AnimatedLogo(),
          
          // Animated Loading Text Component
          const AnimatedLoadingText(),

          SizedBox(height: Get.height / 6),
          
          // Bottom Content Component
          const SplashBottomContent(),
        ],
      ),
    );
  }
}
