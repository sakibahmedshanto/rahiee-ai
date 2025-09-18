class AdminDashboardSummaryModel {
  final DateTime date;
  final int totalEmployees;
  final int checkedInToday;
  final int pendingApprovals;
  final int grantedToday;
  final int notGrantedToday;
  final double totalHoursToday;
  final double totalAmountToday;
  final double unpaidAmount;
  final List<DepartmentBreakdownModel> departmentBreakdown;
  final DateTime generatedAt;

  AdminDashboardSummaryModel({
    required this.date,
    required this.totalEmployees,
    required this.checkedInToday,
    required this.pendingApprovals,
    required this.grantedToday,
    required this.notGrantedToday,
    required this.totalHoursToday,
    required this.totalAmountToday,
    required this.unpaidAmount,
    required this.departmentBreakdown,
    required this.generatedAt,
  });

  factory AdminDashboardSummaryModel.fromMap(Map<String, dynamic> json) {
    return AdminDashboardSummaryModel(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      totalEmployees: json['total_employees'] ?? 0,
      checkedInToday: json['checked_in_today'] ?? 0,
      pendingApprovals: json['pending_approvals'] ?? 0,
      grantedToday: json['granted_today'] ?? 0,
      notGrantedToday: json['not_granted_today'] ?? 0,
      totalHoursToday: (json['total_hours_today'] ?? 0.0).toDouble(),
      totalAmountToday: (json['total_amount_today'] ?? 0.0).toDouble(),
      unpaidAmount: (json['unpaid_amount'] ?? 0.0).toDouble(),
      departmentBreakdown: json['department_breakdown'] != null
          ? (json['department_breakdown'] as List)
              .map((dept) => DepartmentBreakdownModel.fromMap(dept))
              .toList()
          : [],
      generatedAt: json['generated_at'] != null ? DateTime.parse(json['generated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'total_employees': totalEmployees,
      'checked_in_today': checkedInToday,
      'pending_approvals': pendingApprovals,
      'granted_today': grantedToday,
      'not_granted_today': notGrantedToday,
      'total_hours_today': totalHoursToday,
      'total_amount_today': totalAmountToday,
      'unpaid_amount': unpaidAmount,
      'department_breakdown': departmentBreakdown.map((dept) => dept.toMap()).toList(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class DepartmentBreakdownModel {
  final String department;
  final int totalEmployees;
  final int checkedIn;
  final int pendingCount;
  final double totalHours;

  DepartmentBreakdownModel({
    required this.department,
    required this.totalEmployees,
    required this.checkedIn,
    required this.pendingCount,
    required this.totalHours,
  });

  factory DepartmentBreakdownModel.fromMap(Map<String, dynamic> json) {
    return DepartmentBreakdownModel(
      department: json['department'] ?? '',
      totalEmployees: json['total_employees'] ?? 0,
      checkedIn: json['checked_in'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'department': department,
      'total_employees': totalEmployees,
      'checked_in': checkedIn,
      'pending_count': pendingCount,
      'total_hours': totalHours,
    };
  }
}
