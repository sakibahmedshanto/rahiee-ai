// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Factory constructor from Firestore
  factory TotalSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TotalSummaryModel(
      summaryId: doc.id,
      periodStart: (data['periodStart'] as Timestamp).toDate(),
      periodEnd: (data['periodEnd'] as Timestamp).toDate(),
      periodType: data['periodType'] ?? 'daily',
      totalEmployees: data['totalEmployees'] ?? 0,
      activeEmployees: data['activeEmployees'] ?? 0,
      totalScheduledHours: Duration(milliseconds: data['totalScheduledHours'] ?? 0),
      totalWorkedHours: Duration(milliseconds: data['totalWorkedHours'] ?? 0),
      totalApprovedHours: Duration(milliseconds: data['totalApprovedHours'] ?? 0),
      totalPaidHours: Duration(milliseconds: data['totalPaidHours'] ?? 0),
      totalSchedules: data['totalSchedules'] ?? 0,
      completedSchedules: data['completedSchedules'] ?? 0,
      pendingSchedules: data['pendingSchedules'] ?? 0,
      totalAttendances: data['totalAttendances'] ?? 0,
      approvedAttendances: data['approvedAttendances'] ?? 0,
      unusualAttendances: data['unusualAttendances'] ?? 0,
      appealedAttendances: data['appealedAttendances'] ?? 0,
      totalPayroll: data['totalPayroll']?.toDouble() ?? 0.0,
      pendingPayments: data['pendingPayments']?.toDouble() ?? 0.0,
      totalBonuses: data['totalBonuses']?.toDouble() ?? 0.0,
      totalDeductions: data['totalDeductions']?.toDouble() ?? 0.0,
      averageHourlyRate: data['averageHourlyRate']?.toDouble() ?? 0.0,
      departmentPayroll: data['departmentPayroll'] != null
          ? Map<String, double>.from(data['departmentPayroll'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      overallAttendanceRate: data['overallAttendanceRate']?.toDouble() ?? 0.0,
      overallApprovalRate: data['overallApprovalRate']?.toDouble() ?? 0.0,
      averagePunctualityScore: data['averagePunctualityScore']?.toDouble() ?? 0.0,
      totalAbsences: data['totalAbsences'] ?? 0,
      employeeRetentionRate: data['employeeRetentionRate']?.toDouble() ?? 0.0,
      schedulesByDepartment: data['schedulesByDepartment'] != null
          ? Map<String, int>.from(data['schedulesByDepartment'])
          : null,
      hoursWorkedByDepartment: data['hoursWorkedByDepartment'] != null
          ? Map<String, Duration>.from(data['hoursWorkedByDepartment'].map((k, v) => MapEntry(k, Duration(milliseconds: v))))
          : null,
      performanceByDepartment: data['performanceByDepartment'] != null
          ? Map<String, double>.from(data['performanceByDepartment'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      topPerformers: data['topPerformers'] != null
          ? (data['topPerformers'] as List).map((e) => TopPerformer.fromMap(e)).toList()
          : null,
      problematicAreas: data['problematicAreas'] != null
          ? List<String>.from(data['problematicAreas'])
          : null,
      trends: data['trends'],
      growthRate: data['growthRate']?.toDouble(),
      insights: data['insights'],
      predictions: data['predictions'],
      complianceMetrics: data['complianceMetrics'] != null
          ? Map<String, int>.from(data['complianceMetrics'])
          : null,
      auditFlags: data['auditFlags'] != null
          ? List<String>.from(data['auditFlags'])
          : null,
      overtimePercentage: data['overtimePercentage']?.toDouble() ?? 0.0,
      policyViolations: data['policyViolations'] ?? 0,
      mlVerificationFailures: data['mlVerificationFailures'] ?? 0,
      systemErrors: data['systemErrors'] ?? 0,
      dataAccuracy: data['dataAccuracy']?.toDouble() ?? 100.0,
      lastSystemUpdate: (data['lastSystemUpdate'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      updatedBySystem: data['updatedBySystem'] ?? 'auto_function',
      isFinalized: data['isFinalized'] ?? false,
      finalizedByAdminId: data['finalizedByAdminId'],
      finalizedAt: data['finalizedAt'] != null
          ? (data['finalizedAt'] as Timestamp).toDate()
          : null,
      reportGeneratedBy: data['reportGeneratedBy'],
      metadata: data['metadata'],
      version: data['version'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'periodType': periodType,
      'totalEmployees': totalEmployees,
      'activeEmployees': activeEmployees,
      'totalScheduledHours': totalScheduledHours.inMilliseconds,
      'totalWorkedHours': totalWorkedHours.inMilliseconds,
      'totalApprovedHours': totalApprovedHours.inMilliseconds,
      'totalPaidHours': totalPaidHours.inMilliseconds,
      'totalSchedules': totalSchedules,
      'completedSchedules': completedSchedules,
      'pendingSchedules': pendingSchedules,
      'totalAttendances': totalAttendances,
      'approvedAttendances': approvedAttendances,
      'unusualAttendances': unusualAttendances,
      'appealedAttendances': appealedAttendances,
      'totalPayroll': totalPayroll,
      'pendingPayments': pendingPayments,
      'totalBonuses': totalBonuses,
      'totalDeductions': totalDeductions,
      'averageHourlyRate': averageHourlyRate,
      'departmentPayroll': departmentPayroll,
      'overallAttendanceRate': overallAttendanceRate,
      'overallApprovalRate': overallApprovalRate,
      'averagePunctualityScore': averagePunctualityScore,
      'totalAbsences': totalAbsences,
      'employeeRetentionRate': employeeRetentionRate,
      'schedulesByDepartment': schedulesByDepartment,
      'hoursWorkedByDepartment': hoursWorkedByDepartment?.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'performanceByDepartment': performanceByDepartment,
      'topPerformers': topPerformers?.map((e) => e.toMap()).toList(),
      'problematicAreas': problematicAreas,
      'trends': trends,
      'growthRate': growthRate,
      'insights': insights,
      'predictions': predictions,
      'complianceMetrics': complianceMetrics,
      'auditFlags': auditFlags,
      'overtimePercentage': overtimePercentage,
      'policyViolations': policyViolations,
      'mlVerificationFailures': mlVerificationFailures,
      'systemErrors': systemErrors,
      'dataAccuracy': dataAccuracy,
      'lastSystemUpdate': Timestamp.fromDate(lastSystemUpdate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBySystem': updatedBySystem,
      'isFinalized': isFinalized,
      'finalizedByAdminId': finalizedByAdminId,
      'finalizedAt': finalizedAt != null ? Timestamp.fromDate(finalizedAt!) : null,
      'reportGeneratedBy': reportGeneratedBy,
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
