import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../core/security/permission_service.dart';
import '../models/pending_action.dart';
import '../models/task.dart';

class TaskRepository {
  TaskRepository({DbHelper? dbHelper, Dio? dio, Uuid? uuid})
    : _dbHelper = dbHelper ?? DbHelper.instance,
      _dio = dio ?? DioClient.instance.dio,
      _uuid = uuid ?? const Uuid();

  final DbHelper _dbHelper;
  final Dio _dio;
  final Uuid _uuid;

  // ─── Helper: unwrap NestJS { success, data } envelope ────────────────────
  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ─── GET /projects/:projectId/tasks ───────────────────────────────────────
  Future<List<Task>> getTasks({
    String? projectId,
    String? search,
    String? status,
    required bool isOnline,
    bool allowCacheFallback = true,
  }) async {
    final shouldLoadFromApi =
        projectId != null && (isOnline || !allowCacheFallback);
    if (shouldLoadFromApi) {
      try {
        final response = await _dio.get('/projects/$projectId/tasks');
        final raw = _unwrap(response.data);
        if (raw is! List) {
          throw const FormatException('Invalid tasks response.');
        }
        final tasks = (raw)
            .whereType<Map>()
            .map((json) => Task.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        await _dbHelper.cacheTasks(tasks);
        return _filterTasks(tasks, search: search, status: status);
      } catch (error) {
        if (!allowCacheFallback || !_isConnectionFailure(error)) {
          throw _apiException(error, 'Unable to load project tasks.');
        }
      }
    }

    if (!allowCacheFallback) {
      throw const TaskException(
        'Unable to load live task data. Check your internet connection.',
      );
    }

    var tasks = await _dbHelper.getCachedTasks(projectId: projectId);
    if (tasks.isEmpty) {
      await _seedDemoTasksIfNeeded();
      tasks = await _dbHelper.getCachedTasks(projectId: projectId);
    }
    return _filterTasks(tasks, search: search, status: status);
  }

  /// Seeds demo tasks only once, and only for the offline demo project, so
  /// real projects never share or steal the demo data.
  Future<void> _seedDemoTasksIfNeeded() async {
    const demoProjectId = 'proj_01';
    final allTasks = await _dbHelper.getCachedTasks();
    if (allTasks.isNotEmpty) return;
    final demoProject = await _dbHelper.getCachedProject(demoProjectId);
    if (demoProject == null) return;
    await _dbHelper.cacheTasks(_buildDemoTasks(demoProjectId));
  }

  // ─── GET /tasks/my ────────────────────────────────────────────────────────
  Future<List<Task>> getMyTasks({
    required bool isOnline,
    required String currentUserId,
    bool allowCacheFallback = true,
  }) async {
    if (isOnline || !allowCacheFallback) {
      try {
        final response = await _dio.get('/tasks/my');
        final raw = _unwrap(response.data);
        if (raw is! List) {
          throw const FormatException('Invalid my-tasks response.');
        }
        final tasks = (raw)
            .whereType<Map>()
            .map((json) => Task.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        await _dbHelper.cacheTasks(tasks);
        return tasks;
      } catch (error) {
        if (!allowCacheFallback || !_isConnectionFailure(error)) {
          throw _apiException(error, 'Unable to load your assigned tasks.');
        }
      }
    }
    if (!allowCacheFallback) {
      throw const TaskException(
        'Unable to load live task data. Check your internet connection.',
      );
    }
    final cachedTasks = await _dbHelper.getCachedTasks();
    return cachedTasks
        .where((task) => task.assignedTo == currentUserId)
        .toList();
  }

  // ─── GET /tasks/:id ───────────────────────────────────────────────────────
  Future<Task> getTask(String taskId, {required bool isOnline}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/tasks/$taskId');
        final raw = _unwrap(response.data);
        if (raw is! Map) {
          throw const FormatException('Invalid task detail response.');
        }
        final task = Task.fromJson(Map<String, dynamic>.from(raw));
        await _dbHelper.cacheTasks([task]);
        return task;
      } catch (_) {}
    }
    final task = await _dbHelper.getCachedTask(taskId);
    if (task == null) throw const TaskException('Task not found.');
    return task;
  }

