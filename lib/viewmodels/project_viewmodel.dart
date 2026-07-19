import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../services/connectivity_service.dart';

import '../providers/providers.dart';

class ProjectState {
  ProjectState({
    List<Project> projects = const [],
    this.details,
    this.isLoadingProjects = false,
    this.isLoadingDetails = false,
    this.isSubmitting = false,
    this.errorMessage,
  }) : projects = List.unmodifiable(projects);

  final List<Project> projects;
  final ProjectDetails? details;
  final bool isLoadingProjects;
  final bool isLoadingDetails;
  final bool isSubmitting;
  final String? errorMessage;

  ProjectState copyWith({
    List<Project>? projects,
    ProjectDetails? details,
    bool clearDetails = false,
    bool? isLoadingProjects,
    bool? isLoadingDetails,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      details: clearDetails ? null : (details ?? this.details),
      isLoadingProjects: isLoadingProjects ?? this.isLoadingProjects,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
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

  Future<void> loadProjects() async {
    state = state.copyWith(isLoadingProjects: true, clearError: true);
    try {
      final projects = await _repository.getProjects(
        isOnline: _connectivityService.isOnline,
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
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final project = await _repository.createProject(
        name: name,
        description: description,
        ownerId: ownerId,
        isOnline: _connectivityService.isOnline,
      );
      state = state.copyWith(
        projects: _upsertProject(state.projects, project),
        isSubmitting: false,
      );
      return project;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFrom(error),
      );
      return null;
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

  void clearError() {
    state = state.copyWith(clearError: true);
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
}
