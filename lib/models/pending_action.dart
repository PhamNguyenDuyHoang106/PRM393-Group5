class PendingAction {
  final String id;
  final String actionType; // 'CREATE_TASK', 'UPDATE_TASK', 'DELETE_TASK', etc.
  final String payload; // JSON serialized data of the target model
  final DateTime createdAt;

  PendingAction({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
  });

  PendingAction copyWith({
    String? id,
    String? actionType,
    String? payload,
    DateTime? createdAt,
  }) {
    return PendingAction(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'] as String,
      actionType: json['action_type'] as String,
      payload: json['payload'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
