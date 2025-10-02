import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/schedule_exchange_controller.dart';
import '../../../utils/app_constant.dart';

class CreateExchangeRequestScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const CreateExchangeRequestScreen({
    Key? key,
    required this.schedule,
  }) : super(key: key);

  @override
  State<CreateExchangeRequestScreen> createState() => _CreateExchangeRequestScreenState();
}

class _CreateExchangeRequestScreenState extends State<CreateExchangeRequestScreen> {
  final ScheduleExchangeController controller = Get.put(ScheduleExchangeController());
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedUserId;
  String _requestType = 'exchange';
  int _expiresInDays = 7;

  @override
  void initState() {
    super.initState();
    // Load available users for this schedule
    controller.loadAvailableUsersForExchange(
      scheduleId: widget.schedule['id'],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Change Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppConstant.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Schedule Information Card
              _buildScheduleInfoCard(),
              const SizedBox(height: 16),

              // Exchange Request Form
              _buildExchangeRequestForm(),
              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleInfoCard() {
    final startTime = DateFormat('HH:mm').format(
      DateTime.parse(widget.schedule['start_date_time'])
    );
    final endTime = DateFormat('HH:mm').format(
      DateTime.parse(widget.schedule['end_date_time'])
    );
    final date = DateFormat('MMM d, yyyy').format(
      DateTime.parse(widget.schedule['start_date_time'])
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AppConstant.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Schedule Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstant.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Title', widget.schedule['title'], Icons.title),
            _buildInfoRow('Date', date, Icons.calendar_today),
            _buildInfoRow('Time', '$startTime - $endTime', Icons.access_time),
            _buildInfoRow('Location', widget.schedule['location'], Icons.location_on),
            _buildInfoRow('Department', widget.schedule['department'], Icons.business),
            if (widget.schedule['description'] != null && widget.schedule['description'].isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Description', widget.schedule['description'], Icons.description),
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

  Widget _buildExchangeRequestForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Change Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Request Type
            _buildRequestTypeSelector(),
            const SizedBox(height: 16),

            // Available Users Dropdown
            _buildUserSelector(),
            const SizedBox(height: 16),

            // Reason Field
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Schedule Change *',
                hintText: 'Please provide a reason for requesting this schedule change...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a reason for the schedule change';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes Field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Add any additional information...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Expiration Days
            _buildExpirationSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Type',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstant.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Exchange'),
                subtitle: const Text('Mutual swap'),
                value: 'exchange',
                groupValue: _requestType,
                onChanged: (value) => setState(() => _requestType = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Coverage'),
                subtitle: const Text('Temporary coverage'),
                value: 'coverage',
                groupValue: _requestType,
                onChanged: (value) => setState(() => _requestType = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserSelector() {
    return Obx(() {
      if (controller.availableUsers.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: const Column(
            children: [
              Icon(Icons.person_off, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'No available users found',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'All users have conflicting schedules',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      }

      return DropdownButtonFormField<String>(
        value: _selectedUserId,
        decoration: const InputDecoration(
          labelText: 'Select User to Exchange With *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        items: controller.availableUsers.map<DropdownMenuItem<String>>((user) {
          return DropdownMenuItem<String>(
            value: user['id'],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${user['employee_id']} • ${user['department']}',
                  style: const TextStyle(
                    color: AppConstant.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedUserId = value),
        validator: (value) {
          if (value == null) {
            return 'Please select a user to exchange with';
          }
          return null;
        },
      );
    });
  }

  Widget _buildExpirationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Expiration',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstant.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<int>(
                title: const Text('3 days'),
                value: 3,
                groupValue: _expiresInDays,
                onChanged: (value) => setState(() => _expiresInDays = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<int>(
                title: const Text('7 days'),
                value: 7,
                groupValue: _expiresInDays,
                onChanged: (value) => setState(() => _expiresInDays = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<int>(
                title: const Text('14 days'),
                value: 14,
                groupValue: _expiresInDays,
                onChanged: (value) => setState(() => _expiresInDays = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: controller.isCreatingRequest.value ? null : _submitRequest,
          icon: controller.isCreatingRequest.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
          label: Text(
            controller.isCreatingRequest.value
                ? 'Creating Request...'
                : 'Submit Schedule Change Request',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstant.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    });
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (_selectedUserId == null) {
      Get.snackbar(
        'Selection Required',
        'Please select a user to exchange with',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.person_off, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Show confirmation dialog
    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    final selectedUser = controller.availableUsers.firstWhere(
      (user) => user['id'] == _selectedUserId,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Exchange Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are requesting to exchange your schedule:'),
            const SizedBox(height: 8),
            Text(
              widget.schedule['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('With: ${selectedUser['full_name']}'),
            const SizedBox(height: 8),
            Text('Reason: ${_reasonController.text}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This request will be sent to admin for approval',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
            onPressed: controller.isCreatingRequest.value ? null : () async {
              Get.back(); // Close the confirmation dialog
              
              final result = await controller.createExchangeRequest(
                scheduleId: widget.schedule['id'],
                requestedUserId: _selectedUserId!,
                requestReason: _reasonController.text,
                requestNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
                requestType: _requestType,
                expiresInDays: _expiresInDays,
              );
              
              if (result['success']) {
                // Show success message and navigate back
                Get.snackbar(
                  '✅ Request Submitted!',
                  'Your schedule exchange request has been submitted successfully. You will be notified when the admin reviews your request.',
                  backgroundColor: Colors.green.withOpacity(0.9),
                  colorText: Colors.white,
                  icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  duration: const Duration(seconds: 4),
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 8,
                  isDismissible: true,
                  dismissDirection: DismissDirection.horizontal,
                );
                
                // Navigate back to schedule screen
                Get.back();
              } else {
                // Show error message
                Get.snackbar(
                  '❌ Submission Failed',
                  result['error'] ?? 'Failed to submit schedule change request. Please try again.',
                  backgroundColor: Colors.red.withOpacity(0.9),
                  colorText: Colors.white,
                  icon: const Icon(Icons.error, color: Colors.white, size: 28),
                  duration: const Duration(seconds: 4),
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 8,
                  isDismissible: true,
                  dismissDirection: DismissDirection.horizontal,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.primaryColor,
            ),
            child: controller.isCreatingRequest.value
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submitting...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : const Text(
                    'Submit Request',
                    style: TextStyle(color: Colors.white),
                  ),
          )),
        ],
      ),
    );
  }
}
