// ignore_for_file: file_names

class TotalSummaryModel {
  final String summaryId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodType; // 'daily', 'weekly', 'monthly', 'yearly'
  
  // Company-wide metrics
  final int totalEmployees;
  final int activeEmployees;
  final Duration totalScheduledHours;
  final Duration totalWorkedHours;
  final Duration totalApprovedHours;
  final Duration totalPaidHours;
  final int totalSchedules;
  final int completedSchedules;
  final int pendingSchedules;
  final int totalAttendances;
  final int approvedAttendances;
  final int unusualAttendances;
  final int appealedAttendances;
  
  // Financial overview
  final double totalPayroll;
  final double pendingPayments;
  final double totalBonuses;
  final double totalDeductions;
  final double averageHourlyRate;
  final Map<String, double>? departmentPayroll; // Department -> Amount
  
  // Performance metrics
  final double overallAttendanceRate;
  final double overallApprovalRate;
  final double averagePunctualityScore;
  final int totalAbsences;
  final double employeeRetentionRate;
  
  // Operational insights
  final Map<String, int>? schedulesByDepartment;
  final Map<String, Duration>? hoursWorkedByDepartment;
  final Map<String, double>? performanceByDepartment;
  final List<TopPerformer>? topPerformers;
  final List<String>? problematicAreas;
  
  // Trends and analytics
  final Map<String, dynamic>? trends; // Various trend data
  final double? growthRate; // Compared to previous period
  final Map<String, dynamic>? insights; // AI-generated business insights
  final Map<String, dynamic>? predictions; // Future projections
  
  // Compliance and audit
  final Map<String, int>? complianceMetrics;
  final List<String>? auditFlags;
  final double overtimePercentage;
  final int policyViolations;
  
  // System health
  final int mlVerificationFailures;
  final int systemErrors;
  final double dataAccuracy;
  final DateTime lastSystemUpdate;
  
  // Administrative data
  final DateTime lastUpdated;
  final String updatedBySystem;
  final bool isFinalized;
  final String? finalizedByAdminId;
  final DateTime? finalizedAt;
  final String? reportGeneratedBy; // For audit trails
  
  // Metadata
  final Map<String, dynamic>? metadata;
  final String? version;

  TotalSummaryModel({
    required this.summaryId,
    required this.periodStart,
    required this.periodEnd,
    required this.periodType,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.totalScheduledHours,
    required this.totalWorkedHours,
    required this.totalApprovedHours,
    required this.totalPaidHours,
    required this.totalSchedules,
    required this.completedSchedules,
    required this.pendingSchedules,
    required this.totalAttendances,
    required this.approvedAttendances,
    required this.unusualAttendances,
    required this.appealedAttendances,
    required this.totalPayroll,
    required this.pendingPayments,
    required this.totalBonuses,
    required this.totalDeductions,
    required this.averageHourlyRate,
    this.departmentPayroll,
    required this.overallAttendanceRate,
    required this.overallApprovalRate,
    required this.averagePunctualityScore,
    required this.totalAbsences,
    required this.employeeRetentionRate,
    this.schedulesByDepartment,
    this.hoursWorkedByDepartment,
    this.performanceByDepartment,
    this.topPerformers,
    this.problematicAreas,
    this.trends,
    this.growthRate,
    this.insights,
    this.predictions,
    this.complianceMetrics,
    this.auditFlags,
    required this.overtimePercentage,
    required this.policyViolations,
    required this.mlVerificationFailures,
    required this.systemErrors,
    required this.dataAccuracy,
    required this.lastSystemUpdate,
    required this.lastUpdated,
    required this.updatedBySystem,
    this.isFinalized = false,
    this.finalizedByAdminId,
    this.finalizedAt,
    this.reportGeneratedBy,
    this.metadata,
    this.version,
  });

