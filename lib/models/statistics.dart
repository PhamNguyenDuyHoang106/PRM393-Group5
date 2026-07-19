class Statistics {
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final Map<String, int> taskStatusDistribution;
  final Map<String, int> taskPriorityDistribution;

  Statistics({
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.taskStatusDistribution,
    required this.taskPriorityDistribution,
  });

  /// Tỉ lệ hoàn thành (0.0 → 1.0)
  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  /// Số task theo trạng thái TODO
  int get todoCount => taskStatusDistribution['TODO'] ?? 0;

  /// Số task đang làm
  int get inProgressCount => taskStatusDistribution['IN_PROGRESS'] ?? 0;

  /// Số task đã xong
  int get doneCount => taskStatusDistribution['DONE'] ?? 0;

  /// Số task ưu tiên thấp
  int get lowCount => taskPriorityDistribution['LOW'] ?? 0;

  /// Số task ưu tiên trung bình
  int get mediumCount => taskPriorityDistribution['MEDIUM'] ?? 0;

  /// Số task ưu tiên cao
  int get highCount => taskPriorityDistribution['HIGH'] ?? 0;

  Statistics copyWith({
    int? totalProjects,
    int? totalTasks,
    int? completedTasks,
    int? pendingTasks,
    int? overdueTasks,
    Map<String, int>? taskStatusDistribution,
    Map<String, int>? taskPriorityDistribution,
  }) {
    return Statistics(
      totalProjects: totalProjects ?? this.totalProjects,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      taskStatusDistribution:
          taskStatusDistribution ?? this.taskStatusDistribution,
      taskPriorityDistribution:
          taskPriorityDistribution ?? this.taskPriorityDistribution,
    );
  }

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalProjects: json['total_projects'] as int? ?? 0,
      totalTasks: json['total_tasks'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
      pendingTasks: json['pending_tasks'] as int? ?? 0,
      overdueTasks: json['overdue_tasks'] as int? ?? 0,
      taskStatusDistribution: Map<String, int>.from(
        (json['task_status_distribution'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
      ),
      taskPriorityDistribution: Map<String, int>.from(
        (json['task_priority_distribution'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_projects': totalProjects,
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'pending_tasks': pendingTasks,
      'overdue_tasks': overdueTasks,
      'task_status_distribution': taskStatusDistribution,
      'task_priority_distribution': taskPriorityDistribution,
    };
  }

  /// Trả mock data cho trường hợp chưa có backend
  factory Statistics.mock() {
    return Statistics(
      totalProjects: 3,
      totalTasks: 24,
      completedTasks: 12,
      pendingTasks: 10,
      overdueTasks: 2,
      taskStatusDistribution: {
        'TODO': 8,
        'IN_PROGRESS': 4,
        'DONE': 12,
      },
      taskPriorityDistribution: {
        'LOW': 10,
        'MEDIUM': 8,
        'HIGH': 6,
      },
    );
  }
}
