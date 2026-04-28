import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/schedule_exchange_controller.dart';
import '../../utils/app_constant.dart';
import '../../utils/timezone_utils.dart';

/// Employee screen for managing schedule exchange requests
class EmployeeExchangeScreen extends StatelessWidget {
  const EmployeeExchangeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleExchangeController());
    
    // Load employee's exchange requests
    controller.loadExchangeRequests();

    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Schedule Exchanges',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppConstant.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.loadExchangeRequests(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstant.primaryColor),
            ),
          );
        }

        if (controller.exchangeRequests.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadExchangeRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.exchangeRequests.length,
            itemBuilder: (context, index) {
              final request = controller.exchangeRequests[index];
              return _buildExchangeRequestCard(request, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_outlined,
            size: 80,
            color: AppConstant.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Exchange Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstant.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any schedule exchange requests yet.',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Schedules'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRequestCard(Map<String, dynamic> request, ScheduleExchangeController controller) {
    final scheduleInfo = request['schedule_info'] as Map<String, dynamic>;
    final requesterInfo = request['requester_info'] as Map<String, dynamic>;
    final requestedUserInfo = request['requested_user_info'] as Map<String, dynamic>;
    final requestDetails = request['request_details'] as Map<String, dynamic>;
    final adminInfo = request['admin_info'] as Map<String, dynamic>?;

    final status = requestDetails['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    scheduleInfo['title'] ?? 'Unknown Schedule',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Schedule details
            _buildScheduleDetails(scheduleInfo),
            const SizedBox(height: 12),

            // Exchange details
            _buildExchangeDetails(requesterInfo, requestedUserInfo, requestDetails),
            const SizedBox(height: 12),

            // Admin response (if available)
            if (adminInfo != null) ...[
              _buildAdminResponse(adminInfo),
              const SizedBox(height: 12),
            ],

            // Action buttons
            _buildActionButtons(request, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleDetails(Map<String, dynamic> scheduleInfo) {
    final startTime = TimezoneUtils.parseToLocal(scheduleInfo['start_time']);
    final endTime = TimezoneUtils.parseToLocal(scheduleInfo['end_time']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstant.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstant.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppConstant.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Schedule Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: AppConstant.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${TimezoneUtils.formatTime12Hour(startTime)} - ${TimezoneUtils.formatTime12Hour(endTime)}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          if (scheduleInfo['location'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppConstant.textSecondary),
                const SizedBox(width: 6),
                Text(
                  scheduleInfo['location'],
                  style: TextStyle(
                    fontSize: 13,
                    color: AppConstant.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExchangeDetails(Map<String, dynamic> requesterInfo, Map<String, dynamic> requestedUserInfo, Map<String, dynamic> requestDetails) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstant.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstant.accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 16, color: AppConstant.accentColor),
              const SizedBox(width: 8),
              Text(
                'Exchange Request',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'From: ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstant.textSecondary,
                ),
              ),
              Text(
                requesterInfo['name'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppConstant.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'To: ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstant.textSecondary,
                ),
              ),
              Text(
                requestedUserInfo['name'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppConstant.textPrimary,
                ),
              ),
            ],
          ),
          if (requestDetails['reason'] != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppConstant.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    requestDetails['reason'],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstant.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppConstant.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Requested: ${DateFormat('MMM dd, yyyy HH:mm').format(TimezoneUtils.parseToLocal(requestDetails['created_at']) ?? DateTime.now())}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminResponse(Map<String, dynamic> adminInfo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstant.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstant.successColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 16, color: AppConstant.successColor),
              const SizedBox(width: 8),
              Text(
                'Admin Response',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Reviewed by: ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstant.textSecondary,
                ),
              ),
              Text(
                adminInfo['name'] ?? 'Unknown Admin',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppConstant.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppConstant.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Reviewed: ${DateFormat('MMM dd, yyyy HH:mm').format(TimezoneUtils.parseToLocal(adminInfo['reviewed_at']) ?? DateTime.now())}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
          ),
          if (adminInfo['admin_notes'] != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 14, color: AppConstant.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    adminInfo['admin_notes'],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstant.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (adminInfo['rejection_reason'] != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cancel, size: 14, color: AppConstant.errorColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rejection reason: ${adminInfo['rejection_reason']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstant.errorColor,
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

  Widget _buildActionButtons(Map<String, dynamic> request, ScheduleExchangeController controller) {
    final requestDetails = request['request_details'] as Map<String, dynamic>;
    final status = requestDetails['status'] as String;
    final requestId = request['request_id'] as String;

    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(requestId, controller),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel Request'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstant.errorColor,
                side: BorderSide(color: AppConstant.errorColor),
              ),
            ),
          ),
        ],
        if (status == 'approved') ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstant.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstant.successColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppConstant.successColor),
                  const SizedBox(width: 8),
                  Text(
                    'Exchange Approved',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.successColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (status == 'rejected') ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstant.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstant.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 16, color: AppConstant.errorColor),
                  const SizedBox(width: 8),
                  Text(
                    'Exchange Rejected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(String requestId, ScheduleExchangeController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Exchange Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this exchange request?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason (Optional)',
                hintText: 'Why are you cancelling this request?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.cancelExchangeRequest(
                requestId: requestId,
                cancellationReason: reasonController.text.trim().isEmpty 
                    ? null 
                    : reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.errorColor,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppConstant.warningColor;
      case 'approved':
        return AppConstant.successColor;
      case 'rejected':
        return AppConstant.errorColor;
      case 'cancelled':
        return AppConstant.textSecondary;
      case 'expired':
        return AppConstant.textSecondary;
      default:
        return AppConstant.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}
