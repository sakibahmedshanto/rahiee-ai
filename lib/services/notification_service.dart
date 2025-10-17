// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Notification types supported by the Edge Function
enum NotificationType {
  scheduleAssignment,
  scheduleUpdate,
  scheduleCancellation,
  attendanceReminder,
  general,
  custom,
}

/// Schedule-specific data for notifications
class ScheduleNotificationData {
  final String? scheduleId;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? department;

  ScheduleNotificationData({
    this.scheduleId,
    this.startTime,
    this.endTime,
    this.location,
    this.department,
  });

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'department': department,
    };
  }
}

/// Custom template for notifications
class CustomNotificationTemplate {
  final String? titleTemplate;
  final String? bodyTemplate;

  CustomNotificationTemplate({
    this.titleTemplate,
    this.bodyTemplate,
  });

  Map<String, dynamic> toMap() {
    return {
      'titleTemplate': titleTemplate,
      'bodyTemplate': bodyTemplate,
    };
  }
}

/// Notification request parameters
class NotificationRequest {
  final List<String> userIds;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final ScheduleNotificationData? scheduleData;
  final String? priority;
  final String? scheduledTime;
  final CustomNotificationTemplate? customTemplate;

  NotificationRequest({
    required this.userIds,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.imageUrl,
    this.scheduleData,
    this.priority,
    this.scheduledTime,
    this.customTemplate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userIds': userIds,
      'type': _getTypeString(),
      'title': title,
      'body': body,
      if (data != null) 'data': data,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (scheduleData != null) 'scheduleData': scheduleData!.toMap(),
      if (priority != null) 'priority': priority,
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
      if (customTemplate != null) 'customTemplate': customTemplate!.toMap(),
    };
  }

  String _getTypeString() {
    switch (type) {
      case NotificationType.scheduleAssignment:
        return 'schedule_assignment';
      case NotificationType.scheduleUpdate:
        return 'schedule_update';
      case NotificationType.scheduleCancellation:
        return 'schedule_cancellation';
      case NotificationType.attendanceReminder:
        return 'attendance_reminder';
      case NotificationType.general:
        return 'general';
      case NotificationType.custom:
        return 'custom';
    }
  }
}

/// Notification result from Edge Function
class NotificationResult {
  final bool success;
  final int sentCount;
  final int failedCount;
  final List<String> errors;
  final List<ProcessedUser> processedUsers;

  NotificationResult({
    required this.success,
    required this.sentCount,
    required this.failedCount,
    required this.errors,
    required this.processedUsers,
  });

  factory NotificationResult.fromMap(Map<String, dynamic> map) {
    return NotificationResult(
      success: map['success'] ?? false,
      sentCount: map['sentCount'] ?? 0,
      failedCount: map['failedCount'] ?? 0,
      errors: List<String>.from(map['errors'] ?? []),
      processedUsers: (map['processedUsers'] as List?)
          ?.map((e) => ProcessedUser.fromMap(e))
          .toList() ?? [],
    );
  }
}

/// Processed user result
class ProcessedUser {
  final String userId;
  final bool success;
  final String? error;

  ProcessedUser({
    required this.userId,
    required this.success,
    this.error,
  });

  factory ProcessedUser.fromMap(Map<String, dynamic> map) {
    return ProcessedUser(
      userId: map['userId'] ?? '',
      success: map['success'] ?? false,
      error: map['error'],
    );
  }
}

