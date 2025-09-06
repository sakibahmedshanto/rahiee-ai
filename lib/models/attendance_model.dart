// ignore_for_file: file_names

class AttendanceModel {
  final String attendanceId;
  final String userId;
  final String scheduleId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status; // 'completed', 'pending_checkout', 'unusual', 'appealed', 'rejected', 'approved'
  final Duration? totalWorkingHours;
  
  // Check-in data
  final String? checkInPhotoUrl;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String? checkInAddress;
  final Map<String, dynamic>? mlCheckInResults; // ML verification results
  final bool uniformDetected;
  final double? uniformConfidence;
  
  // Check-out data
  final String? checkOutPhotoUrl;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutAddress;
  final Map<String, dynamic>? mlCheckOutResults;
  
  // Unusual circumstances tracking
  final bool isUnusual;
  final String? unusualReason; // 'ml_failed', 'overtime', 'no_checkout', 'location_mismatch', 'manual_override'
  final List<String>? unusualFlags; // Multiple flags possible
  
  // Appeal system
  final bool hasAppeal;
  final AppealDetails? appealDetails;
  
  // Administrative data
  final bool isApprovedForPayment;
  final String? approvedByAdminId;
  final DateTime? approvalDateTime;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Break tracking (future feature)
  final List<BreakRecord>? breaks;
  final Duration? totalBreakTime;
  
  // Additional metadata
  final Map<String, dynamic>? metadata; // Future extensibility
  final String? deviceInfo;
  final String? appVersion;

  AttendanceModel({
    required this.attendanceId,
    required this.userId,
    required this.scheduleId,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.totalWorkingHours,
    this.checkInPhotoUrl,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInAddress,
    this.mlCheckInResults,
    required this.uniformDetected,
    this.uniformConfidence,
    this.checkOutPhotoUrl,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAddress,
    this.mlCheckOutResults,
    this.isUnusual = false,
    this.unusualReason,
    this.unusualFlags,
    this.hasAppeal = false,
    this.appealDetails,
    this.isApprovedForPayment = false,
    this.approvedByAdminId,
    this.approvalDateTime,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.breaks,
    this.totalBreakTime,
    this.metadata,
    this.deviceInfo,
    this.appVersion,
  });

  // Factory constructor from Supabase JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> data) {
    return AttendanceModel(
      attendanceId: data['id'] ?? '',
      userId: data['employee_id'] ?? '',
      scheduleId: data['schedule_id'] ?? '',
      checkInTime: DateTime.parse(data['check_in_time']),
      checkOutTime: data['check_out_time'] != null 
          ? DateTime.parse(data['check_out_time'])
          : null,
      status: data['status'] ?? 'pending_checkout',
      totalWorkingHours: data['total_hours'] != null
          ? Duration(hours: (data['total_hours'] as num).toInt())
          : null,
      checkInPhotoUrl: data['check_in_photo_url'],
      checkInLatitude: data['check_in_location_lat']?.toDouble(),
      checkInLongitude: data['check_in_location_lng']?.toDouble(),
      checkInAddress: data['check_in_address'],
      mlCheckInResults: data['ml_check_in_results'],
      uniformDetected: data['uniform_detected'] ?? false,
      uniformConfidence: data['uniform_confidence']?.toDouble(),
      checkOutPhotoUrl: data['check_out_photo_url'],
      checkOutLatitude: data['check_out_location_lat']?.toDouble(),
      checkOutLongitude: data['check_out_location_lng']?.toDouble(),
      checkOutAddress: data['check_out_address'],
      mlCheckOutResults: data['ml_check_out_results'],
      isUnusual: data['is_unusual'] ?? false,
      unusualReason: data['unusual_reason'],
      unusualFlags: data['unusual_flags'] != null 
          ? List<String>.from(data['unusual_flags']) 
          : null,
      hasAppeal: data['has_appeal'] ?? false,
      appealDetails: data['appeal_details'] != null
          ? AppealDetails.fromMap(data['appeal_details'])
          : null,
      isApprovedForPayment: data['is_approved_for_payment'] ?? false,
      approvedByAdminId: data['approved_by_admin_id'],
      approvalDateTime: data['approval_date_time'] != null
          ? DateTime.parse(data['approval_date_time'])
          : null,
      adminNotes: data['admin_notes'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      breaks: data['breaks'] != null
          ? (data['breaks'] as List)
              .map((e) => BreakRecord.fromMap(e))
              .toList()
          : null,
      totalBreakTime: data['total_break_time'] != null
          ? Duration(milliseconds: data['total_break_time'])
          : null,
      metadata: data['metadata'],
      deviceInfo: data['device_info'],
      appVersion: data['app_version'],
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': attendanceId,
      'employee_id': userId,
      'schedule_id': scheduleId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
      'total_hours': totalWorkingHours?.inHours,
      'check_in_photo_url': checkInPhotoUrl,
      'check_in_location_lat': checkInLatitude,
      'check_in_location_lng': checkInLongitude,
      'check_in_address': checkInAddress,
      'ml_check_in_results': mlCheckInResults,
      'uniform_detected': uniformDetected,
      'uniform_confidence': uniformConfidence,
      'check_out_photo_url': checkOutPhotoUrl,
      'check_out_location_lat': checkOutLatitude,
      'check_out_location_lng': checkOutLongitude,
      'check_out_address': checkOutAddress,
      'ml_check_out_results': mlCheckOutResults,
      'is_unusual': isUnusual,
      'unusual_reason': unusualReason,
      'unusual_flags': unusualFlags,
      'has_appeal': hasAppeal,
      'appeal_details': appealDetails?.toMap(),
      'is_approved_for_payment': isApprovedForPayment,
      'approved_by_admin_id': approvedByAdminId,
      'approval_date_time': approvalDateTime?.toIso8601String(),
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'breaks': breaks?.map((e) => e.toMap()).toList(),
      'total_break_time': totalBreakTime?.inMilliseconds,
      'metadata': metadata,
      'device_info': deviceInfo,
      'app_version': appVersion,
    };
  }

