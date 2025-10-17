class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? imageUrl;
  final String type;
  final String? category;
  final String priority;
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final String status;
  final bool isRead;
  final DateTime? readAt;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final String? failedReason;
  final String? batchId;
  final String? groupKey;
  final String? scheduleId;
  final Map<String, dynamic>? scheduleData;
  final DateTime? expiresAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.type,
    this.category,
    required this.priority,
    this.actionType,
    this.actionData,
    required this.status,
    required this.isRead,
    this.readAt,
    required this.sentAt,
    this.deliveredAt,
    this.failedReason,
    this.batchId,
    this.groupKey,
    this.scheduleId,
    this.scheduleData,
    this.expiresAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      type: json['type'] as String,
      category: json['category'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      actionType: json['action_type'] as String?,
      actionData: json['action_data'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'sent',
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      sentAt: DateTime.parse(json['sent_at'] as String),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      failedReason: json['failed_reason'] as String?,
      batchId: json['batch_id'] as String?,
      groupKey: json['group_key'] as String?,
      scheduleId: json['schedule_id'] as String?,
      scheduleData: json['schedule_data'] as Map<String, dynamic>?,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'type': type,
      'category': category,
      'priority': priority,
      'action_type': actionType,
      'action_data': actionData,
      'status': status,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'sent_at': sentAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'failed_reason': failedReason,
      'batch_id': batchId,
      'group_key': groupKey,
      'schedule_id': scheduleId,
      'schedule_data': scheduleData,
      'expires_at': expiresAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? imageUrl,
    String? type,
    String? category,
    String? priority,
    String? actionType,
    Map<String, dynamic>? actionData,
    String? status,
    bool? isRead,
    DateTime? readAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    String? failedReason,
    String? batchId,
    String? groupKey,
    String? scheduleId,
    Map<String, dynamic>? scheduleData,
    DateTime? expiresAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failedReason: failedReason ?? this.failedReason,
      batchId: batchId ?? this.batchId,
      groupKey: groupKey ?? this.groupKey,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleData: scheduleData ?? this.scheduleData,
      expiresAt: expiresAt ?? this.expiresAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isDeleted => deletedAt != null;
  bool get isActive => !isExpired && !isDeleted;
  
  String get timeAgo {
    final Duration diff = DateTime.now().difference(createdAt);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}


