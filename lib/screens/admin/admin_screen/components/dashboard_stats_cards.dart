// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';

class DashboardStatsCards extends StatelessWidget {
  const DashboardStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Column(
      children: [
        // First row of cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Employees',
                value: '${controller.totalActiveEmployees.value}',
                icon: Icons.people,
                color: AppConstant.primaryColor,
                subtitle: 'Active employees',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Checked In',
                value: '${controller.totalCheckedInToday.value}',
                icon: Icons.login,
                color: AppConstant.successColor,
                subtitle: 'Today',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        // Second row of cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pending Approvals',
                value: '${controller.totalPendingApprovals.value}',
                icon: Icons.pending_actions,
                color: AppConstant.warningColor,
                subtitle: 'Need review',
                isAlert: controller.totalPendingApprovals.value > 0,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Unpaid Amount',
                value: '\$${controller.totalUnpaidAmount.value.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: AppConstant.errorColor,
                subtitle: 'Outstanding',
              ),
            ),
          ],
        ),
      ],
    ));
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool isAlert = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? color.withOpacity(0.3) : AppConstant.borderColor,
          width: isAlert ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstant.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              if (isAlert) ...[
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
