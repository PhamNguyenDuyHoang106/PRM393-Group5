class ActivityLog {
  final String id;
  final String? userId;
  final String userName;
  final String action;
  final String entity;
  final String entityId;
  final String? oldData;
  final String? newData;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    this.userId,
    required this.userName,
    required this.action,
    required this.entity,
    required this.entityId,
    this.oldData,
    this.newData,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    String name = json['user_name'] ?? 'System';
    if (json['user'] is Map) {
      name = json['user']['name'] ?? name;
    }

    return ActivityLog(
      id: json['id'] as String,
      userId: json['userId'] ?? json['user_id'],
      userName: name,
      action: json['action'] as String,
      entity: json['entity'] as String,
      entityId: json['entityId'] ?? json['entity_id'] ?? '',
      oldData: json['oldData'] ?? json['old_data'],
      newData: json['newData'] ?? json['new_data'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'entity': entity,
      'entity_id': entityId,
      'old_data': oldData,
      'new_data': newData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedMessage {
    switch (action) {
      case 'TASK_CREATED':
        return '$userName created this task';
      case 'STATUS_CHANGED':
        final status = newData != null ? newData!.replaceAll('"', '') : '';
        return '$userName changed status to $status';
      case 'PRIORITY_CHANGED':
        final priority = newData != null ? newData!.replaceAll('"', '') : '';
        return '$userName changed priority to $priority';
      case 'ASSIGNEE_CHANGED':
        return '$userName updated task assignee';
      case 'COMMENT_ADDED':
        return '$userName added a comment';
      case 'CHECKLIST_COMPLETED':
        final item = newData != null ? newData!.replaceAll('"', '') : 'a checklist item';
        return '$userName completed $item';
      default:
        return '$userName updated task';
    }
  }
}
