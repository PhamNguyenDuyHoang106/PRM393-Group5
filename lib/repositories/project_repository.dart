import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/database/db_helper.dart';
import '../models/project.dart';
import '../models/pending_action.dart';

class ProjectRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<List<Project>> getProjects() async {
    try {
      // Try hitting API first
      // final response = await _dioClient.dio.get('/projects');
      // final List data = response.data;
      // final List<Project> projects = data.map((json) => Project.fromJson(json)).toList();

      // Mock delay
      await Future.delayed(const Duration(milliseconds: 500));
      final projects = [
        Project(
          id: 'proj_01',
          name: 'Smart Task App',
          description: 'Flutter MVVM SQLite group project',
          ownerId: 'usr_7719',
          createdAt: DateTime.now(),
        ),
      ];

      // Update cache
      await _dbHelper.cacheProjects(projects);
      return projects;
    } catch (_) {
      // Offline fallback: load from SQLite cache
      return await _dbHelper.getCachedProjects();
    }
  }

  Future<Project> createProject(String name, String description, String ownerId, bool isOnline) async {
    final newProject = Project(
      id: const Uuid().v4(),
      name: name,
      description: description,
      ownerId: ownerId,
      createdAt: DateTime.now(),
    );

    if (isOnline) {
      try {
        // Post to api
        // await _dioClient.dio.post('/projects', data: newProject.toJson());
        await _dbHelper.cacheProjects([newProject]);
        return newProject;
      } catch (e) {
        // If request fails, fall through to offline caching
      }
    }

    // Offline logic: Cache locally + Enqueue sync action
    await _dbHelper.cacheProjects([newProject]);
    final pendingAction = PendingAction(
      id: const Uuid().v4(),
      actionType: 'CREATE_PROJECT',
      payload: jsonEncode(newProject.toJson()),
      createdAt: DateTime.now(),
    );
    await _dbHelper.enqueueAction(pendingAction);

    return newProject;
  }
}
