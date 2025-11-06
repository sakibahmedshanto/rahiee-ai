import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_constant.dart';
import '../screens/attendance_screen/camera_check_in_screen.dart';
import '../controllers/schedule_controller.dart';

class CurrentCheckInStatusWidget extends StatelessWidget {
  final VoidCallback? onStatusChanged;
  final bool showCheckoutButton;
  final EdgeInsets? padding;

  const CurrentCheckInStatusWidget({
    super.key,
    this.onStatusChanged,
    this.showCheckoutButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Get the controller to access current check-in status
    final controller = Get.find<ScheduleController>();
    
    return Obx(() {
      final currentStatus = controller.currentCheckInStatus;
      
      if (currentStatus['has_active_checkin'] != true) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: padding ?? const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstant.primaryColor.withOpacity(0.1),
              AppConstant.secondaryColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstant.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstant.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.login,
                    color: AppConstant.successColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currentStatus['is_from_yesterday'] == true 
                                ? 'Active Check-in from Yesterday'
                                : 'Currently Checked In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppConstant.textPrimary,
                            ),
                          ),
                          if (currentStatus['is_from_yesterday'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstant.warningColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Yesterday',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppConstant.warningColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        currentStatus['schedule_title'] ?? 'Unknown Schedule',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstant.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showCheckoutButton)
                  ElevatedButton.icon(
                    onPressed: () => _handleCheckout(currentStatus),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Check Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstant.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status Details
            Row(
              children: [
                // Duration
                Expanded(
                  child: _buildStatusItem(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: currentStatus['duration_formatted'] ?? '0m',
                    color: AppConstant.primaryColor,
                  ),
                ),
                
                // Check-in Time
                Expanded(
                  child: _buildStatusItem(
                    icon: Icons.schedule,
                    label: 'Checked In',
                    value: _formatTime(currentStatus['check_in_time']),
                    color: AppConstant.secondaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Location and Status
            Row(
              children: [
                // Location
                Expanded(
                  child: _buildStatusItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: currentStatus['schedule_location'] ?? 'Not specified',
                    color: AppConstant.accentColor,
                  ),
                ),
                
                // Uniform Status
                if (currentStatus['wearing_uniform'] != null)
                  Expanded(
                    child: _buildStatusItem(
                      icon: currentStatus['wearing_uniform'] == true 
                          ? Icons.check_circle 
                          : Icons.warning,
                      label: 'Uniform',
                      value: currentStatus['wearing_uniform'] == true 
                          ? 'Verified' 
                          : 'Not Verified',
                      color: currentStatus['wearing_uniform'] == true 
                          ? AppConstant.successColor 
                          : AppConstant.warningColor,
                    ),
                  ),
              ],
            ),
            
            // Late indicator
            if (currentStatus['is_late'] == true)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstant.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppConstant.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning,
                      size: 14,
                      color: AppConstant.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Late Check-in',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstant.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _handleCheckout(Map<String, dynamic> currentStatus) async {
    try {
      final attendanceId = currentStatus['attendance_id']?.toString();
      final scheduleId = currentStatus['schedule_id']?.toString();
      final scheduleTitle = currentStatus['schedule_title']?.toString() ?? 'Check Out';
      
      if (attendanceId == null || scheduleId == null) return;

      // Navigate to camera screen for checkout
      Get.to(
        () => CameraCheckInScreen(
          scheduleId: scheduleId,
          scheduleTitle: scheduleTitle,
          onCheckInComplete: () async {
            // Refresh status after checkout
            onStatusChanged?.call();
          },
        ),
        arguments: {
          'attendanceId': attendanceId,
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start checkout: $e',
        backgroundColor: AppConstant.errorColor,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppConstant.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstant.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null) return 'Unknown';
    
    try {
      DateTime time;
      if (timeValue is String) {
        time = DateTime.parse(timeValue);
      } else if (timeValue is DateTime) {
        time = timeValue;
      } else {
        return 'Unknown';
      }
      
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:$minute $period';
    } catch (e) {
      return 'Unknown';
    }
  }
}