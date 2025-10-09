import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../../../../controllers/admin_controllers/admin_controller.dart';
import '../../../../../utils/app_constant.dart';

class AttendanceSummaryTab extends StatelessWidget {
  final AdminController controller;

  const AttendanceSummaryTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isSummaryLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            color: AppConstant.primaryColor,
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadSummaryData(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Quick Stats Row
              _buildQuickStatsRow(),
              SizedBox(height: 24),
          
          // Charts Section
          Column(
            children: [
              // Attendance Status Pie Chart
              _buildAttendanceStatusChart(),
              SizedBox(height: 16),
              
              // Department Breakdown
              _buildDepartmentChart(),
            ],
          ),
          SizedBox(height: 24),
          
          // Time Analytics
          _buildTimeAnalytics(),
          SizedBox(height: 16),
          
          // Weekly Trend
          _buildWeeklyTrendChart(),
          SizedBox(height: 16),
          
          // Recent Activity
          _buildRecentActivity(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQuickStatsRow() {
    final todayData = controller.todayData;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Today\'s Check-ins',
                value: '${todayData['total_present'] ?? 0}',
                icon: Icons.login,
                color: Colors.green,
                trend: controller.getCheckInsTrend(),
                trendUp: controller.getCheckInsTrend().startsWith('+'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Approvals',
                value: '${todayData['pending_approvals'] ?? 0}',
                icon: Icons.pending_actions,
                color: Colors.orange,
                trend: controller.getPendingTrend(),
                trendUp: controller.getPendingTrend().startsWith('+'),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Late Arrivals',
                value: '${todayData['total_late'] ?? 0}',
                icon: Icons.access_time,
                color: Colors.red,
                trend: controller.getLateTrend(),
                trendUp: controller.getLateTrend().startsWith('+'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Active Sessions',
                value: '${todayData['currently_active'] ?? 0}',
                icon: Icons.person_outline,
                color: Colors.blue,
                trend: 'Live',
                trendUp: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (trendUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 10,
                      color: trendUp ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppConstant.textPrimary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatusChart() {
    final todayData = controller.todayData;
    
    // Calculate real percentages from data
    final totalPresent = (todayData['total_present'] ?? 0) as int;
    final totalPending = (todayData['pending_approvals'] ?? 0) as int;
    final totalAbsent = (todayData['total_absent'] ?? 0) as int;
    final totalLate = (todayData['total_late'] ?? 0) as int;
    
    final total = totalPresent + totalPending + totalAbsent + totalLate;
    
    if (total == 0) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Attendance Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
            SizedBox(height: 40),
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No attendance data today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final presentPercentage = (totalPresent / total * 100);
    final pendingPercentage = (totalPending / total * 100);
    final absentPercentage = (totalAbsent / total * 100);
    final latePercentage = (totalLate / total * 100);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  if (presentPercentage > 0)
                    PieChartSectionData(
                      value: presentPercentage,
                      title: '${presentPercentage.toStringAsFixed(0)}%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (pendingPercentage > 0)
                    PieChartSectionData(
                      value: pendingPercentage,
                      title: '${pendingPercentage.toStringAsFixed(0)}%',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (absentPercentage > 0)
                    PieChartSectionData(
                      value: absentPercentage,
                      title: '${absentPercentage.toStringAsFixed(0)}%',
                      color: Colors.red,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (latePercentage > 0)
                    PieChartSectionData(
                      value: latePercentage,
                      title: '${latePercentage.toStringAsFixed(0)}%',
                      color: Colors.grey,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildLegend(presentPercentage, pendingPercentage, absentPercentage, latePercentage),
        ],
      ),
    );
  }

  Widget _buildLegend(double present, double pending, double absent, double late) {
    return Column(
      children: [
        if (present > 0) _buildLegendItem('Present', Colors.green, '${present.toStringAsFixed(1)}%'),
        if (pending > 0) _buildLegendItem('Pending', Colors.orange, '${pending.toStringAsFixed(1)}%'),
        if (absent > 0) _buildLegendItem('Absent', Colors.red, '${absent.toStringAsFixed(1)}%'),
        if (late > 0) _buildLegendItem('Late', Colors.grey, '${late.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.textPrimary,
            ),
          ),
          Spacer(),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstant.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChart() {
    final departmentData = controller.departmentData;
    
    if (departmentData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Department Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstant.textPrimary,
              ),
            ),
            SizedBox(height: 40),
            Icon(
              Icons.business_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No department data available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 20),
          ...departmentData.map((dept) {
            final stats = dept['stats'] as Map<String, dynamic>? ?? {};
            final attendanceRate = (stats['attendance_rate'] ?? 0.0) as double;
            final departmentName = dept['department'] as String;
            
            // Assign colors based on department name
            Color color = Colors.blue;
            switch (departmentName.toLowerCase()) {
              case 'engineering':
                color = Colors.blue;
                break;
              case 'marketing':
                color = Colors.purple;
                break;
              case 'sales':
                color = Colors.green;
                break;
              case 'hr':
                color = Colors.orange;
                break;
              case 'finance':
                color = Colors.red;
                break;
              default:
                color = Colors.blue;
            }
            
            return _buildDepartmentBar(departmentName, attendanceRate, color);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDepartmentBar(String department, double percentage, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                department,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstant.textPrimary,
                ),
              ),
              Spacer(),
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAnalytics() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTimeMetric('Avg. Check-in', controller.avgCheckInTime, Icons.login, Colors.green)),
                  SizedBox(width: 8),
                  Expanded(child: _buildTimeMetric('Avg. Check-out', controller.avgCheckOutTime, Icons.logout, Colors.blue)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTimeMetric('Avg. Working Hrs', controller.avgWorkingHours, Icons.schedule, Colors.purple)),
                  SizedBox(width: 8),
                  Expanded(child: _buildTimeMetric('Peak Hours', controller.peakHours, Icons.trending_up, Colors.orange)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: AppConstant.textPrimary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weekly Attendance Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstant.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: controller.weeklyTrendDirection == 'up' 
                          ? Colors.green.withOpacity(0.1)
                          : controller.weeklyTrendDirection == 'down'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.weeklyTrendDirection == 'up'
                              ? Icons.trending_up
                              : controller.weeklyTrendDirection == 'down'
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 10,
                          color: controller.weeklyTrendDirection == 'up'
                              ? Colors.green
                              : controller.weeklyTrendDirection == 'down'
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${controller.currentWeekAvgAttendance.toStringAsFixed(1)}% avg',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: controller.weeklyTrendDirection == 'up'
                                ? Colors.green
                                : controller.weeklyTrendDirection == 'down'
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Last 7 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstant.textPrimary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        );
                        String text = '';
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mon';
                            break;
                          case 1:
                            text = 'Tue';
                            break;
                          case 2:
                            text = 'Wed';
                            break;
                          case 3:
                            text = 'Thu';
                            break;
                          case 4:
                            text = 'Fri';
                            break;
                          case 5:
                            text = 'Sat';
                            break;
                          case 6:
                            text = 'Sun';
                            break;
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: controller.weeklyAttendanceData.isEmpty 
                        ? [
                            FlSpot(0, 0),
                            FlSpot(1, 0),
                            FlSpot(2, 0),
                            FlSpot(3, 0),
                            FlSpot(4, 0),
                            FlSpot(5, 0),
                            FlSpot(6, 0),
                          ]
                        : controller.weeklyAttendanceData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value);
                          }).toList(),
                    isCurved: true,
                    color: AppConstant.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstant.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstant.textPrimary,
            ),
          ),
          SizedBox(height: 20),
          if (controller.recentActivity.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...controller.recentActivity.map((activity) => _buildActivityItem(
              activity['title'] as String,
              activity['time'] as String,
              activity['icon'] as IconData,
              activity['color'] as Color,
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstant.textPrimary,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstant.textPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
