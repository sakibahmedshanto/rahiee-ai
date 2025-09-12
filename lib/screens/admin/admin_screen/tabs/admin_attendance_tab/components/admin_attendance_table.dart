import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../../models/attendance_model.dart';
import '../../../../../../utils/app_constant.dart';

class AdminAttendanceTable extends StatelessWidget {
  final AdminController controller;
  
  const AdminAttendanceTable({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final displayList = _getDisplayList();
    
    if (displayList.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 16,
          minWidth: 1200,
          headingRowColor: MaterialStateProperty.all(
            AppConstant.primaryColor.withOpacity(0.1),
          ),
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
          rows: displayList.map((attendance) => _buildDataRow(attendance)).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No attendance records found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendance records will appear here when employees check in',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(AttendanceModel attendance) {
    final employeeData = controller.getEmployeeDataForAttendance(attendance.attendanceId);
    final statusInfo = controller.getStatusInfoForAttendance(attendance.attendanceId);
    final rawData = controller.attendanceRawData[attendance.attendanceId];
    
    return DataRow(
      cells: [
        DataCell(_buildEmployeeCell(employeeData)),
        DataCell(Text(_getAttendanceDate(rawData), style: _cellStyle())),
        DataCell(_buildTimeCell(attendance.checkInTime)),
        DataCell(_buildTimeCell(attendance.checkOutTime)),
        DataCell(_buildDurationCell(attendance)),
        DataCell(_buildStatusChip(attendance.status)),
        DataCell(_buildActionsCell(attendance, statusInfo)),
      ],
    );
  }

  Widget _buildEmployeeCell(Map<String, dynamic>? employeeData) {
    if (employeeData == null) {
      return _buildUnknownEmployee();
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppConstant.primaryColor,
          backgroundImage: employeeData['user_img'] != null 
              ? NetworkImage(employeeData['user_img']) 
              : null,
          child: employeeData['user_img'] == null 
              ? Text(
                  (employeeData['full_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                '${employeeData['employee_id'] ?? 'N/A'} • ${employeeData['department'] ?? 'N/A'}',
                style: _cellStyle(fontSize: 11, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnknownEmployee() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey,
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Unknown Employee', style: _cellStyle(fontWeight: FontWeight.w600)),
            Text('N/A', style: _cellStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeCell(DateTime? time) {
    if (time == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('--:--', style: _cellStyle(color: Colors.grey[600])),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('HH:mm').format(time),
          style: _cellStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('MMM dd').format(time),
          style: _cellStyle(fontSize: 11, color: Colors.grey[600]),
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
        const SizedBox(height: 2),
        if (attendance.checkOutTime == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Active',
              style: _cellStyle(fontSize: 10, color: Colors.green[700]),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.pending_actions;
        break;
      case 'granted':
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case 'not_granted':
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCell(AttendanceModel attendance, Map<String, dynamic>? statusInfo) {
    final canApprove = statusInfo?['can_approve'] ?? false;
    final canReject = statusInfo?['can_reject'] ?? false;
    final needsCheckout = statusInfo?['needs_checkout'] ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canApprove)
          _buildActionButton(
            icon: Icons.check_circle,
            color: Colors.green,
            tooltip: 'Approve',
            onPressed: () => _showApprovalDialog(attendance, 'approve'),
          ),
        if (canReject)
          _buildActionButton(
            icon: Icons.cancel,
            color: Colors.red,
            tooltip: 'Reject',
            onPressed: () => _showApprovalDialog(attendance, 'reject'),
          ),
        if (needsCheckout)
          _buildActionButton(
            icon: Icons.warning,
            color: Colors.orange,
            tooltip: 'Needs checkout',
            onPressed: null,
          ),
        _buildActionButton(
          icon: Icons.info_outline,
          color: Colors.blue,
          tooltip: 'View details',
          onPressed: () => _showAttendanceDetails(attendance),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
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

  List<AttendanceModel> _getDisplayList() {
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

  void _showApprovalDialog(AttendanceModel attendance, String action) {
    final TextEditingController notesController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              action == 'approve' ? Icons.check_circle : Icons.cancel,
              color: action == 'approve' ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text('${action == 'approve' ? 'Approve' : 'Reject'} Attendance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to ${action} this attendance record?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
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
            child: const Text('Cancel'),
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
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(AttendanceModel attendance) {
    final employeeData = controller.getEmployeeDataForAttendance(attendance.attendanceId);
    final scheduleData = controller.getScheduleDataForAttendance(attendance.attendanceId);
    final rawData = controller.attendanceRawData[attendance.attendanceId];

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Attendance Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (employeeData != null) ...[
                _buildDetailRow('Employee', employeeData['full_name']),
                _buildDetailRow('ID', employeeData['employee_id']),
                _buildDetailRow('Department', employeeData['department']),
                const Divider(),
              ],
              _buildDetailRow('Date', _getAttendanceDate(rawData)),
              _buildDetailRow('Check-in', DateFormat('HH:mm').format(attendance.checkInTime)),
              if (attendance.checkOutTime != null)
                _buildDetailRow('Check-out', DateFormat('HH:mm').format(attendance.checkOutTime!)),
              _buildDetailRow('Status', attendance.status),
              if (scheduleData != null) ...[
                const Divider(),
                _buildDetailRow('Schedule', scheduleData['title']),
                _buildDetailRow('Location', scheduleData['location']),
              ],
              if (rawData?['employee_notes']?.toString().isNotEmpty == true) ...[
                const Divider(),
                const Text('Employee Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(rawData!['employee_notes']),
              ],
              if (attendance.adminNotes?.isNotEmpty == true) ...[
                const Divider(),
                const Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(attendance.adminNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
