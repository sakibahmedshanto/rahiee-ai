// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_constant.dart';
import '../../../controllers/schedule_controller.dart';

class ScheduleDatePicker extends StatelessWidget {
  const ScheduleDatePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleController = Get.find<ScheduleController>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous day button
          GestureDetector(
            onTap: scheduleController.previousDay,
            child: Container(
              padding: const EdgeInsets.all(8),
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
                onTap: () => _showDatePicker(context, scheduleController),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstant.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstant.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
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
                        scheduleController.formattedDate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstant.primaryColor,
                        ),
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ),
          
          // Next day button
          GestureDetector(
            onTap: scheduleController.nextDay,
            child: Container(
              padding: const EdgeInsets.all(8),
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

  void _showDatePicker(BuildContext context, ScheduleController controller) {
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
              surface: Colors.white,
              onSurface: AppConstant.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        controller.changeDate(selectedDate);
      }
    });
  }
}
