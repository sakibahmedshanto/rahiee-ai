class ScheduleCoverageModel {
  final String id;
  final String scheduleId;
  final String requestingEmployeeId;
  final String? coveringEmployeeId;
  final String coverageType;
  final String status;
  final DateTime? coverageStartTime;
  final DateTime? coverageEndTime;
  final double? compensationRate;
  final int emergencyPriority;
  final String reason;
  final String? coveringEmployeeNotes;
  final String? adminNotes;
  final bool requiresAdminApproval;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  ScheduleCoverageModel({
    required this.id,
    required this.scheduleId,
    required this.requestingEmployeeId,
    this.coveringEmployeeId,
    required this.coverageType,
    required this.status,
    this.coverageStartTime,
    this.coverageEndTime,
    this.compensationRate,
    required this.emergencyPriority,
    required this.reason,
    this.coveringEmployeeNotes,
    this.adminNotes,
    required this.requiresAdminApproval,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.expiresAt,
  });

  factory ScheduleCoverageModel.fromMap(Map<String, dynamic> json) {
    return ScheduleCoverageModel(
      id: json['id'],
      scheduleId: json['schedule_id'],
      requestingEmployeeId: json['requesting_employee_id'],
      coveringEmployeeId: json['covering_employee_id'],
      coverageType: json['coverage_type'] ?? 'full',
      status: json['status'] ?? 'open',
      coverageStartTime: json['coverage_start_time'] != null
          ? DateTime.parse(json['coverage_start_time'])
          : null,
      coverageEndTime: json['coverage_end_time'] != null
          ? DateTime.parse(json['coverage_end_time'])
          : null,
      compensationRate: json['compensation_rate']?.toDouble(),
      emergencyPriority: json['emergency_priority'] ?? 0,
      reason: json['reason'] ?? '',
      coveringEmployeeNotes: json['covering_employee_notes'],
      adminNotes: json['admin_notes'],
      requiresAdminApproval: json['requires_admin_approval'] ?? false,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'requesting_employee_id': requestingEmployeeId,
      'covering_employee_id': coveringEmployeeId,
      'coverage_type': coverageType,
      'status': status,
      'coverage_start_time': coverageStartTime?.toIso8601String(),
      'coverage_end_time': coverageEndTime?.toIso8601String(),
      'compensation_rate': compensationRate,
      'emergency_priority': emergencyPriority,
      'reason': reason,
      'covering_employee_notes': coveringEmployeeNotes,
      'admin_notes': adminNotes,
      'requires_admin_approval': requiresAdminApproval,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