  // Copy with method
  AttendanceModel copyWith({
    DateTime? checkOutTime,
    String? status,
    Duration? totalWorkingHours,
    String? checkOutPhotoUrl,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? checkOutAddress,
    Map<String, dynamic>? mlCheckOutResults,
    bool? isUnusual,
    String? unusualReason,
    List<String>? unusualFlags,
    bool? hasAppeal,
    AppealDetails? appealDetails,
    bool? isApprovedForPayment,
    String? approvedByAdminId,
    DateTime? approvalDateTime,
    String? adminNotes,
    DateTime? updatedAt,
    List<BreakRecord>? breaks,
    Duration? totalBreakTime,
    Map<String, dynamic>? metadata,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId,
      userId: userId,
      scheduleId: scheduleId,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      totalWorkingHours: totalWorkingHours ?? this.totalWorkingHours,
      checkInPhotoUrl: checkInPhotoUrl,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      checkInAddress: checkInAddress,
      mlCheckInResults: mlCheckInResults,
      uniformDetected: uniformDetected,
      uniformConfidence: uniformConfidence,
      checkOutPhotoUrl: checkOutPhotoUrl ?? this.checkOutPhotoUrl,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkOutAddress: checkOutAddress ?? this.checkOutAddress,
      mlCheckOutResults: mlCheckOutResults ?? this.mlCheckOutResults,
      isUnusual: isUnusual ?? this.isUnusual,
      unusualReason: unusualReason ?? this.unusualReason,
      unusualFlags: unusualFlags ?? this.unusualFlags,
      hasAppeal: hasAppeal ?? this.hasAppeal,
      appealDetails: appealDetails ?? this.appealDetails,
      isApprovedForPayment: isApprovedForPayment ?? this.isApprovedForPayment,
      approvedByAdminId: approvedByAdminId ?? this.approvedByAdminId,
      approvalDateTime: approvalDateTime ?? this.approvalDateTime,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      breaks: breaks ?? this.breaks,
      totalBreakTime: totalBreakTime ?? this.totalBreakTime,
      metadata: metadata ?? this.metadata,
      deviceInfo: deviceInfo,
      appVersion: appVersion,
    );
  }

  // Helper methods
  bool get isCheckedOut => checkOutTime != null;
  bool get isOvertime => totalWorkingHours != null && totalWorkingHours!.inHours > 10;
  bool get isEligibleForPayment => status == 'completed' && isApprovedForPayment && !isUnusual;
  Duration get actualWorkingTime => totalWorkingHours ?? Duration.zero;
}

// Appeal details model
class AppealDetails {
  final String appealId;
  final String reason;
  final String description;
  final DateTime appealDateTime;
  final String appealStatus; // 'pending', 'approved', 'rejected'
  final String? reviewedByAdminId;
  final DateTime? reviewedAt;
  final String? adminResponse;
  final List<String>? supportingDocuments; // URLs to supporting files

  AppealDetails({
    required this.appealId,
    required this.reason,
    required this.description,
    required this.appealDateTime,
    this.appealStatus = 'pending',
    this.reviewedByAdminId,
    this.reviewedAt,
    this.adminResponse,
    this.supportingDocuments,
  });

  factory AppealDetails.fromMap(Map<String, dynamic> map) {
    return AppealDetails(
      appealId: map['appeal_id'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      appealDateTime: DateTime.parse(map['appeal_date_time']),
      appealStatus: map['appeal_status'] ?? 'pending',
      reviewedByAdminId: map['reviewed_by_admin_id'],
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'])
          : null,
      adminResponse: map['admin_response'],
      supportingDocuments: map['supporting_documents'] != null
          ? List<String>.from(map['supporting_documents'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appeal_id': appealId,
      'reason': reason,
      'description': description,
      'appeal_date_time': appealDateTime.toIso8601String(),
      'appeal_status': appealStatus,
      'reviewed_by_admin_id': reviewedByAdminId,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'admin_response': adminResponse,
      'supporting_documents': supportingDocuments,
    };
  }
}

// Break record model (future feature)
class BreakRecord {
  final String breakId;
  final DateTime startTime;
  final DateTime? endTime;
  final String type; // 'lunch', 'short', 'sick', 'emergency'
  final String? reason;

  BreakRecord({
    required this.breakId,
    required this.startTime,
    this.endTime,
    required this.type,
    this.reason,
  });

  factory BreakRecord.fromMap(Map<String, dynamic> map) {
    return BreakRecord(
      breakId: map['break_id'] ?? '',
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'])
          : null,
      type: map['type'] ?? '',
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'break_id': breakId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'type': type,
      'reason': reason,
    };
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}
