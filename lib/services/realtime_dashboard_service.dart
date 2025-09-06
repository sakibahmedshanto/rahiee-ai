// ignore_for_file: file_names

import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

class RealtimeDashboardService extends GetxService {
  static RealtimeDashboardService get to => Get.find();
  
  final SupabaseService _supabaseService = SupabaseService.to;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable data for real-time dashboard
  final RxMap<String, dynamic> dashboardSummary = <String, dynamic>{}.obs;
  final RxList<ActiveScheduleViewModel> activeSchedules = <ActiveScheduleViewModel>[].obs;
  final RxList<Map<String, dynamic>> pendingAttendance = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> recentSwaps = <Map<String, dynamic>>[].obs;
  final RxList<EmployeePerformanceModel> employeePerformance = <EmployeePerformanceModel>[].obs;
  
  // Real-time notification system
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadNotificationCount = 0.obs;

  Timer? _dashboardRefreshTimer;
  RealtimeChannel? _attendanceChannel;
  RealtimeChannel? _scheduleChannel;
  RealtimeChannel? _swapChannel;
  RealtimeChannel? _notificationChannel;

  @override
  void onInit() {
    super.onInit();
    _setupRealtimeSubscriptions();
    _startPeriodicRefresh();
  }

  @override
  void onClose() {
    _dashboardRefreshTimer?.cancel();
    _attendanceChannel?.unsubscribe();
    _scheduleChannel?.unsubscribe();
    _swapChannel?.unsubscribe();
    _notificationChannel?.unsubscribe();
    super.onClose();
  }

  void _setupRealtimeSubscriptions() {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return;

    // Subscribe to attendance changes
    _attendanceChannel = _supabase
        .channel('attendance_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          callback: (payload) {
            _handleAttendanceChange(payload);
          },
        )
        .onBroadcast(
          event: 'attendance_changes',
          callback: (payload) {
            _refreshDashboardSummary();
          },
        )
        .subscribe();

    // Subscribe to schedule changes
    _scheduleChannel = _supabase
        .channel('schedule_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'employee_schedules',
          callback: (payload) {
            _handleScheduleChange(payload);
          },
        )
        .onBroadcast(
          event: 'schedule_changes',
          callback: (payload) {
            _refreshActiveSchedules();
          },
        )
        .subscribe();

    // Subscribe to swap request changes
    _swapChannel = _supabase
        .channel('swap_request_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedule_swap_requests',
          callback: (payload) {
            _handleSwapChange(payload);
          },
        )
        .onBroadcast(
          event: 'swap_request_changes',
          callback: (payload) {
            _refreshRecentSwaps();
          },
        )
        .subscribe();

