// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_constant.dart';
import '../../controllers/admin_controller/admin_controller.dart';
import '../../models/user_model.dart';
import 'components/admin_header.dart';
import 'components/schedule_form.dart';
import 'components/user_selection.dart';
import 'components/create_schedule_button.dart';
import 'components/admin_stats_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late AdminController adminController;
  UserModel? userModel;

  @override
  void initState() {
    super.initState();
    print('DEBUG: AdminScreen initState called');
    print('DEBUG: Get.arguments: ${Get.arguments}');
    
    adminController = Get.put(AdminController());
    
    // Safely get UserModel from arguments with null checking
    userModel = Get.arguments as UserModel?;
    
    print('DEBUG: UserModel from arguments: ${userModel?.fullName}');
    
    // If no user model is provided, redirect to sign-in
    if (userModel == null) {
      print('DEBUG: UserModel is null, redirecting to sign-in');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/sign-in');
        Get.snackbar(
          'Error',
          'Please sign in again',
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
        );
      });
    } else {
      // Initialize admin controller with valid user
      print('DEBUG: Initializing AdminController with user');
      adminController.initializeWithUser(userModel!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no user model, show loading screen while redirecting
    if (userModel == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstant.primaryColor),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstant.gradientStart.withOpacity(0.1),
              AppConstant.gradientEnd.withOpacity(0.05),
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Admin Header
            AdminHeader(),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppConstant.primaryColor,
                            AppConstant.primaryColor.withOpacity(0.8),
                            AppConstant.secondaryColor,
                          ],
                          stops: [0.0, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstant.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back, Admin!',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      userModel!.fullName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Schedule Management System',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Quick Stats Overview
                    AdminStatsWidget(),
                    
                    SizedBox(height: 24),
                    
                    // Create Schedule Section
                    Text(
                      'Create New Schedule',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Schedule Form
                    ScheduleForm(),
                    
                    SizedBox(height: 24),
                    
                    // User Selection Section
                    Text(
                      'Select Employees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // User Selection Grid
                    UserSelection(),
                    
                    SizedBox(height: 32),
                    
                    // Create Schedule Button
                    CreateScheduleButton(),
                    
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
