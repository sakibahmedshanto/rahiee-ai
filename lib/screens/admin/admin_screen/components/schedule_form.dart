// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/app_constant.dart';
import '../../../../controllers/admin_controller/admin_controller.dart';

class ScheduleForm extends StatelessWidget {
  const ScheduleForm({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          _buildTextField(
            controller: adminController.titleController,
            label: 'Schedule Title',
            hint: 'e.g., Morning Shift, Evening Service',
            icon: Icons.title,
          ),
          
          SizedBox(height: 16),
          
          // Description Field
          _buildTextField(
            controller: adminController.descriptionController,
            label: 'Description',
            hint: 'Describe the schedule details',
            icon: Icons.description,
            maxLines: 3,
          ),
          
          SizedBox(height: 16),
          
          // Location Field
          _buildTextField(
            controller: adminController.locationController,
            label: 'Location',
            hint: 'e.g., Main Bar, Kitchen, Dining Area',
            icon: Icons.location_on,
          ),
          
          SizedBox(height: 16),
          
          // Department Dropdown
          Text(
            'Department',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Obx(() => Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppConstant.borderColor),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: adminController.selectedDepartment.value,
                icon: Icon(Icons.arrow_drop_down, color: AppConstant.primaryColor),
                isExpanded: true,
                style: TextStyle(
                  color: AppConstant.textPrimary,
                  fontSize: 16,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    adminController.setDepartment(newValue);
                  }
                },
                items: adminController.departments
                    .map<DropdownMenuItem<String>>((String department) {
                  return DropdownMenuItem<String>(
                    value: department,
                    child: Row(
                      children: [
                        Icon(
                          _getDepartmentIcon(department),
                          size: 20,
                          color: AppConstant.primaryColor,
                        ),
                        SizedBox(width: 12),
                        Text(department),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          )),
          
          SizedBox(height: 16),
          
          // Date Selection
          Text(
            'Schedule Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Obx(() => InkWell(
            onTap: () => _selectDate(context, adminController),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppConstant.borderColor),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppConstant.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    adminController.formattedDate,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstant.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppConstant.primaryColor,
                  ),
                ],
              ),
            ),
          )),
          
          SizedBox(height: 16),
          
          // Time Selection Row
          Row(
            children: [
              // Start Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() => InkWell(
                      onTap: () => _selectStartTime(context, adminController),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppConstant.borderColor),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppConstant.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              adminController.formatTime(adminController.selectedStartTime.value),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppConstant.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              
              SizedBox(width: 16),
              
              // End Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() => InkWell(
                      onTap: () => _selectEndTime(context, adminController),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppConstant.borderColor),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppConstant.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              adminController.formatTime(adminController.selectedEndTime.value),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppConstant.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Notes Field
          _buildTextField(
            controller: adminController.notesController,
            label: 'Additional Notes (Optional)',
            hint: 'Any special instructions or notes',
            icon: Icons.note,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: AppConstant.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppConstant.textSecondary.withOpacity(0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppConstant.primaryColor,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstant.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstant.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstant.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  IconData _getDepartmentIcon(String department) {
    switch (department) {
      case 'Restaurant':
        return Icons.restaurant;
      case 'Kitchen':
        return Icons.kitchen;
      case 'Management':
        return Icons.business;
      case 'Cleaning':
        return Icons.cleaning_services;
      case 'Security':
        return Icons.security;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.work;
    }
  }

  Future<void> _selectDate(BuildContext context, AdminController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
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
    );
    
    if (picked != null && picked != controller.selectedDate.value) {
      controller.setSelectedDate(picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context, AdminController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: controller.selectedStartTime.value,
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
    );
    
    if (picked != null && picked != controller.selectedStartTime.value) {
      controller.setStartTime(picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context, AdminController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: controller.selectedEndTime.value,
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
    );
    
    if (picked != null && picked != controller.selectedEndTime.value) {
      controller.setEndTime(picked);
    }
  }
}
