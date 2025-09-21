import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../controllers/admin_controllers/admin_schedule_controller.dart';
import '../../../../utils/app_constant.dart';
import 'components/schedule_create_tab.dart';
import 'components/schedule_table_tab.dart';

class AdminSchedulesTab extends StatefulWidget {
  const AdminSchedulesTab({super.key});

  @override
  State<AdminSchedulesTab> createState() => _AdminSchedulesTabState();
}

class _AdminSchedulesTabState extends State<AdminSchedulesTab> {
  late AdminController adminController;
  late AdminScheduleController scheduleController;

  @override
  void initState() {
    super.initState();
    adminController = Get.find<AdminController>();
    scheduleController = Get.put(AdminScheduleController());
  }

  @override
  Widget build(BuildContext context) {

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
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 6),
                        Text('Create'),
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
                  ScheduleCreateTab(
                    adminController: adminController,
                    scheduleController: scheduleController,
                  ),
                  ScheduleTableTab(
                    adminController: adminController,
                    scheduleController: scheduleController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
