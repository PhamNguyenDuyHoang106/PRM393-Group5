import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../models/statistics.dart';

// ─── New Models for Phase 4/5 ──────────────────────────────────────────────
class DashboardStats {
  final int totalProjects;
  final int totalTasks;
  final int myTasks;
  final int completedTasks;
  final int overallCompletionRate;
  final Map<String, int> tasksByStatus;
  final Map<String, int> tasksByPriority;
  final List<ProjectStats> projectStats;

  const DashboardStats({
    required this.totalProjects,
    required this.totalTasks,
    required this.myTasks,
    required this.completedTasks,
    required this.overallCompletionRate,
    required this.tasksByStatus,
    required this.tasksByPriority,
    required this.projectStats,
  });

  factory DashboardStats.empty() => const DashboardStats(
    totalProjects: 0,
    totalTasks: 0,
    myTasks: 0,
    completedTasks: 0,
    overallCompletionRate: 0,
    tasksByStatus: {'TODO': 0, 'IN_PROGRESS': 0, 'DONE': 0},
    tasksByPriority: {'LOW': 0, 'MEDIUM': 0, 'HIGH': 0},
    projectStats: [],
  );

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalProjects: (json['totalProjects'] as num?)?.toInt() ?? 0,
    totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
    myTasks: (json['myTasks'] as num?)?.toInt() ?? 0,
    completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
    overallCompletionRate:
        (json['overallCompletionRate'] as num?)?.toInt() ?? 0,
    tasksByStatus: _toIntMap(json['tasksByStatus']),
    tasksByPriority: _toIntMap(json['tasksByPriority']),
    projectStats: (json['projectStats'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ProjectStats.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  static Map<String, int> _toIntMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }
}

class ProjectStats {
  final String projectId;
  final String projectName;
  final int totalTasks;
  final int todoCount;
  final int inProgressCount;
  final int doneCount;
  final int completionRate;
  final int lowCount;
  final int mediumCount;
  final int highCount;

  const ProjectStats({
    required this.projectId,
    required this.projectName,
    required this.totalTasks,
    required this.todoCount,
    required this.inProgressCount,
    required this.doneCount,
    required this.completionRate,
    required this.lowCount,
    required this.mediumCount,
    required this.highCount,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) => ProjectStats(
    projectId: json['projectId']?.toString() ?? '',
    projectName: json['projectName']?.toString() ?? '',
    totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
    todoCount: (json['todoCount'] as num?)?.toInt() ?? 0,
    inProgressCount: (json['inProgressCount'] as num?)?.toInt() ?? 0,
    doneCount: (json['doneCount'] as num?)?.toInt() ?? 0,
    completionRate: (json['completionRate'] as num?)?.toInt() ?? 0,
    lowCount: (json['lowCount'] as num?)?.toInt() ?? 0,
    mediumCount: (json['mediumCount'] as num?)?.toInt() ?? 0,
    highCount: (json['highCount'] as num?)?.toInt() ?? 0,
  );
}

// ─── Unified StatisticsRepository ───────────────────────────────────────────
class StatisticsRepository {
  StatisticsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ─── Legacy Method: getStatistics (for DashboardViewModel compatibility) ───
  Future<Statistics> getStatistics() async {
    try {
      final response = await _dio.get('/statistics/dashboard');
      final raw = _unwrap(response.data);
      if (raw is! Map) {
        throw const FormatException('Invalid dashboard statistics response.');
      }
      final totalTasks = (raw['totalTasks'] as num?)?.toInt() ?? 0;
      final completedTasks = (raw['completedTasks'] as num?)?.toInt() ?? 0;
      return Statistics(
        totalProjects: (raw['totalProjects'] as num?)?.toInt() ?? 0,
        totalTasks: totalTasks,
        myTasks: (raw['myTasks'] as num?)?.toInt() ?? 0,
        completedTasks: completedTasks,
        pendingTasks: totalTasks - completedTasks,
        overdueTasks: 0,
        taskStatusDistribution: _toIntMap(raw['tasksByStatus']),
        taskPriorityDistribution: _toIntMap(raw['tasksByPriority']),
      );
    } catch (error) {
      throw _apiException(error, 'Unable to load live dashboard data.');
    }
  }

  // ─── New Method: getDashboard (for StatisticsViewModel / Analytics UI) ────
  Future<DashboardStats> getDashboard() async {
    try {
      final response = await _dio.get('/statistics/dashboard');
      final raw = _unwrap(response.data);
      if (raw is! Map) {
        throw const FormatException('Invalid dashboard statistics response.');
      }
      return DashboardStats.fromJson(Map<String, dynamic>.from(raw));
    } catch (error) {
      throw _apiException(error, 'Unable to load live dashboard data.');
    }
  }

  // ─── New Method: getProjectStats ──────────────────────────────────────────
  Future<ProjectStats?> getProjectStats(String projectId) async {
    try {
      final response = await _dio.get('/statistics/projects/$projectId');
      final raw = _unwrap(response.data);
      if (raw is! Map) {
        throw const FormatException('Invalid project statistics response.');
      }
      return ProjectStats.fromJson(Map<String, dynamic>.from(raw));
    } catch (error) {
      throw _apiException(error, 'Unable to load live project statistics.');
    }
  }

  StatisticsException _apiException(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return StatisticsException(message.toString());
        }
      }
      if (error.message?.trim().isNotEmpty == true) {
        return StatisticsException(error.message!.trim());
      }
    }
    return StatisticsException(fallback);
  }

  static Map<String, int> _toIntMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }

  double computeCompletionRate(Statistics stats) {
    if (stats.totalTasks == 0) return 0.0;
    return stats.completedTasks / stats.totalTasks;
  }

  int getCountByStatus(Statistics stats, String status) {
    return stats.taskStatusDistribution[status] ?? 0;
  }

  int getCountByPriority(Statistics stats, String priority) {
    return stats.taskPriorityDistribution[priority] ?? 0;
  }

  // ─── Legacy Method: invalidateCache ───────────────────────────────────────
}

class StatisticsException implements Exception {
  const StatisticsException(this.message);

  final String message;

  @override
  String toString() => message;
}
