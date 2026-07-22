class MemberTaskItem {
  final String userId;
  final String userName;
  final int count;

  MemberTaskItem({required this.userId, required this.userName, required this.count});

  factory MemberTaskItem.fromJson(Map<String, dynamic> json) {
    return MemberTaskItem(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? 'Member',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TaskBriefItem {
  final String id;
  final String title;
  final String projectId;
  final String status;
  final String priority;
  final DateTime? dueDate;

  TaskBriefItem({
    required this.id,
    required this.title,
    required this.projectId,
    required this.status,
    required this.priority,
    this.dueDate,
  });

  factory TaskBriefItem.fromJson(Map<String, dynamic> json) {
    return TaskBriefItem(
      id: json['id'] as String,
      title: json['title'] as String,
      projectId: json['projectId'] ?? json['project_id'] ?? '',
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : (json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null),
    );
  }
}

class Statistics {
  final int totalProjects;
  final int totalTasks;
  final int myTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int overdueTasks;
  final Map<String, int> taskStatusDistribution;
  final Map<String, int> taskPriorityDistribution;
  final List<MemberTaskItem> tasksByMember;
  final List<TaskBriefItem> upcomingTasksList;
  final List<TaskBriefItem> overdueTasksList;

  Statistics({
    required this.totalProjects,
    required this.totalTasks,
    this.myTasks = 0,
    required this.completedTasks,
    this.inProgressTasks = 0,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.taskStatusDistribution,
    required this.taskPriorityDistribution,
    this.tasksByMember = const [],
    this.upcomingTasksList = const [],
    this.overdueTasksList = const [],
  });

  /// Tỉ lệ hoàn thành (0.0 → 1.0)
  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  /// Số task theo trạng thái TODO
  int get todoCount => taskStatusDistribution['TODO'] ?? 0;

  /// Số task đang làm
  int get inProgressCount => inProgressTasks > 0 ? inProgressTasks : (taskStatusDistribution['IN_PROGRESS'] ?? 0);

  /// Số task đã xong
  int get doneCount => taskStatusDistribution['DONE'] ?? 0;

  /// Số task ưu tiên thấp
  int get lowCount => taskPriorityDistribution['LOW'] ?? 0;

  /// Số task ưu tiên trung bình
  int get mediumCount => taskPriorityDistribution['MEDIUM'] ?? 0;

  /// Số task ưu tiên cao
  int get highCount => taskPriorityDistribution['HIGH'] ?? 0;

  factory Statistics.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseMap(dynamic mapRaw) {
      if (mapRaw is Map) {
        return mapRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
      return {};
    }

    final statusMap = parseMap(json['tasksByStatus'] ?? json['task_status_distribution']);
    final priorityMap = parseMap(json['tasksByPriority'] ?? json['task_priority_distribution']);

    final memberRaw = json['tasksByMember'] as List?;
    final upcomingRaw = json['upcomingTasksList'] as List?;
    final overdueRaw = json['overdueTasksList'] as List?;

    return Statistics(
      totalProjects: (json['totalProjects'] ?? json['total_projects']) as int? ?? 0,
      totalTasks: (json['totalTasks'] ?? json['total_tasks']) as int? ?? 0,
      myTasks: (json['myTasks'] ?? json['my_tasks']) as int? ?? 0,
      completedTasks: (json['completedTasks'] ?? json['completed_tasks']) as int? ?? 0,
      inProgressTasks: (json['inProgressTasks'] ?? statusMap['IN_PROGRESS']) as int? ?? 0,
      pendingTasks: (json['pendingTasks'] ?? json['pending_tasks']) as int? ?? 0,
      overdueTasks: (json['overdueTasks'] ?? json['overdue_tasks']) as int? ?? 0,
      taskStatusDistribution: statusMap,
      taskPriorityDistribution: priorityMap,
      tasksByMember: memberRaw != null
          ? memberRaw.whereType<Map>().map((m) => MemberTaskItem.fromJson(Map<String, dynamic>.from(m))).toList()
          : [],
      upcomingTasksList: upcomingRaw != null
          ? upcomingRaw.whereType<Map>().map((m) => TaskBriefItem.fromJson(Map<String, dynamic>.from(m))).toList()
          : [],
      overdueTasksList: overdueRaw != null
          ? overdueRaw.whereType<Map>().map((m) => TaskBriefItem.fromJson(Map<String, dynamic>.from(m))).toList()
          : [],
    );
  }

  /// Trả mock data cho trường hợp chưa có backend
  factory Statistics.mock() {
    return Statistics(
      totalProjects: 3,
      totalTasks: 24,
      completedTasks: 12,
      inProgressTasks: 4,
      pendingTasks: 10,
      overdueTasks: 2,
      taskStatusDistribution: {'TODO': 8, 'IN_PROGRESS': 4, 'DONE': 12},
      taskPriorityDistribution: {'LOW': 10, 'MEDIUM': 8, 'HIGH': 6},
    );
  }
}
