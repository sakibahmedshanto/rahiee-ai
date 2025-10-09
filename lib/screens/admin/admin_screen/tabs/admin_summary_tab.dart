// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';
import '../components/date_range_picker_dialog.dart';

class AdminSummaryTab extends StatelessWidget {
  const AdminSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return RefreshIndicator(
      onRefresh: () => controller.loadSummaryReportsData(),
      child: Obx(() => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter options
            _buildHeader(controller),
            
            SizedBox(height: 16),
            
            // Filter chips
            _buildFilterChips(controller),
            
            SizedBox(height: 16),
            
            // Date range selector
            _buildDateRangeSelector(controller, context),
            
            SizedBox(height: 20),
            
            // Summary stats cards
            _buildSummaryStats(controller),
            
            SizedBox(height: 20),
            
            // Data table
            Expanded(
              child: _buildDataTable(controller),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildHeader(AdminController controller) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Summary Reports',
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
            Get.snackbar('Export', 'Exporting ${value.toUpperCase()}...');
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'csv', child: Text('Export CSV')),
            PopupMenuItem(value: 'excel', child: Text('Export Excel')),
            PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips(AdminController controller) {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip('Daily', controller.selectedSummaryTimeRange.value == 'Daily', () {
          controller.updateSummaryTimeRange('Daily');
        }),
        _buildFilterChip('Weekly', controller.selectedSummaryTimeRange.value == 'Weekly', () {
          controller.updateSummaryTimeRange('Weekly');
        }),
        _buildFilterChip('Monthly', controller.selectedSummaryTimeRange.value == 'Monthly', () {
          controller.updateSummaryTimeRange('Monthly');
        }),
        _buildFilterChip('Custom Range', controller.selectedSummaryTimeRange.value == 'Custom', () {
          controller.updateSummaryTimeRange('Custom');
        }),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppConstant.cardColor,
      selectedColor: AppConstant.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppConstant.primaryColor : AppConstant.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppConstant.primaryColor : AppConstant.borderColor,
      ),
    );
  }

  Widget _buildDateRangeSelector(AdminController controller, BuildContext context) {
    if (controller.selectedSummaryTimeRange.value != 'Custom') {
      return SizedBox.shrink();
    }

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
                  'Custom Date Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
                Text(
                  'Select start and end date',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showDateRangePicker(context, controller),
            icon: Icon(Icons.calendar_today, size: 16),
            label: Text('Select'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstant.primaryColor,
              side: BorderSide(color: AppConstant.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(AdminController controller) {
    return Obx(() {
      final stats = controller.summaryReportsStats;
      final totalRecords = stats['totalRecords'] ?? 0;
      final avgAttendance = stats['avgAttendance'] ?? 0;
      final totalHours = stats['totalHours'] ?? 0;

      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total Records',
              value: totalRecords.toString(),
              icon: Icons.receipt_long,
              color: AppConstant.primaryColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Avg Attendance',
              value: '${avgAttendance}%',
              icon: Icons.trending_up,
              color: AppConstant.successColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Total Hours',
              value: totalHours.toString(),
              icon: Icons.schedule,
              color: AppConstant.infoColor,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(AdminController controller) {
    return Obx(() {
      final summaryData = controller.summaryReportsData;
      
      if (controller.isSummaryReportsLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            color: AppConstant.primaryColor,
          ),
        );
      }
      
      if (summaryData.isEmpty) {
        return _buildEmptyState();
      }

    return Container(
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstant.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _getTableHeaders(controller)[0],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Hours',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Table body - scrollable
          Expanded(
            child: ListView.builder(
              itemCount: summaryData.length,
              itemBuilder: (context, index) {
                final data = summaryData[index];
                final isEven = index % 2 == 0;
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isEven ? AppConstant.backgroundColor : AppConstant.cardColor,
                  ),
                  child: Row(
                    children: [
                      // Date/Period column
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['period'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppConstant.textPrimary,
                              ),
                            ),
                            if (data['subPeriod'] != null) ...[
                              SizedBox(height: 2),
                              Text(
                                data['subPeriod'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConstant.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Attendance column
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${data['attendanceRate']}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getAttendanceColor(data['attendanceRate']),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '${data['present']}/${data['total']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppConstant.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      // Hours column
                      Expanded(
                        child: Text(
                          '${data['totalHours']}h',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstant.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Status column
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['status'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(data['status']),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_rows_outlined,
            size: 64,
            color: AppConstant.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No summary data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select a different time range or check back later',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<String> _getTableHeaders(AdminController controller) {
    switch (controller.selectedSummaryTimeRange.value) {
      case 'Daily':
        return ['Date', 'Attendance', 'Hours', 'Status'];
      case 'Weekly':
        return ['Week', 'Attendance', 'Hours', 'Status'];
      case 'Monthly':
        return ['Month', 'Attendance', 'Hours', 'Status'];
      default:
        return ['Period', 'Attendance', 'Hours', 'Status'];
    }
  }


  Color _getAttendanceColor(int rate) {
    if (rate >= 90) return AppConstant.successColor;
    if (rate >= 75) return AppConstant.warningColor;
    return AppConstant.errorColor;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Excellent':
        return AppConstant.successColor;
      case 'Good':
        return AppConstant.infoColor;
      default:
        return AppConstant.errorColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


  void _showDateRangePicker(BuildContext context, AdminController controller) {
    showDialog(
      context: context,
      builder: (context) => CustomDateRangePickerDialog(
        initialStartDate: DateTime.now().subtract(Duration(days: 30)),
        initialEndDate: DateTime.now(),
        onDateRangeSelected: (startDate, endDate) {
          // Update controller with selected date range
          controller.loadSummaryReportsData();
          Get.snackbar(
            'Date Range Updated',
            'Showing data from ${_formatDate(startDate)} to ${_formatDate(endDate)}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
    );
  }
}
