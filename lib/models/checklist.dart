class TaskChecklist {
  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final DateTime createdAt;

  TaskChecklist({
    required this.id,
    required this.taskId,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });

  factory TaskChecklist.fromJson(Map<String, dynamic> json) {
    return TaskChecklist(
      id: json['id'] as String,
      taskId: json['taskId'] ?? json['task_id'] ?? '',
      title: json['title'] as String,
      isDone: json['isDone'] == true || json['is_done'] == 1,
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
      'task_id': taskId,
      'title': title,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskChecklist copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return TaskChecklist(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
