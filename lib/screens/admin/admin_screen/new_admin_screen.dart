// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controllers/admin_controller.dart';
import '../../../utils/app_constant.dart';
import '../../../models/user_model.dart';
import 'components/admin_bottom_navigation.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_employees_tab.dart';
import 'tabs/enhanced_admin_attendance_tab.dart';
import 'tabs/admin_schedules_tab.dart';
import 'tabs/admin_summary_tab.dart';

class AdminScreen extends StatefulWidget {
  final UserModel? userModel; // Make it optional
  
  const AdminScreen({
    super.key,
    this.userModel, // Optional parameter
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final RxInt _selectedIndex = 0.obs;
  late final AdminController adminController;

  // Get current user - either from widget parameter or from session/service
  UserModel get currentUser {
    if (widget.userModel != null) {
      return widget.userModel!;
    }
    
    // Get from Supabase session or create default admin user
    // This is where you'd typically get the current logged-in user
    return UserModel(
      uId: 'admin-001',
      employeeId: 'ADMIN001',
      username: 'admin',
      email: 'admin@rahiee.ai',
      phone: '+1234567890',
      fullName: 'System Administrator',
      department: 'IT',
      position: 'System Administrator',
      userRole: 'admin',
      isActive: true,
      createdOn: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    adminController = Get.put(AdminController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          switch (_selectedIndex.value) {
            case 0:
              return const AdminDashboardTab();
            case 1:
              return const AdminEmployeesTab();
            case 2:
              return const EnhancedAdminAttendanceTab();
            case 3:
              return const AdminSchedulesTab();
            case 4:
              return const AdminSummaryTab();
            default:
              return const AdminDashboardTab();
          }
        }),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        selectedIndex: _selectedIndex,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstant.primaryColor,
      foregroundColor: AppConstant.textLight,
      elevation: 0,
      title: Obx(() {
        String title = 'Admin Dashboard';
        switch (_selectedIndex.value) {
          case 0:
            title = 'Admin Dashboard';
            break;
          case 1:
            title = 'Employee Management';
            break;
          case 2:
            title = 'Attendance Management';
            break;
          case 3:
            title = 'Schedule Management';
            break;
          case 4:
            title = 'Summary Reports';
            break;
        }
        return Text(
          title,
          style: TextStyle(
            color: AppConstant.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        );
      }),
      actions: [
        // Notification indicator
        Obx(() => Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: () {
                // Handle notifications
              },
            ),
            if (adminController.totalPendingApprovals.value > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppConstant.errorColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${adminController.totalPendingApprovals.value}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        )),
        
        // Refresh button
        Obx(() => IconButton(
          icon: adminController.isRefreshing.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstant.textLight),
                  ),
                )
              : Icon(Icons.refresh),
          onPressed: adminController.isRefreshing.value
              ? null
              : () => adminController.refreshData(),
        )),
        
        // User profile
        PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: AppConstant.accentColor,
            backgroundImage: currentUser.userImg != null
                ? NetworkImage(currentUser.userImg!)
                : null,
            child: currentUser.userImg == null
                ? Text(
                    currentUser.fullName.isNotEmpty
                        ? currentUser.fullName[0].toUpperCase()
                        : 'A',
                    style: TextStyle(
                      color: AppConstant.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // Navigate to admin profile
                break;
              case 'settings':
                // Navigate to admin settings
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: AppConstant.textPrimary),
                  SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, color: AppConstant.textPrimary),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppConstant.errorColor),
                  SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(color: AppConstant.errorColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog first
              
              // Call the logout method from controller
              await adminController.onLogoutPressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.errorColor,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
