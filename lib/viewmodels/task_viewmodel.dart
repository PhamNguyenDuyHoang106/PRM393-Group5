import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../services/connectivity_service.dart';

import '../providers/providers.dart';

class TaskState {
  TaskState({
    List<Task> tasks = const [],
    this.selectedTask,
    this.searchQuery = '',
    this.statusFilter,
    this.isLoadingTasks = false,
    this.isLoadingDetails = false,
    this.isSubmitting = false,
    this.errorMessage,
  }) : tasks = List.unmodifiable(tasks);

  final List<Task> tasks;
  final Task? selectedTask;
  final String searchQuery;
  final String? statusFilter;
  final bool isLoadingTasks;
  final bool isLoadingDetails;
  final bool isSubmitting;
  final String? errorMessage;

  List<Task> get filteredTasks {
    final query = searchQuery.trim().toLowerCase();
    return tasks.where((task) {
      final matchesQuery =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);
      final matchesStatus = statusFilter == null || task.status == statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  TaskState copyWith({
    List<Task>? tasks,
    Task? selectedTask,
    bool clearSelectedTask = false,
    String? searchQuery,
    String? statusFilter,
    bool clearStatusFilter = false,
    bool? isLoadingTasks,
    bool? isLoadingDetails,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      selectedTask: clearSelectedTask
          ? null
          : (selectedTask ?? this.selectedTask),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      isLoadingTasks: isLoadingTasks ?? this.isLoadingTasks,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TaskViewModel extends StateNotifier<TaskState> {
  TaskViewModel(this._repository, this._connectivityService, this._ref)
    : super(TaskState());

  final TaskRepository _repository;
  final ConnectivityService _connectivityService;
  final Ref _ref;

  Future<void> loadTasks({String? projectId, bool requireFresh = false}) async {
    state = state.copyWith(
      tasks: requireFresh ? const [] : null,
      isLoadingTasks: true,
      clearError: true,
    );
    try {
      final tasks = projectId == null
          ? await _loadMyTasks(requireFresh: requireFresh)
          : await _repository.getTasks(
              projectId: projectId,
              isOnline: _connectivityService.isOnline,
              allowCacheFallback: !requireFresh,
            );
      state = state.copyWith(tasks: tasks, isLoadingTasks: false);
    } catch (error) {
      state = state.copyWith(
        isLoadingTasks: false,
        errorMessage: _messageFrom(error),
      );
    }
  }

  Future<List<Task>> _loadMyTasks({required bool requireFresh}) {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      throw const TaskException('You must be logged in.');
    }
    return _repository.getMyTasks(
      isOnline: _connectivityService.isOnline,
      currentUserId: currentUser.id,
      allowCacheFallback: !requireFresh,
    );
  }

  Future<void> loadTask(String taskId) async {
    Task? existing;
    for (final task in state.tasks) {
      if (task.id == taskId) {
        existing = task;
        break;
      }
    }
    state = state.copyWith(
      selectedTask: existing,
      clearSelectedTask: existing == null,
      isLoadingDetails: true,
      clearError: true,
    );
    try {
      final task = await _repository.getTask(
        taskId,
        isOnline: _connectivityService.isOnline,
      );
      state = state.copyWith(
        selectedTask: task,
        tasks: _upsert(state.tasks, task),
        isLoadingDetails: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDetails: false,
        errorMessage: _messageFrom(error),
      );
    }
  }

  Future<Task?> createTask({
    required String projectId,
    required String title,
    required String description,
    required String priority,
    String? assignedTo,
    DateTime? dueDate,
  }) async {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final task = await _repository.createTask(
        projectId: projectId,
        title: title,
        description: description,
        priority: priority,
        assignedTo: assignedTo,
        dueDate: dueDate,
        isOnline: _connectivityService.isOnline,
        currentUserId: currentUser.id,
      );
      state = state.copyWith(
        tasks: _upsert(state.tasks, task),
        selectedTask: task,
        isSubmitting: false,
      );
      return task;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return null;
    }
  }

  Future<Task?> updateTask(Task task) async {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await _repository.updateTask(
        task: task,
        isOnline: _connectivityService.isOnline,
        currentUserId: currentUser.id,
      );
      state = state.copyWith(
        tasks: _upsert(state.tasks, updated),
        selectedTask: updated,
        isSubmitting: false,
      );
      return updated;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return null;
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setStatusFilter(String? value) {
    state = value == null
        ? state.copyWith(clearStatusFilter: true)
        : state.copyWith(statusFilter: value);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  List<Task> _upsert(List<Task> tasks, Task task) {
    final updated = [...tasks];
    final index = updated.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      updated.insert(0, task);
    } else {
      updated[index] = task;
    }
    return updated;
  }

  String _messageFrom(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }
}
