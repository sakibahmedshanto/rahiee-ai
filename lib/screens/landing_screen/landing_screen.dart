// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_model.dart';
import '../../utils/app_constant.dart';
import '../../controllers/landing_screen_controller/landing_controller.dart';
import '../schedule_screen/schedule_screen.dart';
import '../schedule_screen/components/schedule_floating_action_button.dart';
import '../profile_screen/profile_screen.dart';
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
              return _buildComingSoonScreen('Time Tracking');
            case 2:
              return _buildComingSoonScreen('Chat');
            case 3:
              return const ProfileScreen();
            case 4:
              return _buildComingSoonScreen('More');
            default:
              return const ScheduleScreen();
          }
        }),
      ),
      floatingActionButton: Obx(() => _selectedIndex.value == 0 
          ? const ScheduleFloatingActionButton() 
          : const SizedBox.shrink()),
      bottomNavigationBar: LandingBottomNavigation(
        selectedIndex: _selectedIndex,
      ),
    );
  }

  Widget _buildComingSoonScreen(String screenName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppConstant.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '$screenName',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 16,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
