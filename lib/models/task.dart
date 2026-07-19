class Task {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String priority; // 'LOW', 'MEDIUM', 'HIGH'
  final String status; // 'TODO', 'IN_PROGRESS', 'DONE'
  final String? assignedTo; // user id or null
  final DateTime? dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.dueDate,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? assignedTo,
    DateTime? dueDate,
    DateTime? createdAt,
    bool clearAssignedTo = false,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      projectId: json['project_id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString().toUpperCase() ?? 'MEDIUM',
      status: json['status']?.toString().toUpperCase() ?? 'TODO',
      assignedTo: json['assigned_to']?.toString(),
      dueDate: _parseDate(json['due_date']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}
