import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../core/security/permission_service.dart';
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

  // ─── Helper: unwrap NestJS { success, data } envelope ────────────────────
  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ─── GET /projects ────────────────────────────────────────────────────────
  Future<List<Project>> getProjects({required bool isOnline}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/projects');
        final raw = _unwrap(response.data);
        if (raw is! List) throw const FormatException('Invalid projects response.');
        final projects = raw
            .whereType<Map>()
            .map((item) => Project.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        await _dbHelper.cacheProjects(projects);
        return projects;
      } catch (_) {
        // Fall back to cache below.
      }
    }
    final cached = await _dbHelper.getCachedProjects();
    if (cached.isNotEmpty) return cached;
    final demo = _buildDemoProject();
    await _dbHelper.cacheProjects([demo]);
    await _dbHelper.cacheProjectMembers(demo.id, _buildDemoMembers());
    return [demo];
  }

  // ─── GET /projects/:id ────────────────────────────────────────────────────
  Future<ProjectDetails> getProjectDetails(
    String projectId, {
    required bool isOnline,
  }) async {
    if (isOnline) {
      try {
        return await _getProjectDetailsFromApi(projectId);
      } catch (_) {}
    }
    return _getCachedProjectDetails(projectId);
  }

  // ─── POST /projects ───────────────────────────────────────────────────────
  Future<Project> createProject({
    required String name,
    required String description,
    required String ownerId,
    required bool isOnline,
  }) async {
    final caller = await _dbHelper.getCachedUser(ownerId);
    PermissionService.requireManager(caller, action: 'create projects');

    if (isOnline) {
      try {
        final response = await _dio.post(
          '/projects',
          data: {'name': name.trim(), 'description': description.trim()},
        );
        final raw = _unwrap(response.data);
        if (raw is! Map) throw const FormatException('Invalid create project response.');
        final project = Project.fromJson(Map<String, dynamic>.from(raw));
        await _dbHelper.cacheProjects([project]);
        return project;
      } catch (_) {}
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

  // ─── POST /projects/:id/members ───────────────────────────────────────────
  Future<ProjectDetails> addMember({
    required String projectId,
    required String email,
    required bool isOnline,
    required String currentUserId,
  }) async {
    final caller = await _dbHelper.getCachedUser(currentUserId);
    PermissionService.requireManager(caller, action: 'add members');

    if (isOnline) {
      try {
        await _dio.post(
          '/projects/$projectId/members',
          data: {'email': email},
        );
        try {
          return await _getProjectDetailsFromApi(projectId);
        } catch (_) {
          return _getCachedProjectDetails(projectId);
        }
      } catch (_) {}
    }

    await _enqueueAction('ADD_PROJECT_MEMBER', {
      'project_id': projectId,
      'email': email,
    });
    return _getCachedProjectDetails(projectId);
  }

  // ─── DELETE /projects/:id/members/:userId ─────────────────────────────────
  Future<ProjectDetails> removeMember({
    required String projectId,
    required String userId,
    required bool isOnline,
    required String currentUserId,
  }) async {
    final caller = await _dbHelper.getCachedUser(currentUserId);
    PermissionService.requireManager(caller, action: 'remove members');

    final details = await _getCachedProjectDetails(projectId);
    if (details.project.ownerId == userId) {
      throw const ProjectException('The project owner cannot be removed.');
    }

    if (isOnline) {
      try {
        await _dio.delete('/projects/$projectId/members/$userId');
        return _removeMemberFromCache(details, userId);
      } catch (_) {}
    }

    final updated = await _removeMemberFromCache(details, userId);
    await _enqueueAction('REMOVE_PROJECT_MEMBER', {
      'project_id': projectId,
      'user_id': userId,
    });
    return updated;
  }

  // ─── PUT /projects/:id ────────────────────────────────────────────────────
  Future<Project> updateProject({
    required String projectId,
    required String name,
    required String description,
    required bool isOnline,
    required String currentUserId,
  }) async {
    final caller = await _dbHelper.getCachedUser(currentUserId);
    PermissionService.requireManager(caller, action: 'update projects');

    if (isOnline) {
      try {
        final response = await _dio.put(
          '/projects/$projectId',
          data: {'name': name.trim(), 'description': description.trim()},
        );
        final raw = _unwrap(response.data);
        if (raw is! Map) throw const FormatException('Invalid update project response.');
        final project = Project.fromJson(Map<String, dynamic>.from(raw));
        await _dbHelper.cacheProjects([project]);
        return project;
      } catch (_) {}
    }

    final cached = await _dbHelper.getCachedProject(projectId);
    if (cached == null) throw const ProjectException('Project not found.');
    final updated = Project(
      id: cached.id,
      name: name.trim(),
      description: description.trim(),
      ownerId: cached.ownerId,
      createdAt: cached.createdAt,
    );
    await _dbHelper.cacheProjects([updated]);
    await _enqueueAction('UPDATE_PROJECT', updated.toJson());
    return updated;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────
  Future<ProjectDetails> _getProjectDetailsFromApi(String projectId) async {
    final response = await _dio.get('/projects/$projectId');
    final raw = _unwrap(response.data);
    if (raw is! Map) throw const FormatException('Invalid project detail response.');
    final details = ProjectDetails.fromJson(Map<String, dynamic>.from(raw));
    await _cacheProjectDetails(details);
    return details;
  }

  Future<ProjectDetails> _getCachedProjectDetails(String projectId) async {
    final project = await _dbHelper.getCachedProject(projectId);
    if (project == null) throw const ProjectException('Project not found.');
    final members = await _dbHelper.getCachedProjectMembers(projectId);
    return ProjectDetails(project: project, members: members);
  }

  Future<void> _cacheProjectDetails(ProjectDetails details) async {
    await _dbHelper.cacheProjects([details.project]);
    await _dbHelper.cacheProjectMembers(details.project.id, details.members);
  }

  Future<ProjectDetails> _removeMemberFromCache(
    ProjectDetails details,
    String userId,
  ) async {
    await _dbHelper.removeCachedProjectMember(details.project.id, userId);
    return details.copyWith(
      members: details.members.where((m) => m.id != userId).toList(),
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

  Project _buildDemoProject() => Project(
    id: 'proj_01',
    name: 'Smart Task App',
    description: 'Flutter MVVM SQLite group project',
    ownerId: 'usr_7719',
    createdAt: DateTime.now(),
  );

  List<ProjectMember> _buildDemoMembers() => const [
    ProjectMember(id: 'usr_7719', name: 'Hoang Team Lead', email: 'manager@gmail.com', role: 'Manager'),
    ProjectMember(id: 'usr_8231', name: 'Nguyen Member', email: 'member@gmail.com', role: 'Member'),
  ];
}

class ProjectException implements Exception {
  const ProjectException(this.message);
  final String message;
  @override
  String toString() => message;
}
