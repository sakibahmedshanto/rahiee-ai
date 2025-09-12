import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../controllers/admin_controllers/admin_controller.dart';
import 'components/admin_attendance_header.dart';
import 'components/admin_attendance_stats.dart';
import 'components/admin_attendance_filters.dart';
import 'components/admin_attendance_table.dart';

class AdminAttendanceTab extends StatelessWidget {
  const AdminAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Obx(() => Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons header (without title duplication)
            AdminAttendanceHeader(controller: controller),
            const SizedBox(height: 20),
            
            // Quick statistics overview
            AdminAttendanceStats(controller: controller),
            const SizedBox(height: 20),
            
            // Date and status filter chips
            AdminAttendanceFilters(controller: controller),
            const SizedBox(height: 20),
            
            // Main data table
            Expanded(
              child: controller.isLoading.value
                  ? _buildLoadingState()
                  : AdminAttendanceTable(controller: controller),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading attendance data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
