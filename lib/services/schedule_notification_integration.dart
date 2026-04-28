// Example integration of NotificationService with AdminScheduleService
// This shows how to send notifications when schedules are created/assigned

import 'package:get/get.dart';
import 'notification_service.dart';

class ScheduleNotificationIntegration {
  static final NotificationService _notificationService = Get.find<NotificationService>();

  /// Example: Send notifications when a schedule is created and assigned to users
  static Future<void> notifyScheduleAssignment({
    required String scheduleId,
    required List<String> assignedUserIds,
    required String scheduleTitle,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? department,
  }) async {
    try {
      print('Sending schedule assignment notifications to ${assignedUserIds.length} users');
      
      final result = await _notificationService.sendScheduleAssignmentNotifications(
        userIds: assignedUserIds,
        scheduleId: scheduleId,
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        location: location,
        department: department,
        customTitle: 'New Schedule: $scheduleTitle',
        customBody: 'Hey {firstName}! You have been assigned to "$scheduleTitle" starting at {startTime}. Location: {location}',
      );

      if (result.success) {
        print('✅ Schedule assignment notifications sent successfully');
        print('   - Sent: ${result.sentCount}');
        print('   - Failed: ${result.failedCount}');
        
        if (result.errors.isNotEmpty) {
          print('   - Errors: ${result.errors.join(', ')}');
        }
      } else {
        print('❌ Failed to send schedule assignment notifications');
        print('   - Errors: ${result.errors.join(', ')}');
      }
    } catch (e) {
      print('Error sending schedule assignment notifications: $e');
    }
  }

  /// Example: Send notifications when a schedule is updated
  static Future<void> notifyScheduleUpdate({
    required String scheduleId,
    required List<String> assignedUserIds,
    required String scheduleTitle,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? department,
  }) async {
    try {
      print('Sending schedule update notifications to ${assignedUserIds.length} users');
      
      final result = await _notificationService.sendScheduleUpdateNotifications(
        userIds: assignedUserIds,
        scheduleId: scheduleId,
        startTime: startTime?.toIso8601String(),
        endTime: endTime?.toIso8601String(),
        location: location,
        department: department,
        customTitle: 'Schedule Updated: $scheduleTitle',
        customBody: 'Hey {firstName}! Your schedule "$scheduleTitle" has been updated. Please check the new details.',
      );

      if (result.success) {
        print('✅ Schedule update notifications sent successfully');
        print('   - Sent: ${result.sentCount}');
        print('   - Failed: ${result.failedCount}');
      } else {
        print('❌ Failed to send schedule update notifications');
        print('   - Errors: ${result.errors.join(', ')}');
      }
    } catch (e) {
      print('Error sending schedule update notifications: $e');
    }
  }

  /// Example: Send notifications when a schedule is cancelled
  static Future<void> notifyScheduleCancellation({
    required String scheduleId,
    required List<String> assignedUserIds,
    required String scheduleTitle,
  }) async {
    try {
      print('Sending schedule cancellation notifications to ${assignedUserIds.length} users');
      
      final result = await _notificationService.sendScheduleCancellationNotifications(
        userIds: assignedUserIds,
        scheduleId: scheduleId,
        customTitle: 'Schedule Cancelled: $scheduleTitle',
        customBody: 'Hey {firstName}! Your schedule "$scheduleTitle" has been cancelled. Please check for alternative assignments.',
      );

      if (result.success) {
        print('✅ Schedule cancellation notifications sent successfully');
        print('   - Sent: ${result.sentCount}');
        print('   - Failed: ${result.failedCount}');
      } else {
        print('❌ Failed to send schedule cancellation notifications');
        print('   - Errors: ${result.errors.join(', ')}');
      }
    } catch (e) {
      print('Error sending schedule cancellation notifications: $e');
    }
  }

  /// Example: Send attendance reminder notifications
  static Future<void> notifyAttendanceReminder({
    required List<String> userIds,
    String? customMessage,
  }) async {
    try {
      print('Sending attendance reminder notifications to ${userIds.length} users');
      
      final result = await _notificationService.sendAttendanceReminderNotifications(
        userIds: userIds,
        customTitle: 'Attendance Reminder',
        customBody: customMessage ?? 'Hey {firstName}! Don\'t forget to mark your attendance for today.',
      );

      if (result.success) {
        print('✅ Attendance reminder notifications sent successfully');
        print('   - Sent: ${result.sentCount}');
        print('   - Failed: ${result.failedCount}');
      } else {
        print('❌ Failed to send attendance reminder notifications');
        print('   - Errors: ${result.errors.join(', ')}');
      }
    } catch (e) {
      print('Error sending attendance reminder notifications: $e');
    }
  }

  /// Example: Send general notifications to all active users
  static Future<void> notifyAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Get all active user IDs
      final userIds = await _notificationService.getAllActiveUserIds();
      
      if (userIds.isEmpty) {
        print('No active users found');
        return;
      }

      print('Sending general notifications to ${userIds.length} users');
      
      final result = await _notificationService.sendGeneralNotifications(
        userIds: userIds,
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
        priority: 'normal',
      );

      if (result.success) {
        print('✅ General notifications sent successfully');
        print('   - Sent: ${result.sentCount}');
        print('   - Failed: ${result.failedCount}');
      } else {
        print('❌ Failed to send general notifications');
        print('   - Errors: ${result.errors.join(', ')}');
      }
    } catch (e) {
      print('Error sending general notifications: $e');
    }
  }

  /// Example: Send notifications to users by department
  static Future<void> notifyDepartment({
    required String department,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user IDs by department
      final userIds = await _notificationService.getUserIdsByDepartment(department);
      
      if (userIds.isEmpty) {
        print('No users found in department: $department');
        return;
      }

      print('Sending notifications to ${userIds.length} users in $department department');
      
      final result = await _notificationService.sendGeneralNotifications(
        userIds: userIds,
        title: title,
        body: body,
        data: data,
        priority: 'normal',
      );

      if (result.success) {
        print('✅ Department notifications sent successfully');
        print('   - Sent: ${result.sentCount}');
        print('   - Failed: ${result.failedCount}');
      } else {
        print('❌ Failed to send department notifications');
        print('   - Errors: ${result.errors.join(', ')}');
      }
    } catch (e) {
      print('Error sending department notifications: $e');
    }
  }

  /// Example: Send notifications to users by role
  static Future<void> notifyRole({
    required String role,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user IDs by role
      final userIds = await _notificationService.getUserIdsByRole(role);
      
      if (userIds.isEmpty) {
        print('No users found with role: $role');
        return;
      }

      print('Sending notifications to ${userIds.length} users with role: $role');
      
      final result = await _notificationService.sendGeneralNotifications(
        userIds: userIds,
        title: title,
        body: body,
        data: data,
        priority: 'normal',
      );

      if (result.success) {
        print('✅ Role notifications sent successfully');
        print('   - Sent: ${result.sentCount}');
        print('   - Failed: ${result.failedCount}');
      } else {
        print('❌ Failed to send role notifications');
        print('   - Errors: ${result.errors.join(', ')}');
      }
    } catch (e) {
      print('Error sending role notifications: $e');
    }
  }
}
