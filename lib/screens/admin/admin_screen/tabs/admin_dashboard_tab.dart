// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';
import '../components/dashboard_stats_cards.dart';
import '../components/dashboard_chart_widget.dart';
import '../components/attendance_pie_chart_widget.dart';
import '../components/quick_actions_widget.dart';
import '../components/recent_activity_widget.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            color: AppConstant.primaryColor,
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              _buildWelcomeHeader(),
              
              SizedBox(height: 20),
              
              // Stats cards
              DashboardStatsCards(),
              
              SizedBox(height: 24),
              
              // Attendance Status Pie Chart - Matching the image
              AttendancePieChartWidget(),
              
              SizedBox(height: 24),
              
              // Quick actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              QuickActionsWidget(),
              
              SizedBox(height: 24),
              
              // Analytics chart
              // Text(
              //   'Today\'s Overview',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //     color: AppConstant.textPrimary,
              //   ),
              // ),
              // SizedBox(height: 12),
              // DashboardChartWidget(),
              
              // SizedBox(height: 24),
              
              // // Recent activity
              // Text(
              //   'Recent Activity',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //     color: AppConstant.textPrimary,
              //   ),
              // ),
              // SizedBox(height: 12),
              // RecentActivityWidget(),
              
              SizedBox(height: 80), // Bottom padding for navigation
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstant.primaryColor, AppConstant.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin!',
                  style: TextStyle(
                    color: AppConstant.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your team today.',
                  style: TextStyle(
                    color: AppConstant.textLight.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: AppConstant.textLight,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
