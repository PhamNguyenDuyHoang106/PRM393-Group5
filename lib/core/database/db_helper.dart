import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/user.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../models/notification.dart';
import '../../models/pending_action.dart';

class DbHelper {
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static Database? _database;
  static const String _dbName = 'smart_task.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        owner_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. project_members table
    await db.execute('''
      CREATE TABLE project_members (
        project_id TEXT,
        user_id TEXT,
        PRIMARY KEY (project_id, user_id)
      )
    ''');

    // 4. tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        assigned_to TEXT,
        due_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        read_status INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 6. pending_actions table (Offline Sync Queue)
    await db.execute('''
      CREATE TABLE pending_actions (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implement database migrations in future versions
    if (oldVersion < 2) {
      // Future Migration code
    }
  }

  // --- CRUD HELPERS FOR CACHING & OFFLINE VIEWS ---

  // Users Cache
  Future<void> cacheUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getCachedUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  // Projects Cache
  Future<void> cacheProjects(List<Project> projects) async {
    final db = await database;
    final batch = db.batch();
    for (var project in projects) {
      batch.insert(
        'projects',
        project.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Project>> getCachedProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Project.fromJson(m)).toList();
  }

  Future<Project?> getCachedProject(String projectId) async {
    final db = await database;
    final maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Project.fromJson(maps.first);
  }

  Future<void> cacheProjectMembers(
    String projectId,
    List<ProjectMember> members,
  ) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'project_members',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );

      for (final member in members) {
        await transaction.insert('users', {
          ...member.toJson(),
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await transaction.insert('project_members', {
          'project_id': projectId,
          'user_id': member.id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<ProjectMember>> getCachedProjectMembers(String projectId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT users.id, users.name, users.email, users.role
      FROM users
      INNER JOIN project_members
        ON project_members.user_id = users.id
      WHERE project_members.project_id = ?
      ORDER BY users.name COLLATE NOCASE ASC
      ''',
      [projectId],
    );
    return maps.map(ProjectMember.fromJson).toList();
  }

  Future<void> addCachedProjectMember(
    String projectId,
    ProjectMember member,
  ) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.insert('users', {
        ...member.toJson(),
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await transaction.insert('project_members', {
        'project_id': projectId,
        'user_id': member.id,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> removeCachedProjectMember(
    String projectId,
    String userId,
  ) async {
    final db = await database;
    await db.delete(
      'project_members',
      where: 'project_id = ? AND user_id = ?',
      whereArgs: [projectId, userId],
    );
  }

  Future<void> deleteCachedProject(String projectId) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [projectId]);
  }

  // Tasks Cache
  Future<void> cacheTasks(List<Task> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (var task in tasks) {
      batch.insert(
        'tasks',
        task.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Task>> getCachedTasks({String? projectId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: projectId != null ? 'project_id = ?' : null,
      whereArgs: projectId != null ? [projectId] : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Task.fromJson(m)).toList();
  }

  Future<Task?> getCachedTask(String taskId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromJson(maps.first);
  }

  Future<void> deleteCachedTask(String taskId) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // Notifications Cache
  Future<void> cacheNotifications(List<AppNotification> notifications) async {
    final db = await database;
    final batch = db.batch();
    for (var notif in notifications) {
      batch.insert(
        'notifications',
        notif.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AppNotification>> getCachedNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notifications');
    return maps.map((m) => AppNotification.fromJson(m)).toList();
  }

  // Pending Actions Sync Queue CRUD
  Future<void> enqueueAction(PendingAction action) async {
    final db = await database;
    await db.insert(
      'pending_actions',
      action.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PendingAction>> getPendingActions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_actions',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => PendingAction.fromJson(m)).toList();
  }

  Future<void> dequeueAction(String actionId) async {
    final db = await database;
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [actionId]);
  }
}
