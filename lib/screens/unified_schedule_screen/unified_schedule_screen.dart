import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/unified_schedule_controller.dart';
import '../../utils/app_constant.dart';
import 'components/schedule_calendar_widget.dart';
import 'components/attendance_status_card.dart';
import 'components/schedule_list_widget.dart';
import 'components/quick_actions_widget.dart';

class UnifiedScheduleScreen extends StatelessWidget {
  const UnifiedScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UnifiedScheduleController());
    
    return Scaffold(
      backgroundColor: AppConstant.backgroundColor,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppConstant.primaryColor,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: AppConstant.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'My Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppConstant.primaryColor,
                        AppConstant.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Obx(() => IconButton(
                  onPressed: controller.refreshData,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                )),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Attendance Status
                    const AttendanceStatusCard(),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Actions (Check In/Out)
                    const QuickActionsWidget(),
                    
                    const SizedBox(height: 20),
                    
                    // Calendar Widget
                    const ScheduleCalendarWidget(),
                    
                    const SizedBox(height: 20),
                    
                    // Schedules List
                    Text(
                      'Today\'s Schedules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstant.appTextColor,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const ScheduleListWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
