import 'package:get/get.dart';
import 'notification_service.dart';

/// Service to integrate notifications with schedule and attendance events
class NotificationIntegrationService extends GetxService {
  static NotificationIntegrationService get to => Get.find();
  
  // Use lazy initialization to avoid dependency issues
  NotificationService get _notificationService => Get.find<NotificationService>();

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

  /// Send personalized notifications when admin creates schedules for assigned users
  Future<void> sendScheduleAssignmentNotifications({
    required List<String> userIds,
    required String scheduleTitle,
    required String scheduleId,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String department,
  }) async {
    try {
      final result = await _notificationService.sendScheduleAssignmentNotifications(
        userIds: userIds,
        scheduleId: scheduleId,
        startTime: startTime.toIso8601String(),
        endTime: endTime.toIso8601String(),
        location: location,
        department: department,
        customTitle: '📅 New Schedule Assignment',
        customBody: 'Hey {firstName}! You have been assigned to a new schedule: "$scheduleTitle" starting ${_formatDateTime(startTime)}.',
      );

      print('Schedule assignment notifications sent: ${result.sentCount} success, ${result.failedCount} failed');
    } catch (e) {
      print('Error sending schedule assignment notifications: $e');
    }
  }

  /// Helper method to format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final scheduleDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (scheduleDate == today) {
      return 'today at ${_formatTime(dateTime)}';
    } else if (scheduleDate == tomorrow) {
      return 'tomorrow at ${_formatTime(dateTime)}';
    } else {
      return 'on ${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
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

  /// Send notification to employee when attendance status is changed by admin
  Future<void> notifyEmployeeAttendanceStatusChange({
    required String employeeId,
    required String employeeName,
    required String oldStatus,
    required String newStatus,
    required String changedBy,
    required DateTime changeTime,
    String? reason,
    String? notes,
    String? scheduleId,
    String? scheduleTitle,
  }) async {
    try {
      String statusEmoji = '';
      String statusText = '';
      
      switch (newStatus.toLowerCase()) {
        case 'approved':
          statusEmoji = '✅';
          statusText = 'approved';
          break;
        case 'rejected':
        case 'cancelled':
          statusEmoji = '❌';
          statusText = 'rejected';
          break;
        case 'pending':
          statusEmoji = '⏳';
          statusText = 'pending review';
          break;
        default:
          statusEmoji = '📋';
          statusText = 'updated';
      }

      await _notificationService.sendCustomNotifications(
        userIds: [employeeId],
        title: '$statusEmoji Attendance Status $statusText',
        body: 'Hey {firstName}! Your attendance has been $statusText by $changedBy.${reason != null ? '\n\nReason: $reason' : ''}${notes != null ? '\n\nNotes: $notes' : ''}',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'changedBy': changedBy,
          'changeTime': changeTime.toIso8601String(),
          'reason': reason,
          'notes': notes,
          'scheduleId': scheduleId,
          'scheduleTitle': scheduleTitle,
          'action': 'attendance_status_change',
          'type': 'attendance_status',
          'actionType': 'view_attendance_history',
        },
        priority: 'normal',
      );

      print('Attendance status change notification sent to employee: $employeeName');
    } catch (e) {
      print('Error sending attendance status change notification: $e');
    }
  }

  /// Send notification to employee when schedule exchange is approved
  Future<void> notifyEmployeeScheduleExchangeApproval({
    required String employeeId,
    required String employeeName,
    required String requesterName,
    required String scheduleTitle,
    required DateTime scheduleStartTime,
    required DateTime scheduleEndTime,
    required String approvedBy,
    String? notes,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: [employeeId],
        title: '✅ Schedule Exchange Approved',
        body: 'Hey {firstName}! Your schedule exchange request for "$scheduleTitle" with $requesterName has been approved by $approvedBy.${notes != null ? '\n\nNotes: $notes' : ''}',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'requesterName': requesterName,
          'scheduleTitle': scheduleTitle,
          'scheduleStartTime': scheduleStartTime.toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toIso8601String(),
          'approvedBy': approvedBy,
          'notes': notes,
          'action': 'schedule_exchange_approved',
          'type': 'schedule_exchange',
          'actionType': 'view_schedule',
        },
        priority: 'normal',
      );

      print('Schedule exchange approval notification sent to employee: $employeeName');
    } catch (e) {
      print('Error sending schedule exchange approval notification: $e');
    }
  }

  /// Send notification to employee when schedule exchange is rejected
  Future<void> notifyEmployeeScheduleExchangeRejection({
    required String employeeId,
    required String employeeName,
    required String requesterName,
    required String scheduleTitle,
    required DateTime scheduleStartTime,
    required DateTime scheduleEndTime,
    required String rejectedBy,
    String? rejectionReason,
    String? notes,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: [employeeId],
        title: '❌ Schedule Exchange Rejected',
        body: 'Hey {firstName}! Your schedule exchange request for "$scheduleTitle" with $requesterName has been rejected by $rejectedBy.${rejectionReason != null ? '\n\nReason: $rejectionReason' : ''}${notes != null ? '\n\nNotes: $notes' : ''}',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'requesterName': requesterName,
          'scheduleTitle': scheduleTitle,
          'scheduleStartTime': scheduleStartTime.toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toIso8601String(),
          'rejectedBy': rejectedBy,
          'rejectionReason': rejectionReason,
          'notes': notes,
          'action': 'schedule_exchange_rejected',
          'type': 'schedule_exchange',
          'actionType': 'view_schedule',
        },
        priority: 'normal',
      );

      print('Schedule exchange rejection notification sent to employee: $employeeName');
    } catch (e) {
      print('Error sending schedule exchange rejection notification: $e');
    }
  }

  /// Send notification to employee when schedule exchange is cancelled
  Future<void> notifyEmployeeScheduleExchangeCancellation({
    required String employeeId,
    required String employeeName,
    required String requesterName,
    required String scheduleTitle,
    required DateTime scheduleStartTime,
    required DateTime scheduleEndTime,
    required String cancelledBy,
    String? cancellationReason,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: [employeeId],
        title: '🚫 Schedule Exchange Cancelled',
        body: 'Hey {firstName}! Your schedule exchange request for "$scheduleTitle" with $requesterName has been cancelled by $cancelledBy.${cancellationReason != null ? '\n\nReason: $cancellationReason' : ''}',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'requesterName': requesterName,
          'scheduleTitle': scheduleTitle,
          'scheduleStartTime': scheduleStartTime.toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toIso8601String(),
          'cancelledBy': cancelledBy,
          'cancellationReason': cancellationReason,
          'action': 'schedule_exchange_cancelled',
          'type': 'schedule_exchange',
          'actionType': 'view_schedule',
        },
        priority: 'normal',
      );

      print('Schedule exchange cancellation notification sent to employee: $employeeName');
    } catch (e) {
      print('Error sending schedule exchange cancellation notification: $e');
    }
  }

  /// Send notification to employee when schedule is reassigned
  Future<void> notifyEmployeeScheduleReassignment({
    required String employeeId,
    required String employeeName,
    required String scheduleTitle,
    required DateTime scheduleStartTime,
    required DateTime scheduleEndTime,
    required String location,
    required String reassignedBy,
    String? reason,
    String? notes,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: [employeeId],
        title: '🔄 Schedule Reassigned',
        body: 'Hey {firstName}! Your schedule "$scheduleTitle" has been reassigned by $reassignedBy.${reason != null ? '\n\nReason: $reason' : ''}${notes != null ? '\n\nNotes: $notes' : ''}',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'scheduleTitle': scheduleTitle,
          'scheduleStartTime': scheduleStartTime.toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toIso8601String(),
          'location': location,
          'reassignedBy': reassignedBy,
          'reason': reason,
          'notes': notes,
          'action': 'schedule_reassignment',
          'type': 'schedule_update',
          'actionType': 'view_schedule',
        },
        priority: 'normal',
      );

      print('Schedule reassignment notification sent to employee: $employeeName');
    } catch (e) {
      print('Error sending schedule reassignment notification: $e');
    }
  }

  /// Send notification to employee when schedule is cancelled
  Future<void> notifyEmployeeScheduleCancellation({
    required String employeeId,
    required String employeeName,
    required String scheduleTitle,
    required DateTime scheduleStartTime,
    required DateTime scheduleEndTime,
    required String location,
    required String cancelledBy,
    String? reason,
    String? notes,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: [employeeId],
        title: '🚫 Schedule Cancelled',
        body: 'Hey {firstName}! Your schedule "$scheduleTitle" has been cancelled by $cancelledBy.${reason != null ? '\n\nReason: $reason' : ''}${notes != null ? '\n\nNotes: $notes' : ''}',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'scheduleTitle': scheduleTitle,
          'scheduleStartTime': scheduleStartTime.toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toIso8601String(),
          'location': location,
          'cancelledBy': cancelledBy,
          'reason': reason,
          'notes': notes,
          'action': 'schedule_cancellation',
          'type': 'schedule_update',
          'actionType': 'view_schedule',
        },
        priority: 'high',
      );

      print('Schedule cancellation notification sent to employee: $employeeName');
    } catch (e) {
      print('Error sending schedule cancellation notification: $e');
    }
  }

  /// Send notification to employee when schedule is updated
  Future<void> notifyEmployeeScheduleUpdate({
    required String employeeId,
    required String employeeName,
    required String scheduleTitle,
    required DateTime oldStartTime,
    required DateTime oldEndTime,
    required DateTime newStartTime,
    required DateTime newEndTime,
    required String location,
    required String updatedBy,
    String? changes,
    String? notes,
  }) async {
    try {
      await _notificationService.sendCustomNotifications(
        userIds: [employeeId],
        title: '📝 Schedule Updated',
        body: 'Hey {firstName}! Your schedule "$scheduleTitle" has been updated by $updatedBy.${changes != null ? '\n\nChanges: $changes' : ''}${notes != null ? '\n\nNotes: $notes' : ''}',
        data: {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'scheduleTitle': scheduleTitle,
          'oldStartTime': oldStartTime.toIso8601String(),
          'oldEndTime': oldEndTime.toIso8601String(),
          'newStartTime': newStartTime.toIso8601String(),
          'newEndTime': newEndTime.toIso8601String(),
          'location': location,
          'updatedBy': updatedBy,
          'changes': changes,
          'notes': notes,
          'action': 'schedule_update',
          'type': 'schedule_update',
          'actionType': 'view_schedule',
        },
        priority: 'normal',
      );

      print('Schedule update notification sent to employee: $employeeName');
    } catch (e) {
      print('Error sending schedule update notification: $e');
    }
  }
}

