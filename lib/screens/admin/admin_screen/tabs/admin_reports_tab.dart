// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with export options
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reports & Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.download, color: AppConstant.primaryColor),
                onSelected: (value) {
                  _handleExport(value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'excel', child: Text('Export to Excel')),
                  PopupMenuItem(value: 'pdf', child: Text('Export to PDF')),
                  PopupMenuItem(value: 'csv', child: Text('Export to CSV')),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Date range selector
          _buildDateRangeSelector(controller),
          
          SizedBox(height: 20),
          
          // Key metrics overview
          _buildKeyMetrics(controller),
          
          SizedBox(height: 20),
          
          // Report sections
          Expanded(
            child: ListView(
              children: [
                _buildReportSection(
                  'Attendance Reports',
                  'Track employee attendance patterns and compliance',
                  Icons.fact_check,
                  AppConstant.primaryColor,
                  () => _showAttendanceReport(context),
                ),
                SizedBox(height: 12),
                _buildReportSection(
                  'Schedule Compliance',
                  'Monitor schedule adherence and coverage',
                  Icons.schedule,
                  AppConstant.successColor,
                  () => _showScheduleReport(context),
                ),
                SizedBox(height: 12),
                _buildReportSection(
                  'Payment Reports',
                  'Review payroll and compensation data',
                  Icons.payment,
                  AppConstant.warningColor,
                  () => _showPaymentReport(context),
                ),
                SizedBox(height: 12),
                _buildReportSection(
                  'Performance Analytics',
                  'Analyze employee performance metrics',
                  Icons.analytics,
                  AppConstant.infoColor,
                  () => _showPerformanceReport(context),
                ),
                SizedBox(height: 12),
                _buildReportSection(
                  'Department Summary',
                  'Department-wise analytics and insights',
                  Icons.business,
                  AppConstant.textPrimary,
                  () => _showDepartmentReport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDateRangeSelector(AdminController controller) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: AppConstant.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Period',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
                Text(
                  '${controller.selectedTimeRange.value}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _showDateRangePicker(Get.context!),
            child: Text('Change'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstant.primaryColor,
              side: BorderSide(color: AppConstant.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(AdminController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Total Employees',
            value: '${controller.totalActiveEmployees.value}',
            change: '+2.5%',
            isPositive: true,
            icon: Icons.people,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Attendance Rate',
            value: '94.2%',
            change: '+1.2%',
            isPositive: true,
            icon: Icons.check_circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Avg Work Hours',
            value: '8.3h',
            change: '-0.5%',
            isPositive: false,
            icon: Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstant.primaryColor, size: 20),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AppConstant.successColor : AppConstant.errorColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppConstant.successColor : AppConstant.errorColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstant.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstant.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppConstant.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstant.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppConstant.textSecondary),
          ],
        ),
      ),
    );
  }

  void _handleExport(String format) {
    Get.snackbar(
      'Export',
      'Exporting report to ${format.toUpperCase()}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Date Range'),
        content: Text('Date range picker will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.snackbar('Success', 'Date range updated');
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attendance Report'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('Detailed attendance report will be shown here'),
              SizedBox(height: 16),
              Text('• Employee attendance rates'),
              Text('• Late arrivals and early departures'),
              Text('• Absence patterns'),
              Text('• Overtime hours'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _handleExport('pdf'),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showScheduleReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Compliance Report'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('Schedule compliance metrics will be shown here'),
              SizedBox(height: 16),
              Text('• Schedule adherence rates'),
              Text('• Coverage gaps'),
              Text('• Shift swaps and changes'),
              Text('• Employee schedule preferences'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _handleExport('excel'),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showPaymentReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Report'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('Payment and payroll data will be shown here'),
              SizedBox(height: 16),
              Text('• Salary distributions'),
              Text('• Overtime payments'),
              Text('• Bonus and incentives'),
              Text('• Deductions and taxes'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _handleExport('csv'),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showPerformanceReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Performance Analytics'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('Performance metrics will be shown here'),
              SizedBox(height: 16),
              Text('• Productivity indicators'),
              Text('• Goal achievements'),
              Text('• Performance trends'),
              Text('• Employee ratings'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _handleExport('pdf'),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDepartmentReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Department Summary'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('Department-wise analytics will be shown here'),
              SizedBox(height: 16),
              Text('• Department headcounts'),
              Text('• Average performance by department'),
              Text('• Cost centers analysis'),
              Text('• Inter-department comparisons'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _handleExport('excel'),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }
}
