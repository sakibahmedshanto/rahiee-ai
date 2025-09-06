import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/attendance_management_service.dart';
import '../utils/app_constant.dart';
import 'attendance_screen/schedule_selection_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;
  final RxMap<String, dynamic> todayAttendance = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    try {
      isLoading.value = true;
      
      // Get today's attendance status using the new RPC function
      final attendanceStatus = await _attendanceService.getTodayAttendanceStatus();
      
      if (attendanceStatus != null && attendanceStatus['success'] == true) {
        todayAttendance.assignAll({
          'has_checked_in': attendanceStatus['status'] != 'not_checked_in',
          'status': attendanceStatus['status'],
          'can_check_in': attendanceStatus['can_check_in'] ?? false,
          'can_check_out': attendanceStatus['can_check_out'] ?? false,
          'check_in_time': attendanceStatus['check_in_time'],
          'check_out_time': attendanceStatus['check_out_time'],
          'schedule_title': attendanceStatus['schedule_title'],
          'attendance_id': attendanceStatus['attendance_id'],
          'total_hours': attendanceStatus['total_hours'],
        });
      } else {
        // Fallback: check available schedules
        final schedules = await _attendanceService.getAvailableSchedulesForEmployee();
        todayAttendance.assignAll({
          'has_checked_in': false,
          'status': 'not_checked_in',
          'can_check_in': true,
          'can_check_out': false,
          'available_schedules': schedules.length,
          'check_in_time': null,
          'schedule_title': null,
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load attendance data: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateToScheduleSelection() {
    Get.to(() => const ScheduleSelectionScreen());
  }

  IconData _getStatusIcon() {
    final status = todayAttendance['status'] ?? 'not_checked_in';
    switch (status) {
      case 'checked_in':
        return Icons.check_circle;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.login;
    }
  }

  String _getButtonText() {
    final status = todayAttendance['status'] ?? 'not_checked_in';
    switch (status) {
      case 'checked_in':
        return 'Already Checked In';
      case 'completed':
        return 'Attendance Completed';
      default:
        return 'View Schedules & Check In';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstant.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadTodayAttendance,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstant.primaryColor,
                      AppConstant.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstant.primaryColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.today,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Today - ${_formatDate(DateTime.now())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Attendance Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: todayAttendance['has_checked_in'] == true
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: todayAttendance['has_checked_in'] == true
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                todayAttendance['has_checked_in'] == true
                                    ? Icons.check_circle
                                    : Icons.schedule,
                                color: todayAttendance['has_checked_in'] == true
                                    ? Colors.green
                                    : Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                todayAttendance['has_checked_in'] == true
                                    ? 'Checked In'
                                    : 'Not Checked In',
                                style: TextStyle(
                                  color: todayAttendance['has_checked_in'] == true
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (todayAttendance['has_checked_in'] == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Check-in Time: ${todayAttendance['check_in_time'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (todayAttendance['schedule_title'] != null)
                        Text(
                          'Schedule: ${todayAttendance['schedule_title']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Available Schedules Info
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
                    Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          color: AppConstant.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Schedules',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstant.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      'You have ${todayAttendance['available_schedules'] ?? 0} schedule(s) available for today',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Check-in Instructions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'How to Check In',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. View your assigned schedules\n'
                            '2. Select the schedule you want to check in for\n'
                            '3. Verify schedule details\n'
                            '4. Complete check-in with location verification',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Check-in Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: todayAttendance['can_check_in'] == true
                      ? _navigateToScheduleSelection
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstant.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              if (todayAttendance['has_checked_in'] == true) ...[
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstant.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to attendance history or clock out
                          Get.snackbar(
                            'Coming Soon',
                            'Clock out functionality will be available soon',
                            backgroundColor: Colors.blue[100],
                            colorText: Colors.blue[800],
                          );
                        },
                        icon: Icon(
                          Icons.logout,
                          color: AppConstant.primaryColor,
                          size: 18,
                        ),
                        label: Text(
                          'Clock Out',
                          style: TextStyle(color: AppConstant.primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppConstant.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.snackbar(
                            'Coming Soon',
                            'Attendance history will be available soon',
                            backgroundColor: Colors.blue[100],
                            colorText: Colors.blue[800],
                          );
                        },
                        icon: Icon(
                          Icons.history,
                          color: AppConstant.primaryColor,
                          size: 18,
                        ),
                        label: Text(
                          'History',
                          style: TextStyle(color: AppConstant.primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppConstant.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
