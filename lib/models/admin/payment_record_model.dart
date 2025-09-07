class PaymentRecordModel {
  final String id;
  final String? employeeId;
  final DateTime paymentPeriodStart;
  final DateTime paymentPeriodEnd;
  final double totalHours;
  final double grantedHours;
  final double regularAmount;
  final double overtimeAmount;
  final double bonusAmount;
  final double deductionAmount;
  final double grossAmount;
  final double netAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String? paymentReference;
  final DateTime? paymentDate;
  final String? processedBy;
  final String? approvedBy;
  final String? adminNotes;
  final List<String>? attendanceIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentRecordModel({
    required this.id,
    this.employeeId,
    required this.paymentPeriodStart,
    required this.paymentPeriodEnd,
    required this.totalHours,
    required this.grantedHours,
    required this.regularAmount,
    required this.overtimeAmount,
    required this.bonusAmount,
    required this.deductionAmount,
    required this.grossAmount,
    required this.netAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentReference,
    this.paymentDate,
    this.processedBy,
    this.approvedBy,
    this.adminNotes,
    this.attendanceIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentRecordModel.fromMap(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'],
      employeeId: json['employee_id'],
      paymentPeriodStart: DateTime.parse(json['payment_period_start']),
      paymentPeriodEnd: DateTime.parse(json['payment_period_end']),
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
      grantedHours: (json['granted_hours'] ?? 0.0).toDouble(),
      regularAmount: (json['regular_amount'] ?? 0.0).toDouble(),
      overtimeAmount: (json['overtime_amount'] ?? 0.0).toDouble(),
      bonusAmount: (json['bonus_amount'] ?? 0.0).toDouble(),
      deductionAmount: (json['deduction_amount'] ?? 0.0).toDouble(),
      grossAmount: (json['gross_amount'] ?? 0.0).toDouble(),
      netAmount: (json['net_amount'] ?? 0.0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'bank_transfer',
      paymentReference: json['payment_reference'],
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
      processedBy: json['processed_by'],
      approvedBy: json['approved_by'],
      adminNotes: json['admin_notes'],
      attendanceIds: json['attendance_ids'] != null 
          ? List<String>.from(json['attendance_ids']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'payment_period_start': paymentPeriodStart.toIso8601String(),
      'payment_period_end': paymentPeriodEnd.toIso8601String(),
      'total_hours': totalHours,
      'granted_hours': grantedHours,
      'regular_amount': regularAmount,
      'overtime_amount': overtimeAmount,
      'bonus_amount': bonusAmount,
      'deduction_amount': deductionAmount,
      'gross_amount': grossAmount,
      'net_amount': netAmount,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'payment_date': paymentDate?.toIso8601String(),
      'processed_by': processedBy,
      'approved_by': approvedBy,
      'admin_notes': adminNotes,
      'attendance_ids': attendanceIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
