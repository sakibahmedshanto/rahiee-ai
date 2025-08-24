// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_constant.dart';
import '../../controllers/admin_controller.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());
    
    return Scaffold(
      backgroundColor: AppConstant.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstant.appMainColor,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: AppConstant.appTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: controller.onLogoutPressed,
            icon: Icon(
              Icons.logout,
              color: AppConstant.appTextColor,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() => controller.isLoading.value 
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.refreshDashboard,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstant.appMainColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Admin',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'System Administrator',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Full System Access',
                            style: TextStyle(
                              color: AppConstant.appMainColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Statistics Cards
              Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      icon: Icons.people,
                      title: 'Total Users',
                      value: controller.totalUsers.value,
                      color: AppConstant.successColor,
                    )),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      icon: Icons.access_time,
                      title: 'Active Today',
                      value: controller.activeToday.value,
                      color: AppConstant.infoColor,
                    )),
                  ),
                ],
              ),
              
              SizedBox(width: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      icon: Icons.warning,
                      title: 'Pending',
                      value: controller.pendingItems.value,
                      color: AppConstant.warningColor,
                    )),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => _buildStatCard(
                      icon: Icons.trending_up,
                      title: 'Reports',
                      value: controller.totalReports.value,
                      color: AppConstant.accentColor,
                    )),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Admin Actions
              Text(
                'Admin Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              SizedBox(height: 12),
              
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    icon: Icons.people_alt,
                    title: 'Manage Users',
                    onTap: controller.onManageUsersPressed,
                  ),
                  _buildActionCard(
                    icon: Icons.assessment,
                    title: 'Reports',
                    onTap: controller.onReportsPressed,
                  ),
                  _buildActionCard(
                    icon: Icons.settings,
                    title: 'System Settings',
                    onTap: controller.onSystemSettingsPressed,
                  ),
                  _buildActionCard(
                    icon: Icons.security,
                    title: 'Security',
                    onTap: controller.onSecurityPressed,
                  ),
                  _buildActionCard(
                    icon: Icons.backup,
                    title: 'Backup',
                    onTap: controller.onBackupPressed,
                  ),
                  _buildActionCard(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    onTap: controller.onAnalyticsPressed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    ));
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppConstant.appMainColor,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
