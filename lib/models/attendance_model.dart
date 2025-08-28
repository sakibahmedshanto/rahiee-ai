// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Factory constructor from Firestore
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      attendanceId: doc.id,
      userId: data['userId'] ?? '',
      scheduleId: data['scheduleId'] ?? '',
      checkInTime: (data['checkInTime'] as Timestamp).toDate(),
      checkOutTime: data['checkOutTime'] != null 
          ? (data['checkOutTime'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'pending_checkout',
      totalWorkingHours: data['totalWorkingHours'] != null
          ? Duration(milliseconds: data['totalWorkingHours'])
          : null,
      checkInPhotoUrl: data['checkInPhotoUrl'],
      checkInLatitude: data['checkInLatitude']?.toDouble(),
      checkInLongitude: data['checkInLongitude']?.toDouble(),
      checkInAddress: data['checkInAddress'],
      mlCheckInResults: data['mlCheckInResults'],
      uniformDetected: data['uniformDetected'] ?? false,
      uniformConfidence: data['uniformConfidence']?.toDouble(),
      checkOutPhotoUrl: data['checkOutPhotoUrl'],
      checkOutLatitude: data['checkOutLatitude']?.toDouble(),
      checkOutLongitude: data['checkOutLongitude']?.toDouble(),
      checkOutAddress: data['checkOutAddress'],
      mlCheckOutResults: data['mlCheckOutResults'],
      isUnusual: data['isUnusual'] ?? false,
      unusualReason: data['unusualReason'],
      unusualFlags: data['unusualFlags'] != null 
          ? List<String>.from(data['unusualFlags']) 
          : null,
      hasAppeal: data['hasAppeal'] ?? false,
      appealDetails: data['appealDetails'] != null
          ? AppealDetails.fromMap(data['appealDetails'])
          : null,
      isApprovedForPayment: data['isApprovedForPayment'] ?? false,
      approvedByAdminId: data['approvedByAdminId'],
      approvalDateTime: data['approvalDateTime'] != null
          ? (data['approvalDateTime'] as Timestamp).toDate()
          : null,
      adminNotes: data['adminNotes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      breaks: data['breaks'] != null
          ? (data['breaks'] as List)
              .map((e) => BreakRecord.fromMap(e))
              .toList()
          : null,
      totalBreakTime: data['totalBreakTime'] != null
          ? Duration(milliseconds: data['totalBreakTime'])
          : null,
      metadata: data['metadata'],
      deviceInfo: data['deviceInfo'],
      appVersion: data['appVersion'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'scheduleId': scheduleId,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null 
          ? Timestamp.fromDate(checkOutTime!) 
          : null,
      'status': status,
      'totalWorkingHours': totalWorkingHours?.inMilliseconds,
      'checkInPhotoUrl': checkInPhotoUrl,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkInAddress': checkInAddress,
      'mlCheckInResults': mlCheckInResults,
      'uniformDetected': uniformDetected,
      'uniformConfidence': uniformConfidence,
      'checkOutPhotoUrl': checkOutPhotoUrl,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkOutAddress': checkOutAddress,
      'mlCheckOutResults': mlCheckOutResults,
      'isUnusual': isUnusual,
      'unusualReason': unusualReason,
      'unusualFlags': unusualFlags,
      'hasAppeal': hasAppeal,
      'appealDetails': appealDetails?.toMap(),
      'isApprovedForPayment': isApprovedForPayment,
      'approvedByAdminId': approvedByAdminId,
      'approvalDateTime': approvalDateTime != null
          ? Timestamp.fromDate(approvalDateTime!)
          : null,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'breaks': breaks?.map((e) => e.toMap()).toList(),
      'totalBreakTime': totalBreakTime?.inMilliseconds,
      'metadata': metadata,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
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
      appealId: map['appealId'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      appealDateTime: (map['appealDateTime'] as Timestamp).toDate(),
      appealStatus: map['appealStatus'] ?? 'pending',
      reviewedByAdminId: map['reviewedByAdminId'],
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      adminResponse: map['adminResponse'],
      supportingDocuments: map['supportingDocuments'] != null
          ? List<String>.from(map['supportingDocuments'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appealId': appealId,
      'reason': reason,
      'description': description,
      'appealDateTime': Timestamp.fromDate(appealDateTime),
      'appealStatus': appealStatus,
      'reviewedByAdminId': reviewedByAdminId,
      'reviewedAt': reviewedAt != null 
          ? Timestamp.fromDate(reviewedAt!) 
          : null,
      'adminResponse': adminResponse,
      'supportingDocuments': supportingDocuments,
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
      breakId: map['breakId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      type: map['type'] ?? '',
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'breakId': breakId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'type': type,
      'reason': reason,
    };
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}
