// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';

class DashboardChartWidget extends StatelessWidget {
  const DashboardChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() {
      final summary = controller.dashboardSummary.value;
      
      return Container(
        padding: EdgeInsets.all(20),
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
        child: summary != null 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...summary.departmentBreakdown.map((dept) => 
                    _buildDepartmentRow(dept.department, dept.checkedIn, dept.totalEmployees)
                  ).toList(),
                  if (summary.departmentBreakdown.isEmpty)
                    _buildEmptyState(),
                ],
              )
            : _buildLoadingState(),
      );
    });
  }

  Widget _buildDepartmentRow(String department, int checkedIn, int total) {
    double percentage = total > 0 ? (checkedIn / total) : 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                department,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstant.textPrimary,
                ),
              ),
              Text(
                '$checkedIn/$total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppConstant.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 0.8 
                  ? AppConstant.successColor
                  : percentage >= 0.5 
                      ? AppConstant.warningColor 
                      : AppConstant.errorColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}% attendance',
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: AppConstant.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'No department data available',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppConstant.primaryColor,
      ),
    );
  }
}
