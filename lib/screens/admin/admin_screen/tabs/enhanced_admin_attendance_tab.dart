// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../models/attendance_model.dart';
import '../../../../utils/app_constant.dart';

class EnhancedAdminAttendanceTab extends StatelessWidget {
  const EnhancedAdminAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters and actions
          _buildHeader(controller),
          SizedBox(height: 16),
          
          // Quick stats
          _buildQuickStats(controller),
          SizedBox(height: 16),
          
          // Filter chips
          _buildFilterChips(controller),
          SizedBox(height: 20),
          
          // Attendance data table
          Expanded(
            child: controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : _getDisplayList(controller).isEmpty
                    ? _buildEmptyState()
                    : _buildDataTable(controller),
          ),
        ],
      ),
    ));
  }

  Widget _buildHeader(AdminController controller) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Attendance Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
        ),
        // Refresh button
        IconButton(
          onPressed: () {
            controller.refreshAttendanceData();
          },
          icon: Icon(Icons.refresh, color: AppConstant.primaryColor),
          tooltip: 'Refresh Data',
        ),
        // Date filter button
        IconButton(
          onPressed: () => _showDateFilterDialog(Get.context!, controller),
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
        // Department filter
        PopupMenuButton<String>(
          icon: Icon(Icons.business, color: AppConstant.primaryColor),
          onSelected: (value) async {
            controller.selectedDepartment.value = value;
            controller.refreshAttendanceData();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'All', child: Text('All Departments')),
            ...controller.departments.where((dept) => dept != 'All').map(
              (dept) => PopupMenuItem(value: dept, child: Text(dept)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(AdminController controller) {
    final displayList = _getDisplayList(controller);
    final pendingCount = displayList.where((att) => att.status == 'pending').length;
    final approvedCount = displayList.where((att) => att.status == 'granted').length;
    final rejectedCount = displayList.where((att) => att.status == 'not_granted').length;
    final activeCount = displayList.where((att) => 
      att.checkOutTime == null).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatCard('Total', displayList.length.toString(), Colors.blue),
          SizedBox(width: 16),
          _buildStatCard('Pending', pendingCount.toString(), Colors.orange),
          SizedBox(width: 16),
          _buildStatCard('Approved', approvedCount.toString(), Colors.green),
          SizedBox(width: 16),
          _buildStatCard('Rejected', rejectedCount.toString(), Colors.red),
          SizedBox(width: 16),
          _buildStatCard('Active', activeCount.toString(), Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(AdminController controller) {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: Text('Today'),
          selected: controller.dateFilterType.value == 'today',
          onSelected: (selected) {
            if (selected) controller.setDateFilterToday();
          },
        ),
        FilterChip(
          label: Text('This Week'),
          selected: controller.dateFilterType.value == 'week',
          onSelected: (selected) {
            if (selected) {
              controller.dateFilterType.value = 'week';
              controller.refreshAttendanceData();
            }
          },
        ),
        FilterChip(
          label: Text('This Month'),
          selected: controller.dateFilterType.value == 'month',
          onSelected: (selected) {
            if (selected) {
              controller.dateFilterType.value = 'month';
              controller.refreshAttendanceData();
            }
          },
        ),
        FilterChip(
          label: Text('All Time'),
          selected: controller.dateFilterType.value == 'all',
          onSelected: (selected) {
            if (selected) controller.setDateFilterAll();
          },
        ),
        FilterChip(
          label: Text('Custom Range'),
          selected: controller.dateFilterType.value == 'range',
          onSelected: (selected) {
            if (selected) _showDateFilterDialog(Get.context!, controller);
          },
        ),
      ],
    );
  }

  Widget _buildDataTable(AdminController controller) {
    final displayList = _getDisplayList(controller);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 1200,
          columns: [
            DataColumn2(
              label: Text('Employee', style: _headerStyle()),
              size: ColumnSize.L,
            ),
            DataColumn2(
              label: Text('Date', style: _headerStyle()),
              size: ColumnSize.S,
            ),
            DataColumn2(
              label: Text('Check-in', style: _headerStyle()),
              size: ColumnSize.M,
            ),
            DataColumn2(
              label: Text('Check-out', style: _headerStyle()),
              size: ColumnSize.M,
            ),
            DataColumn2(
              label: Text('Duration', style: _headerStyle()),
              size: ColumnSize.S,
            ),
            DataColumn2(
              label: Text('Status', style: _headerStyle()),
              size: ColumnSize.S,
            ),
            DataColumn2(
              label: Text('Actions', style: _headerStyle()),
              size: ColumnSize.L,
            ),
          ],
          rows: displayList.map((attendance) => _buildDataRow(attendance, controller)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(AttendanceModel attendance, AdminController controller) {
    final employeeData = controller.getEmployeeDataForAttendance(attendance.attendanceId);
    final statusInfo = controller.getStatusInfoForAttendance(attendance.attendanceId);
    final rawData = controller.attendanceRawData[attendance.attendanceId];
    
    return DataRow(
      cells: [
        // Employee cell with avatar and info
        DataCell(_buildEmployeeCell(employeeData)),
        // Date cell
        DataCell(Text(
          _getAttendanceDate(rawData),
          style: _cellStyle(),
        )),
        // Check-in cell
        DataCell(_buildTimeCell(attendance.checkInTime)),
        // Check-out cell
        DataCell(_buildTimeCell(attendance.checkOutTime)),
        // Duration cell
        DataCell(_buildDurationCell(attendance)),
        // Status cell
        DataCell(_buildStatusChip(attendance.status)),
        // Actions cell
        DataCell(_buildActionsCell(attendance, controller, statusInfo)),
      ],
    );
  }

  Widget _buildEmployeeCell(Map<String, dynamic>? employeeData) {
    if (employeeData == null) {
      return Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Text('?'),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Unknown', style: _cellStyle(fontWeight: FontWeight.w600)),
              Text('N/A', style: _cellStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppConstant.primaryColor,
          backgroundImage: employeeData['user_img'] != null 
              ? NetworkImage(employeeData['user_img']) 
              : null,
          child: employeeData['user_img'] == null 
              ? Text(
                  (employeeData['full_name'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                employeeData['full_name'] ?? 'Unknown',
                style: _cellStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${employeeData['employee_id'] ?? 'N/A'} • ${employeeData['department'] ?? 'N/A'}',
                style: _cellStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCell(DateTime? time) {
    if (time == null) {
      return Text('--:--', style: _cellStyle(color: Colors.grey));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('HH:mm').format(time),
          style: _cellStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          DateFormat('MMM dd').format(time),
          style: _cellStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDurationCell(AttendanceModel attendance) {
    DateTime checkIn = attendance.checkInTime;
    DateTime checkOut = attendance.checkOutTime ?? DateTime.now();
    
    Duration duration = checkOut.difference(checkIn);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${duration.inHours}h ${duration.inMinutes % 60}m',
          style: _cellStyle(fontWeight: FontWeight.w600),
        ),
        if (attendance.checkOutTime == null)
          Text(
            'Ongoing',
            style: _cellStyle(fontSize: 11, color: Colors.orange),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'granted':
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'not_granted':
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionsCell(AttendanceModel attendance, AdminController controller, Map<String, dynamic>? statusInfo) {
    final canApprove = statusInfo?['can_approve'] ?? false;
    final canReject = statusInfo?['can_reject'] ?? false;
    final needsCheckout = statusInfo?['needs_checkout'] ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canApprove)
          IconButton(
            icon: Icon(Icons.check_circle, color: Colors.green, size: 20),
            onPressed: () => _showApprovalDialog(attendance, controller, 'approve'),
            tooltip: 'Approve',
          ),
        if (canReject)
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red, size: 20),
            onPressed: () => _showApprovalDialog(attendance, controller, 'reject'),
            tooltip: 'Reject',
          ),
        if (needsCheckout)
          Icon(Icons.warning, color: Colors.orange, size: 20),
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.blue, size: 20),
          onPressed: () => _showAttendanceDetails(attendance, controller),
          tooltip: 'Details',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Attendance records will appear here when employees check in',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: AppConstant.textPrimary,
    );
  }

  TextStyle _cellStyle({double? fontSize, Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: fontSize ?? 13,
      color: color ?? AppConstant.textPrimary,
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }

  List<AttendanceModel> _getDisplayList(AdminController controller) {
    switch (controller.selectedAttendanceFilter.value) {
      case 'pending':
        return controller.pendingAttendance;
      case 'all':
      default:
        return controller.allAttendance;
    }
  }

  String _getAttendanceDate(Map<String, dynamic>? rawData) {
    if (rawData != null && rawData['date'] != null) {
      try {
        final date = DateTime.parse(rawData['date']);
        return DateFormat('MMM dd').format(date);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    return DateFormat('MMM dd').format(DateTime.now());
  }

  void _showDateFilterDialog(BuildContext context, AdminController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Today'),
              leading: Radio(
                value: 'today',
                groupValue: controller.dateFilterType.value,
                onChanged: (value) {
                  controller.setDateFilterToday();
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('This Week'),
              leading: Radio(
                value: 'week',
                groupValue: controller.dateFilterType.value,
                onChanged: (value) {
                  controller.dateFilterType.value = 'week';
                  controller.refreshAttendanceData();
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('This Month'),
              leading: Radio(
                value: 'month',
                groupValue: controller.dateFilterType.value,
                onChanged: (value) {
                  controller.dateFilterType.value = 'month';
                  controller.refreshAttendanceData();
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('All Time'),
              leading: Radio(
                value: 'all',
                groupValue: controller.dateFilterType.value,
                onChanged: (value) {
                  controller.setDateFilterAll();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(AttendanceModel attendance, AdminController controller, String action) {
    final TextEditingController notesController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text('${action == 'approve' ? 'Approve' : 'Reject'} Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to ${action} this attendance record?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Admin Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.reviewAttendance(
                attendanceId: attendance.attendanceId,
                action: action,
                adminNotes: notesController.text.isNotEmpty ? notesController.text : null,
                reviewReason: reasonController.text.isNotEmpty ? reasonController.text : null,
              );
              
              Navigator.pop(context);
              
              if (success) {
                Get.snackbar(
                  'Success',
                  'Attendance ${action}d successfully',
                  backgroundColor: action == 'approve' ? Colors.green : Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
            ),
            child: Text('${action == 'approve' ? 'Approve' : 'Reject'}'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(AttendanceModel attendance, AdminController controller) {
    final employeeData = controller.getEmployeeDataForAttendance(attendance.attendanceId);
    final scheduleData = controller.getScheduleDataForAttendance(attendance.attendanceId);
    final rawData = controller.attendanceRawData[attendance.attendanceId];

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text('Attendance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (employeeData != null) ...[
                Text('Employee: ${employeeData['full_name']}'),
                Text('ID: ${employeeData['employee_id']}'),
                Text('Department: ${employeeData['department']}'),
                SizedBox(height: 12),
              ],
              Text('Date: ${_getAttendanceDate(rawData)}'),
              Text('Check-in: ${DateFormat('HH:mm').format(attendance.checkInTime)}'),
              if (attendance.checkOutTime != null)
                Text('Check-out: ${DateFormat('HH:mm').format(attendance.checkOutTime!)}'),
              Text('Status: ${attendance.status}'),
              if (scheduleData != null) ...[
                SizedBox(height: 12),
                Text('Schedule: ${scheduleData['title']}'),
                Text('Location: ${scheduleData['location']}'),
              ],
              if (rawData?['employee_notes']?.toString().isNotEmpty == true) ...[
                SizedBox(height: 12),
                Text('Employee Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(rawData!['employee_notes']),
              ],
              if (attendance.adminNotes?.isNotEmpty == true) ...[
                SizedBox(height: 12),
                Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(attendance.adminNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
