class AttendanceAuditModel {
  final String id;
  final String? attendanceId;
  final String? employeeId;
  final String action;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? changedBy;
  final String? changeReason;
  final String? ipAddress;
  final String? userAgent;
  final DateTime changedAt;

  AttendanceAuditModel({
    required this.id,
    this.attendanceId,
    this.employeeId,
    required this.action,
    this.oldValues,
    this.newValues,
    this.changedBy,
    this.changeReason,
    this.ipAddress,
    this.userAgent,
    required this.changedAt,
  });

  factory AttendanceAuditModel.fromMap(Map<String, dynamic> json) {
    return AttendanceAuditModel(
      id: json['id'],
      attendanceId: json['attendance_id'],
      employeeId: json['employee_id'],
      action: json['action'],
      oldValues: json['old_values'],
      newValues: json['new_values'],
      changedBy: json['changed_by'],
      changeReason: json['change_reason'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      changedAt: DateTime.parse(json['changed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attendance_id': attendanceId,
      'employee_id': employeeId,
      'action': action,
      'old_values': oldValues,
      'new_values': newValues,
      'changed_by': changedBy,
      'change_reason': changeReason,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'changed_at': changedAt.toIso8601String(),
    };
  }
}
