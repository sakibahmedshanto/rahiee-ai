// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_constant.dart';
import '../../controllers/schedule_controller/schedule_controller.dart';
import 'components/schedule_header.dart';
import 'components/schedule_date_picker.dart';
import 'components/role_section.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleController = Get.put(ScheduleController());
    
    return Column(
      children: [
        // Header with Schedule title and filter
         ScheduleHeader(),
        
        // Date picker section
        ScheduleDatePicker(),
        
        // Schedules list
        Expanded(
          child: Obx(() {
            if (scheduleController.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppConstant.primaryColor,
                ),
              );
            }
            
            // Get current schedules based on view
            final currentSchedules = scheduleController.currentView.value == 'role' 
                ? scheduleController.schedulesByRole 
                : scheduleController.schedulesByDepartment;
            
            if (currentSchedules.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 64,
                      color: AppConstant.primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No schedules for this date',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppConstant.appTextColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: currentSchedules.length,
              itemBuilder: (context, index) {
                final category = currentSchedules.keys.elementAt(index);
                final schedules = currentSchedules[category]!;
                
                return RoleSection(
                  role: category, // This will now show either role or department
                  schedules: schedules,
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
