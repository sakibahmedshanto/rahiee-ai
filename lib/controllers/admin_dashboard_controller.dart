import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../models/notification_model.dart';
import '../models/schedule_swap_model.dart';
import '../services/supabase_service.dart';
import '../services/schedule_service.dart';
import '../services/schedule_swap_service.dart';
import '../services/attendance_management_service.dart';
import '../services/realtime_dashboard_service.dart';
import '../services/notification_service.dart';

class AdminDashboardController extends GetxController {
  static AdminDashboardController get to => Get.find();

  // Services
  final SupabaseService _supabaseService = SupabaseService.to;
  final ScheduleService _scheduleService = ScheduleService.to;
  final ScheduleSwapService _swapService = ScheduleSwapService.to;
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;
  final RealtimeDashboardService _dashboardService = RealtimeDashboardService.to;
  final NotificationService _notificationService = NotificationService.to;

  // Observable data
  final RxBool isLoading = false.obs;
  final RxString selectedDateRange = 'Today'.obs;
  final RxString selectedDepartment = 'All'.obs;
  final RxInt selectedTabIndex = 0.obs;

  // Dashboard summary data
  final RxInt totalEmployees = 0.obs;
  final RxInt activeEmployees = 0.obs;
  final RxInt schedulesToday = 0.obs;
  final RxInt checkedInToday = 0.obs;
  final RxInt pendingApprovals = 0.obs;
  final RxInt pendingSwapRequests = 0.obs;
  final RxInt activeCoverageRequests = 0.obs;
  final RxDouble todayAttendanceRate = 0.0.obs;
  final RxDouble monthlyAttendanceRate = 0.0.obs;
  
  // Real-time lists
  final RxList<Map<String, dynamic>> todaySchedules = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> liveAttendance = <Map<String, dynamic>>[].obs;
  final RxList<ScheduleSwapModel> recentSwapRequests = <ScheduleSwapModel>[].obs;
  final RxList<Map<String, dynamic>> criticalAlerts = <Map<String, dynamic>>[].obs;
  
