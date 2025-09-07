// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/app_constant.dart';
import '../../../../controllers/admin_controller/admin_controller.dart';

class AdminStatsWidget extends StatelessWidget {
  const AdminStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstant.primaryColor.withOpacity(0.1),
            AppConstant.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
                Icons.analytics_outlined,
                color: AppConstant.primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              // Total Employees
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_outline,
                  title: 'Total Employees',
                  value: adminController.allUsers.length.toString(),
                  color: Colors.blue,
                ),
              ),
              
              SizedBox(width: 12),
              
              // Selected for Schedule
              Expanded(
                child: Obx(() => _buildStatCard(
                  icon: Icons.schedule,
                  title: 'Selected',
                  value: adminController.selectedUsers.length.toString(),
                  color: AppConstant.primaryColor,
                )),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              // Departments Count
              Expanded(
                child: _buildStatCard(
                  icon: Icons.business_outlined,
                  title: 'Departments',
                  value: adminController.departments.length.toString(),
                  color: Colors.orange,
                ),
              ),
              
              SizedBox(width: 12),
              
              // Current Filter
              Expanded(
                child: Obx(() => _buildStatCard(
                  icon: Icons.filter_list,
                  title: 'Filter',
                  value: adminController.userFilterDepartment.value,
                  color: Colors.green,
                  isText: true,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isText = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              Spacer(),
              if (!isText)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppConstant.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isText) ...[
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
