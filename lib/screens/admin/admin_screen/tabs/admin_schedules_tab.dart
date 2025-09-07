// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';

class AdminSchedulesTab extends StatelessWidget {
  const AdminSchedulesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with actions
          Row(
            children: [
              Expanded(
                child: Text(
                  'Schedule Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Create new schedule
                  _showCreateScheduleDialog(context);
                },
                icon: Icon(Icons.add, size: 16),
                label: Text('New Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstant.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Schedule overview stats
          _buildScheduleStats(controller),
          
          SizedBox(height: 20),
          
          // Filter tabs
          _buildFilterTabs(controller),
          
          SizedBox(height: 16),
          
          // Schedules list
          Expanded(
            child: controller.activeSchedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: controller.activeSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = controller.activeSchedules[index];
                      return _buildScheduleCard(schedule, controller, context);
                    },
                  ),
          ),
        ],
      ),
    ));
  }

  Widget _buildScheduleStats(AdminController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Active',
            value: '${controller.activeSchedules.where((s) => s.isActive == true).length}',
            color: AppConstant.successColor,
            icon: Icons.schedule,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Coverage Requests',
            value: '${controller.coverageRequests.length}',
            color: AppConstant.warningColor,
            icon: Icons.swap_horiz,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total',
            value: '${controller.activeSchedules.length}',
            color: AppConstant.primaryColor,
            icon: Icons.calendar_month,
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

  Widget _buildFilterTabs(AdminController controller) {
    return Row(
      children: [
        _buildFilterChip('All', true),
        SizedBox(width: 8),
        _buildFilterChip('Active', false),
        SizedBox(width: 8),
        _buildFilterChip('Inactive', false),
        SizedBox(width: 8),
        _buildFilterChip('Pending Coverage', false),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Handle filter
      },
      backgroundColor: AppConstant.cardColor,
      selectedColor: AppConstant.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppConstant.primaryColor : AppConstant.textSecondary,
      ),
    );
  }

  Widget _buildScheduleCard(dynamic schedule, AdminController controller, BuildContext context) {
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
                  'Employee: ${schedule.assignedUserId}', // You might want to join with user data
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
                  color: (schedule.isActive == true 
                      ? AppConstant.successColor 
                      : AppConstant.errorColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  schedule.isActive == true ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: schedule.isActive == true 
                        ? AppConstant.successColor 
                        : AppConstant.errorColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppConstant.textSecondary),
              SizedBox(width: 8),
              Text(
                'Date: ${_formatDate(schedule.startDateTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppConstant.textSecondary),
              SizedBox(width: 8),
              Text(
                'Time: ${_formatTime(schedule.startDateTime)} - ${_formatTime(schedule.endDateTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.business, size: 16, color: AppConstant.textSecondary),
              SizedBox(width: 8),
              Text(
                'Department: ${schedule.department}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showEditScheduleDialog(context, schedule);
                  },
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstant.primaryColor,
                    side: BorderSide(color: AppConstant.primaryColor),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _showScheduleDetails(context, schedule);
                },
                icon: Icon(Icons.visibility, size: 16),
                label: Text('View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstant.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
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
            Icons.schedule_outlined,
            size: 64,
            color: AppConstant.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No schedules found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first employee schedule',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Schedule'),
        content: Text('Schedule creation form will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.snackbar('Success', 'Schedule created successfully');
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, dynamic schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Schedule'),
        content: Text('Schedule editing form will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.snackbar('Success', 'Schedule updated successfully');
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDetails(BuildContext context, dynamic schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${schedule.assignedUserId}'),
            SizedBox(height: 8),
            Text('Start: ${_formatDate(schedule.startDateTime)} ${_formatTime(schedule.startDateTime)}'),
            SizedBox(height: 8),
            Text('End: ${_formatDate(schedule.endDateTime)} ${_formatTime(schedule.endDateTime)}'),
            SizedBox(height: 8),
            Text('Department: ${schedule.department}'),
            SizedBox(height: 8),
            Text('Location: ${schedule.location}'),
            SizedBox(height: 8),
            Text('Status: ${schedule.isActive == true ? "Active" : "Inactive"}'),
          ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
