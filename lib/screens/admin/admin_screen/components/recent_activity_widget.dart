// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';

class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Container(
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppConstant.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppConstant.borderColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppConstant.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
                Spacer(),
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstant.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Activity list
          controller.auditLogs.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  itemCount: controller.auditLogs.length.clamp(0, 5), // Show max 5 items
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final activity = controller.auditLogs[index];
                    return _buildActivityItem(activity);
                  },
                ),
        ],
      ),
    ));
  }

  Widget _buildActivityItem(dynamic activity) {
    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    // Determine activity type and display info
    switch (activity.action?.toLowerCase() ?? '') {
      case 'created':
        icon = Icons.add_circle_outline;
        iconColor = AppConstant.successColor;
        title = 'New attendance record created';
        break;
      case 'updated':
        icon = Icons.edit_outlined;
        iconColor = AppConstant.warningColor;
        title = 'Attendance record updated';
        break;
      case 'deleted':
        icon = Icons.delete_outline;
        iconColor = AppConstant.errorColor;
        title = 'Attendance record deleted';
        break;
      default:
        icon = Icons.info_outline;
        iconColor = AppConstant.primaryColor;
        title = 'System activity';
    }

    subtitle = _formatTime(activity.changedAt ?? DateTime.now());

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstant.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: AppConstant.textSecondary,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: AppConstant.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstant.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Activity will appear here when employees interact with the system',
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
