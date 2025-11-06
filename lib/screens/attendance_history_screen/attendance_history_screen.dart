import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/attendance_history_controller.dart';
import '../../utils/app_constant.dart';
import '../../utils/timezone_utils.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceHistoryController controller = Get.put(AttendanceHistoryController());
    final ScrollController scrollController = ScrollController();
    
    // Add scroll listener for lazy loading
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        controller.loadAttendanceHistory();
      }
    });
    
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: _buildAppBar(controller),
      body: Obx(() => RefreshIndicator(
        onRefresh: controller.refreshData,
        child: controller.attendanceRecords.isEmpty && !controller.isLoading.value
            ? _buildEmptyState()
            : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: controller.attendanceRecords.length + (controller.hasMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.attendanceRecords.length) {
                    return _buildLoadingIndicator();
                  }
                  return _buildAttendanceCard(controller.attendanceRecords[index]);
                },
              ),
      )),
    );
  }
  
  PreferredSizeWidget _buildAppBar(AttendanceHistoryController controller) {
    return AppBar(
      title: const Text('Attendance History', style: TextStyle(fontSize: 18)),
      backgroundColor: AppConstant.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Filter button
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, size: 20),
          tooltip: 'Filter',
          onSelected: controller.applyFilter,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: null,
              child: Text('All'),
            ),
            const PopupMenuItem(
              value: 'pending',
              child: Text('Pending'),
            ),
            const PopupMenuItem(
              value: 'pending_checkout',
              child: Text('Pending Checkout'),
            ),
            const PopupMenuItem(
              value: 'completed',
              child: Text('Completed'),
            ),
            const PopupMenuItem(
              value: 'granted',
              child: Text('Granted'),
            ),
            const PopupMenuItem(
              value: 'approved',
              child: Text('Approved'),
            ),
            const PopupMenuItem(
              value: 'rejected',
              child: Text('Rejected'),
            ),
            const PopupMenuItem(
              value: 'not_granted',
              child: Text('Not Granted'),
            ),
            const PopupMenuItem(
              value: 'unusual',
              child: Text('Unusual'),
            ),
            const PopupMenuItem(
              value: 'cancelled',
              child: Text('Cancelled'),
            ),
          ],
        ),
      ],
    );
  }
  
  
  static Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No attendance records',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
  
  static Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final schedule = record['schedule'] as Map<String, dynamic>?;
    final status = record['status'] as String?;
    final checkInTime = TimezoneUtils.parseToLocal(record['check_in_time']);
    final checkOutTime = TimezoneUtils.parseToLocal(record['check_out_time']);
    final workDurationHours = (record['work_duration_hours'] ?? 0.0) as num;
    final expectedHours = (record['expected_hours'] ?? 8.0) as num;
    final isLate = record['is_late'] as bool? ?? false;
    final isEarlyDeparture = record['is_early_departure'] as bool? ?? false;
    final location = record['location'] as String? ?? schedule?['location'] as String?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    schedule?['title'] ?? 'Schedule',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstant.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            
            // Date and location
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  checkInTime != null 
                      ? TimezoneUtils.formatDate(checkInTime)
                      : record['date'] != null
                          ? TimezoneUtils.formatDate(TimezoneUtils.parseToLocal(record['date']))
                          : 'N/A',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location ?? 'N/A',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Attendance flags
            if (isLate || isEarlyDeparture)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (isLate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber, size: 10, color: Colors.orange.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Late',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isLate && isEarlyDeparture) const SizedBox(width: 6),
                    if (isEarlyDeparture)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.exit_to_app, size: 10, color: Colors.red.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Early Out',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            
            // Check-in/out times
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'In',
                    checkInTime,
                    Icons.login,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeInfo(
                    'Out',
                    checkOutTime,
                    Icons.logout,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDurationInfo(workDurationHours.toDouble(), expectedHours.toDouble()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  static Widget _buildStatusChip(String? status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;
    
    switch (status) {
      case 'completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case 'pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Pending';
        icon = Icons.pending;
        break;
      case 'pending_checkout':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Checked In';
        icon = Icons.timer;
        break;
      case 'granted':
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        label = 'Granted';
        icon = Icons.verified;
        break;
      case 'approved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Approved';
        icon = Icons.thumb_up;
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case 'not_granted':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Not Granted';
        icon = Icons.block;
        break;
      case 'unusual':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        label = 'Unusual';
        icon = Icons.warning;
        break;
      case 'appealed':
        bgColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
        label = 'Appealed';
        icon = Icons.gavel;
        break;
      case 'cancelled':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Cancelled';
        icon = Icons.close;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status ?? 'Unknown';
        icon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildTimeInfo(String label, DateTime? time, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          time != null ? TimezoneUtils.formatTime12Hour(time) : '--:--',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
      ],
    );
  }
  
  static Widget _buildDurationInfo(double hours, double expectedHours) {
    final wholeHours = hours.floor();
    final mins = ((hours - wholeHours) * 60).round();
    final isUndertime = hours < expectedHours - 0.5;
    final isOvertime = hours > expectedHours + 0.5;
    
    Color durationColor = AppConstant.textPrimary;
    if (isOvertime) {
      durationColor = Colors.green.shade700;
    } else if (isUndertime) {
      durationColor = Colors.red.shade700;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 10, color: Colors.grey[600]),
            const SizedBox(width: 3),
            Text(
              'Duration',
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          hours > 0 ? '${wholeHours}h ${mins}m' : '--',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: durationColor,
          ),
        ),
      ],
    );
  }
}