import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/checklist.dart';
import '../models/comment.dart';
import '../models/activity_log.dart';
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
    List<TaskChecklist> checklists = const [],
    List<TaskComment> comments = const [],
    List<ActivityLog> activities = const [],
    this.isLoadingChecklists = false,
    this.isLoadingComments = false,
    this.isLoadingActivities = false,
  })  : tasks = List.unmodifiable(tasks),
        checklists = List.unmodifiable(checklists),
        comments = List.unmodifiable(comments),
        activities = List.unmodifiable(activities);

  final List<Task> tasks;
  final Task? selectedTask;
  final String searchQuery;
  final String? statusFilter;
  final bool isLoadingTasks;
  final bool isLoadingDetails;
  final bool isSubmitting;
  final String? errorMessage;
  final List<TaskChecklist> checklists;
  final List<TaskComment> comments;
  final List<ActivityLog> activities;
  final bool isLoadingChecklists;
  final bool isLoadingComments;
  final bool isLoadingActivities;

  int get completedChecklistCount => checklists.where((c) => c.isDone).length;

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
    List<TaskChecklist>? checklists,
    List<TaskComment>? comments,
    List<ActivityLog>? activities,
    bool? isLoadingChecklists,
    bool? isLoadingComments,
    bool? isLoadingActivities,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      selectedTask: clearSelectedTask
          ? null
          : (selectedTask ?? this.selectedTask),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      isLoadingTasks: isLoadingTasks ?? this.isLoadingTasks,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      checklists: checklists ?? this.checklists,
      comments: comments ?? this.comments,
      activities: activities ?? this.activities,
      isLoadingChecklists: isLoadingChecklists ?? this.isLoadingChecklists,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isLoadingActivities: isLoadingActivities ?? this.isLoadingActivities,
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

  Future<bool> deleteTask(String taskId) async {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.deleteTask(
        taskId: taskId,
        isOnline: _connectivityService.isOnline,
        currentUserId: currentUser.id,
      );
      state = state.copyWith(
        tasks: state.tasks.where((task) => task.id != taskId).toList(),
        clearSelectedTask: state.selectedTask?.id == taskId,
        isSubmitting: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return false;
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

  // ─── CHECKLIST METHODS ───────────────────────────────────────────────────
  Future<void> loadChecklists(String taskId) async {
    state = state.copyWith(isLoadingChecklists: true);
    try {
      final items = await _repository.getChecklists(
        taskId,
        isOnline: _connectivityService.isOnline,
      );
      state = state.copyWith(checklists: items, isLoadingChecklists: false);
    } catch (e) {
      state = state.copyWith(isLoadingChecklists: false, errorMessage: _messageFrom(e));
    }
  }

  Future<bool> addChecklist(String taskId, String title) async {
    try {
      final item = await _repository.createChecklist(
        taskId: taskId,
        title: title,
        isOnline: _connectivityService.isOnline,
      );
      final updated = [...state.checklists, item];
      state = state.copyWith(checklists: updated);
      // Reload activities in case an audit log was created
      loadActivities(taskId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _messageFrom(e));
      return false;
    }
  }

  Future<void> toggleChecklist(String id, String taskId, bool isDone) async {
    final updatedList = state.checklists.map((c) {
      return c.id == id ? c.copyWith(isDone: isDone) : c;
    }).toList();
    state = state.copyWith(checklists: updatedList);

    try {
      await _repository.toggleChecklist(
        id: id,
        taskId: taskId,
        isDone: isDone,
        isOnline: _connectivityService.isOnline,
      );
      loadActivities(taskId);
    } catch (e) {
      state = state.copyWith(errorMessage: _messageFrom(e));
    }
  }

  Future<void> deleteChecklist(String id, String taskId) async {
    final updatedList = state.checklists.where((c) => c.id != id).toList();
    state = state.copyWith(checklists: updatedList);

    try {
      await _repository.deleteChecklist(
        id: id,
        taskId: taskId,
        isOnline: _connectivityService.isOnline,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: _messageFrom(e));
    }
  }

  // ─── COMMENT METHODS ──────────────────────────────────────────────────────
  Future<void> loadComments(String taskId) async {
    state = state.copyWith(isLoadingComments: true);
    try {
      final comments = await _repository.getComments(
        taskId,
        isOnline: _connectivityService.isOnline,
      );
      state = state.copyWith(comments: comments, isLoadingComments: false);
    } catch (e) {
      state = state.copyWith(isLoadingComments: false, errorMessage: _messageFrom(e));
    }
  }

  Future<bool> addComment(String taskId, String content) async {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in to comment.');
      return false;
    }

    try {
      final comment = await _repository.createComment(
        taskId: taskId,
        content: content,
        userId: currentUser.id,
        userName: currentUser.name,
        userAvatarUrl: currentUser.avatarUrl,
        isOnline: _connectivityService.isOnline,
      );
      final updated = [...state.comments, comment];
      state = state.copyWith(comments: updated);
      loadActivities(taskId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _messageFrom(e));
      return false;
    }
  }

  Future<void> deleteComment(String id, String taskId) async {
    final updatedList = state.comments.where((c) => c.id != id).toList();
    state = state.copyWith(comments: updatedList);

    try {
      await _repository.deleteComment(
        id: id,
        taskId: taskId,
        isOnline: _connectivityService.isOnline,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: _messageFrom(e));
    }
  }

  // ─── ACTIVITY LOG METHODS ─────────────────────────────────────────────────
  Future<void> loadActivities(String taskId) async {
    state = state.copyWith(isLoadingActivities: true);
    try {
      final activities = await _repository.getActivities(
        taskId,
        isOnline: _connectivityService.isOnline,
      );
      state = state.copyWith(activities: activities, isLoadingActivities: false);
    } catch (e) {
      state = state.copyWith(isLoadingActivities: false);
    }
  }
}
