import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/schedule_exchange_controller.dart';
import '../../../utils/app_constant.dart';

class AdminExchangeRequestScreen extends StatelessWidget {
  const AdminExchangeRequestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleExchangeController());
    
    // Load all exchange requests for admin
    controller.loadExchangeRequests(isAdmin: true);

    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      // appBar: AppBar(

      //   title: const Text(
      //     'Exchange Requests',
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       color: Colors.white,
      //     ),
      //   ),
      //   backgroundColor: AppConstant.primaryColor,
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh, color: Colors.white),
      //       onPressed: () => controller.loadExchangeRequests(isAdmin: true),
      //     ),
      //   ],
      // ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadExchangeRequests(isAdmin: true),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstant.primaryColor),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                _buildStatisticsCards(controller),
                const SizedBox(height: 16),
                
                // Filters
                _buildFiltersSection(controller),
                const SizedBox(height: 16),
                
                // Exchange Requests List
                _buildExchangeRequestsList(controller),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatisticsCards(ScheduleExchangeController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Requests',
            controller.totalRequests.toString(),
            Icons.swap_horiz,
            AppConstant.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending',
            controller.totalPendingRequests.toString(),
            Icons.schedule,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved',
            controller.totalApprovedRequests.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rejected',
            controller.totalRejectedRequests.toString(),
            Icons.cancel,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppConstant.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection(ScheduleExchangeController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    'Status',
                    controller.selectedStatus.value,
                    ['All', 'pending', 'approved', 'rejected', 'cancelled', 'expired'],
                    (value) => controller.setStatusFilter(value == 'All' ? null : value, isAdmin: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterDropdown(
                    'Type',
                    controller.selectedRequestType.value,
                    ['All', 'exchange', 'swap', 'coverage'],
                    (value) => controller.setRequestTypeFilter(value == 'All' ? null : value, isAdmin: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.clearFilters(isAdmin: true),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstant.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildExchangeRequestsList(ScheduleExchangeController controller) {
    final requests = controller.exchangeRequests;

    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exchange Requests (${requests.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstant.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildExchangeRequestCard(requests[index], controller);
          },
        ),
      ],
    );
  }

  Widget _buildExchangeRequestCard(
    Map<String, dynamic> request,
    ScheduleExchangeController controller,
  ) {
    final requestDetails = request['request_details'];
    final scheduleInfo = request['schedule_info'];
    final requesterInfo = request['requester_info'];
    final requestedUserInfo = request['requested_user_info'];
    final adminInfo = request['admin_info'];

    final status = requestDetails['status'];
    final statusColor = controller.getStatusColor(status);
    final statusIcon = controller.getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  requestDetails['created_at'] != null 
                    ? DateFormat('MMM d, yyyy').format(
                        DateTime.parse(requestDetails['created_at'])
                      )
                    : 'Unknown',
                  style: const TextStyle(
                    color: AppConstant.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Schedule Information
            _buildInfoRow(
              'Schedule',
              scheduleInfo['title'] ?? 'Unknown',
              Icons.schedule,
            ),
            _buildInfoRow(
              'Time',
              scheduleInfo['start_time'] != null && scheduleInfo['end_time'] != null
                ? '${DateFormat('HH:mm').format(DateTime.parse(scheduleInfo['start_time']))} - ${DateFormat('HH:mm').format(DateTime.parse(scheduleInfo['end_time']))}'
                : 'Unknown',
              Icons.access_time,
            ),
            _buildInfoRow(
              'Location',
              scheduleInfo['location'] ?? 'Unknown',
              Icons.location_on,
            ),

            const SizedBox(height: 12),

            // Exchange Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstant.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstant.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildUserInfo(
                          'From',
                          requesterInfo['name'] ?? 'Unknown',
                          requesterInfo['employee_id'] ?? 'Unknown',
                          Icons.person_outline,
                        ),
                      ),
                      const Icon(Icons.swap_horiz, color: AppConstant.primaryColor),
                      Expanded(
                        child: _buildUserInfo(
                          'To',
                          requestedUserInfo['name'] ?? 'Unknown',
                          requestedUserInfo['employee_id'] ?? 'Unknown',
                          Icons.person,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Request Details
            if (requestDetails['reason'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Reason',
                requestDetails['reason'],
                Icons.info_outline,
              ),
            ],
            if (requestDetails['notes'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Notes',
                requestDetails['notes'],
                Icons.note,
              ),
            ],

            // Admin Review (if reviewed)
            if (adminInfo != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Review',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Reviewed by',
                      adminInfo['name'] ?? 'Unknown',
                      Icons.admin_panel_settings,
                    ),
                    _buildInfoRow(
                      'Reviewed at',
                      requestDetails['reviewed_at'] != null
                        ? DateFormat('MMM d, yyyy HH:mm').format(
                            DateTime.parse(requestDetails['reviewed_at'])
                          )
                        : 'Unknown',
                      Icons.schedule,
                    ),
                    if (adminInfo['admin_notes'] != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Admin Notes',
                        adminInfo['admin_notes'],
                        Icons.note,
                      ),
                    ],
                    if (adminInfo['rejection_reason'] != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Rejection Reason',
                        adminInfo['rejection_reason'],
                        Icons.cancel,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Action Buttons (for pending requests)
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(request, controller),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(request, controller),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppConstant.textSecondary, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppConstant.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppConstant.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String label, String name, String employeeId, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstant.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstant.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppConstant.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          employeeId,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstant.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.swap_horiz,
            size: 64,
            color: AppConstant.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No exchange requests found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstant.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exchange requests will appear here when employees request schedule changes',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> request, ScheduleExchangeController controller) {
    final adminNotesController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Approve Exchange Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to approve this exchange request?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: adminNotesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any notes about this approval...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.manageExchangeRequest(
                requestId: request['request_id'],
                action: 'approve',
                adminNotes: adminNotesController.text.isNotEmpty ? adminNotesController.text : null,
                isAdmin: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Approve',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> request, ScheduleExchangeController controller) {
    final adminNotesController = TextEditingController();
    final rejectionReasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Reject Exchange Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject this exchange request?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
                hintText: 'Please provide a reason for rejection...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: adminNotesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any additional notes...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (rejectionReasonController.text.isEmpty) {
                Get.snackbar('Error', 'Please provide a rejection reason');
                return;
              }
              Get.back();
              controller.manageExchangeRequest(
                requestId: request['request_id'],
                action: 'reject',
                adminNotes: adminNotesController.text.isNotEmpty ? adminNotesController.text : null,
                rejectionReason: rejectionReasonController.text,
                isAdmin: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

