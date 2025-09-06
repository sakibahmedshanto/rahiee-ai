import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

// Notification type constants
class NotificationTypes {
  static const String scheduleAssigned = 'schedule_assigned';
  static const String scheduleUpdated = 'schedule_updated';
  static const String scheduleRemoved = 'schedule_removed';
  static const String swapRequested = 'swap_requested';
  static const String swapAccepted = 'swap_accepted';
  static const String swapDeclined = 'swap_declined';
  static const String swapCancelled = 'swap_cancelled';
  static const String coverageRequested = 'coverage_requested';
  static const String coverageAccepted = 'coverage_accepted';
  static const String coverageDeclined = 'coverage_declined';
  static const String attendanceApproved = 'attendance_approved';
  static const String attendanceRejected = 'attendance_rejected';
  static const String attendanceReminder = 'attendance_reminder';
  static const String newAttendance = 'new_attendance';
  static const String paymentProcessed = 'payment_processed';
  static const String paymentPending = 'payment_pending';
  static const String adminMessage = 'admin_message';
  static const String systemUpdate = 'system_update';
  static const String reminder = 'reminder';
  static const String general = 'general';
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();
  
  final SupabaseService _supabaseService = SupabaseService.to;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable lists for notifications
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxList<NotificationModel> unreadNotifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;

  // Real-time subscription
  RealtimeChannel? _notificationChannel;

  @override
  void onInit() {
    super.onInit();
    setupRealtimeSubscription();
    loadNotifications();
  }

  @override
  void onClose() {
    _notificationChannel?.unsubscribe();
    super.onClose();
  }

  // Setup real-time subscription for notifications
  void setupRealtimeSubscription() {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return;

    _notificationChannel = _supabase
        .channel('notifications_channel')
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

  // Handle real-time notification changes
  void _handleNotificationChange(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final notification = NotificationModel.fromMap(payload.newRecord);
        notifications.insert(0, notification);
        if (!notification.isRead) {
          unreadNotifications.insert(0, notification);
        }
        break;
      case PostgresChangeEvent.update:
        final updatedNotification = NotificationModel.fromMap(payload.newRecord);
        final index = notifications.indexWhere((n) => n.id == updatedNotification.id);
        if (index != -1) {
          notifications[index] = updatedNotification;
        }
        
        // Update unread list
        final unreadIndex = unreadNotifications.indexWhere((n) => n.id == updatedNotification.id);
        if (updatedNotification.isRead && unreadIndex != -1) {
          unreadNotifications.removeAt(unreadIndex);
        } else if (!updatedNotification.isRead && unreadIndex == -1) {
          unreadNotifications.insert(0, updatedNotification);
        }
        break;
      case PostgresChangeEvent.delete:
        final deletedId = payload.oldRecord['id'] as String;
        notifications.removeWhere((n) => n.id == deletedId);
        unreadNotifications.removeWhere((n) => n.id == deletedId);
        break;
      case PostgresChangeEvent.all:
        // Handle the 'all' event type if needed
        // This case typically represents subscription to all change types
        break;
    }
  }

