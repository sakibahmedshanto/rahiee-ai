// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';
import '../components/employee_search_bar.dart';
import '../components/employee_card.dart';

class AdminEmployeesTab extends StatelessWidget {
  const AdminEmployeesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filters
          EmployeeSearchBar(),
          
          SizedBox(height: 16),
          
          // Department filter chips
          _buildDepartmentFilters(controller),
          
          SizedBox(height: 16),
          
          // Employee count and sort
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.filteredEmployees.length} employees',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.sort, color: AppConstant.textSecondary),
                onSelected: (value) {
                  // Handle sorting
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                  PopupMenuItem(value: 'department', child: Text('Sort by Department')),
                  PopupMenuItem(value: 'role', child: Text('Sort by Role')),
                  PopupMenuItem(value: 'status', child: Text('Sort by Status')),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Employee list
          Expanded(
            child: controller.filteredEmployees.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => controller.loadAllEmployees(),
                    child: ListView.builder(
                      itemCount: controller.filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = controller.filteredEmployees[index];
                        return EmployeeCard(employee: employee);
                      },
                    ),
                  ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDepartmentFilters(AdminController controller) {
    return Obx(() => SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.departments.length,
        itemBuilder: (context, index) {
          final department = controller.departments[index];
          final isSelected = controller.selectedDepartment.value == department;
          
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(department),
              selected: isSelected,
              onSelected: (selected) {
                controller.selectedDepartment.value = department;
                controller.filterEmployees();
              },
              backgroundColor: AppConstant.cardColor,
              selectedColor: AppConstant.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppConstant.primaryColor : AppConstant.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppConstant.primaryColor : AppConstant.borderColor,
              ),
            ),
          );
        },
      ),
    ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppConstant.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No employees found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: AppConstant.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
