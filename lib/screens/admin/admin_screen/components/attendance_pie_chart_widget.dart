// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';

class AttendancePieChartWidget extends StatelessWidget {
  const AttendancePieChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() {
      // Get real-time data from controller
      final totalPresent = controller.totalCheckedInToday.value;
      final totalAbsent = controller.totalAbsentToday.value;
      final totalPending = controller.totalPendingApprovals.value;
      final totalLate = controller.totalLateToday.value;
      
      // Calculate total for percentages
      final total = totalPresent + totalAbsent + totalPending + totalLate;
      
      if (total == 0) {
        return _buildEmptyState();
      }

      // Calculate percentages
      final presentPercentage = (totalPresent / total * 100);
      final absentPercentage = (totalAbsent / total * 100);
      final pendingPercentage = (totalPending / total * 100);
      final latePercentage = (totalLate / total * 100);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
                // Live indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstant.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstant.successColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppConstant.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppConstant.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Chart and Legend
            Row(
              children: [
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        'Present',
                        presentPercentage,
                        AppConstant.successColor,
                        totalPresent,
                      ),
                      SizedBox(height: 8),
                      _buildLegendItem(
                        'Pending',
                        pendingPercentage,
                        AppConstant.warningColor,
                        totalPending,
                      ),
                      SizedBox(height: 8),
                      _buildLegendItem(
                        'Absent',
                        absentPercentage,
                        AppConstant.errorColor,
                        totalAbsent,
                      ),
                      SizedBox(height: 8),
                      _buildLegendItem(
                        'Late',
                        latePercentage,
                        Colors.orange,
                        totalLate,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 20),
                
                // Pie Chart
                Expanded(
                  flex: 3,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: presentPercentage,
                            title: '${presentPercentage.toStringAsFixed(0)}%',
                            color: AppConstant.successColor,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: pendingPercentage,
                            title: '${pendingPercentage.toStringAsFixed(0)}%',
                            color: AppConstant.warningColor,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: absentPercentage,
                            title: '${absentPercentage.toStringAsFixed(0)}%',
                            color: AppConstant.errorColor,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: latePercentage,
                            title: '${latePercentage.toStringAsFixed(0)}%',
                            color: Colors.orange,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLegendItem(String label, double percentage, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label - ${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppConstant.textPrimary,
            ),
          ),
        ),
        Text(
          '($count)',
          style: TextStyle(
            fontSize: 11,
            color: AppConstant.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppConstant.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No attendance data today',
              style: TextStyle(
                fontSize: 14,
                color: AppConstant.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