  // Load all notifications for current user
  Future<void> loadNotifications({int? limit}) async {
    try {
      isLoading.value = true;
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return;

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      
      final notificationList = response
          .map((json) => NotificationModel.fromMap(json))
          .toList();

      notifications.value = notificationList;
      unreadNotifications.value = notificationList
          .where((notification) => !notification.isRead)
          .toList();

    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create a new notification
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? actionLabel,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'metadata': metadata,
        'action_url': actionUrl,
        'action_label': actionLabel,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('notifications')
          .insert(notificationData);

      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', currentUserId)
          .eq('is_read', false);

      // Update local state - create new notification objects instead of modifying
      final updatedNotifications = <NotificationModel>[];
      for (var notification in unreadNotifications) {
        updatedNotifications.add(notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        ));
      }
      unreadNotifications.clear();

      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Delete all notifications
  Future<bool> deleteAllNotifications() async {
    try {
      final currentUserId = _supabaseService.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', currentUserId);

      // Clear local state
      notifications.clear();
      unreadNotifications.clear();

      return true;
    } catch (e) {
      print('Error deleting all notifications: $e');
      return false;
    }
  }

  // Send notification to multiple users
  Future<bool> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? actionLabel,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'metadata': metadata,
        'action_url': actionUrl,
        'action_label': actionLabel,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase
          .from('notifications')
          .insert(notifications);

      return true;
    } catch (e) {
      print('Error sending bulk notifications: $e');
      return false;
    }
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return notifications.where((n) => n.type == type).toList();
  }

  // Get recent notifications (last 24 hours)
  List<NotificationModel> getRecentNotifications() {
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));
    return notifications.where((n) => n.createdAt.isAfter(dayAgo)).toList();
  }

  // Helper methods for specific notification types
  Future<bool> notifyScheduleAssignment({
    required String employeeId,
    required String scheduleName,
    required DateTime scheduleDate,
    required String adminName,
  }) async {
    return await createNotification(
      userId: employeeId,
      title: 'New Schedule Assignment',
      message: 'You have been assigned to "$scheduleName" on ${scheduleDate.toString().split(' ')[0]} by $adminName',
      type: NotificationTypes.scheduleAssigned,
      metadata: {
        'schedule_date': scheduleDate.toIso8601String(),
        'assigned_by': adminName,
      },
      actionUrl: '/schedules',
      actionLabel: 'View Schedule',
    );
  }

  Future<bool> notifySwapRequest({
    required String employeeId,
    required String requesterName,
    required String scheduleName,
    required DateTime scheduleDate,
    required String swapRequestId,
  }) async {
    return await createNotification(
      userId: employeeId,
      title: 'Schedule Swap Request',
      message: '$requesterName wants to swap "$scheduleName" on ${scheduleDate.toString().split(' ')[0]} with you',
      type: NotificationTypes.swapRequested,
      metadata: {
        'swap_request_id': swapRequestId,
        'schedule_date': scheduleDate.toIso8601String(),
        'requester': requesterName,
      },
      actionUrl: '/swap-requests/$swapRequestId',
      actionLabel: 'Review Request',
    );
  }

  Future<bool> notifySwapResponse({
    required String employeeId,
    required String responderName,
    required bool isAccepted,
    required String scheduleName,
    required DateTime scheduleDate,
  }) async {
    return await createNotification(
      userId: employeeId,
      title: 'Swap Request ${isAccepted ? "Accepted" : "Declined"}',
      message: '$responderName has ${isAccepted ? "accepted" : "declined"} your swap request for "$scheduleName" on ${scheduleDate.toString().split(' ')[0]}',
      type: isAccepted ? NotificationTypes.swapAccepted : NotificationTypes.swapDeclined,
      metadata: {
        'schedule_date': scheduleDate.toIso8601String(),
        'responder': responderName,
        'accepted': isAccepted,
      },
      actionUrl: '/schedules',
      actionLabel: 'View Schedules',
    );
  }

  Future<bool> notifyAttendanceReview({
    required String employeeId,
    required bool isApproved,
    required DateTime attendanceDate,
    required String adminName,
    String? notes,
  }) async {
    return await createNotification(
      userId: employeeId,
      title: 'Attendance ${isApproved ? "Approved" : "Rejected"}',
      message: 'Your attendance for ${attendanceDate.toString().split(' ')[0]} has been ${isApproved ? "approved" : "rejected"} by $adminName${notes != null ? ". Notes: $notes" : ""}',
      type: isApproved ? NotificationTypes.attendanceApproved : NotificationTypes.attendanceRejected,
      metadata: {
        'attendance_date': attendanceDate.toIso8601String(),
        'reviewed_by': adminName,
        'approved': isApproved,
        'notes': notes,
      },
      actionUrl: '/attendance',
      actionLabel: 'View Attendance',
    );
  }

  Future<bool> notifyPaymentProcessed({
    required String employeeId,
    required double amount,
    required String period,
    required DateTime paymentDate,
  }) async {
    return await createNotification(
      userId: employeeId,
      title: 'Payment Processed',
      message: 'Your payment of \$${amount.toStringAsFixed(2)} for $period has been processed on ${paymentDate.toString().split(' ')[0]}',
      type: NotificationTypes.paymentProcessed,
      metadata: {
        'amount': amount,
        'period': period,
        'payment_date': paymentDate.toIso8601String(),
      },
      actionUrl: '/payments',
      actionLabel: 'View Payments',
    );
  }

  // Admin notifications
  Future<bool> notifyNewAttendance({
    required String adminId,
    required String employeeName,
    required DateTime attendanceDate,
    required String attendanceId,
  }) async {
    return await createNotification(
      userId: adminId,
      title: 'New Attendance Record',
      message: '$employeeName has submitted attendance for ${attendanceDate.toString().split(' ')[0]} for review',
      type: NotificationTypes.newAttendance,
      metadata: {
        'attendance_id': attendanceId,
        'employee_name': employeeName,
        'attendance_date': attendanceDate.toIso8601String(),
      },
      actionUrl: '/admin/attendance/$attendanceId',
      actionLabel: 'Review Attendance',
    );
  }

  Future<bool> notifySwapRequestAdmin({
    required String adminId,
    required String requesterName,
    required String targetName,
    required String scheduleName,
    required DateTime scheduleDate,
    required String swapRequestId,
  }) async {
    return await createNotification(
      userId: adminId,
      title: 'Schedule Swap Request',
      message: '$requesterName has requested to swap "$scheduleName" on ${scheduleDate.toString().split(' ')[0]} with $targetName',
      type: NotificationTypes.swapRequested,
      metadata: {
        'swap_request_id': swapRequestId,
        'requester': requesterName,
        'target': targetName,
        'schedule_date': scheduleDate.toIso8601String(),
      },
      actionUrl: '/admin/swap-requests/$swapRequestId',
      actionLabel: 'Review Request',
    );
  }

  // Convenience getters
  int get unreadCount => unreadNotifications.length;
  
  bool get hasUnread => unreadNotifications.isNotEmpty;
  
  List<NotificationModel> get criticalNotifications => notifications
      .where((n) => n.type == NotificationTypes.attendanceRejected || 
                   n.type == NotificationTypes.swapDeclined)
      .toList();
}
