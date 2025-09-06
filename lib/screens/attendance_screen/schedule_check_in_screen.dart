import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/attendance_management_service.dart';
import '../../services/location_permission_service.dart';
import '../../utils/app_constant.dart';

class ScheduleCheckInScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  const ScheduleCheckInScreen({
    super.key,
    required this.schedule,
  });

  @override
  State<ScheduleCheckInScreen> createState() => _ScheduleCheckInScreenState();
}

class _ScheduleCheckInScreenState extends State<ScheduleCheckInScreen> {
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;
  final LocationPermissionService _locationService = LocationPermissionService.to;
  final TextEditingController _notesController = TextEditingController();
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final result = await _locationService.requestLocationPermission();
    
    if (!result.success) {
      switch (result.action) {
        case LocationPermissionAction.openSettings:
          Get.defaultDialog(
            title: 'Location Permission Required',
            middleText: result.message,
            textConfirm: 'Open Settings',
            textCancel: 'Cancel',
            confirmTextColor: Colors.white,
            onConfirm: () async {
              Get.back();
              await _locationService.openAppSettings();
            },
            onCancel: () => Get.back(),
          );
          break;
        case LocationPermissionAction.enableGPS:
          Get.snackbar(
            'GPS Required',
            result.message,
            backgroundColor: Colors.orange[100],
            colorText: Colors.orange[800],
            duration: const Duration(seconds: 5),
          );
          break;
        case LocationPermissionAction.requestAgain:
          Get.snackbar(
            'Permission Required',
            result.message,
            backgroundColor: Colors.orange[100],
            colorText: Colors.orange[800],
            duration: const Duration(seconds: 5),
          );
          break;
        case LocationPermissionAction.none:
          Get.snackbar(
            'Location Error',
            result.message,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[800],
            duration: const Duration(seconds: 5),
          );
          break;
      }
    }
  }

  Future<void> _performCheckIn() async {
    try {
      // Ensure we have location permission and current position
      if (!_locationService.hasLocationPermission.value) {
        await _checkLocationPermission();
        return;
      }

      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        Get.snackbar(
          'Location Required',
          'Unable to get your current location. Please try again.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
        return;
      }

      // Show immediate loading feedback
      isLoading.value = true;
      
      // Show progress dialog with loading message
      Get.dialog(
        PopScope(
          canPop: false, // Prevent dismissing during check-in
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Checking you in...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we process your check-in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final result = await _attendanceService.clockIn(
        scheduleId: widget.schedule['id'].toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      // Close loading dialog
      Get.back();

      if (result['success'] == true) {
        Get.snackbar(
          'Check-in Successful',
          'You have successfully checked in for this schedule',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          duration: const Duration(seconds: 3),
        );
        
        // Go back to previous screens (schedule selection and possibly home)
        Get.back(); // Back to schedule selection
        Get.back(); // Back to home or previous screen
      } else {
        Get.snackbar(
          'Check-in Failed',
          result['message'] ?? 'Failed to check in',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        'Error',
        'Check-in failed: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.parse(widget.schedule['start_date_time']);
    final endTime = DateTime.parse(widget.schedule['end_date_time']);

    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Check In to Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstant.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Schedule details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstant.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Title
                        _buildDetailRow(
                          icon: Icons.event,
                          label: 'Title',
                          value: widget.schedule['title'] ?? 'Untitled',
                        ),
                        
                        // Time
                        _buildDetailRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                        ),
                        
                        // Location
                        if (widget.schedule['location'] != null) ...[
                          _buildDetailRow(
                            icon: Icons.location_on,
                            label: 'Location',
                            value: widget.schedule['location'].toString(),
                          ),
                        ],
                        
                        // Department
                        if (widget.schedule['department'] != null) ...[
                          _buildDetailRow(
                            icon: Icons.business,
                            label: 'Department',
                            value: widget.schedule['department'].toString(),
                          ),
                        ],
                        
                        // Description
                        if (widget.schedule['description'] != null &&
                            widget.schedule['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: AppConstant.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.schedule['description'].toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location status card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstant.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Obx(() {
                          String statusText;
                          Color statusColor;
                          IconData statusIcon;
                          
                          if (_locationService.hasLocationPermission.value && _locationService.currentPosition.value != null) {
                            statusText = 'Location verified and ready for check-in';
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle;
                          } else if (_locationService.hasLocationPermission.value && _locationService.currentPosition.value == null) {
                            statusText = 'Getting your current location...';
                            statusColor = Colors.blue;
                            statusIcon = Icons.location_searching;
                          } else {
                            statusText = 'Location permission required for check-in';
                            statusColor = Colors.orange;
                            statusIcon = Icons.location_disabled;
                          }
                          
                          return Row(
                            children: [
                              Icon(
                                statusIcon,
                                color: statusColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: statusColor.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              if (!_locationService.hasLocationPermission.value || _locationService.currentPosition.value == null)
                                TextButton(
                                  onPressed: _checkLocationPermission,
                                  child: Text(
                                    _locationService.hasLocationPermission.value ? 'Retry' : 'Enable',
                                    style: TextStyle(color: AppConstant.primaryColor),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in Notes (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstant.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add any notes about your check-in...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppConstant.primaryColor),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Check-in button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Obx(() => ElevatedButton(
              onPressed: (!isLoading.value && 
                         _locationService.hasLocationPermission.value && 
                         _locationService.currentPosition.value != null)
                  ? _performCheckIn
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstant.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Check In Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppConstant.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $amPm';
  }
}
