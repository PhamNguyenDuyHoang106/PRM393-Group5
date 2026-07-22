import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../providers/providers.dart';
import '../repositories/project_repository.dart';
import '../services/connectivity_service.dart';

class ProjectState {
  ProjectState({
    List<Project> projects = const [],
    this.details,
    this.isLoadingProjects = false,
    this.isLoadingDetails = false,
    this.isSubmitting = false,
    this.isValidatingMember = false,
    this.errorMessage,
  }) : projects = List.unmodifiable(projects);

  final List<Project> projects;
  final ProjectDetails? details;
  final bool isLoadingProjects;
  final bool isLoadingDetails;
  final bool isSubmitting;
  final bool isValidatingMember;
  final String? errorMessage;

  ProjectState copyWith({
    List<Project>? projects,
    ProjectDetails? details,
    bool clearDetails = false,
    bool? isLoadingProjects,
    bool? isLoadingDetails,
    bool? isSubmitting,
    bool? isValidatingMember,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      details: clearDetails ? null : (details ?? this.details),
      isLoadingProjects: isLoadingProjects ?? this.isLoadingProjects,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValidatingMember: isValidatingMember ?? this.isValidatingMember,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProjectViewModel extends StateNotifier<ProjectState> {
  ProjectViewModel(this._repository, this._connectivityService, this._ref)
    : super(ProjectState());

  final ProjectRepository _repository;
  final ConnectivityService _connectivityService;
  final Ref _ref;

  Future<void> loadProjects({bool requireFresh = false}) async {
    state = state.copyWith(
      projects: requireFresh ? const [] : null,
      isLoadingProjects: true,
      clearError: true,
    );
    try {
      final currentUserId = _ref.read(authViewModelProvider).user?.id;
      final projects = await _repository.getProjects(
        isOnline: _connectivityService.isOnline,
        allowCacheFallback: !requireFresh,
        currentUserId: currentUserId,
      );
      state = state.copyWith(projects: projects, isLoadingProjects: false);
    } catch (error) {
      state = state.copyWith(
        isLoadingProjects: false,
        errorMessage: _messageFrom(error),
      );
    }
  }

  Future<void> loadProjectDetails(String projectId) async {
    final isAnotherProject = state.details?.project.id != projectId;
    state = state.copyWith(
      isLoadingDetails: true,
      clearDetails: isAnotherProject,
      clearError: true,
    );
    try {
      final details = await _repository.getProjectDetails(
        projectId,
        isOnline: _connectivityService.isOnline,
      );
      state = state.copyWith(
        details: details,
        projects: _upsertProject(state.projects, details.project),
        isLoadingDetails: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDetails: false,
        errorMessage: _messageFrom(error),
      );
    }
  }

  Future<Project?> createProject({
    required String name,
    required String description,
    required String ownerId,
    List<String> memberEmails = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final normalizedEmails = memberEmails
          .map((email) => email.trim().toLowerCase())
          .where((email) => email.isNotEmpty)
          .toSet()
          .toList();

      for (final email in normalizedEmails) {
        await _repository.findMemberByEmail(
          email,
          isOnline: _connectivityService.isOnline,
        );
      }

      final project = await _repository.createProject(
        name: name,
        description: description,
        ownerId: ownerId,
        isOnline: _connectivityService.isOnline,
      );

      var details = ProjectDetails(project: project);
      final failedEmails = <String>[];
      for (final email in normalizedEmails) {
        try {
          details = await _repository.addMember(
            projectId: project.id,
            email: email,
            isOnline: _connectivityService.isOnline,
            currentUserId: ownerId,
          );
        } catch (_) {
          failedEmails.add(email);
        }
      }

      state = state.copyWith(
        projects: _upsertProject(state.projects, project),
        details: details,
        isSubmitting: false,
        errorMessage: failedEmails.isEmpty
            ? null
            : 'Project created, but these members could not be added: '
                  '${failedEmails.join(', ')}',
        clearError: failedEmails.isEmpty,
      );
      _refreshDashboard();
      return project;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return null;
    }
  }

  Future<String?> validateMemberEmail(String email) async {
    state = state.copyWith(isValidatingMember: true, clearError: true);
    try {
      await _repository.findMemberByEmail(
        email,
        isOnline: _connectivityService.isOnline,
      );
      state = state.copyWith(isValidatingMember: false);
      return null;
    } catch (error) {
      final message = _memberValidationMessage(error);
      state = state.copyWith(isValidatingMember: false);
      return message;
    }
  }

  Future<bool> addMember({
    required String projectId,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existingMembers = state.details?.members ?? const <ProjectMember>[];
    if (existingMembers.any(
      (member) => member.email.toLowerCase() == normalizedEmail,
    )) {
      state = state.copyWith(
        errorMessage: 'This user is already a project member.',
      );
      return false;
    }

    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final details = await _repository.addMember(
        projectId: projectId,
        email: normalizedEmail,
        isOnline: _connectivityService.isOnline,
        currentUserId: currentUser.id,
      );
      state = state.copyWith(details: details, isSubmitting: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return false;
    }
  }

  Future<bool> removeMember({
    required String projectId,
    required String userId,
  }) async {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final details = await _repository.removeMember(
        projectId: projectId,
        userId: userId,
        isOnline: _connectivityService.isOnline,
        currentUserId: currentUser.id,
      );
      state = state.copyWith(details: details, isSubmitting: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return false;
    }
  }

  Future<Project?> updateProject({
    required String projectId,
    required String name,
    required String description,
  }) async {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final project = await _repository.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        isOnline: _connectivityService.isOnline,
        currentUserId: currentUser.id,
      );
      final currentDetails = state.details;
      state = state.copyWith(
        projects: _upsertProject(state.projects, project),
        details: currentDetails?.project.id == projectId
            ? currentDetails?.copyWith(project: project)
            : null,
        isSubmitting: false,
      );
      _refreshDashboard();
      return project;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return null;
    }
  }

  Future<bool> deleteProject(String projectId) async {
    final currentUser = _ref.read(authViewModelProvider).user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.deleteProject(
        projectId: projectId,
        isOnline: _connectivityService.isOnline,
        currentUserId: currentUser.id,
      );
      state = state.copyWith(
        projects: state.projects
            .where((project) => project.id != projectId)
            .toList(),
        clearDetails: state.details?.project.id == projectId,
        isSubmitting: false,
      );
      _refreshDashboard();
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Báo cho Dashboard biết dữ liệu project vừa đổi — bỏ cache thống kê cũ
  /// và tải lại để Dashboard/Statistics phản ánh ngay số liệu mới nhất.
  void _refreshDashboard() {
    _ref.read(statisticsRepositoryProvider).invalidateCache();
    final user = _ref.read(authViewModelProvider).user;
    if (user != null) {
      _ref
          .read(dashboardViewModelProvider.notifier)
          .refreshData(userId: user.id, role: user.role);
    }
  }

  List<Project> _upsertProject(List<Project> projects, Project project) {
    final updated = [...projects];
    final index = updated.indexWhere((item) => item.id == project.id);
    if (index == -1) {
      updated.insert(0, project);
    } else {
      updated[index] = project;
    }
    return updated;
  }

  String _messageFrom(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  String _memberValidationMessage(Object error) {
    final message = _messageFrom(error);
    if (message.toLowerCase().contains('not found')) {
      return 'No account was found for this email.';
    }
    return message;
  }
}
