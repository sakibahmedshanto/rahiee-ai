import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controllers/admin_schedule_controller.dart';

/// Example UI screen for admin schedule management
/// This is a basic implementation - customize according to your UI design
class AdminScheduleManagementScreen extends StatelessWidget {
  final AdminScheduleController controller = Get.put(AdminScheduleController());

  AdminScheduleManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateScheduleDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.loadSchedules(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          
          // Statistics Section
          _buildStatisticsSection(),
          
          // Schedules List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (controller.schedules.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No schedules found'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showCreateScheduleDialog(context),
                        child: Text('Create First Schedule'),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: controller.schedules.length,
                itemBuilder: (context, index) {
                  final schedule = controller.schedules[index];
                  return _buildScheduleCard(schedule);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => DropdownButton<String>(
              hint: Text('Department'),
              value: controller.selectedDepartment.value,
              items: ['IT', 'HR', 'Finance', 'Operations']
                  .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                  .toList(),
              onChanged: controller.setDepartmentFilter,
            )),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Obx(() => DropdownButton<String>(
              hint: Text('Status'),
              value: controller.selectedStatus.value,
              items: ['active', 'completed', 'cancelled', 'pending']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: controller.setStatusFilter,
            )),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: controller.clearFilters,
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Obx(() => Row(
        children: [
          _buildStatCard('Total', controller.totalSchedules.toString(), Colors.blue),
          _buildStatCard('Active', controller.totalActiveSchedules.toString(), Colors.green),
          _buildStatCard('Upcoming', controller.totalUpcomingSchedules.toString(), Colors.orange),
          _buildStatCard('Ongoing', controller.totalOngoingSchedules.toString(), Colors.purple),
        ],
      )),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final startTime = DateTime.parse(schedule['start_date_time']);
    final endTime = DateTime.parse(schedule['end_date_time']);
    final assignedUser = schedule['assigned_user'];
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Builder(
        builder: (BuildContext cardContext) => ListTile(
          title: Text(schedule['title'] ?? 'Untitled Schedule'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${schedule['department']} • ${schedule['location']}'),
              Text('${_formatDateTime(startTime)} - ${_formatDateTime(endTime)}'),
              if (assignedUser != null)
                Text('Assigned to: ${assignedUser['full_name']}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                label: Text(schedule['status'] ?? 'unknown'),
                backgroundColor: _getStatusColor(schedule['status']),
              ),
              PopupMenuButton(
                itemBuilder: (BuildContext popupContext) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditScheduleDialog(cardContext, schedule);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(cardContext, schedule['schedule_id']);
                  }
                },
              ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active': return Colors.green.withOpacity(0.2);
      case 'completed': return Colors.blue.withOpacity(0.2);
      case 'cancelled': return Colors.red.withOpacity(0.2);
      case 'pending': return Colors.orange.withOpacity(0.2);
      default: return Colors.grey.withOpacity(0.2);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateScheduleDialog(BuildContext context) {
    // TODO: Implement create schedule dialog
    // This would include form fields for all the required parameters
    Get.dialog(
      AlertDialog(
        title: Text('Create Schedule'),
        content: Text('Schedule creation form would go here.\n\nRequired fields:\n• Title\n• Start/End DateTime\n• Assigned User\n• Department\n• Location'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Example call (replace with actual form data):
              // controller.createSchedule(
              //   title: 'Example Schedule',
              //   startDateTime: DateTime.now(),
              //   endDateTime: DateTime.now().add(Duration(hours: 8)),
              //   assignedUserId: 'user-uuid',
              //   department: 'IT',
              //   location: 'Office',
              // );
              Get.back();
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, Map<String, dynamic> schedule) {
    // TODO: Implement edit schedule dialog
    Get.dialog(
      AlertDialog(
        title: Text('Edit Schedule'),
        content: Text('Schedule editing form would go here.\n\nCurrent: ${schedule['title']}'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Example call (replace with actual form data):
              // controller.updateSchedule(
              //   scheduleId: schedule['schedule_id'],
              //   title: 'Updated Title',
              // );
              Get.back();
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String scheduleId) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Schedule'),
        content: Text('Are you sure you want to delete this schedule?\n\nThis action will mark it as inactive but preserve the data.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSchedule(scheduleId);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}