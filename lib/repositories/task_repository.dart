import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../core/security/permission_service.dart';
import '../models/pending_action.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/checklist.dart';
import '../models/comment.dart';
import '../models/activity_log.dart';

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
        // Backend already returns the role-aware list (all project tasks for
        // managers, assigned-only for members) — trust it directly instead of
        // re-deriving visibility from local cache, which may be incomplete.
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
    // Offline best-effort: local cache may not reflect full project
    // membership, so this is an approximation until connectivity returns.
    return _visibleMyTasks(await _dbHelper.getCachedTasks(), currentUserId);
  }

  /// Offline-only fallback. Members: tasks assigned to them.
  /// Managers: assigned tasks + every task in locally cached owned projects.
  Future<List<Task>> _visibleMyTasks(
    List<Task> tasks,
    String currentUserId,
  ) async {
    final user = await _dbHelper.getCachedUser(currentUserId);
    final isManager = user?.isManager ?? false;
    var ownedProjectIds = const <String>{};
    if (isManager) {
      final projects = await _dbHelper.getCachedProjects();
      ownedProjectIds = projects
          .where((project) => project.ownerId == currentUserId)
          .map((project) => project.id)
          .toSet();
    }

    return tasks.where((task) {
      if (task.assignedTo == currentUserId) return true;
      if (isManager && ownedProjectIds.contains(task.projectId)) return true;
      return false;
    }).toList();
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
        await _ensureAssigneeIsMember(
          projectId: created.projectId,
          assigneeId: created.assignedTo,
        );
        return created;
      } catch (_) {}
    }

    await _dbHelper.cacheTasks([newTask]);
    await _ensureAssigneeIsMember(
      projectId: newTask.projectId,
      assigneeId: newTask.assignedTo,
    );
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
          await _ensureAssigneeIsMember(
            projectId: updated.projectId,
            assigneeId: updated.assignedTo,
          );
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
    await _ensureAssigneeIsMember(
      projectId: task.projectId,
      assigneeId: task.assignedTo,
    );
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
  Future<void> _ensureAssigneeIsMember({
    required String projectId,
    required String? assigneeId,
  }) async {
    if (assigneeId == null || assigneeId.isEmpty) return;

    final members = await _dbHelper.getCachedProjectMembers(projectId);
    if (members.any((member) => member.id == assigneeId)) return;

    final user = await _dbHelper.getCachedUser(assigneeId);
    await _dbHelper.addCachedProjectMember(
      projectId,
      ProjectMember(
        id: assigneeId,
        name: user?.name ?? 'Member',
        email: user?.email ?? '',
        role: user?.role == UserRole.manager ? 'manager' : 'member',
      ),
    );
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

  // ─── CHECKLIST METHODS ───────────────────────────────────────────────────
  Future<List<TaskChecklist>> getChecklists(String taskId, {required bool isOnline}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/tasks/$taskId/checklists');
        final raw = _unwrap(response.data);
        if (raw is List) {
          final items = raw
              .whereType<Map>()
              .map((json) => TaskChecklist.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          await _dbHelper.cacheChecklists(taskId, items);
          return items;
        }
      } catch (_) {}
    }
    return _dbHelper.getCachedChecklists(taskId);
  }

  Future<TaskChecklist> createChecklist({
    required String taskId,
    required String title,
    required bool isOnline,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw const TaskException('Checklist title cannot be empty.');
    if (trimmed.length > 100) throw const TaskException('Checklist title cannot exceed 100 characters.');

    final item = TaskChecklist(
      id: _uuid.v4(),
      taskId: taskId,
      title: trimmed,
      isDone: false,
      createdAt: DateTime.now(),
    );

    await _dbHelper.saveCachedChecklist(item);

    if (isOnline) {
      try {
        final response = await _dio.post(
          '/tasks/$taskId/checklists',
          data: {'id': item.id, 'title': item.title},
        );
        final raw = _unwrap(response.data);
        if (raw is Map) {
          final synced = TaskChecklist.fromJson(Map<String, dynamic>.from(raw));
          await _dbHelper.saveCachedChecklist(synced);
          return synced;
        }
      } catch (_) {}
    }

    await _enqueueAction(
      'CREATE_CHECKLIST',
      {'id': item.id, 'taskId': taskId, 'title': item.title},
    );

    return item;
  }

  Future<TaskChecklist> toggleChecklist({
    required String id,
    required String taskId,
    required bool isDone,
    required bool isOnline,
  }) async {
    final cached = await _dbHelper.getCachedChecklists(taskId);
    final existing = cached.firstWhere((c) => c.id == id, orElse: () => TaskChecklist(
      id: id,
      taskId: taskId,
      title: 'Item',
      isDone: !isDone,
      createdAt: DateTime.now(),
    ));

    final updated = existing.copyWith(isDone: isDone);
    await _dbHelper.saveCachedChecklist(updated);

    if (isOnline) {
      try {
        final response = await _dio.patch('/tasks/checklists/$id', data: {'isDone': isDone});
        final raw = _unwrap(response.data);
        if (raw is Map) {
          final synced = TaskChecklist.fromJson(Map<String, dynamic>.from(raw));
          await _dbHelper.saveCachedChecklist(synced);
          return synced;
        }
      } catch (_) {}
    }

    await _enqueueAction(
      'UPDATE_CHECKLIST',
      {'id': id, 'taskId': taskId, 'isDone': isDone},
    );

    return updated;
  }

  Future<void> deleteChecklist({
    required String id,
    required String taskId,
    required bool isOnline,
  }) async {
    await _dbHelper.deleteCachedChecklist(id);

    if (isOnline) {
      try {
        await _dio.delete('/tasks/checklists/$id');
        return;
      } catch (_) {}
    }

    await _enqueueAction(
      'DELETE_CHECKLIST',
      {'id': id, 'taskId': taskId},
    );
  }

  // ─── COMMENT METHODS ──────────────────────────────────────────────────────
  Future<List<TaskComment>> getComments(String taskId, {required bool isOnline}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/tasks/$taskId/comments');
        final raw = _unwrap(response.data);
        if (raw is List) {
          final comments = raw
              .whereType<Map>()
              .map((json) => TaskComment.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          await _dbHelper.cacheComments(taskId, comments);
          return comments;
        }
      } catch (_) {}
    }
    return _dbHelper.getCachedComments(taskId);
  }

  Future<TaskComment> createComment({
    required String taskId,
    required String content,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required bool isOnline,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) throw const TaskException('Comment content cannot be empty or whitespace only.');
    if (trimmed.length > 1000) throw const TaskException('Comment content cannot exceed 1000 characters.');

    final comment = TaskComment(
      id: _uuid.v4(),
      taskId: taskId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    await _dbHelper.saveCachedComment(comment);

    if (isOnline) {
      try {
        final response = await _dio.post(
          '/tasks/$taskId/comments',
          data: {'id': comment.id, 'content': comment.content},
        );
        final raw = _unwrap(response.data);
        if (raw is Map) {
          final synced = TaskComment.fromJson(Map<String, dynamic>.from(raw));
          await _dbHelper.saveCachedComment(synced);
          return synced;
        }
      } catch (_) {}
    }

    await _enqueueAction(
      'CREATE_COMMENT',
      {'id': comment.id, 'taskId': taskId, 'content': comment.content},
    );

    return comment;
  }

  Future<void> deleteComment({
    required String id,
    required String taskId,
    required bool isOnline,
  }) async {
    await _dbHelper.deleteCachedComment(id);

    if (isOnline) {
      try {
        await _dio.delete('/tasks/comments/$id');
        return;
      } catch (_) {}
    }

    await _enqueueAction(
      'DELETE_COMMENT',
      {'id': id, 'taskId': taskId},
    );
  }

  // ─── ACTIVITY LOG METHODS ─────────────────────────────────────────────────
  Future<List<ActivityLog>> getActivities(String taskId, {required bool isOnline}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/tasks/$taskId/activities');
        final raw = _unwrap(response.data);
        if (raw is List) {
          final logs = raw
              .whereType<Map>()
              .map((json) => ActivityLog.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          await _dbHelper.cacheAuditLogs(taskId, logs);
          return logs;
        }
      } catch (_) {}
    }
    return _dbHelper.getCachedAuditLogs(taskId);
  }
}

class TaskException implements Exception {
  const TaskException(this.message);
  final String message;
  @override
  String toString() => message;
}
