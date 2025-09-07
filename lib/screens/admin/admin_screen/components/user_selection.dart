// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/app_constant.dart';
import '../../../../controllers/admin_controller/admin_controller.dart';

class UserSelection extends StatelessWidget {
  const UserSelection({super.key});

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
          // Header
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppConstant.primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Assign Employees',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
              Spacer(),
              Obx(() => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstant.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${adminController.selectedUsers.length} selected',
                  style: TextStyle(
                    color: AppConstant.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Department Filter
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppConstant.borderColor),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppConstant.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Text(
                    'Filter by Department:',
                    style: TextStyle(
                      color: AppConstant.textSecondary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Obx(() => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: adminController.userFilterDepartment.value,
                      icon: Icon(Icons.arrow_drop_down, color: AppConstant.primaryColor),
                      style: TextStyle(
                        color: AppConstant.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          adminController.setUserFilterDepartment(newValue);
                        }
                      },
                      items: ['All', ...adminController.departments]
                          .map<DropdownMenuItem<String>>((String department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(
                            department,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  )),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Loading State
          Obx(() {
            if (adminController.isLoadingUsers.value) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstant.primaryColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading employees...',
                        style: TextStyle(
                          color: AppConstant.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Filter users based on department
            final filteredUsers = adminController.userFilterDepartment.value == 'All'
                ? adminController.allUsers
                : adminController.allUsers.where((user) => 
                    user.department == adminController.userFilterDepartment.value).toList();
            
            if (filteredUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: AppConstant.textSecondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        adminController.userFilterDepartment.value == 'All' 
                          ? 'No employees found'
                          : 'No employees in ${adminController.userFilterDepartment.value}',
                        style: TextStyle(
                          color: AppConstant.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try selecting a different department or contact admin',
                        style: TextStyle(
                          color: AppConstant.textSecondary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // User List
            return Container(
              constraints: BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: filteredUsers.map((user) {
                    final isSelected = adminController.selectedUsers.contains(user);
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppConstant.primaryColor : AppConstant.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? AppConstant.primaryColor.withOpacity(0.05) : Colors.white,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isSelected 
                            ? AppConstant.primaryColor 
                            : AppConstant.primaryColor.withOpacity(0.1),
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppConstant.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppConstant.textPrimary,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.email.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: AppConstant.textSecondary,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getDepartmentColor(user.department).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.department,
                                      style: TextStyle(
                                        color: _getDepartmentColor(user.department),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (user.position.isNotEmpty) ...[
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '• ${user.position}',
                                      style: TextStyle(
                                        color: AppConstant.textSecondary,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppConstant.primaryColor,
                              size: 24,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: AppConstant.borderColor,
                              size: 24,
                            ),
                        onTap: () {
                          adminController.toggleUserSelectionById(user.uId);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          
          SizedBox(height: 16),
          
          // Bulk Actions
          Obx(() {
            if (adminController.allUsers.isNotEmpty) {
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final filteredUsers = adminController.userFilterDepartment.value == 'All'
                            ? adminController.allUsers
                            : adminController.allUsers.where((user) => 
                                user.department == adminController.userFilterDepartment.value).toList();
                        adminController.selectAllUsers(filteredUsers);
                      },
                      icon: Icon(
                        Icons.select_all,
                        size: 18,
                        color: AppConstant.primaryColor,
                      ),
                      label: Text(
                        'Select All',
                        style: TextStyle(
                          color: AppConstant.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppConstant.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        adminController.clearUserSelection();
                      },
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: AppConstant.textSecondary,
                      ),
                      label: Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppConstant.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppConstant.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Restaurant':
        return Colors.orange;
      case 'Kitchen':
        return Colors.red;
      case 'Management':
        return Colors.blue;
      case 'Cleaning':
        return Colors.green;
      case 'Security':
        return Colors.purple;
      case 'Maintenance':
        return Colors.brown;
      default:
        return AppConstant.primaryColor;
    }
  }
}
