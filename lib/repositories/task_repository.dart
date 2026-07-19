import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../core/security/permission_service.dart';
import '../models/task.dart';
import '../models/pending_action.dart';

class TaskRepository {
  TaskRepository({DbHelper? dbHelper, Dio? dio, Uuid? uuid})
    : _dbHelper = dbHelper ?? DbHelper.instance,
      _dio = dio ?? DioClient.instance.dio,
      _uuid = uuid ?? const Uuid();

  final DbHelper _dbHelper;
  final Dio _dio;
  final Uuid _uuid;

  Future<List<Task>> getTasks({
    String? projectId,
    String? search,
    String? status,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _dio.get(
          '/tasks',
          queryParameters: {
            if (projectId != null && projectId.isNotEmpty)
              'project_id': projectId,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
            if (status != null && status.isNotEmpty) 'status': status,
          },
        );
        if (response.data is! List) {
          throw const FormatException('Invalid tasks response.');
        }
        final tasks = (response.data as List)
            .whereType<Map>()
            .map((json) => Task.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        await _dbHelper.cacheTasks(tasks);
        return tasks;
      } catch (_) {
        // Fall back to SQLite when the API is unavailable.
      }
    }

    var tasks = await _dbHelper.getCachedTasks(projectId: projectId);
    if (tasks.isEmpty) {
      tasks = _buildDemoTasks(projectId ?? 'proj_01');
      await _dbHelper.cacheTasks(tasks);
    }
    return _filterTasks(tasks, search: search, status: status);
  }

  Future<Task> getTask(String taskId, {required bool isOnline}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/tasks/$taskId');
        if (response.data is! Map) {
          throw const FormatException('Invalid task detail response.');
        }
        final task = Task.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        await _dbHelper.cacheTasks([task]);
        return task;
      } catch (_) {
        // Fall back to SQLite when the API is unavailable.
      }
    }

    final task = await _dbHelper.getCachedTask(taskId);
    if (task == null) throw const TaskException('Task not found.');
    return task;
  }

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
          '/tasks',
          data: _createPayload(newTask),
        );
        final data = response.data;
        if (data is! Map) {
          throw const FormatException('Invalid create task response.');
        }
        final created = Task.fromJson(Map<String, dynamic>.from(data));
        await _dbHelper.cacheTasks([created]);
        return created;
      } catch (_) {
        // Save locally and queue below.
      }
    }

    await _dbHelper.cacheTasks([newTask]);
    await _enqueueAction('CREATE_TASK', newTask.toJson());
    return newTask;
  }

  Future<Task> updateTask({
    required Task task,
    required bool isOnline,
    required String currentUserId,
  }) async {
    final caller = await _dbHelper.getCachedUser(currentUserId);
    if (caller == null) {
      throw const TaskException('Permission Denied: Logged-in user not found.');
    }

    final existingTask = await _dbHelper.getCachedTask(task.id);
    if (existingTask == null) {
      throw const TaskException('Task not found.');
    }

    if (!caller.isManager) {
      // Members are allowed to update ONLY their own task status.
      if (existingTask.assignedTo != caller.id) {
        throw const TaskException('Permission Denied: You are not assigned to this task.');
      }
      
      // Check if anything other than status was changed
      if (task.title != existingTask.title ||
          task.description != existingTask.description ||
          task.priority != existingTask.priority ||
          task.assignedTo != existingTask.assignedTo ||
          task.dueDate != existingTask.dueDate ||
          task.projectId != existingTask.projectId) {
        throw const TaskException('Permission Denied: Members can only update task status.');
      }
    }

    if (isOnline) {
      try {
        final response = await _dio.put(
          '/tasks/${task.id}',
          data: _updatePayload(task),
        );
        final data = response.data;
        if (data is! Map) {
          throw const FormatException('Invalid update task response.');
        }
        final updated = Task.fromJson(Map<String, dynamic>.from(data));
        await _dbHelper.cacheTasks([updated]);
        return updated;
      } catch (_) {
        // Save locally and queue below.
      }
    }

    await _dbHelper.cacheTasks([task]);
    await _enqueueAction('UPDATE_TASK', task.toJson());
    return task;
  }

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

  Map<String, dynamic> _createPayload(Task task) => {
    'project_id': task.projectId,
    'title': task.title,
    'description': task.description,
    'priority': task.priority,
    'assigned_to': task.assignedTo,
    'due_date': task.dueDate?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _updatePayload(Task task) => {
    'title': task.title,
    'description': task.description,
    'priority': task.priority,
    'status': task.status,
    'assigned_to': task.assignedTo,
    'due_date': task.dueDate?.toUtc().toIso8601String(),
  };

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
