import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/schedule_model.dart';
import '../../utils/app_constant.dart';
import '../../utils/timezone_utils.dart';
import '../../widgets/current_checkin_status_widget.dart';
import 'create_exchange_request_screen.dart';
import 'employee_exchange_screen.dart';

/// Clean, efficient schedule screen with optimized performance
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleController());

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
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () => Get.to(() => const EmployeeExchangeScreen()),
            tooltip: 'My Exchange Requests',
          ),
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
                _buildDateNavigationHeader(controller),
                const SizedBox(height: 16),
                
                // Current Check-in Status Widget
                Obx(() {
                  if (controller.hasActiveCheckIn.value) {
                    return CurrentCheckInStatusWidget(
                      onStatusChanged: () => controller.refreshData(),
                      showCheckoutButton: true,
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
                const SizedBox(height: 16),
                
                // Schedules List
                _buildSchedulesList(controller),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Build date navigation header
  Widget _buildDateNavigationHeader(ScheduleController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: controller.previousDay,
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppConstant.primaryColor,
                    size: 28,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(controller.selectedDate.value),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (controller.isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstant.primaryColor,
                            borderRadius: BorderRadius.circular(12),
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
                  ),
                ),
                IconButton(
                  onPressed: controller.nextDay,
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppConstant.primaryColor,
                    size: 28,
                  ),
                ),
              ],
            ),
            if (!controller.isToday) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: controller.goToToday,
                icon: const Icon(Icons.today, size: 16),
                label: const Text('Go to Today'),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstant.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build schedules list
  Widget _buildSchedulesList(ScheduleController controller) {
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

  /// Build individual schedule card
  Widget _buildScheduleCard(ScheduleModel schedule, ScheduleController controller) {
    final startTime = TimezoneUtils.formatTime12Hour(schedule.startDateTime);
    final endTime = TimezoneUtils.formatTime12Hour(schedule.endDateTime);
    
    final statusColor = controller.getScheduleStatusColor(schedule);
    final statusText = controller.getScheduleStatusText(schedule);
    final statusIcon = controller.getScheduleStatusIcon(schedule);
    
    final canTap = schedule.canCheckIn == true || 
                   schedule.canCheckOut == true || 
                   schedule.isCompleted == true || 
                   schedule.isExpired == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: canTap ? () => controller.onScheduleTap(schedule) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstant.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schedule.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppConstant.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Schedule Details
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppConstant.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$startTime - $endTime',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppConstant.textPrimary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppConstant.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      schedule.location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (schedule.department.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: AppConstant.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      schedule.department,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Check-in/Check-out Times (if available)
              if (schedule.checkInTime != null || schedule.checkOutTime != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstant.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstant.borderColor),
                  ),
                  child: Column(
                    children: [
                      if (schedule.checkInTime != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.login,
                              size: 16,
                              color: AppConstant.successColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Checked in: ${TimezoneUtils.formatTime12Hour(schedule.checkInTime)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppConstant.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (schedule.checkOutTime != null) const SizedBox(height: 4),
                      ],
                      if (schedule.checkOutTime != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.exit_to_app,
                              size: 16,
                              color: AppConstant.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Checked out: ${TimezoneUtils.formatTime12Hour(schedule.checkOutTime)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppConstant.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (schedule.actualDurationHours != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: AppConstant.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: ${schedule.actualDurationHours!.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppConstant.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              // Action Hint
              if (canTap && controller.isToday) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getActionHint(schedule),
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Exchange Request Button - show ONLY for future, non-completed schedules (ignore status)
              // Manual local-time check; RPC still validates on submit
              if (schedule.isCompleted != true && schedule.startDateTime.isAfter(DateTime.now())) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToExchangeRequestScreen(schedule),
                    icon: Icon(Icons.swap_horiz, size: 16),
                    label: Text('Exchange Schedule'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstant.accentColor,
                      side: BorderSide(color: AppConstant.accentColor.withOpacity(0.5)),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get action hint text
  String _getActionHint(ScheduleModel schedule) {
    if (schedule.canCheckIn == true) {
      return 'Tap to check in for this schedule';
    } else if (schedule.canCheckOut == true) {
      return 'Tap to check out from this schedule';
    } else if (schedule.isCompleted == true) {
      return 'Schedule completed successfully';
    } else if (schedule.isExpired == true) {
      return 'Schedule has expired';
    }
    return 'Tap for more details';
  }

  /// Navigate to exchange request screen
  void _navigateToExchangeRequestScreen(ScheduleModel schedule) {
    Get.to(() => CreateExchangeRequestScreen(
      schedule: schedule.toMap(),
    ));
  }

  /// Build empty state
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
}
