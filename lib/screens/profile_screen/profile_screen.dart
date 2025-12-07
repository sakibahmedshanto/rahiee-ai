// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../controllers/landing_screen_controller/landing_controller.dart';
import '../../services/account_deletion_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_constant.dart';
import '../auth_ui/welcome_screen.dart';

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
            
            SizedBox(height: 16),
            
            // Delete Account Button
            _buildDeleteAccountButton(controller),
            
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
          value: controller.userPhone ?? 'Not provided',
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

  Widget _buildDeleteAccountButton(LandingController controller) {
    return Container(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => _showDeleteAccountConfirmation(controller),
        icon: Icon(
          Icons.delete_forever,
          color: AppConstant.errorColor,
        ),
        label: Text(
          'Delete Account',
          style: TextStyle(
            color: AppConstant.errorColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppConstant.errorColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(LandingController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppConstant.errorColor,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Account?',
                style: TextStyle(
                  color: AppConstant.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(
                color: AppConstant.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'The following data will be permanently deleted:',
              style: TextStyle(
                color: AppConstant.textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            _buildDeletionItem('Your profile and personal information'),
            _buildDeletionItem('Your notification history'),
            _buildDeletionItem('Your account access'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstant.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstant.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstant.errorColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This cannot be undone',
                      style: TextStyle(
                        color: AppConstant.errorColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppConstant.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              _handleDeleteAccount(controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppConstant.textSecondary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppConstant.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(LandingController controller) async {
    try {
      EasyLoading.show(status: 'Deleting account...');
      
      final supabaseService = Get.find<SupabaseService>();
      final userId = supabaseService.currentUser?.id;
      
      if (userId == null) {
        EasyLoading.dismiss();
        Get.snackbar(
          'Error',
          'Unable to identify user. Please try again.',
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final accountDeletionService = Get.find<AccountDeletionService>();
      final result = await accountDeletionService.deleteUserAccount(userId);
      
      EasyLoading.dismiss();
      
      if (result['success'] == true) {
        // Sign out the user
        await supabaseService.signOut();
        
        // Show success message
        Get.snackbar(
          'Account Deleted',
          result['message'],
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
        );
        
        // Navigate to welcome screen
        Get.offAll(() => WelcomeScreen());
      } else if (result['partial'] == true) {
        // Partial deletion - profile removed but auth account needs manual deletion
        await supabaseService.signOut();
        
        Get.snackbar(
          'Deletion Initiated',
          result['message'],
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 7),
        );
        
        Get.offAll(() => WelcomeScreen());
      } else {
        Get.snackbar(
          'Deletion Failed',
          result['message'],
          backgroundColor: AppConstant.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please contact support at support@rahiee.ai',
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
    }
  }
}
