import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../utils/app_constant.dart';
import 'components/attendance_summary_tab.dart';
import 'components/attendance_table_tab.dart';

class EnhancedAdminAttendanceTab extends StatelessWidget {
  const EnhancedAdminAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Custom Tab Bar
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                physics: NeverScrollableScrollPhysics(), // Disable tab scrolling
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppConstant.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstant.primaryColor.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                indicatorPadding: EdgeInsets.all(2),
                tabs: [
                  Tab(
                    height: 45,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 20),
                        SizedBox(width: 6),
                        Text('Summary'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 45,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_chart_outlined, size: 20),
                        SizedBox(width: 6),
                        Text('Table'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(), // Disable tab view scrolling
                children: [
                  AttendanceSummaryTab(controller: controller),
                  AttendanceTableTab(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
