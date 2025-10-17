import 'package:get/get.dart';
import 'notification_service.dart';

/// Service to integrate notifications with schedule and attendance events
class NotificationIntegrationService extends GetxService {
  static NotificationIntegrationService get to => Get.find();
  
  final NotificationService _notificationService = Get.find<NotificationService>();

  /// Send notifications when a schedule is created and users are assigned
  Future<void> notifyScheduleAssignment({
    required List<String> assignedUserIds,
    required String scheduleId,
    required String scheduleTitle,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? department,
  }) async {
    try {
      final result = await _notificationService.sendScheduleAssignmentNotifications(
        userIds: assignedUserIds,
        scheduleId: scheduleId,
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        location: location,
        department: department,
        customTitle: 'New Schedule Assignment',
        customBody: 'Hey {firstName}! You have been assigned to "$scheduleTitle" at $location.',
      );

      print('Schedule assignment notifications sent: ${result.sentCount} success, ${result.failedCount} failed');
    } catch (e) {
      print('Error sending schedule assignment notifications: $e');
    }
  }

  /// Send notifications when a schedule is updated
  Future<void> notifyScheduleUpdate({
    required List<String> assignedUserIds,
    required String scheduleId,
    required String scheduleTitle,
    String? changes,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: assignedUserIds,
        title: 'Schedule Updated',
        body: 'Hey {firstName}! Your schedule "$scheduleTitle" has been updated.${changes != null ? '\n\nChanges: $changes' : ''}',
        data: {
          'scheduleId': scheduleId,
          'changes': changes,
          'type': 'schedule_update',
          'actionType': 'view_schedule',
        },
      );
    } catch (e) {
      print('Error sending schedule update notifications: $e');
    }
  }

  /// Send notifications when a schedule is cancelled
  Future<void> notifyScheduleCancellation({
    required List<String> assignedUserIds,
    required String scheduleId,
    required String scheduleTitle,
    String? reason,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: assignedUserIds,
        title: 'Schedule Cancelled',
        body: 'Hey {firstName}! The schedule "$scheduleTitle" has been cancelled.${reason != null ? '\n\nReason: $reason' : ''}',
        data: {
          'scheduleId': scheduleId,
          'reason': reason,
          'type': 'schedule_cancellation',
          'actionType': 'open_app',
        },
      );
    } catch (e) {
      print('Error sending schedule cancellation notifications: $e');
    }
  }

  /// Send notification to admins when an employee checks in
  Future<void> notifyAdminsCheckIn({
    required List<String> adminIds,
    required String employeeId,
    required String employeeName,
    required String location,
    required DateTime checkInTime,
    String? scheduleId,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '✅ Employee Check-In',
        body: '$employeeName has checked in at $location.',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'location': location,
          'checkInTime': checkInTime.toIso8601String(),
          'scheduleId': scheduleId,
          'action': 'check_in',
          'type': 'check_in',
          'actionType': 'view_attendance',
        },
        priority: 'normal',
      );

      print('Check-in notification sent to ${adminIds.length} admins');
    } catch (e) {
      print('Error sending check-in notification: $e');
    }
  }

  /// Send notification to admins when an employee checks out
  Future<void> notifyAdminsCheckOut({
    required List<String> adminIds,
    required String employeeId,
    required String employeeName,
    required String location,
    required DateTime checkOutTime,
    String? scheduleId,
    Duration? workDuration,
  }) async {
    try {
      String durationText = '';
      if (workDuration != null) {
        final hours = workDuration.inHours;
        final minutes = workDuration.inMinutes.remainder(60);
        durationText = ' Work duration: ${hours}h ${minutes}m';
      }

      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '👋 Employee Check-Out',
        body: '$employeeName has checked out from $location.$durationText',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'location': location,
          'checkOutTime': checkOutTime.toIso8601String(),
          'scheduleId': scheduleId,
          'workDuration': workDuration?.inMinutes,
          'action': 'check_out',
          'type': 'check_out',
          'actionType': 'view_attendance',
        },
        priority: 'normal',
      );

      print('Check-out notification sent to ${adminIds.length} admins');
    } catch (e) {
      print('Error sending check-out notification: $e');
    }
  }

  /// Send notification to admins about late check-in
  Future<void> notifyAdminsLateCheckIn({
    required List<String> adminIds,
    required String employeeId,
    required String employeeName,
    required DateTime scheduledTime,
    required DateTime actualTime,
    required String location,
  }) async {
    try {
      final lateDuration = actualTime.difference(scheduledTime);
      final minutes = lateDuration.inMinutes;

      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '⚠️ Late Check-In',
        body: '$employeeName checked in $minutes minutes late at $location.',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'location': location,
          'scheduledTime': scheduledTime.toIso8601String(),
          'actualTime': actualTime.toIso8601String(),
          'lateMinutes': minutes,
          'action': 'late_check_in',
          'type': 'check_in',
          'actionType': 'view_attendance',
        },
        priority: 'high',
      );
    } catch (e) {
      print('Error sending late check-in notification: $e');
    }
  }

  /// Send notification to employee about upcoming schedule
  Future<void> notifyUpcomingSchedule({
    required String userId,
    required String scheduleTitle,
    required String location,
    required DateTime startTime,
    required int minutesBefore,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: [userId],
        title: '⏰ Upcoming Schedule',
        body: 'Hey {firstName}! Your schedule "$scheduleTitle" starts in $minutesBefore minutes at $location.',
        data: {
          'scheduleTitle': scheduleTitle,
          'location': location,
          'startTime': startTime.toIso8601String(),
          'minutesBefore': minutesBefore,
          'type': 'attendance_reminder',
          'actionType': 'view_schedule',
        },
        priority: 'high',
      );
    } catch (e) {
      print('Error sending upcoming schedule notification: $e');
    }
  }

  /// Get all admin user IDs
  Future<List<String>> getAdminUserIds() async {
    try {
      final adminIds = await _notificationService.getUserIdsByRole('admin');
      return adminIds;
    } catch (e) {
      print('Error getting admin user IDs: $e');
      return [];
    }
  }

  /// Get all HR user IDs
  Future<List<String>> getHRUserIds() async {
    try {
      final hrIds = await _notificationService.getUserIdsByRole('hr');
      return hrIds;
    } catch (e) {
      print('Error getting HR user IDs: $e');
      return [];
    }
  }

  /// Get admin and HR user IDs combined
  Future<List<String>> getAdminAndHRUserIds() async {
    try {
      final adminIds = await getAdminUserIds();
      final hrIds = await getHRUserIds();
      return {...adminIds, ...hrIds}.toList();
    } catch (e) {
      print('Error getting admin and HR user IDs: $e');
      return [];
    }
  }

  /// Send notification to admins about schedule exchange request
  Future<void> notifyAdminsScheduleExchangeRequest({
    required List<String> adminIds,
    required String requesterId,
    required String requesterName,
    required String requestedUserId,
    required String requestedUserName,
    required String scheduleTitle,
    required DateTime scheduleStartTime,
    required DateTime scheduleEndTime,
    required String reason,
    String? notes,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '🔄 Schedule Exchange Request',
        body: '$requesterName wants to exchange schedule "$scheduleTitle" with $requestedUserName.\n\nReason: $reason',
        data: {
          'requesterId': requesterId,
          'requesterName': requesterName,
          'requestedUserId': requestedUserId,
          'requestedUserName': requestedUserName,
          'scheduleTitle': scheduleTitle,
          'scheduleStartTime': scheduleStartTime.toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toIso8601String(),
          'reason': reason,
          'notes': notes,
          'action': 'schedule_exchange_request',
          'type': 'schedule_exchange',
          'actionType': 'view_exchange_requests',
        },
        priority: 'high',
      );

      print('Schedule exchange request notification sent to ${adminIds.length} admins');
    } catch (e) {
      print('Error sending schedule exchange request notification: $e');
    }
  }

  /// Send notification to admins about schedule exchange approval
  Future<void> notifyAdminsScheduleExchangeApproval({
    required List<String> adminIds,
    required String requesterId,
    required String requesterName,
    required String requestedUserId,
    required String requestedUserName,
    required String scheduleTitle,
    required String approvedBy,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '✅ Schedule Exchange Approved',
        body: 'Schedule exchange between $requesterName and $requestedUserName for "$scheduleTitle" has been approved by $approvedBy.',
        data: {
          'requesterId': requesterId,
          'requesterName': requesterName,
          'requestedUserId': requestedUserId,
          'requestedUserName': requestedUserName,
          'scheduleTitle': scheduleTitle,
          'approvedBy': approvedBy,
          'action': 'schedule_exchange_approved',
          'type': 'schedule_exchange',
          'actionType': 'view_exchange_requests',
        },
        priority: 'normal',
      );

      print('Schedule exchange approval notification sent to ${adminIds.length} admins');
    } catch (e) {
      print('Error sending schedule exchange approval notification: $e');
    }
  }

  /// Send notification to admins about schedule exchange rejection
  Future<void> notifyAdminsScheduleExchangeRejection({
    required List<String> adminIds,
    required String requesterId,
    required String requesterName,
    required String requestedUserId,
    required String requestedUserName,
    required String scheduleTitle,
    required String rejectedBy,
    String? rejectionReason,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '❌ Schedule Exchange Rejected',
        body: 'Schedule exchange between $requesterName and $requestedUserName for "$scheduleTitle" has been rejected by $rejectedBy.${rejectionReason != null ? '\n\nReason: $rejectionReason' : ''}',
        data: {
          'requesterId': requesterId,
          'requesterName': requesterName,
          'requestedUserId': requestedUserId,
          'requestedUserName': requestedUserName,
          'scheduleTitle': scheduleTitle,
          'rejectedBy': rejectedBy,
          'rejectionReason': rejectionReason,
          'action': 'schedule_exchange_rejected',
          'type': 'schedule_exchange',
          'actionType': 'view_exchange_requests',
        },
        priority: 'normal',
      );

      print('Schedule exchange rejection notification sent to ${adminIds.length} admins');
    } catch (e) {
      print('Error sending schedule exchange rejection notification: $e');
    }
  }

  /// Send notification to admins about attendance approval needed
  Future<void> notifyAdminsAttendanceApprovalNeeded({
    required List<String> adminIds,
    required String employeeId,
    required String employeeName,
    required String attendanceType, // 'check_in' or 'check_out'
    required DateTime attendanceTime,
    required String location,
    String? notes,
    String? scheduleId,
  }) async {
    try {
      final actionText = attendanceType == 'check_in' ? 'checked in' : 'checked out';
      
      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '⏳ Attendance Approval Needed',
        body: '$employeeName has $actionText at $location and requires approval.',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'attendanceType': attendanceType,
          'attendanceTime': attendanceTime.toIso8601String(),
          'location': location,
          'notes': notes,
          'scheduleId': scheduleId,
          'action': 'attendance_approval_needed',
          'type': 'attendance_approval',
          'actionType': 'view_pending_approvals',
        },
        priority: 'high',
      );

      print('Attendance approval notification sent to ${adminIds.length} admins');
    } catch (e) {
      print('Error sending attendance approval notification: $e');
    }
  }

  /// Send notification to admins about uniform violation
  Future<void> notifyAdminsUniformViolation({
    required List<String> adminIds,
    required String employeeId,
    required String employeeName,
    required String location,
    required DateTime checkInTime,
    required double confidence,
    String? violationDetails,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: adminIds,
        title: '👔 Uniform Violation Detected',
        body: '$employeeName checked in at $location without proper uniform (Confidence: ${(confidence * 100).toStringAsFixed(1)}%).',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'location': location,
          'checkInTime': checkInTime.toIso8601String(),
          'confidence': confidence,
          'violationDetails': violationDetails,
          'action': 'uniform_violation',
          'type': 'uniform_violation',
          'actionType': 'view_attendance',
        },
        priority: 'high',
      );

      print('Uniform violation notification sent to ${adminIds.length} admins');
    } catch (e) {
      print('Error sending uniform violation notification: $e');
    }
  }
}

