import 'package:flutter/material.dart';
import '../../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../../models/attendance_model.dart';
import '../../../../../../utils/app_constant.dart';

class AdminAttendanceStats extends StatelessWidget {
  final AdminController controller;
  
  const AdminAttendanceStats({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final displayList = _getDisplayList();
    final stats = _calculateStats(displayList);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstant.primaryColor.withOpacity(0.1),
            AppConstant.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstant.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildStatCard(
            'Total Records', 
            stats['total'].toString(), 
            Icons.assignment,
            Colors.blue,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Pending Review', 
            stats['pending'].toString(), 
            Icons.pending_actions,
            Colors.orange,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Approved', 
            stats['approved'].toString(), 
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Rejected', 
            stats['rejected'].toString(), 
            Icons.cancel,
            Colors.red,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Active Sessions', 
            stats['active'].toString(), 
            Icons.access_time,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppConstant.textPrimary.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<AttendanceModel> _getDisplayList() {
    switch (controller.selectedAttendanceFilter.value) {
      case 'pending':
        return controller.pendingAttendance;
      case 'all':
      default:
        return controller.allAttendance;
    }
  }

  Map<String, int> _calculateStats(List<AttendanceModel> displayList) {
    final pendingCount = displayList.where((att) => att.status == 'pending').length;
    final approvedCount = displayList.where((att) => att.status == 'granted').length;
    final rejectedCount = displayList.where((att) => att.status == 'not_granted').length;
    final activeCount = displayList.where((att) => att.checkOutTime == null).length;

    return {
      'total': displayList.length,
      'pending': pendingCount,
      'approved': approvedCount,
      'rejected': rejectedCount,
      'active': activeCount,
    };
  }
}
