// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';

class EmployeeSearchBar extends StatelessWidget {
  const EmployeeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Container(
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
      ),
      child: TextField(
        onChanged: (value) {
          controller.employeeSearchQuery.value = value;
          controller.filterEmployees();
        },
        decoration: InputDecoration(
          hintText: 'Search employees by name, ID, or email...',
          hintStyle: TextStyle(color: AppConstant.textSecondary),
          prefixIcon: Icon(
            Icons.search,
            color: AppConstant.textSecondary,
          ),
          suffixIcon: Obx(() => controller.employeeSearchQuery.value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppConstant.textSecondary),
                  onPressed: () {
                    controller.employeeSearchQuery.value = '';
                    controller.filterEmployees();
                  },
                )
              : SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
