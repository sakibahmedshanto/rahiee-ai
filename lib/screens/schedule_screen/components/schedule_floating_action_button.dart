// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_constant.dart';

class ScheduleFloatingActionButton extends StatelessWidget {
  const ScheduleFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showCreateScheduleOptions(context),
      backgroundColor: AppConstant.primaryColor,
      child: Icon(
        Icons.add,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showCreateScheduleOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Create New Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstant.appTextColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstant.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_add,
                  color: AppConstant.primaryColor,
                ),
              ),
              title: const Text('Single Employee'),
              subtitle: const Text('Create schedule for one employee'),
              onTap: () {
                Navigator.pop(context);
                _createSingleSchedule(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstant.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.group_add,
                  color: AppConstant.primaryColor,
                ),
              ),
              title: const Text('Multiple Employees'),
              subtitle: const Text('Create schedules for multiple employees'),
              onTap: () {
                Navigator.pop(context);
                _createBulkSchedule(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstant.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.copy,
                  color: AppConstant.primaryColor,
                ),
              ),
              title: const Text('Copy from Previous'),
              subtitle: const Text('Copy schedules from another date'),
              onTap: () {
                Navigator.pop(context);
                _copyFromPrevious(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstant.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppConstant.primaryColor,
                ),
              ),
              title: const Text('Auto Generate'),
              subtitle: const Text('Generate schedules based on templates'),
              onTap: () {
                Navigator.pop(context);
                _autoGenerateSchedule(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createSingleSchedule(BuildContext context) {
    // TODO: Navigate to create single schedule screen
    Get.snackbar(
      'Coming Soon',
      'Single employee schedule creation coming soon',
      backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
      colorText: AppConstant.primaryColor,
    );
  }

  void _createBulkSchedule(BuildContext context) {
    // TODO: Navigate to create bulk schedule screen
    Get.snackbar(
      'Coming Soon',
      'Bulk schedule creation coming soon',
      backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
      colorText: AppConstant.primaryColor,
    );
  }

  void _copyFromPrevious(BuildContext context) {
    // TODO: Implement copy from previous functionality
    Get.snackbar(
      'Coming Soon',
      'Copy from previous date coming soon',
      backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
      colorText: AppConstant.primaryColor,
    );
  }

  void _autoGenerateSchedule(BuildContext context) {
    // TODO: Implement auto generate functionality
    Get.snackbar(
      'Coming Soon',
      'Auto generate schedules coming soon',
      backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
      colorText: AppConstant.primaryColor,
    );
  }
}
