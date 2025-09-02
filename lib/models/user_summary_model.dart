// ignore_for_file: file_names

class UserSummaryModel {
  final String summaryId;
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodType; // 'daily', 'weekly', 'monthly', 'yearly'
  
  // Working hours summary
  final Duration totalScheduledHours;
  final Duration totalWorkedHours;
  final Duration totalApprovedHours;
  final Duration totalPaidHours;
  final int totalSchedules;
  final int completedSchedules;
  final int pendingSchedules;
  final int unusualAttendances;
  final int appealedAttendances;
  
  // Performance metrics
  final double attendanceRate; // Percentage of scheduled hours actually worked
  final double approvalRate; // Percentage of worked hours approved for payment
  final double punctualityScore; // Custom score based on check-in timing
  final int consecutiveWorkDays;
  final int totalAbsences;
  
  // Financial summary
  final double totalEarnings;
  final double pendingPayments;
  final double hourlyRate;
  final Map<String, double>? bonuses; // Type -> Amount
  final Map<String, double>? deductions; // Type -> Amount
  
  // Detailed breakdowns
  final Map<String, Duration>? hoursBreakdown; // 'regular', 'overtime', 'holiday', etc.
  final Map<String, int>? statusBreakdown; // Count by attendance status
  final List<String>? topPerformanceAreas;
  final List<String>? improvementAreas;
  
  // Trends and analytics
  final Map<String, dynamic>? performanceTrends;
  final double? previousPeriodComparison;
  final Map<String, dynamic>? insights; // AI-generated insights about performance
  
  // Administrative data
  final DateTime lastUpdated;
  final String updatedBySystem; // 'auto_function', 'admin_manual'
  final bool isFinalized; // Whether this summary is locked for payroll
  final String? finalizedByAdminId;
  final DateTime? finalizedAt;
  
  // Metadata
  final Map<String, dynamic>? metadata;
  final String? version; // Schema version for future migrations

  UserSummaryModel({
    required this.summaryId,
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.periodType,
    required this.totalScheduledHours,
    required this.totalWorkedHours,
    required this.totalApprovedHours,
    required this.totalPaidHours,
    required this.totalSchedules,
    required this.completedSchedules,
    required this.pendingSchedules,
    required this.unusualAttendances,
    required this.appealedAttendances,
    required this.attendanceRate,
    required this.approvalRate,
    required this.punctualityScore,
    required this.consecutiveWorkDays,
    required this.totalAbsences,
    required this.totalEarnings,
    required this.pendingPayments,
    required this.hourlyRate,
    this.bonuses,
    this.deductions,
    this.hoursBreakdown,
    this.statusBreakdown,
    this.topPerformanceAreas,
    this.improvementAreas,
    this.performanceTrends,
    this.previousPeriodComparison,
    this.insights,
    required this.lastUpdated,
    required this.updatedBySystem,
    this.isFinalized = false,
    this.finalizedByAdminId,
    this.finalizedAt,
    this.metadata,
    this.version,
  });

