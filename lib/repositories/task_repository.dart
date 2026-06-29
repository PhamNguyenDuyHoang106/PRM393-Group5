import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/database/db_helper.dart';
import '../models/task.dart';
import '../models/pending_action.dart';

class TaskRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<List<Task>> getTasks(String projectId) async {
    try {
      // Try calling API first
      // final response = await _dioClient.dio.get('/tasks', queryParameters: {'project_id': projectId});
      // final List data = response.data;
      // final List<Task> tasks = data.map((json) => Task.fromJson(json)).toList();

      // Mock Delay
      await Future.delayed(const Duration(milliseconds: 500));
      final tasks = [
        Task(
          id: 'task_550',
          projectId: projectId,
          title: 'Integrate Dio Client',
          description: 'Configure HTTP interceptors and headers.',
          priority: 'HIGH',
          status: 'TODO',
          assignedTo: 'usr_7719',
          createdAt: DateTime.now(),
        ),
      ];

      // Update cache
      await _dbHelper.cacheTasks(tasks);
      return tasks;
    } catch (_) {
      // Offline fallback: load from SQLite cache
      return await _dbHelper.getCachedTasks(projectId: projectId);
    }
  }

  Future<Task> createTask(String projectId, String title, String description, String priority, String? assignedTo, DateTime? dueDate, bool isOnline) async {
    final newTask = Task(
      id: const Uuid().v4(),
      projectId: projectId,
      title: title,
      description: description,
      priority: priority,
      status: 'TODO',
      assignedTo: assignedTo,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    if (isOnline) {
      try {
        // Post to API
        // await _dioClient.dio.post('/tasks', data: newTask.toJson());
        await _dbHelper.cacheTasks([newTask]);
        return newTask;
      } catch (_) {
        // Fallback to offline on failure
      }
    }

    // Offline caching & sync queue enqueue
    await _dbHelper.cacheTasks([newTask]);
    final pendingAction = PendingAction(
      id: const Uuid().v4(),
      actionType: 'CREATE_TASK',
      payload: jsonEncode(newTask.toJson()),
      createdAt: DateTime.now(),
    );
    await _dbHelper.enqueueAction(pendingAction);

    return newTask;
  }

  Future<Task> updateTask(Task task, bool isOnline) async {
    if (isOnline) {
      try {
        // Put updates to API
        // await _dioClient.dio.put('/tasks/${task.id}', data: task.toJson());
        await _dbHelper.cacheTasks([task]);
        return task;
      } catch (_) {
        // Fallback to offline on failure
      }
    }

    // Offline caching & sync queue enqueue
    await _dbHelper.cacheTasks([task]);
    final pendingAction = PendingAction(
      id: const Uuid().v4(),
      actionType: 'UPDATE_TASK',
      payload: jsonEncode(task.toJson()),
      createdAt: DateTime.now(),
    );
    await _dbHelper.enqueueAction(pendingAction);

    return task;
  }
}
