// ignore_for_file: file_names

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  
  // Status
  final bool isRead;
  final bool isPushSent;
  
  // Priority and category
  final int priority; // 1-5 (1 = low, 5 = critical)
  final String category;
  
  // References
  final String? referenceId; // Can reference schedule, attendance, swap request, etc.
  final String? referenceType;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.isPushSent,
    required this.priority,
    required this.category,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['is_read'] as bool? ?? false,
      isPushSent: data['is_push_sent'] as bool? ?? false,
      priority: data['priority'] as int? ?? 1,
      category: data['category']?.toString() ?? 'general',
      referenceId: data['reference_id']?.toString(),
      referenceType: data['reference_type']?.toString(),
      createdAt: DateTime.parse(data['created_at']),
      readAt: data['read_at'] != null ? DateTime.parse(data['read_at']) : null,
      expiresAt: data['expires_at'] != null ? DateTime.parse(data['expires_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isEmpty ? null : id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'is_push_sent': isPushSent,
      'priority': priority,
      'category': category,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isPushSent,
    int? priority,
    String? category,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isPushSent: isPushSent ?? this.isPushSent,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Helper methods
  bool get isUnread => !isRead;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isCritical => priority >= 4;
  bool get isHigh => priority == 3;
  bool get isMedium => priority == 2;
  bool get isLow => priority == 1;

  String get priorityText {
    switch (priority) {
      case 5:
        return 'Critical';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      case 1:
        return 'Info';
      default:
        return 'Unknown';
    }
  }

  // Notification type helpers
  bool get isScheduleSwap => type.contains('schedule_swap');
  bool get isAttendance => type.contains('attendance');
  bool get isSchedule => type.contains('schedule') && !isScheduleSwap;
  bool get isCoverage => type.contains('coverage');
  bool get isAdmin => type.contains('admin');
}

class DashboardSummaryModel {
  final int totalEmployees;
  final int totalSchedulesToday;
  final int checkedInToday;
  final int checkedOutToday;
  final int pendingApprovals;
  final int pendingSwapRequests;
  final int activeCoverageRequests;

  DashboardSummaryModel({
    required this.totalEmployees,
    required this.totalSchedulesToday,
    required this.checkedInToday,
    required this.checkedOutToday,
    required this.pendingApprovals,
    required this.pendingSwapRequests,
    required this.activeCoverageRequests,
  });

  factory DashboardSummaryModel.fromMap(Map<String, dynamic> data) {
    return DashboardSummaryModel(
      totalEmployees: data['total_employees'] as int? ?? 0,
      totalSchedulesToday: data['total_schedules_today'] as int? ?? 0,
      checkedInToday: data['checked_in_today'] as int? ?? 0,
      checkedOutToday: data['checked_out_today'] as int? ?? 0,
      pendingApprovals: data['pending_approvals'] as int? ?? 0,
      pendingSwapRequests: data['pending_swap_requests'] as int? ?? 0,
      activeCoverageRequests: data['active_coverage_requests'] as int? ?? 0,
    );
  }
}

class ActiveScheduleViewModel {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String scheduleStatus;
  final String department;
  final String location;
  
  // Employee details
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? assignedEmployeeCode;
  
  final String? actualEmployeeId;
  final String? actualEmployeeName;
  final String? actualEmployeeCode;
  
  // Admin details
  final String? createdByAdminName;
  
  // Attendance status
  final String? attendanceId;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? attendanceStatus;
  final double? totalWorkHours;
  final double? netWorkHours;
  final double? overtimeHours;
  
  // Swap information
  final bool hasSwapRequest;
  final String? swapStatus;
  final String? swapRequesterId;
  final String? swapTargetId;
  
  // Coverage information
  final bool hasCoverageRequest;
  final String? coverageStatus;
  final String? coveringEmployeeId;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  ActiveScheduleViewModel({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.scheduleStatus,
    required this.department,
    required this.location,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.assignedEmployeeCode,
    this.actualEmployeeId,
    this.actualEmployeeName,
    this.actualEmployeeCode,
    this.createdByAdminName,
    this.attendanceId,
    this.checkInTime,
    this.checkOutTime,
    this.attendanceStatus,
    this.totalWorkHours,
    this.netWorkHours,
    this.overtimeHours,
    required this.hasSwapRequest,
    this.swapStatus,
    this.swapRequesterId,
    this.swapTargetId,
    required this.hasCoverageRequest,
    this.coverageStatus,
    this.coveringEmployeeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActiveScheduleViewModel.fromMap(Map<String, dynamic> data) {
    return ActiveScheduleViewModel(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      startDateTime: DateTime.parse(data['start_date_time']),
      endDateTime: DateTime.parse(data['end_date_time']),
      scheduleStatus: data['schedule_status']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      assignedEmployeeId: data['assigned_employee_id']?.toString(),
      assignedEmployeeName: data['assigned_employee_name']?.toString(),
      assignedEmployeeCode: data['assigned_employee_code']?.toString(),
      actualEmployeeId: data['actual_employee_id']?.toString(),
      actualEmployeeName: data['actual_employee_name']?.toString(),
      actualEmployeeCode: data['actual_employee_code']?.toString(),
      createdByAdminName: data['created_by_admin_name']?.toString(),
      attendanceId: data['attendance_id']?.toString(),
      checkInTime: data['check_in_time'] != null ? DateTime.parse(data['check_in_time']) : null,
      checkOutTime: data['check_out_time'] != null ? DateTime.parse(data['check_out_time']) : null,
      attendanceStatus: data['attendance_status']?.toString(),
      totalWorkHours: (data['total_work_hours'] as num?)?.toDouble(),
      netWorkHours: (data['net_work_hours'] as num?)?.toDouble(),
      overtimeHours: (data['overtime_hours'] as num?)?.toDouble(),
      hasSwapRequest: data['has_swap_request'] as bool? ?? false,
      swapStatus: data['swap_status']?.toString(),
      swapRequesterId: data['swap_requester_id']?.toString(),
      swapTargetId: data['swap_target_id']?.toString(),
      hasCoverageRequest: data['has_coverage_request'] as bool? ?? false,
      coverageStatus: data['coverage_status']?.toString(),
      coveringEmployeeId: data['covering_employee_id']?.toString(),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  // Helper methods
  String get currentEmployeeName => actualEmployeeName ?? assignedEmployeeName ?? 'Unassigned';
  String get currentEmployeeCode => actualEmployeeCode ?? assignedEmployeeCode ?? '';
  String get currentEmployeeId => actualEmployeeId ?? assignedEmployeeId ?? '';
  
  bool get isSwapped => actualEmployeeId != null && actualEmployeeId != assignedEmployeeId;
  bool get hasAttendance => attendanceId != null;
  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
  bool get isInProgress => isCheckedIn && !isCheckedOut;
  bool get isCompleted => isCheckedOut;
  
  String get statusDisplayText {
    if (hasSwapRequest && swapStatus == 'pending') return 'Swap Pending';
    if (hasCoverageRequest && coverageStatus == 'open') return 'Needs Coverage';
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'In Progress';
    if (DateTime.now().isAfter(startDateTime)) return 'Not Started';
    return 'Scheduled';
  }
}

class EmployeePerformanceModel {
  final String employeeId;
  final String employeeCode;
  final String fullName;
  final String department;
  final String position;
  final String userRole;
  final double? salaryRate;
  
  // Current month statistics
  final double monthlyWorkHours;
  final double monthlyOvertimeHours;
  final double monthlyGrantedHours;
  final double monthlyAttendanceRate;
  final double monthlyGrossEarnings;
  final double monthlyPaid;
  final double monthlyUnpaid;
  
  // Today's status
  final DateTime? todayCheckIn;
  final DateTime? todayCheckOut;
  final String? todayAttendanceStatus;
  final double todayWorkHours;
  
  // Schedule information
  final int? upcomingCount;
  final DateTime? nextScheduleTime;
  
  // Swap and coverage statistics
  final int totalCoverageGiven;
  final int totalCoverageReceived;
  final int? pendingSwapRequests;
  final int? completedSwapsThisMonth;
  
  // Performance metrics
  final double punctualityRate;
  final double approvalRate;
  
  final bool isActive;
  final DateTime createdOn;
  final DateTime updatedAt;

  EmployeePerformanceModel({
    required this.employeeId,
    required this.employeeCode,
    required this.fullName,
    required this.department,
    required this.position,
    required this.userRole,
    this.salaryRate,
    required this.monthlyWorkHours,
    required this.monthlyOvertimeHours,
    required this.monthlyGrantedHours,
    required this.monthlyAttendanceRate,
    required this.monthlyGrossEarnings,
    required this.monthlyPaid,
    required this.monthlyUnpaid,
    this.todayCheckIn,
    this.todayCheckOut,
    this.todayAttendanceStatus,
    required this.todayWorkHours,
    this.upcomingCount,
    this.nextScheduleTime,
    required this.totalCoverageGiven,
    required this.totalCoverageReceived,
    this.pendingSwapRequests,
    this.completedSwapsThisMonth,
    required this.punctualityRate,
    required this.approvalRate,
    required this.isActive,
    required this.createdOn,
    required this.updatedAt,
  });

  factory EmployeePerformanceModel.fromMap(Map<String, dynamic> data) {
    return EmployeePerformanceModel(
      employeeId: data['employee_id']?.toString() ?? '',
      employeeCode: data['employee_code']?.toString() ?? '',
      fullName: data['full_name']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      position: data['position']?.toString() ?? '',
      userRole: data['user_role']?.toString() ?? '',
      salaryRate: (data['salary_rate'] as num?)?.toDouble(),
      monthlyWorkHours: (data['monthly_work_hours'] as num?)?.toDouble() ?? 0.0,
      monthlyOvertimeHours: (data['monthly_overtime_hours'] as num?)?.toDouble() ?? 0.0,
      monthlyGrantedHours: (data['monthly_granted_hours'] as num?)?.toDouble() ?? 0.0,
      monthlyAttendanceRate: (data['monthly_attendance_rate'] as num?)?.toDouble() ?? 0.0,
      monthlyGrossEarnings: (data['monthly_gross_earnings'] as num?)?.toDouble() ?? 0.0,
      monthlyPaid: (data['monthly_paid'] as num?)?.toDouble() ?? 0.0,
      monthlyUnpaid: (data['monthly_unpaid'] as num?)?.toDouble() ?? 0.0,
      todayCheckIn: data['today_check_in'] != null ? DateTime.parse(data['today_check_in']) : null,
      todayCheckOut: data['today_check_out'] != null ? DateTime.parse(data['today_check_out']) : null,
      todayAttendanceStatus: data['today_attendance_status']?.toString(),
      todayWorkHours: (data['today_work_hours'] as num?)?.toDouble() ?? 0.0,
      upcomingCount: data['upcoming_count'] as int?,
      nextScheduleTime: data['next_schedule_time'] != null ? DateTime.parse(data['next_schedule_time']) : null,
      totalCoverageGiven: data['total_coverage_given'] as int? ?? 0,
      totalCoverageReceived: data['total_coverage_received'] as int? ?? 0,
      pendingSwapRequests: data['pending_swap_requests'] as int?,
      completedSwapsThisMonth: data['completed_swaps_this_month'] as int?,
      punctualityRate: (data['punctuality_rate'] as num?)?.toDouble() ?? 100.0,
      approvalRate: (data['approval_rate'] as num?)?.toDouble() ?? 0.0,
      isActive: data['is_active'] as bool? ?? true,
      createdOn: DateTime.parse(data['created_on']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  // Helper methods
  bool get isTodayCheckedIn => todayCheckIn != null;
  bool get isTodayCheckedOut => todayCheckOut != null;
  bool get isTodayWorking => isTodayCheckedIn && !isTodayCheckedOut;
  bool get hasUpcomingSchedules => upcomingCount != null && upcomingCount! > 0;
  bool get hasPendingSwaps => pendingSwapRequests != null && pendingSwapRequests! > 0;
  
  String get todayStatusText {
    if (isTodayWorking) return 'Working';
    if (isTodayCheckedOut) return 'Completed';
    if (hasUpcomingSchedules) return 'Scheduled';
    return 'Off';
  }

  double get monthlyBalance => monthlyPaid - monthlyUnpaid;
  double get coverageRatio => totalCoverageReceived > 0 ? totalCoverageGiven / totalCoverageReceived : totalCoverageGiven.toDouble();
}
