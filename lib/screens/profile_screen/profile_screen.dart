// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/landing_screen_controller/landing_controller.dart';
import '../../utils/app_constant.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LandingController controller = Get.find<LandingController>();
    
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            
            // Profile Header
            _buildProfileHeader(controller),
            
            SizedBox(height: 30),
            
            // User Information Cards
            _buildUserInfoSection(controller),
            
            SizedBox(height: 40),
            
            // Logout Button
            _buildLogoutButton(controller),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(LandingController controller) {
    return Column(
      children: [
        // Profile Image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppConstant.primaryColor.withOpacity(0.1),
            border: Border.all(
              color: AppConstant.primaryColor,
              width: 3,
            ),
          ),
          child: controller.userImage != null && controller.userImage!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.network(
                    controller.userImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(controller);
                    },
                  ),
                )
              : _buildDefaultAvatar(controller),
        ),
        
        SizedBox(height: 16),
        
        // User Name
        Text(
          controller.userDisplayName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstant.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 8),
        
        // User Role Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstant.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            controller.userRole,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(LandingController controller) {
    return Icon(
      Icons.person,
      size: 60,
      color: AppConstant.primaryColor,
    );
  }

  Widget _buildUserInfoSection(LandingController controller) {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.badge_outlined,
          title: 'Employee ID',
          value: controller.userEmployeeId,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.work_outline,
          title: 'Position',
          value: controller.userPosition,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.business_outlined,
          title: 'Department',
          value: controller.userDepartment,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email',
          value: controller.userEmail,
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: controller.userPhone,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstant.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppConstant.primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstant.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(LandingController controller) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(controller),
        icon: Icon(
          Icons.logout,
          color: Colors.white,
        ),
        label: Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstant.errorColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppConstant.errorColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(LandingController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: AppConstant.errorColor,
            ),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: AppConstant.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(
            color: AppConstant.textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppConstant.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog first
              controller.onLogoutPressed(); // Then logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
