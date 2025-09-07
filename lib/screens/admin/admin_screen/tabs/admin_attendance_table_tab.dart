// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../models/attendance_model.dart';
import '../../../../utils/app_constant.dart';

class AdminAttendanceTableTab extends StatelessWidget {
  const AdminAttendanceTableTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters and actions
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attendance Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: () {
                  controller.loadPendingAttendance();
                  controller.loadAllAttendance();
                },
                icon: Icon(Icons.refresh, color: AppConstant.primaryColor),
                tooltip: 'Refresh Data',
              ),
              // Date filter button
              IconButton(
                onPressed: () => _showDateFilterDialog(context, controller),
                icon: Icon(Icons.date_range, color: AppConstant.primaryColor),
                tooltip: 'Date Filter',
              ),
              // Filter dropdown
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list, color: AppConstant.primaryColor),
                onSelected: (value) async {
                  controller.selectedAttendanceFilter.value = value;
                  switch (value) {
                    case 'pending':
                      await controller.loadPendingAttendance();
                      break;
                    case 'all':
                      await controller.loadAllAttendance();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'pending', child: Text('Pending Only')),
                  PopupMenuItem(value: 'all', child: Text('All Records')),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Quick stats
          _buildQuickStats(controller),
          
          SizedBox(height: 16),
          
          // Date filter chips
          _buildDateFilterChips(controller),
          
          SizedBox(height: 20),
          
          // Attendance table
          Expanded(
            child: controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : _getDisplayList(controller).isEmpty
                    ? _buildEmptyState()
                    : _buildAttendanceTable(controller),
          ),
        ],
      ),
    ));
  }

  Widget _buildQuickStats(AdminController controller) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              title: 'Pending',
              value: '${controller.pendingAttendance.length}',
              color: AppConstant.warningColor,
              icon: Icons.pending_actions,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppConstant.borderColor,
            margin: EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _buildStatItem(
              title: 'Total Today',
              value: '${controller.allAttendance.length}',
              color: AppConstant.primaryColor,
              icon: Icons.today,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppConstant.borderColor,
            margin: EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _buildStatItem(
              title: 'Approved',
              value: '${controller.allAttendance.where((att) => att.status == 'granted').length}',
              color: AppConstant.successColor,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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
    );
  }

  Widget _buildAttendanceTable(AdminController controller) {
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
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstant.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 800, // Same width as table body
                child: Row(
                  children: [
                    Container(
                      width: 180,
                      child: Text(
                        'Employee',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      child: Text(
                        'Check In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      child: Text(
                        'Check Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      child: Text(
                        'Hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      child: Text(
                        'Actions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Table body - Horizontally scrollable
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 800, // Fixed width for horizontal scrolling
                child: ListView.builder(
                  itemCount: _getDisplayList(controller).length,
                  itemBuilder: (context, index) {
                    final attendance = _getDisplayList(controller)[index];
                    return _buildAttendanceRow(attendance, controller, index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(AttendanceModel attendance, AdminController controller, int index) {
    // Extract employee data using the helper method
    final employeeData = controller.getEmployeeDataForAttendance(attendance.attendanceId);
    final employeeName = employeeData?['full_name'] ?? 'Unknown Employee';
    final employeeId = employeeData?['employee_id'] ?? attendance.userId;
    final department = employeeData?['department'] ?? '';
    final userImg = employeeData?['user_img'];
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppConstant.borderColor,
            width: 0.5,
          ),
        ),
        color: index % 2 == 0 ? Colors.transparent : AppConstant.primaryColor.withOpacity(0.02),
      ),
      child: Row(
        children: [
          // Employee info with avatar
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Employee avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
                  backgroundImage: userImg != null && userImg.toString().isNotEmpty 
                      ? NetworkImage(userImg) 
                      : null,
                  child: userImg == null || userImg.toString().isEmpty
                      ? Text(
                          employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstant.primaryColor,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                // Employee details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName, // Now showing actual employee name
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: $employeeId',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstant.textSecondary,
                        ),
                      ),
                      if (department.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          department,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppConstant.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Check in time
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(attendance.checkInTime),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstant.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatDate(attendance.checkInTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Check out time
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.checkOutTime != null 
                      ? _formatTime(attendance.checkOutTime!)
                      : 'Not yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: attendance.checkOutTime != null 
                        ? AppConstant.textPrimary 
                        : AppConstant.textSecondary,
                  ),
                ),
                if (attendance.checkOutTime != null) ...[
                  SizedBox(height: 4),
                  Text(
                    _formatDate(attendance.checkOutTime!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstant.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Working hours
          Expanded(
            flex: 1,
            child: Text(
              attendance.totalWorkingHours != null 
                  ? _formatDuration(attendance.totalWorkingHours!)
                  : '--',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
          
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(attendance.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                attendance.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(attendance.status),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Approve button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: attendance.status == 'pending' 
                        ? () async {
                            final success = await controller.approveAttendance(
                              attendance.attendanceId,
                              notes: 'Approved by admin',
                            );
                            if (success) {
                              Get.snackbar(
                                'Success', 
                                'Attendance approved successfully',
                                backgroundColor: AppConstant.successColor,
                                colorText: Colors.white,
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstant.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Icon(Icons.check, size: 16),
                  ),
                ),
                SizedBox(width: 8),
                // Reject button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: attendance.status == 'pending' 
                        ? () async {
                            final success = await controller.rejectAttendance(
                              attendance.attendanceId,
                              reason: 'Rejected by admin',
                            );
                            if (success) {
                              Get.snackbar(
                                'Info', 
                                'Attendance rejected',
                                backgroundColor: AppConstant.errorColor,
                                colorText: Colors.white,
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstant.errorColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 64,
            color: AppConstant.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No pending attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All attendance records are up to date',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppConstant.warningColor;
      case 'granted':
      case 'approved':
        return AppConstant.successColor;
      case 'not_granted':
      case 'rejected':
        return AppConstant.errorColor;
      default:
        return AppConstant.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // Date filter chips widget
  Widget _buildDateFilterChips(AdminController controller) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Filter',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Today',
                isSelected: controller.dateFilterType.value == 'today',
                onTap: () => controller.setDateFilterToday(),
              ),
              SizedBox(width: 8),
              _buildFilterChip(
                label: 'Custom Range',
                isSelected: controller.dateFilterType.value == 'range',
                onTap: () => _showDateRangePicker(controller),
              ),
              SizedBox(width: 8),
              _buildFilterChip(
                label: 'All Time',
                isSelected: controller.dateFilterType.value == 'all',
                onTap: () => controller.setDateFilterAll(),
              ),
              if (controller.dateFilterType.value == 'range' &&
                  controller.selectedStartDate.value != null &&
                  controller.selectedEndDate.value != null) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstant.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstant.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_formatDate(controller.selectedStartDate.value!)} - ${_formatDate(controller.selectedEndDate.value!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstant.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstant.primaryColor : AppConstant.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppConstant.primaryColor : AppConstant.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstant.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Date range picker
  Future<void> _showDateRangePicker(AdminController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      initialDateRange: controller.selectedStartDate.value != null &&
              controller.selectedEndDate.value != null
          ? DateTimeRange(
              start: controller.selectedStartDate.value!,
              end: controller.selectedEndDate.value!,
            )
          : DateTimeRange(
              start: DateTime.now().subtract(Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstant.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppConstant.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateFilterRange(picked.start, picked.end);
    }
  }

  // Date filter dialog (simpler alternative)
  void _showDateFilterDialog(BuildContext context, AdminController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.today),
              title: Text('Today'),
              onTap: () {
                controller.setDateFilterToday();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Custom Range'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker(controller);
              },
            ),
            ListTile(
              leading: Icon(Icons.all_inclusive),
              title: Text('All Time'),
              onTap: () {
                controller.setDateFilterAll();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get the appropriate list based on current filter
  List<AttendanceModel> _getDisplayList(AdminController controller) {
    switch (controller.selectedAttendanceFilter.value) {
      case 'pending':
        return controller.pendingAttendance;
      case 'all':
        return controller.allAttendance;
      default:
        return controller.pendingAttendance;
    }
  }
}
