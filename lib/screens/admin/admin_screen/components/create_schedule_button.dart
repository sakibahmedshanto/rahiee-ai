// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/app_constant.dart';
import '../../../../controllers/admin_controller/admin_controller.dart';

class CreateScheduleButton extends StatelessWidget {
  const CreateScheduleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      child: Obx(() => ElevatedButton(
        onPressed: adminController.isLoading.value 
          ? null 
          : () async {
              await adminController.createSchedule();
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstant.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: adminController.isLoading.value
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Creating Schedule...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_task,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Create Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
      )),
    );
  }
}
