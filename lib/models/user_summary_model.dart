// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Factory constructor from Firestore
  factory UserSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSummaryModel(
      summaryId: doc.id,
      userId: data['userId'] ?? '',
      periodStart: (data['periodStart'] as Timestamp).toDate(),
      periodEnd: (data['periodEnd'] as Timestamp).toDate(),
      periodType: data['periodType'] ?? 'daily',
      totalScheduledHours: Duration(milliseconds: data['totalScheduledHours'] ?? 0),
      totalWorkedHours: Duration(milliseconds: data['totalWorkedHours'] ?? 0),
      totalApprovedHours: Duration(milliseconds: data['totalApprovedHours'] ?? 0),
      totalPaidHours: Duration(milliseconds: data['totalPaidHours'] ?? 0),
      totalSchedules: data['totalSchedules'] ?? 0,
      completedSchedules: data['completedSchedules'] ?? 0,
      pendingSchedules: data['pendingSchedules'] ?? 0,
      unusualAttendances: data['unusualAttendances'] ?? 0,
      appealedAttendances: data['appealedAttendances'] ?? 0,
      attendanceRate: data['attendanceRate']?.toDouble() ?? 0.0,
      approvalRate: data['approvalRate']?.toDouble() ?? 0.0,
      punctualityScore: data['punctualityScore']?.toDouble() ?? 0.0,
      consecutiveWorkDays: data['consecutiveWorkDays'] ?? 0,
      totalAbsences: data['totalAbsences'] ?? 0,
      totalEarnings: data['totalEarnings']?.toDouble() ?? 0.0,
      pendingPayments: data['pendingPayments']?.toDouble() ?? 0.0,
      hourlyRate: data['hourlyRate']?.toDouble() ?? 0.0,
      bonuses: data['bonuses'] != null 
          ? Map<String, double>.from(data['bonuses'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      deductions: data['deductions'] != null
          ? Map<String, double>.from(data['deductions'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      hoursBreakdown: data['hoursBreakdown'] != null
          ? Map<String, Duration>.from(data['hoursBreakdown'].map((k, v) => MapEntry(k, Duration(milliseconds: v))))
          : null,
      statusBreakdown: data['statusBreakdown'] != null
          ? Map<String, int>.from(data['statusBreakdown'])
          : null,
      topPerformanceAreas: data['topPerformanceAreas'] != null
          ? List<String>.from(data['topPerformanceAreas'])
          : null,
      improvementAreas: data['improvementAreas'] != null
          ? List<String>.from(data['improvementAreas'])
          : null,
      performanceTrends: data['performanceTrends'],
      previousPeriodComparison: data['previousPeriodComparison']?.toDouble(),
      insights: data['insights'],
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      updatedBySystem: data['updatedBySystem'] ?? 'auto_function',
      isFinalized: data['isFinalized'] ?? false,
      finalizedByAdminId: data['finalizedByAdminId'],
      finalizedAt: data['finalizedAt'] != null
          ? (data['finalizedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
      version: data['version'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'periodType': periodType,
      'totalScheduledHours': totalScheduledHours.inMilliseconds,
      'totalWorkedHours': totalWorkedHours.inMilliseconds,
      'totalApprovedHours': totalApprovedHours.inMilliseconds,
      'totalPaidHours': totalPaidHours.inMilliseconds,
      'totalSchedules': totalSchedules,
      'completedSchedules': completedSchedules,
      'pendingSchedules': pendingSchedules,
      'unusualAttendances': unusualAttendances,
      'appealedAttendances': appealedAttendances,
      'attendanceRate': attendanceRate,
      'approvalRate': approvalRate,
      'punctualityScore': punctualityScore,
      'consecutiveWorkDays': consecutiveWorkDays,
      'totalAbsences': totalAbsences,
      'totalEarnings': totalEarnings,
      'pendingPayments': pendingPayments,
      'hourlyRate': hourlyRate,
      'bonuses': bonuses,
      'deductions': deductions,
      'hoursBreakdown': hoursBreakdown?.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'statusBreakdown': statusBreakdown,
      'topPerformanceAreas': topPerformanceAreas,
      'improvementAreas': improvementAreas,
      'performanceTrends': performanceTrends,
      'previousPeriodComparison': previousPeriodComparison,
      'insights': insights,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBySystem': updatedBySystem,
      'isFinalized': isFinalized,
      'finalizedByAdminId': finalizedByAdminId,
      'finalizedAt': finalizedAt != null ? Timestamp.fromDate(finalizedAt!) : null,
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