    // Subscribe to notifications
    _notificationChannel = _supabase
        .channel('notifications_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            _handleNotificationChange(payload);
          },
        )
        .subscribe();
  }

  void _startPeriodicRefresh() {
    // Refresh dashboard data every 30 seconds
    _dashboardRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _refreshDashboardData(),
    );
  }

  void _handleAttendanceChange(PostgresChangePayload payload) {
    print('Attendance change detected: ${payload.eventType}');
    _refreshDashboardSummary();
    _refreshPendingAttendance();
  }

  void _handleScheduleChange(PostgresChangePayload payload) {
    print('Schedule change detected: ${payload.eventType}');
    _refreshActiveSchedules();
    _refreshDashboardSummary();
  }

  void _handleSwapChange(PostgresChangePayload payload) {
    print('Swap request change detected: ${payload.eventType}');
    _refreshRecentSwaps();
    _refreshDashboardSummary();
  }

  void _handleNotificationChange(PostgresChangePayload payload) {
    try {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          if (payload.newRecord.isNotEmpty) {
            final notification = NotificationModel.fromMap(payload.newRecord);
            _addNotification(notification);
          }
          break;
        case PostgresChangeEvent.update:
          if (payload.newRecord.isNotEmpty) {
            final notification = NotificationModel.fromMap(payload.newRecord);
            _updateNotification(notification);
          }
          break;
        case PostgresChangeEvent.delete:
          if (payload.oldRecord.isNotEmpty) {
            final deletedId = payload.oldRecord['id']?.toString();
            if (deletedId != null) {
              _removeNotification(deletedId);
            }
          }
          break;
        case PostgresChangeEvent.all:
          _refreshNotifications();
          break;
      }
    } catch (e) {
      print('Error handling notification change: $e');
    }
  }

  void _addNotification(NotificationModel notification) {
    notifications.insert(0, notification);
    _updateUnreadCount();
  }

  void _updateNotification(NotificationModel notification) {
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = notification;
      _updateUnreadCount();
    }
  }

  void _removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    unreadNotificationCount.value = notifications.where((n) => n.isUnread).length;
  }

  // Refresh all dashboard data
  Future<void> _refreshDashboardData() async {
    try {
      await Future.wait([
        _refreshDashboardSummary(),
        _refreshActiveSchedules(),
        _refreshPendingAttendance(),
        _refreshRecentSwaps(),
        _refreshEmployeePerformance(),
        _refreshNotifications(),
      ]);
    } catch (e) {
      print('Error refreshing dashboard data: $e');
    }
  }

  // Get real-time admin dashboard summary
  Future<void> _refreshDashboardSummary() async {
    try {
      final response = await _supabase.rpc('get_realtime_admin_dashboard', params: {
        'p_date_from': DateTime.now().toIso8601String().split('T')[0],
        'p_date_to': DateTime.now().toIso8601String().split('T')[0],
      });

      if (response != null) {
        dashboardSummary.value = Map<String, dynamic>.from(response);
      }
    } catch (e) {
      print('Error refreshing dashboard summary: $e');
    }
  }

  // Refresh active schedules
  Future<void> _refreshActiveSchedules() async {
    try {
      final response = await _supabase
          .from('active_schedules_view')
          .select()
          .gte('start_date_time', DateTime.now().toIso8601String().split('T')[0])
          .lte('start_date_time', DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0])
          .order('start_date_time');

      final schedules = (response as List)
          .map((data) => ActiveScheduleViewModel.fromMap(data))
          .toList();

      activeSchedules.value = schedules;
    } catch (e) {
      print('Error refreshing active schedules: $e');
    }
  }

  // Refresh pending attendance
  Future<void> _refreshPendingAttendance() async {
    try {
      final response = await _supabase
          .from('attendance')
          .select('''
            id, date, check_in_time, check_out_time, total_work_hours, 
            net_work_hours, overtime_hours, status, employee_notes,
            employee:my_users!employee_id(full_name, employee_id)
          ''')
          .eq('status', 'pending')
          .order('date', ascending: false)
          .order('check_in_time', ascending: false);

      pendingAttendance.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error refreshing pending attendance: $e');
    }
  }

  // Refresh recent swaps
  Future<void> _refreshRecentSwaps() async {
    try {
      final response = await _supabase
          .from('schedule_swap_requests')
          .select('''
            id, status, swap_type, created_at,
            requesting_employee:my_users!requesting_employee_id(full_name),
            target_employee:my_users!target_employee_id(full_name),
            original_schedule:employee_schedules!original_schedule_id(title, start_date_time)
          ''')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(10);

      recentSwaps.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error refreshing recent swaps: $e');
    }
  }

  // Refresh employee performance data
  Future<void> _refreshEmployeePerformance() async {
    try {
      final response = await _supabase
          .from('employee_performance_dashboard')
          .select()
          .order('full_name');

      final performance = (response as List)
          .map((data) => EmployeePerformanceModel.fromMap(data))
          .toList();

      employeePerformance.value = performance;
    } catch (e) {
      print('Error refreshing employee performance: $e');
    }
  }

  // Refresh notifications
  Future<void> _refreshNotifications() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUserId)
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}')
          .order('created_at', ascending: false)
          .limit(50);

      final notificationList = (response as List)
          .map((data) => NotificationModel.fromMap(data))
          .toList();

      notifications.value = notificationList;
      _updateUnreadCount();
    } catch (e) {
      print('Error refreshing notifications: $e');
    }
  }

  // Public methods for UI to trigger updates
  Future<void> refreshDashboard() async {
    await _refreshDashboardData();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get dashboard summary data
  Map<String, dynamic> get summary => dashboardSummary['summary'] ?? {};
  
  // Get quick stats
  int get totalEmployees => summary['total_employees'] ?? 0;
  int get totalSchedulesToday => summary['total_schedules_today'] ?? 0;
  int get checkedInToday => summary['checked_in_today'] ?? 0;
  int get checkedOutToday => summary['checked_out_today'] ?? 0;
  int get pendingApprovals => summary['pending_approvals'] ?? 0;
  int get pendingSwapRequests => summary['pending_swap_requests'] ?? 0;
  int get activeCoverageRequests => summary['active_coverage_requests'] ?? 0;

  // Get active schedules for current user (if employee)
  List<ActiveScheduleViewModel> get myActiveSchedules {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return [];
    
    return activeSchedules.where((schedule) => 
        schedule.currentEmployeeId == currentUserId
    ).toList();
  }

  // Get high priority notifications
  List<NotificationModel> get highPriorityNotifications {
    return notifications.where((n) => n.priority >= 4 && n.isUnread).toList();
  }

  // Check if user has urgent items requiring attention
  bool get hasUrgentItems {
    return highPriorityNotifications.isNotEmpty || 
           (pendingApprovals > 0) || 
           (pendingSwapRequests > 0);
  }

  // Get employee status summary
  Map<String, int> get employeeStatusSummary {
    final working = employeePerformance.where((e) => e.isTodayWorking).length;
    final scheduled = employeePerformance.where((e) => e.hasUpcomingSchedules).length;
    final off = employeePerformance.where((e) => !e.isTodayWorking && !e.hasUpcomingSchedules).length;
    
    return {
      'working': working,
      'scheduled': scheduled,
      'off': off,
      'total': employeePerformance.length,
    };
  }
}