  // Employee performance data
  final RxList<Map<String, dynamic>> employeeMetrics = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> departmentStats = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeDashboard();
    setupRealtimeUpdates();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // Initialize dashboard with initial data load
  Future<void> initializeDashboard() async {
    try {
      isLoading.value = true;
      
      // Load all dashboard data in parallel
      await Future.wait([
        loadDashboardSummary(),
        loadTodaySchedules(),
        loadLiveAttendance(),
        loadRecentSwapRequests(),
        loadEmployeeMetrics(),
        loadDepartmentStats(),
        loadCriticalAlerts(),
      ]);

    } catch (e) {
      print('Error initializing dashboard: $e');
      Get.snackbar(
        'Error',
        'Failed to load dashboard data',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Setup real-time updates
  void setupRealtimeUpdates() {
    // Listen to dashboard service updates
    ever(_dashboardService.dashboardSummary, (summary) {
      updateDashboardSummary(summary);
    });

    ever(_dashboardService.activeSchedules, (schedules) {
      todaySchedules.value = schedules.map((s) => s.toMap()).toList();
    });

    ever(_dashboardService.pendingAttendance, (attendance) {
      liveAttendance.value = attendance;
    });

    ever(_swapService.allSwapRequests, (swaps) {
      recentSwapRequests.value = swaps.take(10).toList();
    });

    ever(_attendanceService.pendingApprovals, (approvals) {
      pendingApprovals.value = approvals.length;
    });

    ever(_notificationService.notifications, (_) {
      loadCriticalAlerts();
    });
  }

  // Load dashboard summary statistics
  Future<void> loadDashboardSummary() async {
    try {
      final summary = await _dashboardService.getDashboardSummary();
      if (summary != null) {
        updateDashboardSummary(summary);
      }
    } catch (e) {
      print('Error loading dashboard summary: $e');
    }
  }

  // Update dashboard summary from data
  void updateDashboardSummary(Map<String, dynamic> summary) {
    totalEmployees.value = summary['total_employees'] ?? 0;
    activeEmployees.value = summary['active_employees'] ?? 0;
    schedulesToday.value = summary['schedules_today'] ?? 0;
    checkedInToday.value = summary['checked_in_today'] ?? 0;
    pendingApprovals.value = summary['pending_approvals'] ?? 0;
    pendingSwapRequests.value = summary['pending_swap_requests'] ?? 0;
    activeCoverageRequests.value = summary['active_coverage_requests'] ?? 0;
    todayAttendanceRate.value = (summary['today_attendance_rate'] ?? 0.0).toDouble();
    monthlyAttendanceRate.value = (summary['monthly_attendance_rate'] ?? 0.0).toDouble();
  }

  // Load today's schedules
  Future<void> loadTodaySchedules() async {
    try {
      await _dashboardService.refreshActiveSchedules();
    } catch (e) {
      print('Error loading today schedules: $e');
    }
  }

  // Load live attendance data
  Future<void> loadLiveAttendance() async {
    try {
      await _dashboardService.refreshLiveAttendance();
    } catch (e) {
      print('Error loading live attendance: $e');
    }
  }

  // Load recent swap requests
  Future<void> loadRecentSwapRequests() async {
    try {
      await _swapService.loadSwapRequests();
    } catch (e) {
      print('Error loading swap requests: $e');
    }
  }

  // Load employee performance metrics
  Future<void> loadEmployeeMetrics() async {
    try {
      final response = await _supabaseService.supabase
          .from('employee_performance_dashboard')
          .select()
          .order('monthly_attendance_rate', ascending: false)
          .limit(20);

      employeeMetrics.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading employee metrics: $e');
    }
  }

  // Load department statistics
  Future<void> loadDepartmentStats() async {
    try {
      final response = await _supabaseService.supabase.rpc('get_department_statistics');
      if (response != null) {
        departmentStats.value = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error loading department stats: $e');
    }
  }

  // Load critical alerts
  Future<void> loadCriticalAlerts() async {
    try {
      final alerts = <Map<String, dynamic>>[];
      
      // Add critical notifications
      final criticalNotifications = _notificationService.criticalNotifications;
      for (var notification in criticalNotifications.take(5)) {
        alerts.add({
          'type': 'notification',
          'priority': 'high',
          'title': notification.title,
          'message': notification.message,
          'time': notification.createdAt,
          'action': 'View Details',
        });
      }

      // Add attendance alerts (late check-ins, missing check-outs)
      final lateCheckIns = liveAttendance.where((att) {
        final checkIn = DateTime.tryParse(att['check_in_time'] ?? '');
        final scheduleStart = DateTime.tryParse(att['schedule_start_time'] ?? '');
        if (checkIn != null && scheduleStart != null) {
          return checkIn.isAfter(scheduleStart.add(const Duration(minutes: 15)));
        }
        return false;
      }).take(3);

      for (var late in lateCheckIns) {
        alerts.add({
          'type': 'attendance',
          'priority': 'medium',
          'title': 'Late Check-In',
          'message': '${late['employee_name']} checked in late',
          'time': DateTime.parse(late['check_in_time']),
          'action': 'Review',
        });
      }

      // Add pending swap alerts
      final urgentSwaps = recentSwapRequests.where((swap) {
        return swap.status == SwapStatus.pending && 
               swap.requestedDate.difference(DateTime.now()).inDays <= 1;
      }).take(3);

      for (var swap in urgentSwaps) {
        alerts.add({
          'type': 'swap',
          'priority': 'high',
          'title': 'Urgent Swap Request',
          'message': 'Schedule swap needed for tomorrow',
          'time': swap.createdAt,
          'action': 'Approve',
        });
      }

      // Sort by priority and time
      alerts.sort((a, b) {
        final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
        final aPriority = priorityOrder[a['priority']] ?? 0;
        final bPriority = priorityOrder[b['priority']] ?? 0;
        
        if (aPriority != bPriority) {
          return bPriority.compareTo(aPriority);
        }
        
        return (b['time'] as DateTime).compareTo(a['time'] as DateTime);
      });

      criticalAlerts.value = alerts.take(10).toList();
    } catch (e) {
      print('Error loading critical alerts: $e');
    }
  }

  // Refresh all dashboard data
  Future<void> refreshDashboard() async {
    await initializeDashboard();
  }

  // Change selected date range
  void changeDateRange(String range) {
    selectedDateRange.value = range;
    // Reload data based on new date range
    loadEmployeeMetrics();
    loadDepartmentStats();
  }

  // Change selected department filter
  void changeDepartment(String department) {
    selectedDepartment.value = department;
    // Reload filtered data
    loadEmployeeMetrics();
    loadTodaySchedules();
  }

  // Change selected tab
  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  // Bulk approve attendance records
  Future<void> bulkApproveAttendance(List<String> attendanceIds) async {
    try {
      isLoading.value = true;
      
      final result = await _attendanceService.bulkUpdateAttendanceStatus(
        attendanceIds: attendanceIds,
        status: 'granted',
        adminNotes: 'Bulk approved from dashboard',
      );

      if (result['success']) {
        Get.snackbar(
          'Success',
          result['message'],
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
        
        // Refresh data
        await loadDashboardSummary();
        await loadLiveAttendance();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve attendance: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Bulk approve swap requests
  Future<void> bulkApproveSwaps(List<String> swapIds) async {
    try {
      isLoading.value = true;
      
      for (String swapId in swapIds) {
        await _swapService.updateSwapRequestStatus(
          swapId, 
          SwapStatus.approved,
          adminNotes: 'Bulk approved from dashboard',
        );
      }

      Get.snackbar(
        'Success',
        '${swapIds.length} swap requests approved',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
      
      // Refresh data
      await loadRecentSwapRequests();
      await loadDashboardSummary();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve swaps: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get attendance rate color based on percentage
  Color getAttendanceRateColor(double rate) {
    if (rate >= 95) return Colors.green;
    if (rate >= 85) return Colors.orange;
    return Colors.red;
  }

  // Get status color for various statuses
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'granted':
      case 'approved':
      case 'checked_in':
        return Colors.green;
      case 'late':
      case 'pending':
      case 'requested':
        return Colors.orange;
      case 'absent':
      case 'rejected':
      case 'not_granted':
        return Colors.red;
      case 'checked_out':
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Format duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "${hours}h ${minutes}m";
  }

  // Format attendance rate
  String formatAttendanceRate(double rate) {
    return '${rate.toStringAsFixed(1)}%';
  }

  // Convenience getters for UI
  bool get hasActiveEmployees => activeEmployees.value > 0;
  bool get hasSchedulesToday => schedulesToday.value > 0;
  bool get hasPendingItems => pendingApprovals.value > 0 || pendingSwapRequests.value > 0;
  bool get hasAlerts => criticalAlerts.isNotEmpty;
  
  String get attendanceRateStatus {
    if (todayAttendanceRate.value >= 95) return 'Excellent';
    if (todayAttendanceRate.value >= 85) return 'Good';
    if (todayAttendanceRate.value >= 75) return 'Fair';
    return 'Needs Attention';
  }

  int get totalPendingActions => pendingApprovals.value + pendingSwapRequests.value + activeCoverageRequests.value;
}
