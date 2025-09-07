import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/unified_schedule_controller.dart';
import '../models/schedule_model.dart';
import '../utils/app_constant.dart';

class UnifiedScheduleScreen extends StatelessWidget {
  const UnifiedScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UnifiedScheduleController());

    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Schedule & Attendance',
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
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshData(),
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
                // Date Navigation Header
                _buildDateNavigationHeader(context, controller),
                const SizedBox(height: 16),
                
                // Active Attendance Warning (if user has any active attendance)
                if (controller.isToday && controller.hasActiveAttendance) ...[
                  _buildActiveAttendanceWarning(controller),
                  const SizedBox(height: 16),
                ],
                
                // Schedules List
                _buildSchedulesList(controller),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateNavigationHeader(BuildContext context, UnifiedScheduleController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: controller.previousDay,
              icon: const Icon(Icons.chevron_left),
              color: AppConstant.primaryColor,
            ),
            Expanded(
              child: Obx(() => Column(
                children: [
                  Text(
                    DateFormat('EEEE').format(controller.selectedDate.value),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstant.textSecondary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(controller.selectedDate.value),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.textPrimary,
                    ),
                  ),
                  if (controller.isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstant.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              )),
            ),
            IconButton(
              onPressed: controller.nextDay,
              icon: const Icon(Icons.chevron_right),
              color: AppConstant.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAttendanceWarning(UnifiedScheduleController controller) {
    final activeSchedule = controller.currentActiveSchedule;
    if (activeSchedule == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppConstant.warningColor, AppConstant.warningColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currently Working',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Schedule: ${activeSchedule.title}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCheckOutConfirmation(controller, activeSchedule),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                  'Check Out Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstant.errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesList(UnifiedScheduleController controller) {
    return Obx(() {
      final schedules = controller.todaySchedules;
      
      if (schedules.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.isToday 
                ? 'Today\'s Schedule (${schedules.length})'
                : 'Schedule for ${DateFormat('MMM d').format(controller.selectedDate.value)} (${schedules.length})',
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
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              return _buildScheduleCard(schedules[index], controller);
            },
          ),
        ],
      );
    });
  }

  Widget _buildScheduleCard(ScheduleModel schedule, UnifiedScheduleController controller) {
    final startTime = DateFormat('HH:mm').format(schedule.startDateTime);
    final endTime = DateFormat('HH:mm').format(schedule.endDateTime);
    
    // Get attendance status for this specific schedule
    final attendanceStatus = controller.getScheduleAttendanceStatus(schedule);
    final workStatus = controller.getScheduleWorkStatus(schedule);
    final canCheckIn = controller.canCheckInForSchedule(schedule);
    final canCheckOut = controller.canCheckOutForSchedule(schedule);
    final isCompleted = controller.isScheduleCompleted(schedule);
    
    Color statusColor = AppConstant.textSecondary;
    Color backgroundColor = Colors.transparent;
    Color borderColor = Colors.transparent;
    
    if (isCompleted) {
      statusColor = AppConstant.successColor;
      backgroundColor = AppConstant.successColor.withOpacity(0.05);
      borderColor = AppConstant.successColor;
    } else if (canCheckOut) {
      statusColor = AppConstant.warningColor;
      backgroundColor = AppConstant.warningColor.withOpacity(0.05);
      borderColor = AppConstant.warningColor;
    } else if (canCheckIn && controller.isToday) {
      statusColor = AppConstant.primaryColor;
      backgroundColor = AppConstant.primaryColor.withOpacity(0.05);
      borderColor = AppConstant.primaryColor;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (canCheckIn && controller.isToday) {
            _showCheckInDialog(controller, schedule);
          } else if (canCheckOut && controller.isToday) {
            _showCheckOutConfirmation(controller, schedule);
          } else if (isCompleted) {
            _showScheduleCompletedDialog(schedule, attendanceStatus);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: borderColor != Colors.transparent
                ? Border.all(color: borderColor, width: 2)
                : null,
            color: backgroundColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge and Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isCompleted 
                        ? Icons.check_circle
                        : canCheckOut 
                            ? Icons.schedule
                            : canCheckIn && controller.isToday
                                ? Icons.play_circle_outline
                                : Icons.schedule_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Schedule Title and Time
              Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppConstant.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$startTime - $endTime',
                    style: const TextStyle(
                      color: AppConstant.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              // Location and Department
              if (schedule.location.isNotEmpty || schedule.department.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (schedule.location.isNotEmpty) ...[
                      Icon(
                        Icons.location_on,
                        color: AppConstant.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          schedule.location,
                          style: const TextStyle(
                            color: AppConstant.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    if (schedule.location.isNotEmpty && schedule.department.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppConstant.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (schedule.department.isNotEmpty) ...[
                      Icon(
                        Icons.business,
                        color: AppConstant.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.department,
                        style: const TextStyle(
                          color: AppConstant.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              // Description
              if (schedule.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  schedule.description,
                  style: const TextStyle(
                    color: AppConstant.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Attendance Details (if checked in or completed)
              if (attendanceStatus != null && attendanceStatus['has_checked_in'] == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (attendanceStatus['check_in_time'] != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Check-in:',
                              style: TextStyle(
                                color: AppConstant.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(
                                DateTime.parse(attendanceStatus['check_in_time'])
                              ),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (attendanceStatus['check_out_time'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Check-out:',
                              style: TextStyle(
                                color: AppConstant.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(
                                DateTime.parse(attendanceStatus['check_out_time'])
                              ),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              // Action Prompt
              if (controller.isToday) ...[
                const SizedBox(height: 12),
                if (canCheckIn) ...[
                  Text(
                    '👆 Tap to check in for this schedule',
                    style: TextStyle(
                      color: AppConstant.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else if (canCheckOut) ...[
                  Text(
                    '⚠️ Please check out to complete this schedule',
                    style: TextStyle(
                      color: AppConstant.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (isCompleted) ...[
                  Text(
                    '✅ Schedule completed successfully',
                    style: TextStyle(
                      color: AppConstant.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.schedule,
            size: 64,
            color: AppConstant.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules for this date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstant.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check other dates or contact your manager',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckInDialog(UnifiedScheduleController controller, ScheduleModel schedule) {
    Get.dialog(
      AlertDialog(
        title: const Text('Check In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you ready to check in for:'),
            const SizedBox(height: 8),
            Text(
              schedule.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('HH:mm').format(schedule.startDateTime)} - ${DateFormat('HH:mm').format(schedule.endDateTime)}',
              style: const TextStyle(
                color: AppConstant.textSecondary,
              ),
            ),
            if (schedule.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Location: ${schedule.location}',
                style: const TextStyle(
                  color: AppConstant.textSecondary,
                ),
              ),
            ],
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
              controller.checkInForSchedule(schedule);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.primaryColor,
            ),
            child: const Text(
              'Check In',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckOutConfirmation(UnifiedScheduleController controller, ScheduleModel schedule) {
    Get.dialog(
      AlertDialog(
        title: const Text('Check Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you ready to check out from:'),
            const SizedBox(height: 8),
            Text(
              schedule.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will complete your attendance for this schedule.',
              style: const TextStyle(
                color: AppConstant.textSecondary,
              ),
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
              controller.checkOutForSchedule(schedule);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.errorColor,
            ),
            child: const Text(
              'Check Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleCompletedDialog(ScheduleModel schedule, Map<String, dynamic>? attendanceStatus) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppConstant.successColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Schedule Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (attendanceStatus != null) ...[
              if (attendanceStatus['check_in_time'] != null) ...[
                Text(
                  'Check-in: ${DateFormat('hh:mm a').format(DateTime.parse(attendanceStatus['check_in_time']))}',
                ),
              ],
              if (attendanceStatus['check_out_time'] != null) ...[
                Text(
                  'Check-out: ${DateFormat('hh:mm a').format(DateTime.parse(attendanceStatus['check_out_time']))}',
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              'This schedule has been completed successfully.',
              style: TextStyle(
                color: AppConstant.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.successColor,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
