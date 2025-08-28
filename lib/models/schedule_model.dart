// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String scheduleId;
  final String title;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String createdByAdminId;
  final String assignedUserId;
  final String? actualUserId; // Who actually performed the task (for history tracking)
  final String department; // Department categorization (Restaurant, Kitchen, Management, etc.)
  final String location;
  final double? latitude;
  final double? longitude;
  final String status; // 'active', 'completed', 'cancelled', 'reassigned'
  final Map<String, dynamic>? requirements; // ML requirements, uniform check, etc.
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final bool isActive;
  final List<String>? tags; // For categorization
  final Map<String, dynamic>? customFields; // Future extensibility
  
  // Assignment history tracking
  final List<ScheduleAssignmentHistory>? assignmentHistory;
  
  ScheduleModel({
    required this.scheduleId,
    required this.title,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.createdByAdminId,
    required this.assignedUserId,
    this.actualUserId,
    required this.department,
    required this.location,
    this.latitude,
    this.longitude,
    required this.status,
    this.requirements,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isActive = true,
    this.tags,
    this.customFields,
    this.assignmentHistory,
  });

  // Factory constructor from Firestore
  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      scheduleId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: (data['endDateTime'] as Timestamp).toDate(),
      createdByAdminId: data['createdByAdminId'] ?? '',
      assignedUserId: data['assignedUserId'] ?? '',
      actualUserId: data['actualUserId'],
      department: data['department'] ?? '',
      location: data['location'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      status: data['status'] ?? 'active',
      requirements: data['requirements'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      customFields: data['customFields'],
      assignmentHistory: data['assignmentHistory'] != null
          ? (data['assignmentHistory'] as List)
              .map((e) => ScheduleAssignmentHistory.fromMap(e))
              .toList()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'createdByAdminId': createdByAdminId,
      'assignedUserId': assignedUserId,
      'actualUserId': actualUserId,
      'department': department,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'requirements': requirements,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'isActive': isActive,
      'tags': tags,
      'customFields': customFields,
      'assignmentHistory': assignmentHistory?.map((e) => e.toMap()).toList(),
    };
  }

  // Copy with method for updates
  ScheduleModel copyWith({
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? assignedUserId,
    String? actualUserId,
    String? department,
    String? location,
    double? latitude,
    double? longitude,
    String? status,
    Map<String, dynamic>? requirements,
    DateTime? updatedAt,
    String? notes,
    bool? isActive,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    List<ScheduleAssignmentHistory>? assignmentHistory,
  }) {
    return ScheduleModel(
      scheduleId: scheduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      createdByAdminId: createdByAdminId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      actualUserId: actualUserId ?? this.actualUserId,
      department: department ?? this.department,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      assignmentHistory: assignmentHistory ?? this.assignmentHistory,
    );
  }

  // Calculate duration
  Duration get duration => endDateTime.difference(startDateTime);
  
  // Check if schedule is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDateTime) && 
           now.isBefore(endDateTime) &&
           status == 'active';
  }
}

// Assignment history model for tracking who was assigned when
class ScheduleAssignmentHistory {
  final String assignedUserId;
  final String assignedByAdminId;
  final DateTime assignedAt;
  final String? reason;
  final String action; // 'assigned', 'reassigned', 'completed'

  ScheduleAssignmentHistory({
    required this.assignedUserId,
    required this.assignedByAdminId,
    required this.assignedAt,
    this.reason,
    required this.action,
  });

  factory ScheduleAssignmentHistory.fromMap(Map<String, dynamic> map) {
    return ScheduleAssignmentHistory(
      assignedUserId: map['assignedUserId'] ?? '',
      assignedByAdminId: map['assignedByAdminId'] ?? '',
      assignedAt: (map['assignedAt'] as Timestamp).toDate(),
      reason: map['reason'],
      action: map['action'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedUserId': assignedUserId,
      'assignedByAdminId': assignedByAdminId,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'reason': reason,
      'action': action,
    };
  }
}
