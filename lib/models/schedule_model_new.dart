// ignore_for_file: file_names

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

  // Factory constructor from Supabase map
  factory ScheduleModel.fromMap(Map<String, dynamic> data) {
    return ScheduleModel(
      scheduleId: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      startDateTime: DateTime.parse(data['start_date_time']),
      endDateTime: DateTime.parse(data['end_date_time']),
      createdByAdminId: data['created_by_admin_id']?.toString() ?? '',
      assignedUserId: data['assigned_user_id']?.toString() ?? '',
      actualUserId: data['actual_user_id']?.toString(),
      department: data['department']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      status: data['status']?.toString() ?? 'active',
      requirements: data['requirements'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      notes: data['notes']?.toString(),
      isActive: data['is_active'] as bool? ?? true,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      customFields: data['custom_fields'] as Map<String, dynamic>?,
      assignmentHistory: data['assignment_history'] != null
          ? (data['assignment_history'] as List)
              .map((e) => ScheduleAssignmentHistory.fromMap(e))
              .toList()
          : null,
    );
  }

  // Convert to Supabase map
  Map<String, dynamic> toMap() {
    return {
      'id': scheduleId.isEmpty ? null : scheduleId, // Let Supabase generate if empty
      'title': title,
      'description': description,
      'start_date_time': startDateTime.toIso8601String(),
      'end_date_time': endDateTime.toIso8601String(),
      'created_by_admin_id': createdByAdminId,
      'assigned_user_id': assignedUserId,
      'actual_user_id': actualUserId,
      'department': department,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'requirements': requirements,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'is_active': isActive,
      'tags': tags,
      'custom_fields': customFields,
      'assignment_history': assignmentHistory?.map((e) => e.toMap()).toList(),
    };
  }

  // Copy with method for updates
  ScheduleModel copyWith({
    String? scheduleId,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? createdByAdminId,
    String? assignedUserId,
    String? actualUserId,
    String? department,
    String? location,
    double? latitude,
    double? longitude,
    String? status,
    Map<String, dynamic>? requirements,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isActive,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    List<ScheduleAssignmentHistory>? assignmentHistory,
  }) {
    return ScheduleModel(
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      actualUserId: actualUserId ?? this.actualUserId,
      department: department ?? this.department,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      assignmentHistory: assignmentHistory ?? this.assignmentHistory,
    );
  }

  @override
  String toString() {
    return 'ScheduleModel(id: $scheduleId, title: $title, assigned: $assignedUserId, department: $department)';
  }
}

// Assignment history class for tracking who was assigned vs who actually did the work
class ScheduleAssignmentHistory {
  final String originalAssigneeId;
  final String? actualWorkerId;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final String? reassignmentReason;
  final String? notes;

  ScheduleAssignmentHistory({
    required this.originalAssigneeId,
    this.actualWorkerId,
    required this.assignedAt,
    this.completedAt,
    this.reassignmentReason,
    this.notes,
  });

  factory ScheduleAssignmentHistory.fromMap(Map<String, dynamic> data) {
    return ScheduleAssignmentHistory(
      originalAssigneeId: data['original_assignee_id']?.toString() ?? '',
      actualWorkerId: data['actual_worker_id']?.toString(),
      assignedAt: DateTime.parse(data['assigned_at']),
      completedAt: data['completed_at'] != null ? DateTime.parse(data['completed_at']) : null,
      reassignmentReason: data['reassignment_reason']?.toString(),
      notes: data['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'original_assignee_id': originalAssigneeId,
      'actual_worker_id': actualWorkerId,
      'assigned_at': assignedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'reassignment_reason': reassignmentReason,
      'notes': notes,
    };
  }
}
