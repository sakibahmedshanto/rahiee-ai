// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../models/attendance_model.dart';
import '../../../../utils/app_constant.dart';

class AdminAttendanceTab extends StatelessWidget {
  const AdminAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters
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
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list, color: AppConstant.primaryColor),
                onSelected: (value) async {
                  // Handle filter selection
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
          
          SizedBox(height: 20),
          
          // Pending approvals section
          if (controller.pendingAttendance.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Pending Approvals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstant.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.pendingAttendance.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.warningColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
          ],
          
          // Attendance list
          Expanded(
            child: controller.pendingAttendance.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: controller.pendingAttendance.length,
                    itemBuilder: (context, index) {
                      final attendance = controller.pendingAttendance[index];
                      return _buildAttendanceCard(attendance, controller);
                    },
                  ),
          ),
        ],
      ),
    ));
  }

  Widget _buildQuickStats(AdminController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Pending',
            value: '${controller.pendingAttendance.length}',
            color: AppConstant.warningColor,
            icon: Icons.pending_actions,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Checked In',
            value: '${controller.totalCheckedInToday.value}',
            color: AppConstant.successColor,
            icon: Icons.login,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Today',
            value: '${controller.totalCheckedInToday.value + controller.pendingAttendance.length}',
            color: AppConstant.primaryColor,
            icon: Icons.today,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
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
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance, AdminController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Employee: ${_getEmployeeName(attendance)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
              ),
              Container(
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
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Employee Details
          Row(
            children: [
              Icon(Icons.badge, size: 16, color: AppConstant.textSecondary),
              SizedBox(width: 8),
              Text(
                'ID: ${attendance.userId}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppConstant.textSecondary),
              SizedBox(width: 8),
              Text(
                'Check-in: ${_formatDateTime(attendance.checkInTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          if (attendance.checkOutTime != null) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 16, color: AppConstant.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Check-out: ${_formatDateTime(attendance.checkOutTime!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstant.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (attendance.totalWorkingHours != null) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: AppConstant.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Hours: ${_formatDuration(attendance.totalWorkingHours!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstant.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          
          // Location Information
          if (attendance.checkInAddress != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppConstant.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location: ${attendance.checkInAddress}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstant.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Approval Actions
          if (attendance.status == 'pending') ...[
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
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
                    },
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstant.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
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
                    },
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstant.errorColor,
                      side: BorderSide(color: AppConstant.errorColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getEmployeeName(AttendanceModel attendance) {
    // For now return the user ID, but this could be enhanced with joined user data
    return attendance.userId;
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
        return AppConstant.primaryColor;
    }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
