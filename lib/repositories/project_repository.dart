import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../models/pending_action.dart';
import '../models/project.dart';

class ProjectRepository {
  ProjectRepository({DbHelper? dbHelper, Dio? dio, Uuid? uuid})
    : _dbHelper = dbHelper ?? DbHelper.instance,
      _dio = dio ?? DioClient.instance.dio,
      _uuid = uuid ?? const Uuid();

  final DbHelper _dbHelper;
  final Dio _dio;
  final Uuid _uuid;

  Future<List<Project>> getProjects({required bool isOnline}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/projects');
        final data = response.data;
        if (data is! List) {
          throw const FormatException('Invalid projects response.');
        }

        final projects = data
            .whereType<Map>()
            .map((item) => Project.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        await _dbHelper.cacheProjects(projects);
        return projects;
      } catch (_) {
        // Read the local cache below when the API is unavailable.
      }
    }

    final cachedProjects = await _dbHelper.getCachedProjects();
    if (cachedProjects.isNotEmpty) return cachedProjects;

    // Keep the MVP usable on its first offline launch.
    final demoProject = _buildDemoProject();
    await _dbHelper.cacheProjects([demoProject]);
    await _dbHelper.cacheProjectMembers(demoProject.id, _buildDemoMembers());
    return [demoProject];
  }

  Future<ProjectDetails> getProjectDetails(
    String projectId, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        return await _getProjectDetailsFromApi(projectId);
      } catch (_) {
        // Read the local cache below when the API is unavailable.
      }
    }
    return _getCachedProjectDetails(projectId);
  }

  Future<Project> createProject({
    required String name,
    required String description,
    required String ownerId,
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        final response = await _dio.post(
          '/projects',
          data: {'name': name.trim(), 'description': description.trim()},
        );
        final data = response.data;
        if (data is! Map) {
          throw const FormatException('Invalid create project response.');
        }

        final project = Project.fromJson(Map<String, dynamic>.from(data));
        await _dbHelper.cacheProjects([project]);
        return project;
      } catch (_) {
        // The request could not be completed. Save it locally below.
      }
    }

    final project = Project(
      id: _uuid.v4(),
      name: name.trim(),
      description: description.trim(),
      ownerId: ownerId,
      createdAt: DateTime.now(),
    );
    await _dbHelper.cacheProjects([project]);
    await _enqueueAction('CREATE_PROJECT', project.toJson());
    return project;
  }

  Future<ProjectDetails> addMember({
    required String projectId,
    required String email,
    required bool isOnline,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (isOnline) {
      try {
        await _dio.post(
          '/projects/add-member',
          data: {'project_id': projectId, 'user_email': normalizedEmail},
        );

        // Refreshing retrieves the canonical user id and display name.
        try {
          return await _getProjectDetailsFromApi(projectId);
        } catch (_) {
          return _addMemberToCache(projectId, normalizedEmail);
        }
      } catch (_) {
        // Queue the mutation below when the API is unavailable.
      }
    }

    final details = await _addMemberToCache(projectId, normalizedEmail);
    await _enqueueAction('ADD_PROJECT_MEMBER', {
      'project_id': projectId,
      'user_email': normalizedEmail,
    });
    return details;
  }

  Future<ProjectDetails> removeMember({
    required String projectId,
    required String userId,
    required bool isOnline,
  }) async {
    final details = await _getCachedProjectDetails(projectId);
    if (details.project.ownerId == userId) {
      throw const ProjectException('The project owner cannot be removed.');
    }

    if (isOnline) {
      try {
        await _dio.delete(
          '/projects/remove-member',
          data: {'project_id': projectId, 'user_id': userId},
        );
        return _removeMemberFromCache(details, userId);
      } catch (_) {
        // Queue the mutation below when the API is unavailable.
      }
    }

    final updatedDetails = await _removeMemberFromCache(details, userId);
    await _enqueueAction('REMOVE_PROJECT_MEMBER', {
      'project_id': projectId,
      'user_id': userId,
    });
    return updatedDetails;
  }

  Future<ProjectDetails> _getProjectDetailsFromApi(String projectId) async {
    final response = await _dio.get('/projects/$projectId');
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid project detail response.');
    }

    final details = ProjectDetails.fromJson(Map<String, dynamic>.from(data));
    await _cacheProjectDetails(details);
    return details;
  }

  Future<ProjectDetails> _getCachedProjectDetails(String projectId) async {
    final project = await _dbHelper.getCachedProject(projectId);
    if (project == null) {
      throw const ProjectException('Project not found.');
    }
    final members = await _dbHelper.getCachedProjectMembers(projectId);
    return ProjectDetails(project: project, members: members);
  }

  Future<void> _cacheProjectDetails(ProjectDetails details) async {
    await _dbHelper.cacheProjects([details.project]);
    await _dbHelper.cacheProjectMembers(details.project.id, details.members);
  }

  Future<ProjectDetails> _addMemberToCache(
    String projectId,
    String email,
  ) async {
    final details = await _getCachedProjectDetails(projectId);
    final alreadyExists = details.members.any(
      (member) => member.email.toLowerCase() == email,
    );
    if (alreadyExists) {
      throw const ProjectException('This user is already a project member.');
    }

    final member = ProjectMember(
      id: _uuid.v4(),
      name: _displayNameFromEmail(email),
      email: email,
      role: 'Member',
    );
    await _dbHelper.addCachedProjectMember(projectId, member);
    return details.copyWith(members: [...details.members, member]);
  }

  Future<ProjectDetails> _removeMemberFromCache(
    ProjectDetails details,
    String userId,
  ) async {
    await _dbHelper.removeCachedProjectMember(details.project.id, userId);
    return details.copyWith(
      members: details.members.where((member) => member.id != userId).toList(),
    );
  }

  Future<void> _enqueueAction(
    String actionType,
    Map<String, dynamic> payload,
  ) async {
    await _dbHelper.enqueueAction(
      PendingAction(
        id: _uuid.v4(),
        actionType: actionType,
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ),
    );
  }

  Project _buildDemoProject() {
    return Project(
      id: 'proj_01',
      name: 'Smart Task App',
      description: 'Flutter MVVM SQLite group project',
      ownerId: 'usr_7719',
      createdAt: DateTime.now(),
    );
  }

  List<ProjectMember> _buildDemoMembers() {
    return const [
      ProjectMember(
        id: 'usr_7719',
        name: 'Hoang Team Lead',
        email: 'manager@example.com',
        role: 'Manager',
      ),
      ProjectMember(
        id: 'usr_8231',
        name: 'Nguyen Van B',
        email: 'member@example.com',
        role: 'Member',
      ),
    ];
  }

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    return localPart
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class ProjectException implements Exception {
  final String message;

  const ProjectException(this.message);

  @override
  String toString() => message;
}
