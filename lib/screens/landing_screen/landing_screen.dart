// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rahiee_ai/screens/attendance_history_screen/attendance_history_screen.dart';
import '../../models/user_model.dart';
import '../../utils/app_constant.dart';
import '../../controllers/landing_screen_controller/landing_controller.dart';
import '../profile_screen/profile_screen.dart';
import '../schedule_screen/schedule_screen.dart';
import '../notifications/notifications_screen.dart';
import 'components/landing_bottom_navigation.dart';

class LandingScreen extends StatefulWidget {
  final UserModel userModel;
  
  const LandingScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final RxInt _selectedIndex = 0.obs;
  late final LandingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LandingController());
    controller.initializeWithUser(widget.userModel);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      body: SafeArea(
        bottom: false, // Allow navigation bar to extend to bottom
        child: Obx(() {
          switch (_selectedIndex.value) {
            case 0:
              return const ScheduleScreen();
            case 1:
              return const AttendanceHistoryScreen();
            case 2:
              return const NotificationsScreen();
            case 3:
              return const ProfileScreen();
            default:
              return const ScheduleScreen();
          }
        }),
      ),
      bottomNavigationBar: LandingBottomNavigation(
        selectedIndex: _selectedIndex,
      ),
    );
  }

}
