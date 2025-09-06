// ignore_for_file: file_names

class ScheduleSwapModel {
  final String id;
  final String originalScheduleId;
  final String requestingEmployeeId;
  final String targetEmployeeId;
  final String? targetScheduleId;
  final String swapType; // 'direct', 'coverage', 'trade'
  final String? requestReason;
  final bool adminApprovalRequired;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled', 'completed'
  
  // Approval workflow
  final bool approvedByEmployee;
  final bool approvedByTarget;
  final String? approvedByAdmin;
  final DateTime? adminApprovalDate;
  final String? adminNotes;
  
  // Automatic expiry
  final DateTime expiresAt;
  
  // Swap details
  final double compensationOffered;
  final Map<String, dynamic>? swapConditions;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  ScheduleSwapModel({
    required this.id,
    required this.originalScheduleId,
    required this.requestingEmployeeId,
    required this.targetEmployeeId,
    this.targetScheduleId,
    required this.swapType,
    this.requestReason,
    required this.adminApprovalRequired,
    required this.status,
    required this.approvedByEmployee,
    required this.approvedByTarget,
    this.approvedByAdmin,
    this.adminApprovalDate,
    this.adminNotes,
    required this.expiresAt,
    required this.compensationOffered,
    this.swapConditions,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory ScheduleSwapModel.fromMap(Map<String, dynamic> data) {
    return ScheduleSwapModel(
      id: data['id']?.toString() ?? '',
      originalScheduleId: data['original_schedule_id']?.toString() ?? '',
      requestingEmployeeId: data['requesting_employee_id']?.toString() ?? '',
      targetEmployeeId: data['target_employee_id']?.toString() ?? '',
      targetScheduleId: data['target_schedule_id']?.toString(),
      swapType: data['swap_type']?.toString() ?? 'direct',
      requestReason: data['request_reason']?.toString(),
      adminApprovalRequired: data['admin_approval_required'] as bool? ?? true,
      status: data['status']?.toString() ?? 'pending',
      approvedByEmployee: data['approved_by_employee'] as bool? ?? false,
      approvedByTarget: data['approved_by_target'] as bool? ?? false,
      approvedByAdmin: data['approved_by_admin']?.toString(),
      adminApprovalDate: data['admin_approval_date'] != null 
          ? DateTime.parse(data['admin_approval_date']) 
          : null,
      adminNotes: data['admin_notes']?.toString(),
      expiresAt: DateTime.parse(data['expires_at']),
      compensationOffered: (data['compensation_offered'] as num?)?.toDouble() ?? 0.0,
      swapConditions: data['swap_conditions'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      completedAt: data['completed_at'] != null 
          ? DateTime.parse(data['completed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isEmpty ? null : id,
      'original_schedule_id': originalScheduleId,
      'requesting_employee_id': requestingEmployeeId,
      'target_employee_id': targetEmployeeId,
      'target_schedule_id': targetScheduleId,
      'swap_type': swapType,
      'request_reason': requestReason,
      'admin_approval_required': adminApprovalRequired,
      'status': status,
      'approved_by_employee': approvedByEmployee,
      'approved_by_target': approvedByTarget,
      'approved_by_admin': approvedByAdmin,
      'admin_approval_date': adminApprovalDate?.toIso8601String(),
      'admin_notes': adminNotes,
      'expires_at': expiresAt.toIso8601String(),
      'compensation_offered': compensationOffered,
      'swap_conditions': swapConditions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  ScheduleSwapModel copyWith({
    String? id,
    String? originalScheduleId,
    String? requestingEmployeeId,
    String? targetEmployeeId,
    String? targetScheduleId,
    String? swapType,
    String? requestReason,
    bool? adminApprovalRequired,
    String? status,
    bool? approvedByEmployee,
    bool? approvedByTarget,
    String? approvedByAdmin,
    DateTime? adminApprovalDate,
    String? adminNotes,
    DateTime? expiresAt,
    double? compensationOffered,
    Map<String, dynamic>? swapConditions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return ScheduleSwapModel(
      id: id ?? this.id,
      originalScheduleId: originalScheduleId ?? this.originalScheduleId,
      requestingEmployeeId: requestingEmployeeId ?? this.requestingEmployeeId,
      targetEmployeeId: targetEmployeeId ?? this.targetEmployeeId,
      targetScheduleId: targetScheduleId ?? this.targetScheduleId,
      swapType: swapType ?? this.swapType,
      requestReason: requestReason ?? this.requestReason,
      adminApprovalRequired: adminApprovalRequired ?? this.adminApprovalRequired,
      status: status ?? this.status,
      approvedByEmployee: approvedByEmployee ?? this.approvedByEmployee,
      approvedByTarget: approvedByTarget ?? this.approvedByTarget,
      approvedByAdmin: approvedByAdmin ?? this.approvedByAdmin,
      adminApprovalDate: adminApprovalDate ?? this.adminApprovalDate,
      adminNotes: adminNotes ?? this.adminNotes,
      expiresAt: expiresAt ?? this.expiresAt,
      compensationOffered: compensationOffered ?? this.compensationOffered,
      swapConditions: swapConditions ?? this.swapConditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => DateTime.now().isAfter(expiresAt) && isPending;
  
  bool get needsEmployeeApproval => !approvedByEmployee;
  bool get needsTargetApproval => !approvedByTarget;
  bool get needsAdminApproval => adminApprovalRequired && approvedByAdmin == null;
  
  bool get canBeCompleted {
    return approvedByEmployee && 
           approvedByTarget && 
           (!adminApprovalRequired || approvedByAdmin != null);
  }

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        if (needsEmployeeApproval) return 'Waiting for your approval';
        if (needsTargetApproval) return 'Waiting for target approval';
        if (needsAdminApproval) return 'Waiting for admin approval';
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

class ScheduleCoverageModel {
  final String id;
  final String scheduleId;
  final String requestingEmployeeId;
  final String? coveringEmployeeId;
  final String coverageType; // 'full', 'partial', 'emergency'
  final String status; // 'open', 'accepted', 'rejected', 'completed', 'cancelled'
  
  // Coverage details
  final DateTime? coverageStartTime;
  final DateTime? coverageEndTime;
  final double? compensationRate;
  final int emergencyPriority;
  
  // Reason and notes
  final String reason;
  final String? coveringEmployeeNotes;
  final String? adminNotes;
  
  // Approval
  final bool requiresAdminApproval;
  final String? approvedBy;
  final DateTime? approvedAt;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime expiresAt;

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
    required this.expiresAt,
  });

  factory ScheduleCoverageModel.fromMap(Map<String, dynamic> data) {
    return ScheduleCoverageModel(
      id: data['id']?.toString() ?? '',
      scheduleId: data['schedule_id']?.toString() ?? '',
      requestingEmployeeId: data['requesting_employee_id']?.toString() ?? '',
      coveringEmployeeId: data['covering_employee_id']?.toString(),
      coverageType: data['coverage_type']?.toString() ?? 'full',
      status: data['status']?.toString() ?? 'open',
      coverageStartTime: data['coverage_start_time'] != null 
          ? DateTime.parse(data['coverage_start_time']) 
          : null,
      coverageEndTime: data['coverage_end_time'] != null 
          ? DateTime.parse(data['coverage_end_time']) 
          : null,
      compensationRate: (data['compensation_rate'] as num?)?.toDouble(),
      emergencyPriority: data['emergency_priority'] as int? ?? 0,
      reason: data['reason']?.toString() ?? '',
      coveringEmployeeNotes: data['covering_employee_notes']?.toString(),
      adminNotes: data['admin_notes']?.toString(),
      requiresAdminApproval: data['requires_admin_approval'] as bool? ?? false,
      approvedBy: data['approved_by']?.toString(),
      approvedAt: data['approved_at'] != null 
          ? DateTime.parse(data['approved_at']) 
          : null,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      completedAt: data['completed_at'] != null 
          ? DateTime.parse(data['completed_at']) 
          : null,
      expiresAt: DateTime.parse(data['expires_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isEmpty ? null : id,
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
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isOpen => status == 'open';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => DateTime.now().isAfter(expiresAt) && isOpen;
  bool get isEmergency => emergencyPriority > 0;
}
