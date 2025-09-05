// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../../../utils/app_constant.dart';
import '../../../controllers/schedule_controller/schedule_controller.dart';

class EmployeeScheduleCard extends StatelessWidget {
  final ScheduleDisplayModel scheduleDisplay;

  const EmployeeScheduleCard({
    super.key,
    required this.scheduleDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final user = scheduleDisplay.user;
    final schedule = scheduleDisplay.schedule;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
          backgroundImage: user.userImg != null && user.userImg!.isNotEmpty
              ? NetworkImage(user.userImg!)
              : null,
          child: user.userImg == null || user.userImg!.isEmpty
              ? Text(
                  _getInitials(user.fullName),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstant.primaryColor,
                  ),
                )
              : null,
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstant.appTextColor,
          ),
        ),
        subtitle: Text(
          scheduleDisplay.timeRange,
          style: TextStyle(
            fontSize: 14,
            color: AppConstant.appTextColor.withOpacity(0.7),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(schedule.status),
              ),
            ),
            const SizedBox(width: 12),
            // More options button
            InkWell(
              onTap: () => _showScheduleOptions(context),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppConstant.appTextColor.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
        onTap: () => _viewScheduleDetails(context),
      ),
    );
  }

  String _getInitials(String fullName) {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showScheduleOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.visibility, color: AppConstant.primaryColor),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _viewScheduleDetails(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: AppConstant.primaryColor),
              title: const Text('Edit Schedule'),
              onTap: () {
                Navigator.pop(context);
                _editSchedule(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz, color: AppConstant.primaryColor),
              title: const Text('Reassign'),
              onTap: () {
                Navigator.pop(context);
                _reassignSchedule(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel Schedule'),
              onTap: () {
                Navigator.pop(context);
                _cancelSchedule(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewScheduleDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Schedule Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Employee', scheduleDisplay.user.fullName),
            _buildDetailRow('Position', scheduleDisplay.user.position),
            _buildDetailRow('Time', scheduleDisplay.timeRange),
            _buildDetailRow('Location', scheduleDisplay.schedule.location),
            _buildDetailRow('Status', scheduleDisplay.schedule.status),
            if (scheduleDisplay.schedule.description.isNotEmpty)
              _buildDetailRow('Description', scheduleDisplay.schedule.description),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstant.appTextColor.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppConstant.appTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editSchedule(BuildContext context) {
    // TODO: Implement edit schedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit schedule functionality coming soon')),
    );
  }

  void _reassignSchedule(BuildContext context) {
    // TODO: Implement reassign schedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reassign schedule functionality coming soon')),
    );
  }

  void _cancelSchedule(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cancel Schedule'),
        content: Text('Are you sure you want to cancel this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel schedule logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Schedule cancelled successfully')),
              );
            },
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