  // ─── POST /projects/:projectId/tasks ──────────────────────────────────────
  Future<Task> createTask({
    required String projectId,
    required String title,
    required String description,
    required String priority,
    String? assignedTo,
    DateTime? dueDate,
    required bool isOnline,
    required String currentUserId,
  }) async {
    final caller = await _dbHelper.getCachedUser(currentUserId);
    PermissionService.requireManager(caller, action: 'create tasks');

    final newTask = Task(
      id: _uuid.v4(),
      projectId: projectId,
      title: title.trim(),
      description: description.trim(),
      priority: priority.toUpperCase(),
      status: 'TODO',
      assignedTo: assignedTo,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    if (isOnline) {
      try {
        final response = await _dio.post(
          '/projects/$projectId/tasks',
          data: {
            'title': newTask.title,
            'description': newTask.description,
            'priority': newTask.priority,
            'assignedTo': assignedTo,
            'dueDate': dueDate?.toUtc().toIso8601String(),
          },
        );
        final raw = _unwrap(response.data);
        if (raw is! Map) {
          throw const FormatException('Invalid create task response.');
        }
        final created = Task.fromJson(Map<String, dynamic>.from(raw));
        await _dbHelper.cacheTasks([created]);
        return created;
      } catch (_) {}
    }

    await _dbHelper.cacheTasks([newTask]);
    await _enqueueAction('CREATE_TASK', newTask.toJson());
    return newTask;
  }

  // ─── PUT /tasks/:id ───────────────────────────────────────────────────────
  Future<Task> updateTask({
    required Task task,
    required bool isOnline,
    required String currentUserId,
  }) async {
    final caller = await _dbHelper.getCachedUser(currentUserId);
    if (caller == null) {
      throw const TaskException('Permission Denied: user not found.');
    }

    final existing = await _dbHelper.getCachedTask(task.id);
    if (existing == null) throw const TaskException('Task not found.');

    if (!caller.isManager) {
      if (existing.assignedTo != caller.id) {
        throw const TaskException(
          'Permission Denied: you are not assigned to this task.',
        );
      }
      if (task.title != existing.title ||
          task.description != existing.description ||
          task.priority != existing.priority ||
          task.assignedTo != existing.assignedTo ||
          task.dueDate != existing.dueDate) {
        throw const TaskException(
          'Permission Denied: members can only update task status.',
        );
      }
    }

    if (isOnline) {
      try {
        if (caller.isManager) {
          // Full update via PUT /tasks/:id
          final response = await _dio.put(
            '/tasks/${task.id}',
            data: {
              'title': task.title,
              'description': task.description,
              'priority': task.priority,
              'status': task.status,
              'assignedTo': task.assignedTo,
              'dueDate': task.dueDate?.toUtc().toIso8601String(),
            },
          );
          final raw = _unwrap(response.data);
          if (raw is! Map) {
            throw const FormatException('Invalid update task response.');
          }
          final updated = Task.fromJson(Map<String, dynamic>.from(raw));
          await _dbHelper.cacheTasks([updated]);
          return updated;
        } else {
          // Member status-only update via PATCH /tasks/:id/status
          final response = await _dio.patch(
            '/tasks/${task.id}/status',
            data: {'status': task.status},
          );
          final raw = _unwrap(response.data);
          if (raw is! Map) {
            throw const FormatException('Invalid status update response.');
          }
          final updated = Task.fromJson(Map<String, dynamic>.from(raw));
          await _dbHelper.cacheTasks([updated]);
          return updated;
        }
      } catch (_) {}
    }

    await _dbHelper.cacheTasks([task]);
    await _enqueueAction('UPDATE_TASK', task.toJson());
    return task;
  }

  // ─── DELETE /tasks/:id ────────────────────────────────────────────────────
  Future<void> deleteTask({
    required String taskId,
    required bool isOnline,
    required String currentUserId,
  }) async {
    final caller = await _dbHelper.getCachedUser(currentUserId);
    PermissionService.requireManager(caller, action: 'delete tasks');

    if (isOnline) {
      try {
        await _dio.delete('/tasks/$taskId');
        await _dbHelper.deleteTask(taskId);
        return;
      } catch (_) {}
    }

    await _dbHelper.deleteTask(taskId);
    await _enqueueAction('DELETE_TASK', {'task_id': taskId});
  }

  // ─── Private helpers ──────────────────────────────────────────────────────
  List<Task> _filterTasks(List<Task> tasks, {String? search, String? status}) {
    final query = search?.trim().toLowerCase() ?? '';
    return tasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);
      final matchesStatus =
          status == null || status.isEmpty || task.status == status;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  bool _isConnectionFailure(Object error) {
    if (error is! DioException) return false;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => true,
      _ => false,
    };
  }

  TaskException _apiException(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return TaskException(message.toString());
        }
      }
      if (error.message?.trim().isNotEmpty == true) {
        return TaskException(error.message!.trim());
      }
    }
    return TaskException(fallback);
  }

  Future<void> _enqueueAction(String actionType, Map<String, dynamic> payload) {
    return _dbHelper.enqueueAction(
      PendingAction(
        id: _uuid.v4(),
        actionType: actionType,
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ),
    );
  }

  List<Task> _buildDemoTasks(String projectId) {
    final now = DateTime.now();
    return [
      Task(
        id: 'task_550',
        projectId: projectId,
        title: 'Design Database Schema',
        description: 'Define SQLite tables and columns.',
        priority: 'HIGH',
        status: 'TODO',
        assignedTo: 'usr_8231',
        dueDate: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'task_551',
        projectId: projectId,
        title: 'Integrate Dio Client',
        description: 'Configure HTTP interceptors and authorization headers.',
        priority: 'MEDIUM',
        status: 'IN_PROGRESS',
        assignedTo: 'usr_7719',
        dueDate: now.add(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'task_552',
        projectId: projectId,
        title: 'Create UI Wireframes',
        description: 'Prepare the MVP screen layout.',
        priority: 'LOW',
        status: 'DONE',
        assignedTo: 'usr_8231',
        dueDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}

class TaskException implements Exception {
  const TaskException(this.message);
  final String message;
  @override
  String toString() => message;
}
