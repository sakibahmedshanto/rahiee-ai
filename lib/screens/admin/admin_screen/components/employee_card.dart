// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../models/user_model.dart';
import '../../../../utils/app_constant.dart';

class EmployeeCard extends StatelessWidget {
  final UserModel employee;

  const EmployeeCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstant.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstant.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppConstant.shadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEmployeeDetails(context),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile picture or avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
                backgroundImage: employee.userImg != null
                    ? NetworkImage(employee.userImg!)
                    : null,
                child: employee.userImg == null
                    ? Text(
                        employee.fullName.isNotEmpty
                            ? employee.fullName[0].toUpperCase()
                            : 'E',
                        style: TextStyle(
                          color: AppConstant.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              
              SizedBox(width: 16),
              
              // Employee info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppConstant.textPrimary,
                            ),
                          ),
                        ),
                        _buildStatusBadge(),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ID: ${employee.employeeId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstant.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 14,
                          color: AppConstant.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          employee.department,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppConstant.textSecondary,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.work_outline,
                          size: 14,
                          color: AppConstant.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            employee.position,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppConstant.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: AppConstant.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            employee.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstant.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppConstant.textSecondary),
                onSelected: (value) => _handleAction(context, value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Employee'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'attendance',
                    child: Row(
                      children: [
                        Icon(Icons.schedule_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('View Attendance'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: employee.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          employee.isActive ? Icons.block : Icons.check_circle_outlined,
                          size: 16,
                          color: employee.isActive ? AppConstant.errorColor : AppConstant.successColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          employee.isActive ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            color: employee.isActive ? AppConstant.errorColor : AppConstant.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: employee.isActive 
            ? AppConstant.successColor.withOpacity(0.1)
            : AppConstant.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        employee.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: employee.isActive 
              ? AppConstant.successColor
              : AppConstant.errorColor,
        ),
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEmployeeDetailsSheet(context),
    );
  }

  Widget _buildEmployeeDetailsSheet(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppConstant.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstant.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConstant.primaryColor.withOpacity(0.1),
                  backgroundImage: employee.userImg != null
                      ? NetworkImage(employee.userImg!)
                      : null,
                  child: employee.userImg == null
                      ? Text(
                          employee.fullName.isNotEmpty
                              ? employee.fullName[0].toUpperCase()
                              : 'E',
                          style: TextStyle(
                            color: AppConstant.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstant.textPrimary,
                        ),
                      ),
                      Text(
                        employee.position,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstant.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Employee details
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Personal Information', [
                    _buildDetailRow('Employee ID', employee.employeeId),
                    _buildDetailRow('Email', employee.email),
                    _buildDetailRow('Phone', employee.phone),
                    if (employee.emergencyContact != null)
                      _buildDetailRow('Emergency Contact', employee.emergencyContact!),
                    if (employee.emergencyPhone != null)
                      _buildDetailRow('Emergency Phone', employee.emergencyPhone!),
                  ]),
                  
                  SizedBox(height: 24),
                  
                  _buildDetailSection('Work Information', [
                    _buildDetailRow('Department', employee.department),
                    _buildDetailRow('Position', employee.position),
                    _buildDetailRow('Role', employee.userRole),
                    if (employee.workLocation != null)
                      _buildDetailRow('Work Location', employee.workLocation!),
                    if (employee.shiftType != null)
                      _buildDetailRow('Shift Type', employee.shiftType!),
                    if (employee.salaryRate != null)
                      _buildDetailRow('Salary Rate', '\$${employee.salaryRate!.toStringAsFixed(2)}/hr'),
                  ]),
                  
                  SizedBox(height: 24),
                  
                  _buildDetailSection('Statistics', [
                    if (employee.attendanceRate != null)
                      _buildDetailRow('Attendance Rate', '${employee.attendanceRate!.toStringAsFixed(1)}%'),
                    if (employee.totalCoverageGiven != null)
                      _buildDetailRow('Coverage Given', '${employee.totalCoverageGiven} times'),
                    if (employee.totalCoverageReceived != null)
                      _buildDetailRow('Coverage Received', '${employee.totalCoverageReceived} times'),
                    if (employee.leaveBalance != null)
                      _buildDetailRow('Leave Balance', '${employee.leaveBalance} days'),
                  ]),
                  
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstant.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstant.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstant.borderColor),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppConstant.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppConstant.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'view':
        _showEmployeeDetails(context);
        break;
      case 'edit':
        // Navigate to edit employee screen
        Get.snackbar('Info', 'Edit employee functionality coming soon');
        break;
      case 'attendance':
        // Navigate to employee attendance
        Get.snackbar('Info', 'Employee attendance view coming soon');
        break;
      case 'activate':
      case 'deactivate':
        _confirmStatusChange(context, action == 'activate');
        break;
    }
  }

  void _confirmStatusChange(BuildContext context, bool activate) {
    Get.dialog(
      AlertDialog(
        title: Text(activate ? 'Activate Employee' : 'Deactivate Employee'),
        content: Text(
          'Are you sure you want to ${activate ? 'activate' : 'deactivate'} ${employee.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Handle status change
              Get.snackbar(
                'Success',
                '${employee.fullName} has been ${activate ? 'activated' : 'deactivated'}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: activate ? AppConstant.successColor : AppConstant.errorColor,
            ),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }
}
