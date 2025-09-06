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
                // Attendance Status Card - only show for today
                
                
              
                _buildDateNavigationHeader(context, controller),
                if (controller.isToday) const SizedBox(height: 20),
                
                  if (controller.isToday) _buildAttendanceStatusCard(controller),
                // Date Navigation Header
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

  Widget _buildAttendanceStatusCard(UnifiedScheduleController controller) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: controller.shouldShowWorkSummary()
                ? [AppConstant.successColor, AppConstant.successColor.withOpacity(0.8)]
                : controller.shouldShowCheckOut()
                    ? [AppConstant.warningColor, AppConstant.warningColor.withOpacity(0.8)]
                    : [AppConstant.primaryColor, AppConstant.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Icon(
                    controller.shouldShowWorkSummary()
                        ? Icons.check_circle
                        : controller.shouldShowCheckOut()
                            ? Icons.work
                            : Icons.work_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.getAttendanceStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (controller.activeSchedule.value != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Schedule: ${controller.activeSchedule.value!.title}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Work Session Details
              if (controller.shouldShowWorkSummary()) ...[
                _buildWorkSummaryDetails(controller),
              ] else if (controller.shouldShowCheckOut()) ...[
                _buildCurrentWorkDetails(controller),
              ] else ...[
                _buildReadyToWorkDetails(controller),
              ],
              
              const SizedBox(height: 20),
              
              // Action Buttons
              _buildActionButtons(controller),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWorkSummaryDetails(UnifiedScheduleController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in Time:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                controller.checkInTime.value != null
                    ? DateFormat('hh:mm a').format(controller.checkInTime.value!)
                    : '--:--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-out Time:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                controller.checkOutTime.value != null
                    ? DateFormat('hh:mm a').format(controller.checkOutTime.value!)
                    : '--:--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Duration:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                controller.getWorkDurationText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWorkDetails(UnifiedScheduleController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started At:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                controller.checkInTime.value != null
                    ? DateFormat('hh:mm a').format(controller.checkInTime.value!)
                    : '--:--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duration:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                controller.getWorkDurationText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToWorkDetails(UnifiedScheduleController controller) {
    if (controller.todaySchedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No schedules available today. Check back later!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      );
    }

    final nextSchedule = controller.todaySchedules.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Schedule:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(nextSchedule.startDateTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Location:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Flexible(
                child: Text(
                  nextSchedule.location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UnifiedScheduleController controller) {
    if (controller.shouldShowWorkSummary()) {
      // Show completed work message
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Work session completed for today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (controller.shouldShowCheckOut()) {
      // Show checkout button
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              text: 'Check Out',
              icon: Icons.logout,
              onPressed: controller.isCheckingOut.value
                  ? null
                  : () => _showCheckOutConfirmation(controller),
              isLoading: controller.isCheckingOut.value,
              backgroundColor: AppConstant.errorColor,
            ),
          ),
        ],
      );
    } else {
      // Show check-in options based on schedules
      if (controller.todaySchedules.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'No schedules available for check-in today',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        );
      }

      // Check if any schedule is available for check-in
      final availableSchedules = controller.todaySchedules
          .where((schedule) => controller.shouldShowCheckIn(schedule))
          .toList();

      if (availableSchedules.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Check-in will be available when your schedule starts',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              text: 'Check In',
              icon: Icons.login,
              onPressed: controller.isCheckingIn.value
                  ? null
                  : () => _showCheckInDialog(controller, availableSchedules.first),
              isLoading: controller.isCheckingIn.value,
              backgroundColor: AppConstant.successColor,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isLoading,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, color: Colors.white),
      label: Text(
        isLoading ? 'Please wait...' : text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDateNavigationHeader(BuildContext context, UnifiedScheduleController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous day button
          GestureDetector(
            onTap: controller.previousDay,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppConstant.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstant.borderColor,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.chevron_left,
                color: AppConstant.textSecondary,
                size: 20,
              ),
            ),
          ),
          
          // Date display
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => _showDatePicker(context, controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10 , vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstant.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(() => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppConstant.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMM d').format(controller.selectedDate.value),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstant.primaryColor,
                        ),
                      ),
                      if (controller.isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstant.successColor,
                            borderRadius: BorderRadius.circular(8),
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
                    ],
                  )),
                ),
              ),
            ),
          ),
          
          // Next day button
          GestureDetector(
            onTap: controller.nextDay,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppConstant.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstant.borderColor,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.chevron_right,
                color: AppConstant.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
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
    final isCurrentSchedule = controller.isCurrentSchedule(schedule);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (controller.canCheckInForSchedule(schedule)) {
            _showCheckInDialog(controller, schedule);
          } else if (controller.isCheckedInForSchedule(schedule) && !controller.hasCheckedOut.value) {
            _showCheckOutConfirmation(controller);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isCurrentSchedule
                ? Border.all(color: AppConstant.primaryColor, width: 2)
                : controller.isCheckedInForSchedule(schedule)
                    ? Border.all(color: AppConstant.successColor, width: 2)
                    : null,
            color: controller.isCheckedInForSchedule(schedule)
                ? AppConstant.successColor.withOpacity(0.05)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrentSchedule 
                          ? AppConstant.primaryColor 
                          : AppConstant.secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        color: isCurrentSchedule ? Colors.white : AppConstant.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isCurrentSchedule) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstant.successColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ] else if (controller.isCheckedInForSchedule(schedule)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: controller.hasCheckedOut.value 
                            ? AppConstant.textSecondary 
                            : AppConstant.successColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.hasCheckedOut.value 
                                ? Icons.check_circle 
                                : Icons.work,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller.hasCheckedOut.value 
                                ? 'COMPLETED' 
                                : 'ACTIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
              if (schedule.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  schedule.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstant.textPrimary.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppConstant.textPrimary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      schedule.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstant.textPrimary.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              // Show contextual action hints
              if (controller.canCheckInForSchedule(schedule)) ...[
                const SizedBox(height: 12),
                const Text(
                  '👆 Tap to check in for this schedule',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else if (controller.isCheckedInForSchedule(schedule) && !controller.hasCheckedOut.value) ...[
                const SizedBox(height: 12),
                const Text(
                  '✅ Currently checked in - Tap to check out',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (controller.isCheckedInForSchedule(schedule) && controller.hasCheckedOut.value) ...[
                const SizedBox(height: 12),
                const Text(
                  '✅ Work completed for this schedule',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppConstant.textPrimary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules for today',
            style: TextStyle(
              fontSize: 18,
              color: AppConstant.textPrimary.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy your free day! 🎉',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textPrimary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckInDialog(UnifiedScheduleController controller, ScheduleModel schedule) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.login, color: AppConstant.primaryColor),
            const SizedBox(width: 8),
            const Text('Check In'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check in for: ${schedule.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${DateFormat('HH:mm').format(schedule.startDateTime)} - ${DateFormat('HH:mm').format(schedule.endDateTime)}',
            ),
            const SizedBox(height: 8),
            Text('Location: ${schedule.location}'),
            const SizedBox(height: 16),
            const Text(
              '📍 Your location will be recorded for attendance tracking.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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

  void _showDatePicker(BuildContext context, UnifiedScheduleController controller) {
    showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstant.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppConstant.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        controller.selectDate(selectedDate);
      }
    });
  }

  void _showCheckOutConfirmation(UnifiedScheduleController controller) {
    final activeSchedule = controller.activeSchedule.value;
    final checkInTime = controller.checkInTime.value;
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstant.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
                color: AppConstant.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Check Out Confirmation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Work Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstant.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstant.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: AppConstant.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Work Session Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (activeSchedule != null) ...[
                      _buildDetailRow(
                        icon: Icons.assignment,
                        label: 'Schedule',
                        value: activeSchedule.title,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Scheduled Time',
                        value: '${DateFormat('HH:mm').format(activeSchedule.startDateTime)} - ${DateFormat('HH:mm').format(activeSchedule.endDateTime)}',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: activeSchedule.location,
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (checkInTime != null) ...[
                      _buildDetailRow(
                        icon: Icons.login,
                        label: 'Checked In',
                        value: DateFormat('MMM d, yyyy - HH:mm').format(checkInTime),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.timer,
                        label: 'Work Duration',
                        value: _formatDuration(DateTime.now().difference(checkInTime)),
                        isHighlighted: true,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Warning/Info Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your location will be recorded for checkout verification.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppConstant.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              controller.checkOut();
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: const Text(
              'Check Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstant.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlighted 
              ? AppConstant.successColor 
              : AppConstant.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstant.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlighted 
                      ? AppConstant.successColor 
                      : AppConstant.textPrimary,
                  fontWeight: isHighlighted 
                      ? FontWeight.bold 
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
