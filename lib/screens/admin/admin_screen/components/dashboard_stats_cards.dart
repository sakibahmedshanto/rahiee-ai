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
        // First row of cards - Matching the image design
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Today's Check-ins",
                value: '${controller.totalCheckedInToday.value}',
                icon: Icons.login,
                color: AppConstant.successColor,
                subtitle: "Today's Check-ins.",
                trend: controller.getCheckInsTrend(),
                trendColor: AppConstant.successColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Approvals',
                value: '${controller.totalPendingApprovals.value}',
                icon: Icons.pending_actions,
                color: AppConstant.warningColor,
                subtitle: 'Pending Approvals.',
                trend: controller.getPendingTrend(),
                trendColor: AppConstant.errorColor,
                isAlert: controller.totalPendingApprovals.value > 0,
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
                title: 'Late Arrivals',
                value: '${controller.totalLateToday.value}',
                icon: Icons.access_time_filled,
                color: AppConstant.errorColor,
                subtitle: 'Late Arrivals.',
                trend: controller.getLateTrend(),
                trendColor: AppConstant.successColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Active Sessions',
                value: '${controller.currentlyActive.value}',
                icon: Icons.person,
                color: Colors.lightBlue,
                subtitle: 'Active Sessions.',
                badge: 'Live',
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
    String? badge,
    String? trend,
    Color? trendColor,
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
          if (trend != null) ...[
            SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trendColor ?? color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (trendColor ?? color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend.startsWith('+') 
                            ? Icons.trending_up 
                            : Icons.trending_down,
                        size: 12,
                        color: trendColor ?? color,
                      ),
                      SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: trendColor ?? color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (badge != null) ...[
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