/// Service for sending push notifications via Edge Function
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();
  
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send notifications to multiple users
  Future<NotificationResult> sendNotifications(NotificationRequest request) async {
    try {
      print('Sending notifications to ${request.userIds.length} users');
      
      final response = await _supabase.functions.invoke(
        'send-notifications',
        body: request.toMap(),
      );

      if (response.status == 200) {
        final result = NotificationResult.fromMap(response.data);
        print('Notifications sent: ${result.sentCount} success, ${result.failedCount} failed');
        return result;
      } else {
        print('Failed to send notifications: ${response.status} - ${response.data}');
        return NotificationResult(
          success: false,
          sentCount: 0,
          failedCount: request.userIds.length,
          errors: ['HTTP ${response.status}: ${response.data}'],
          processedUsers: [],
        );
      }
    } catch (e) {
      print('Error sending notifications: $e');
      return NotificationResult(
        success: false,
        sentCount: 0,
        failedCount: request.userIds.length,
        errors: [e.toString()],
        processedUsers: [],
      );
    }
  }

  /// Send schedule assignment notifications
  Future<NotificationResult> sendScheduleAssignmentNotifications({
    required List<String> userIds,
    required String scheduleId,
    required String startTime,
    required String endTime,
    required String location,
    String? department,
    String? customTitle,
    String? customBody,
  }) async {
    final request = NotificationRequest(
      userIds: userIds,
      type: NotificationType.scheduleAssignment,
      title: customTitle ?? 'New Schedule Assignment',
      body: customBody ?? 'Hey {firstName}! You have been assigned to a new schedule. Check your app for details.',
      scheduleData: ScheduleNotificationData(
        scheduleId: scheduleId,
        startTime: startTime,
        endTime: endTime,
        location: location,
        department: department,
      ),
      data: {
        'scheduleId': scheduleId,
        'action': 'view_schedule',
      },
      priority: 'high',
    );

    return await sendNotifications(request);
  }

  /// Send schedule update notifications
  Future<NotificationResult> sendScheduleUpdateNotifications({
    required List<String> userIds,
    required String scheduleId,
    String? startTime,
    String? endTime,
    String? location,
    String? department,
    String? customTitle,
    String? customBody,
  }) async {
    final request = NotificationRequest(
      userIds: userIds,
      type: NotificationType.scheduleUpdate,
      title: customTitle ?? 'Schedule Updated',
      body: customBody ?? 'Hey {firstName}! Your schedule has been updated. Please check the new details.',
      scheduleData: ScheduleNotificationData(
        scheduleId: scheduleId,
        startTime: startTime,
        endTime: endTime,
        location: location,
        department: department,
      ),
      data: {
        'scheduleId': scheduleId,
        'action': 'view_schedule',
      },
      priority: 'high',
    );

    return await sendNotifications(request);
  }

  /// Send schedule cancellation notifications
  Future<NotificationResult> sendScheduleCancellationNotifications({
    required List<String> userIds,
    required String scheduleId,
    String? customTitle,
    String? customBody,
  }) async {
    final request = NotificationRequest(
      userIds: userIds,
      type: NotificationType.scheduleCancellation,
      title: customTitle ?? 'Schedule Cancelled',
      body: customBody ?? 'Hey {firstName}! Your schedule has been cancelled. Please check for alternative assignments.',
      scheduleData: ScheduleNotificationData(
        scheduleId: scheduleId,
      ),
      data: {
        'scheduleId': scheduleId,
        'action': 'view_schedule',
      },
      priority: 'high',
    );

    return await sendNotifications(request);
  }

  /// Send attendance reminder notifications
  Future<NotificationResult> sendAttendanceReminderNotifications({
    required List<String> userIds,
    String? customTitle,
    String? customBody,
  }) async {
    final request = NotificationRequest(
      userIds: userIds,
      type: NotificationType.attendanceReminder,
      title: customTitle ?? 'Attendance Reminder',
      body: customBody ?? 'Hey {firstName}! Don\'t forget to mark your attendance for today.',
      data: {
        'action': 'mark_attendance',
      },
      priority: 'normal',
    );

    return await sendNotifications(request);
  }

  /// Send general notifications
  Future<NotificationResult> sendGeneralNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? priority,
  }) async {
    final request = NotificationRequest(
      userIds: userIds,
      type: NotificationType.general,
      title: title,
      body: body,
      data: data,
      imageUrl: imageUrl,
      priority: priority ?? 'normal',
    );

    return await sendNotifications(request);
  }

  /// Send custom notifications with full control
  Future<NotificationResult> sendCustomNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    ScheduleNotificationData? scheduleData,
    String? priority,
    CustomNotificationTemplate? customTemplate,
  }) async {
    final request = NotificationRequest(
      userIds: userIds,
      type: NotificationType.custom,
      title: title,
      body: body,
      data: data,
      imageUrl: imageUrl,
      scheduleData: scheduleData,
      priority: priority ?? 'normal',
      customTemplate: customTemplate,
    );

    return await sendNotifications(request);
  }

  /// Helper method to get user IDs from UserModel list
  static List<String> getUserIdsFromUserModels(List<UserModel> users) {
    return users.map((user) => user.uId).toList();
  }

  /// Helper method to get user IDs from employee IDs
  Future<List<String>> getUserIdsFromEmployeeIds(List<String> employeeIds) async {
    try {
      final response = await _supabase
          .from('my_users')
          .select('id')
          .inFilter('employee_id', employeeIds);
      
      return response.map((user) => user['id'] as String).toList();
    } catch (e) {
      print('Error fetching user IDs from employee IDs: $e');
      return [];
    }
  }

  /// Helper method to get all active user IDs
  Future<List<String>> getAllActiveUserIds() async {
    try {
      final response = await _supabase
          .from('my_users')
          .select('id')
          .eq('is_active', true);
      
      return response.map((user) => user['id'] as String).toList();
    } catch (e) {
      print('Error fetching all active user IDs: $e');
      return [];
    }
  }

  /// Helper method to get user IDs by department
  Future<List<String>> getUserIdsByDepartment(String department) async {
    try {
      final response = await _supabase
          .from('my_users')
          .select('id')
          .eq('department', department)
          .eq('is_active', true);
      
      return response.map((user) => user['id'] as String).toList();
    } catch (e) {
      print('Error fetching user IDs by department: $e');
      return [];
    }
  }

  /// Helper method to get user IDs by role
  Future<List<String>> getUserIdsByRole(String role) async {
    try {
      final response = await _supabase
          .from('my_users')
          .select('id')
          .eq('user_role', role)
          .eq('is_active', true);
      
      return response.map((user) => user['id'] as String).toList();
    } catch (e) {
      print('Error fetching user IDs by role: $e');
      return [];
    }
  }
}
