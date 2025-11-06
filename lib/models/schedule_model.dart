// ignore_for_file: file_names

import '../utils/timezone_utils.dart';

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
  
  // Timezone-aware status fields
  final String? scheduleStatus; // 'upcoming', 'ready_to_checkin', 'in_progress', 'completed', 'expired'
  final String? workStatus; // 'upcoming', 'ready_to_checkin', 'in_progress', 'completed', 'expired'
  final bool? canCheckIn;
  final bool? canCheckOut;
  final bool? hasCheckedIn;
  final bool? hasCheckedOut;
  final bool? isExpired;
  final bool? isCompleted;
  final bool? isLate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? actualDurationHours;
  final double? timeUntilStartSeconds;
  final double? timeSinceEndSeconds;
  final String? attendanceId;
  final String? attendanceStatus;
  final bool? wearingUniform;
  final double? uniformConfidence;
  
  // Assignment information
  final DateTime? assignedAt;
  final String? assignmentNotes;
  final String? assignmentStatus;
  final int? currentParticipants;
  final bool? isMultiUser;
  final double? durationHours;
  
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
    
    // Timezone-aware status fields
    this.scheduleStatus,
    this.workStatus,
    this.canCheckIn,
    this.canCheckOut,
    this.hasCheckedIn,
    this.hasCheckedOut,
    this.isExpired,
    this.isCompleted,
    this.isLate,
    this.checkInTime,
    this.checkOutTime,
    this.actualDurationHours,
    this.timeUntilStartSeconds,
    this.timeSinceEndSeconds,
    this.attendanceId,
    this.attendanceStatus,
    this.wearingUniform,
    this.uniformConfidence,
    
    // Assignment information
    this.assignedAt,
    this.assignmentNotes,
    this.assignmentStatus,
    this.currentParticipants,
    this.isMultiUser,
    this.durationHours,
  });

  // Factory constructor from Supabase map
  factory ScheduleModel.fromMap(Map<String, dynamic> data) {
    // Handle both direct database response and RPC response
    final id = data['id']?.toString() ?? data['schedule_id']?.toString() ?? '';
    final statusValue = data['status']?.toString() ?? data['schedule_status']?.toString() ?? 'active';
    
    // Parse dates safely with timezone handling
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        // Use universal timezone parsing
        final parsed = TimezoneUtils.parseToLocal(value);
        return parsed ?? DateTime.now();
      }
      return DateTime.now();
    }
    
    return ScheduleModel(
      scheduleId: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      startDateTime: parseDateTime(data['start_date_time']),
      endDateTime: parseDateTime(data['end_date_time']),
      createdByAdminId: data['created_by_admin_id']?.toString() ?? data['created_by']?.toString() ?? '',
      assignedUserId: data['assigned_user_id']?.toString() ?? '',
      actualUserId: data['actual_user_id']?.toString(),
      department: data['department']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      status: statusValue,
      requirements: data['requirements'] as Map<String, dynamic>?,
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
      notes: data['notes']?.toString(),
      isActive: data['is_active'] as bool? ?? true,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      customFields: data['custom_fields'] as Map<String, dynamic>?,
      
      // Timezone-aware status fields
      scheduleStatus: data['schedule_status']?.toString(),
      workStatus: data['work_status']?.toString(),
      canCheckIn: data['can_check_in'] as bool?,
      canCheckOut: data['can_check_out'] as bool?,
      hasCheckedIn: data['has_checked_in'] as bool?,
      hasCheckedOut: data['has_checked_out'] as bool?,
      isExpired: data['is_expired'] as bool?,
      isCompleted: data['is_completed'] as bool?,
      isLate: data['is_late'] as bool?,
      checkInTime: TimezoneUtils.parseToLocal(data['check_in_time']),
      checkOutTime: TimezoneUtils.parseToLocal(data['check_out_time']),
      actualDurationHours: data['actual_duration_hours']?.toDouble(),
      timeUntilStartSeconds: data['time_until_start_seconds']?.toDouble(),
      timeSinceEndSeconds: data['time_since_end_seconds']?.toDouble(),
      attendanceId: data['attendance_id']?.toString(),
      attendanceStatus: data['attendance_status']?.toString(),
      wearingUniform: data['wearing_uniform'] as bool?,
      uniformConfidence: data['uniform_confidence']?.toDouble(),
      
      // Assignment information
      assignedAt: data['assigned_at'] != null ? parseDateTime(data['assigned_at']) : null,
      assignmentNotes: data['assignment_notes']?.toString(),
      assignmentStatus: data['assignment_status']?.toString(),
      currentParticipants: data['current_participants']?.toInt(),
      isMultiUser: data['is_multi_user'] as bool?,
      durationHours: data['duration_hours']?.toDouble(),
    );
  }

  // Convert to Supabase map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
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
    };
    
    // Only include id if it's not empty (for updates)
    if (scheduleId.isNotEmpty) {
      map['id'] = scheduleId;
    }
    
    return map;
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