  // Factory constructor from Supabase JSON
  factory TotalSummaryModel.fromJson(Map<String, dynamic> data) {
    return TotalSummaryModel(
      summaryId: data['summary_id'] ?? '',
      periodStart: DateTime.parse(data['period_start']),
      periodEnd: DateTime.parse(data['period_end']),
      periodType: data['period_type'] ?? 'daily',
      totalEmployees: data['total_employees'] ?? 0,
      activeEmployees: data['active_employees'] ?? 0,
      totalScheduledHours: Duration(milliseconds: data['total_scheduled_hours'] ?? 0),
      totalWorkedHours: Duration(milliseconds: data['total_worked_hours'] ?? 0),
      totalApprovedHours: Duration(milliseconds: data['total_approved_hours'] ?? 0),
      totalPaidHours: Duration(milliseconds: data['total_paid_hours'] ?? 0),
      totalSchedules: data['total_schedules'] ?? 0,
      completedSchedules: data['completed_schedules'] ?? 0,
      pendingSchedules: data['pending_schedules'] ?? 0,
      totalAttendances: data['total_attendances'] ?? 0,
      approvedAttendances: data['approved_attendances'] ?? 0,
      unusualAttendances: data['unusual_attendances'] ?? 0,
      appealedAttendances: data['appealed_attendances'] ?? 0,
      totalPayroll: data['total_payroll']?.toDouble() ?? 0.0,
      pendingPayments: data['pending_payments']?.toDouble() ?? 0.0,
      totalBonuses: data['total_bonuses']?.toDouble() ?? 0.0,
      totalDeductions: data['total_deductions']?.toDouble() ?? 0.0,
      averageHourlyRate: data['average_hourly_rate']?.toDouble() ?? 0.0,
      departmentPayroll: data['department_payroll'] != null
          ? Map<String, double>.from(data['department_payroll'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      overallAttendanceRate: data['overall_attendance_rate']?.toDouble() ?? 0.0,
      overallApprovalRate: data['overall_approval_rate']?.toDouble() ?? 0.0,
      averagePunctualityScore: data['average_punctuality_score']?.toDouble() ?? 0.0,
      totalAbsences: data['total_absences'] ?? 0,
      employeeRetentionRate: data['employee_retention_rate']?.toDouble() ?? 0.0,
      schedulesByDepartment: data['schedules_by_department'] != null
          ? Map<String, int>.from(data['schedules_by_department'])
          : null,
      hoursWorkedByDepartment: data['hours_worked_by_department'] != null
          ? Map<String, Duration>.from(data['hours_worked_by_department'].map((k, v) => MapEntry(k, Duration(milliseconds: v))))
          : null,
      performanceByDepartment: data['performance_by_department'] != null
          ? Map<String, double>.from(data['performance_by_department'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      topPerformers: data['top_performers'] != null
          ? (data['top_performers'] as List).map((e) => TopPerformer.fromMap(e)).toList()
          : null,
      problematicAreas: data['problematic_areas'] != null
          ? List<String>.from(data['problematic_areas'])
          : null,
      trends: data['trends'],
      growthRate: data['growth_rate']?.toDouble(),
      insights: data['insights'],
      predictions: data['predictions'],
      complianceMetrics: data['compliance_metrics'] != null
          ? Map<String, int>.from(data['compliance_metrics'])
          : null,
      auditFlags: data['audit_flags'] != null
          ? List<String>.from(data['audit_flags'])
          : null,
      overtimePercentage: data['overtime_percentage']?.toDouble() ?? 0.0,
      policyViolations: data['policy_violations'] ?? 0,
      mlVerificationFailures: data['ml_verification_failures'] ?? 0,
      systemErrors: data['system_errors'] ?? 0,
      dataAccuracy: data['data_accuracy']?.toDouble() ?? 100.0,
      lastSystemUpdate: DateTime.parse(data['last_system_update']),
      lastUpdated: DateTime.parse(data['last_updated']),
      updatedBySystem: data['updated_by_system'] ?? 'auto_function',
      isFinalized: data['is_finalized'] ?? false,
      finalizedByAdminId: data['finalized_by_admin_id'],
      finalizedAt: data['finalized_at'] != null
          ? DateTime.parse(data['finalized_at'])
          : null,
      reportGeneratedBy: data['report_generated_by'],
      metadata: data['metadata'],
      version: data['version'],
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'summary_id': summaryId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'period_type': periodType,
      'total_employees': totalEmployees,
      'active_employees': activeEmployees,
      'total_scheduled_hours': totalScheduledHours.inMilliseconds,
      'total_worked_hours': totalWorkedHours.inMilliseconds,
      'total_approved_hours': totalApprovedHours.inMilliseconds,
      'total_paid_hours': totalPaidHours.inMilliseconds,
      'total_schedules': totalSchedules,
      'completed_schedules': completedSchedules,
      'pending_schedules': pendingSchedules,
      'total_attendances': totalAttendances,
      'approved_attendances': approvedAttendances,
      'unusual_attendances': unusualAttendances,
      'appealed_attendances': appealedAttendances,
      'total_payroll': totalPayroll,
      'pending_payments': pendingPayments,
      'total_bonuses': totalBonuses,
      'total_deductions': totalDeductions,
      'average_hourly_rate': averageHourlyRate,
      'department_payroll': departmentPayroll,
      'overall_attendance_rate': overallAttendanceRate,
      'overall_approval_rate': overallApprovalRate,
      'average_punctuality_score': averagePunctualityScore,
      'total_absences': totalAbsences,
      'employee_retention_rate': employeeRetentionRate,
      'schedules_by_department': schedulesByDepartment,
      'hours_worked_by_department': hoursWorkedByDepartment?.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'performance_by_department': performanceByDepartment,
      'top_performers': topPerformers?.map((e) => e.toMap()).toList(),
      'problematic_areas': problematicAreas,
      'trends': trends,
      'growth_rate': growthRate,
      'insights': insights,
      'predictions': predictions,
      'compliance_metrics': complianceMetrics,
      'audit_flags': auditFlags,
      'overtime_percentage': overtimePercentage,
      'policy_violations': policyViolations,
      'ml_verification_failures': mlVerificationFailures,
      'system_errors': systemErrors,
      'data_accuracy': dataAccuracy,
      'last_system_update': lastSystemUpdate.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'updated_by_system': updatedBySystem,
      'is_finalized': isFinalized,
      'finalized_by_admin_id': finalizedByAdminId,
      'finalized_at': finalizedAt?.toIso8601String(),
      'report_generated_by': reportGeneratedBy,
      'metadata': metadata,
      'version': version,
    };
  }

  // Helper methods
  double get overallEfficiency => totalScheduledHours.inMilliseconds > 0
      ? (totalWorkedHours.inMilliseconds / totalScheduledHours.inMilliseconds) * 100
      : 0.0;

  double get payrollCostPerHour => totalWorkedHours.inMilliseconds > 0
      ? totalPayroll / (totalWorkedHours.inMilliseconds / (1000 * 60 * 60))
      : 0.0;

  bool get hasComplianceIssues => 
      policyViolations > 0 || 
      (auditFlags?.isNotEmpty ?? false) || 
      overtimePercentage > 20.0;

  bool get hasSystemIssues => 
      mlVerificationFailures > 0 || 
      systemErrors > 0 || 
      dataAccuracy < 95.0;
}

// Top performer model for tracking high-performing employees
class TopPerformer {
  final String userId;
  final String userName;
  final String department;
  final double performanceScore;
  final Duration hoursWorked;
  final double attendanceRate;
  final String achievementCategory; // 'attendance', 'punctuality', 'hours', 'overall'

  TopPerformer({
    required this.userId,
    required this.userName,
    required this.department,
    required this.performanceScore,
    required this.hoursWorked,
    required this.attendanceRate,
    required this.achievementCategory,
  });

  factory TopPerformer.fromMap(Map<String, dynamic> map) {
    return TopPerformer(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      department: map['department'] ?? '',
      performanceScore: map['performanceScore']?.toDouble() ?? 0.0,
      hoursWorked: Duration(milliseconds: map['hoursWorked'] ?? 0),
      attendanceRate: map['attendanceRate']?.toDouble() ?? 0.0,
      achievementCategory: map['achievementCategory'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'department': department,
      'performanceScore': performanceScore,
      'hoursWorked': hoursWorked.inMilliseconds,
      'attendanceRate': attendanceRate,
      'achievementCategory': achievementCategory,
    };
  }
}
