import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/schedule_swap_model.dart';
import '../services/supabase_service.dart';
import '../services/schedule_swap_service.dart';
import '../services/attendance_management_service.dart';
import '../services/notification_service.dart';

class AdminDashboardController extends GetxController {
  static AdminDashboardController get to => Get.find();

  // Services
  final SupabaseService _supabaseService = SupabaseService.to;
  final ScheduleSwapService _swapService = ScheduleSwapService.to;
  final AttendanceManagementService _attendanceService = AttendanceManagementService.to;
  final NotificationService _notificationService = NotificationService.to;

  // Observable data
  final RxBool isLoading = false.obs;
  final RxBool isLoadingDashboard = false.obs;
  final RxString loadingMessage = ''.obs;
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

  // Initialize dashboard with initial data load
  Future<void> initializeDashboard() async {
    try {
      isLoadingDashboard.value = true;
      loadingMessage.value = 'Loading dashboard data...';
      
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
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoadingDashboard.value = false;
      loadingMessage.value = '';
    }
  }

  // Setup real-time updates
  void setupRealtimeUpdates() {
    // Listen to service updates
    ever(_swapService.allSwapRequests, (swaps) {
      recentSwapRequests.value = swaps.take(10).toList();
      pendingSwapRequests.value = swaps.where((s) => s.isPending).length;
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
      loadingMessage.value = 'Loading summary statistics...';
      
      // Get current data from database
      final supabase = _supabaseService.currentUser != null ? 
          _supabaseService.client : null;
      
      if (supabase == null) return;

      // Get total employees
      final employeesResponse = await supabase
          .from('my_users')
          .select('id')
          .eq('user_role', 'employee');
      totalEmployees.value = employeesResponse.length;

      // Get today's schedules
      final today = DateTime.now().toIso8601String().split('T')[0];
      final schedulesResponse = await supabase
          .from('employee_schedules')
          .select('id')
          .gte('start_date_time', today)
          .lt('start_date_time', '${today}T23:59:59.999Z');
      schedulesToday.value = schedulesResponse.length;

      // Get today's attendance
      final attendanceResponse = await supabase
          .from('attendance')
          .select('id, check_in_time, check_out_time')
          .eq('date', today);
      
      final attendanceList = attendanceResponse as List;
      checkedInToday.value = attendanceList.where((a) => a['check_in_time'] != null).length;
      
      if (schedulesToday.value > 0) {
        todayAttendanceRate.value = (checkedInToday.value / schedulesToday.value * 100);
      }

    } catch (e) {
      print('Error loading dashboard summary: $e');
    }
  }

  // Load today's schedules
  Future<void> loadTodaySchedules() async {
    try {
      loadingMessage.value = 'Loading today\'s schedules...';
      final supabase = _supabaseService.client;
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final response = await supabase
          .from('employee_schedules')
          .select('''
            *, 
            employee:my_users!assigned_user_id(full_name, employee_id),
            attendance!left(check_in_time, check_out_time, status)
          ''')
          .gte('start_date_time', today)
          .lt('start_date_time', '${today}T23:59:59.999Z')
          .order('start_date_time');

      todaySchedules.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading today schedules: $e');
    }
  }

  // Load live attendance data
  Future<void> loadLiveAttendance() async {
    try {
      loadingMessage.value = 'Loading attendance data...';
      await _attendanceService.loadPendingApprovals();
      liveAttendance.value = _attendanceService.pendingApprovals;
    } catch (e) {
      print('Error loading live attendance: $e');
    }
  }

  // Load recent swap requests
  Future<void> loadRecentSwapRequests() async {
    try {
      loadingMessage.value = 'Loading swap requests...';
      await _swapService.loadAllSwapRequests();
    } catch (e) {
      print('Error loading swap requests: $e');
    }
  }

  // Load employee performance metrics
  Future<void> loadEmployeeMetrics() async {
    try {
      loadingMessage.value = 'Loading employee metrics...';
      final supabase = _supabaseService.client;
      final response = await supabase
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
      loadingMessage.value = 'Loading department statistics...';
      final supabase = _supabaseService.client;
      final response = await supabase.rpc('get_department_statistics');
      
      departmentStats.value = List<Map<String, dynamic>>.from(response ?? []);
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
        return swap.isPending && 
               swap.createdAt.difference(DateTime.now()).inDays.abs() <= 1;
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
    loadEmployeeMetrics();
    loadDepartmentStats();
  }

  // Change selected department filter
  void changeDepartment(String department) {
    selectedDepartment.value = department;
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
      loadingMessage.value = 'Approving swap requests...';
      
      for (String swapId in swapIds) {
        await _swapService.processScheduleSwapRequest(
          swapRequestId: swapId,
          action: 'approve',
          notes: 'Bulk approved from dashboard',
        );
      }

      Get.snackbar(
        'Success',
        '${swapIds.length} swap requests approved',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
      );
      
      await loadRecentSwapRequests();
      await loadDashboardSummary();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve swaps: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
      loadingMessage.value = '';
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
