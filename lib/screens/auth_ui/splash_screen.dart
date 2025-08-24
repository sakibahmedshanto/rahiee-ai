// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../utils/app_constant.dart';
import '../../controllers/splash_controller.dart';

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
          Container(
            width: Get.width / 1.2,
            alignment: Alignment.center,
            child: Lottie.asset('assets/lottie/loading_lottie.json'),
          ),
          Text(
            "Loading...",
            style: TextStyle(
              color: AppConstant.appTextColor,
              fontSize: 18.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: Get.height / 3.5),
          Container(
            width: Get.width,
            alignment: Alignment.center,
            child: Text(
              AppConstant.appPoweredBy,
              style: TextStyle(
                color: AppConstant.appTextColor,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