  // Factory constructor from Supabase JSON
  factory UserSummaryModel.fromJson(Map<String, dynamic> data) {
    return UserSummaryModel(
      summaryId: data['summary_id'] ?? '',
      userId: data['user_id'] ?? '',
      periodStart: DateTime.parse(data['period_start']),
      periodEnd: DateTime.parse(data['period_end']),
      periodType: data['period_type'] ?? 'daily',
      totalScheduledHours: Duration(milliseconds: data['total_scheduled_hours'] ?? 0),
      totalWorkedHours: Duration(milliseconds: data['total_worked_hours'] ?? 0),
      totalApprovedHours: Duration(milliseconds: data['total_approved_hours'] ?? 0),
      totalPaidHours: Duration(milliseconds: data['total_paid_hours'] ?? 0),
      totalSchedules: data['total_schedules'] ?? 0,
      completedSchedules: data['completed_schedules'] ?? 0,
      pendingSchedules: data['pending_schedules'] ?? 0,
      unusualAttendances: data['unusual_attendances'] ?? 0,
      appealedAttendances: data['appealed_attendances'] ?? 0,
      attendanceRate: data['attendance_rate']?.toDouble() ?? 0.0,
      approvalRate: data['approval_rate']?.toDouble() ?? 0.0,
      punctualityScore: data['punctuality_score']?.toDouble() ?? 0.0,
      consecutiveWorkDays: data['consecutive_work_days'] ?? 0,
      totalAbsences: data['total_absences'] ?? 0,
      totalEarnings: data['total_earnings']?.toDouble() ?? 0.0,
      pendingPayments: data['pending_payments']?.toDouble() ?? 0.0,
      hourlyRate: data['hourly_rate']?.toDouble() ?? 0.0,
      bonuses: data['bonuses'] != null 
          ? Map<String, double>.from(data['bonuses'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      deductions: data['deductions'] != null
          ? Map<String, double>.from(data['deductions'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      hoursBreakdown: data['hours_breakdown'] != null
          ? Map<String, Duration>.from(data['hours_breakdown'].map((k, v) => MapEntry(k, Duration(milliseconds: v))))
          : null,
      statusBreakdown: data['status_breakdown'] != null
          ? Map<String, int>.from(data['status_breakdown'])
          : null,
      topPerformanceAreas: data['top_performance_areas'] != null
          ? List<String>.from(data['top_performance_areas'])
          : null,
      improvementAreas: data['improvement_areas'] != null
          ? List<String>.from(data['improvement_areas'])
          : null,
      performanceTrends: data['performance_trends'],
      previousPeriodComparison: data['previous_period_comparison']?.toDouble(),
      insights: data['insights'],
      lastUpdated: DateTime.parse(data['last_updated']),
      updatedBySystem: data['updated_by_system'] ?? 'auto_function',
      isFinalized: data['is_finalized'] ?? false,
      finalizedByAdminId: data['finalized_by_admin_id'],
      finalizedAt: data['finalized_at'] != null
          ? DateTime.parse(data['finalized_at'])
          : null,
      metadata: data['metadata'],
      version: data['version'],
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'summary_id': summaryId,
      'user_id': userId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'period_type': periodType,
      'total_scheduled_hours': totalScheduledHours.inMilliseconds,
      'total_worked_hours': totalWorkedHours.inMilliseconds,
      'total_approved_hours': totalApprovedHours.inMilliseconds,
      'total_paid_hours': totalPaidHours.inMilliseconds,
      'total_schedules': totalSchedules,
      'completed_schedules': completedSchedules,
      'pending_schedules': pendingSchedules,
      'unusual_attendances': unusualAttendances,
      'appealed_attendances': appealedAttendances,
      'attendance_rate': attendanceRate,
      'approval_rate': approvalRate,
      'punctuality_score': punctualityScore,
      'consecutive_work_days': consecutiveWorkDays,
      'total_absences': totalAbsences,
      'total_earnings': totalEarnings,
      'pending_payments': pendingPayments,
      'hourly_rate': hourlyRate,
      'bonuses': bonuses,
      'deductions': deductions,
      'hours_breakdown': hoursBreakdown?.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'status_breakdown': statusBreakdown,
      'top_performance_areas': topPerformanceAreas,
      'improvement_areas': improvementAreas,
      'performance_trends': performanceTrends,
      'previous_period_comparison': previousPeriodComparison,
      'insights': insights,
      'last_updated': lastUpdated.toIso8601String(),
      'updated_by_system': updatedBySystem,
      'is_finalized': isFinalized,
      'finalized_by_admin_id': finalizedByAdminId,
      'finalized_at': finalizedAt?.toIso8601String(),
      'metadata': metadata,
      'version': version,
    };
  }

  // Copy with method
  UserSummaryModel copyWith({
    Duration? totalScheduledHours,
    Duration? totalWorkedHours,
    Duration? totalApprovedHours,
    Duration? totalPaidHours,
    int? totalSchedules,
    int? completedSchedules,
    int? pendingSchedules,
    int? unusualAttendances,
    int? appealedAttendances,
    double? attendanceRate,
    double? approvalRate,
    double? punctualityScore,
    int? consecutiveWorkDays,
    int? totalAbsences,
    double? totalEarnings,
    double? pendingPayments,
    double? hourlyRate,
    Map<String, double>? bonuses,
    Map<String, double>? deductions,
    Map<String, Duration>? hoursBreakdown,
    Map<String, int>? statusBreakdown,
    List<String>? topPerformanceAreas,
    List<String>? improvementAreas,
    Map<String, dynamic>? performanceTrends,
    double? previousPeriodComparison,
    Map<String, dynamic>? insights,
    DateTime? lastUpdated,
    String? updatedBySystem,
    bool? isFinalized,
    String? finalizedByAdminId,
    DateTime? finalizedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserSummaryModel(
      summaryId: summaryId,
      userId: userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      periodType: periodType,
      totalScheduledHours: totalScheduledHours ?? this.totalScheduledHours,
      totalWorkedHours: totalWorkedHours ?? this.totalWorkedHours,
      totalApprovedHours: totalApprovedHours ?? this.totalApprovedHours,
      totalPaidHours: totalPaidHours ?? this.totalPaidHours,
      totalSchedules: totalSchedules ?? this.totalSchedules,
      completedSchedules: completedSchedules ?? this.completedSchedules,
      pendingSchedules: pendingSchedules ?? this.pendingSchedules,
      unusualAttendances: unusualAttendances ?? this.unusualAttendances,
      appealedAttendances: appealedAttendances ?? this.appealedAttendances,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      approvalRate: approvalRate ?? this.approvalRate,
      punctualityScore: punctualityScore ?? this.punctualityScore,
      consecutiveWorkDays: consecutiveWorkDays ?? this.consecutiveWorkDays,
      totalAbsences: totalAbsences ?? this.totalAbsences,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bonuses: bonuses ?? this.bonuses,
      deductions: deductions ?? this.deductions,
      hoursBreakdown: hoursBreakdown ?? this.hoursBreakdown,
      statusBreakdown: statusBreakdown ?? this.statusBreakdown,
      topPerformanceAreas: topPerformanceAreas ?? this.topPerformanceAreas,
      improvementAreas: improvementAreas ?? this.improvementAreas,
      performanceTrends: performanceTrends ?? this.performanceTrends,
      previousPeriodComparison: previousPeriodComparison ?? this.previousPeriodComparison,
      insights: insights ?? this.insights,
      lastUpdated: lastUpdated ?? DateTime.now(),
      updatedBySystem: updatedBySystem ?? this.updatedBySystem,
      isFinalized: isFinalized ?? this.isFinalized,
      finalizedByAdminId: finalizedByAdminId ?? this.finalizedByAdminId,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      metadata: metadata ?? this.metadata,
      version: version,
    );
  }

  // Helper methods
  double get overtimeHours => 
      totalWorkedHours.inMilliseconds > totalScheduledHours.inMilliseconds
          ? (totalWorkedHours.inMilliseconds - totalScheduledHours.inMilliseconds) / (1000 * 60 * 60)
          : 0.0;

  double get efficiency => totalScheduledHours.inMilliseconds > 0
      ? (totalWorkedHours.inMilliseconds / totalScheduledHours.inMilliseconds) * 100
      : 0.0;

  bool get hasOutstandingIssues => unusualAttendances > 0 || appealedAttendances > 0;
  
  Duration get unpaidHours => Duration(
    milliseconds: totalApprovedHours.inMilliseconds - totalPaidHours.inMilliseconds
  );
}
