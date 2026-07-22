import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/user.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../models/notification.dart';
import '../../models/pending_action.dart';
import '../../models/statistics.dart';
import '../../models/checklist.dart';
import '../../models/comment.dart';
import '../../models/activity_log.dart';

class DbHelper {
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static Database? _database;
  static const String _dbName = 'smart_task.db';
  static const int _dbVersion = 2;

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
      onOpen: (db) async {
        await _createHistoryTable(db);
      },
    );
  }

  Future<void> _createHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS forgot_password_history (
        email TEXT,
        requested_at TEXT NOT NULL,
        verified_at TEXT,
        reset_completed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (email, requested_at)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_checklists (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_comments (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT,
        user_avatar_url TEXT,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT,
        action TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        old_data TEXT,
        new_data TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createHistoryTable(db);
    // 1. users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL,
        avatar_url TEXT
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

    // 7. task_checklists table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_checklists (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 8. task_comments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_comments (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT,
        user_avatar_url TEXT,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 9. audit_logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT,
        action TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        old_data TEXT,
        new_data TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN avatar_url TEXT');
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

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  Future<void> updateUserId({
    required String oldId,
    required String newId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'users',
        {'id': newId},
        where: 'id = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'projects',
        {'owner_id': newId},
        where: 'owner_id = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'project_members',
        {'user_id': newId},
        where: 'user_id = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'tasks',
        {'assigned_to': newId},
        where: 'assigned_to = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'notifications',
        {'user_id': newId},
        where: 'user_id = ?',
        whereArgs: [oldId],
      );
    });
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
    await db.transaction((transaction) async {
      await transaction.delete(
        'project_members',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await transaction.delete(
        'tasks',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await transaction.delete(
        'projects',
        where: 'id = ?',
        whereArgs: [projectId],
      );
    });
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

  // Calculate statistics from local tables
  // Calculate statistics from local tables with date range and user filters
  Future<Statistics> getLocalStatistics({String? dateRange, String? userId, String? role}) async {
    final db = await database;
    
    // 1. Establish user filter clauses
    String projectQuery = 'SELECT COUNT(*) as count FROM projects';
    String taskQuery = 'SELECT COUNT(*) as count FROM tasks';
    String completedQuery = "SELECT COUNT(*) as count FROM tasks WHERE status = 'DONE'";
    String pendingQuery = "SELECT COUNT(*) as count FROM tasks WHERE status != 'DONE'";
    String overdueQuery = "SELECT COUNT(*) as count FROM tasks WHERE status != 'DONE' AND due_date < ?";
    String statusQuery = 'SELECT status, COUNT(*) as count FROM tasks';
    String priorityQuery = 'SELECT priority, COUNT(*) as count FROM tasks';
    
    List<dynamic> projectArgs = [];
    List<dynamic> baseArgs = [];
    
    if (userId != null && role != null) {
      final isManager = role.toLowerCase() == 'manager';
      if (isManager) {
        projectQuery = 'SELECT COUNT(*) as count FROM projects WHERE owner_id = ?';
        projectArgs.add(userId);
        
        final managerTaskFilter = " WHERE project_id IN (SELECT id FROM projects WHERE owner_id = ?)";
        taskQuery += managerTaskFilter;
        completedQuery = "SELECT COUNT(*) as count FROM tasks WHERE status = 'DONE' AND project_id IN (SELECT id FROM projects WHERE owner_id = ?)";
        pendingQuery = "SELECT COUNT(*) as count FROM tasks WHERE status != 'DONE' AND project_id IN (SELECT id FROM projects WHERE owner_id = ?)";
        overdueQuery = "SELECT COUNT(*) as count FROM tasks WHERE status != 'DONE' AND due_date < ? AND project_id IN (SELECT id FROM projects WHERE owner_id = ?)";
        statusQuery += managerTaskFilter;
        priorityQuery += managerTaskFilter;
        baseArgs.add(userId);
      } else {
        // Member / employee
        projectQuery = 'SELECT COUNT(*) as count FROM project_members WHERE user_id = ?';
        projectArgs.add(userId);
        
        final memberTaskFilter = " WHERE assigned_to = ?";
        taskQuery += memberTaskFilter;
        completedQuery = "SELECT COUNT(*) as count FROM tasks WHERE status = 'DONE' AND assigned_to = ?";
        pendingQuery = "SELECT COUNT(*) as count FROM tasks WHERE status != 'DONE' AND assigned_to = ?";
        overdueQuery = "SELECT COUNT(*) as count FROM tasks WHERE status != 'DONE' AND due_date < ? AND assigned_to = ?";
        statusQuery += memberTaskFilter;
        priorityQuery += memberTaskFilter;
        baseArgs.add(userId);
      }
    }

    // 2. Establish date range filter clauses
    String filter = "";
    List<dynamic> filterArgs = [];
    final now = DateTime.now();
    final nowStr = now.toIso8601String();
    
    if (dateRange != null && dateRange != 'All Time') {
      if (dateRange == 'This Week') {
        final weekday = now.weekday;
        final startOfWeek = now.subtract(Duration(days: weekday - 1));
        final startStr = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String();
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        final endStr = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day).toIso8601String();
        filter = " due_date >= ? AND due_date < ? ";
        filterArgs.addAll([startStr, endStr]);
      } else if (dateRange == 'This Month') {
        final startStr = DateTime(now.year, now.month, 1).toIso8601String();
        // Calculate start of next month
        final nextMonthYear = now.month == 12 ? now.year + 1 : now.year;
        final nextMonthVal = now.month == 12 ? 1 : now.month + 1;
        final endStr = DateTime(nextMonthYear, nextMonthVal, 1).toIso8601String();
        filter = " due_date >= ? AND due_date < ? ";
        filterArgs.addAll([startStr, endStr]);
      }
    }

    // Combine filters
    if (filter.isNotEmpty) {
      final hasUserFilter = userId != null && role != null;
      final connector = hasUserFilter ? " AND " : " WHERE ";
      
      taskQuery += "$connector$filter";
      completedQuery += " AND $filter";
      pendingQuery += " AND $filter";
      overdueQuery += " AND $filter";
      
      statusQuery += "$connector$filter GROUP BY status";
      priorityQuery += "$connector$filter GROUP BY priority";
    } else {
      statusQuery += ' GROUP BY status';
      priorityQuery += ' GROUP BY priority';
    }

    List<dynamic> taskArgs = [...baseArgs, ...filterArgs];
    List<dynamic> completedArgs = [...baseArgs, ...filterArgs];
    List<dynamic> pendingArgs = [...baseArgs, ...filterArgs];
    List<dynamic> overdueArgs = [nowStr, ...baseArgs, ...filterArgs];

    final projectCountRes = await db.rawQuery(projectQuery, projectArgs.isNotEmpty ? projectArgs : null);
    final taskCountRes = await db.rawQuery(taskQuery, taskArgs.isNotEmpty ? taskArgs : null);
    final completedCountRes = await db.rawQuery(completedQuery, completedArgs.isNotEmpty ? completedArgs : null);
    final pendingCountRes = await db.rawQuery(pendingQuery, pendingArgs.isNotEmpty ? pendingArgs : null);
    final overdueCountRes = await db.rawQuery(overdueQuery, overdueArgs);

    final projectCount = Sqflite.firstIntValue(projectCountRes) ?? 0;
    final taskCount = Sqflite.firstIntValue(taskCountRes) ?? 0;
    final completedCount = Sqflite.firstIntValue(completedCountRes) ?? 0;
    final pendingCount = Sqflite.firstIntValue(pendingCountRes) ?? 0;
    final overdueCount = Sqflite.firstIntValue(overdueCountRes) ?? 0;

    final statusRes = await db.rawQuery(statusQuery, taskArgs.isNotEmpty ? taskArgs : null);
    final priorityRes = await db.rawQuery(priorityQuery, taskArgs.isNotEmpty ? taskArgs : null);

    final Map<String, int> statusDist = {};
    for (var r in statusRes) {
      if (r['status'] != null) {
        statusDist[r['status'] as String] = r['count'] as int;
      }
    }
    final Map<String, int> priorityDist = {};
    for (var r in priorityRes) {
      if (r['priority'] != null) {
        priorityDist[r['priority'] as String] = r['count'] as int;
      }
    }

    return Statistics(
      totalProjects: projectCount,
      totalTasks: taskCount,
      completedTasks: completedCount,
      pendingTasks: pendingCount,
      overdueTasks: overdueCount,
      taskStatusDistribution: statusDist,
      taskPriorityDistribution: priorityDist,
    );
  }

  // Alias for external use by repositories
  Future<void> deleteTask(String taskId) => deleteCachedTask(taskId);

  // Notifications Cache
  Future<void> cacheNotification(AppNotification notif) async {
    final db = await database;
    await db.insert(
      'notifications',
      notif.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<List<AppNotification>> getCachedNotifications({String? userId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = userId != null
        ? await db.query('notifications', where: 'user_id = ?', whereArgs: [userId])
        : await db.query('notifications');
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

  // --- Forgot Password Cache History ---
  Future<void> logOtpRequest(String email) async {
    final db = await database;
    await db.insert('forgot_password_history', {
      'email': email,
      'requested_at': DateTime.now().toIso8601String(),
      'verified_at': null,
      'reset_completed': 0,
    });
  }

  Future<void> logOtpVerification(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> requests = await db.query(
      'forgot_password_history',
      where: "email = ? AND verified_at IS NULL AND reset_completed = 0",
      orderBy: 'requested_at DESC',
      limit: 1,
    );
    if (requests.isNotEmpty) {
      final latestRequest = requests.first;
      await db.update(
        'forgot_password_history',
        {'verified_at': DateTime.now().toIso8601String()},
        where: 'email = ? AND requested_at = ?',
        whereArgs: [latestRequest['email'], latestRequest['requested_at']],
      );
    }
  }

  Future<void> logPasswordResetCompleted(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> requests = await db.query(
      'forgot_password_history',
      where: "email = ? AND verified_at IS NOT NULL AND reset_completed = 0",
      orderBy: 'requested_at DESC',
      limit: 1,
    );
    if (requests.isNotEmpty) {
      final latestRequest = requests.first;
      await db.update(
        'forgot_password_history',
        {'reset_completed': 1},
        where: 'email = ? AND requested_at = ?',
        whereArgs: [latestRequest['email'], latestRequest['requested_at']],
      );
    }
  }

  // --- CHECKLIST CACHE HELPERS ---
  Future<void> cacheChecklists(String taskId, List<TaskChecklist> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('task_checklists', where: 'task_id = ?', whereArgs: [taskId]);
      for (final item in items) {
        await txn.insert('task_checklists', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<TaskChecklist>> getCachedChecklists(String taskId) async {
    final db = await database;
    final maps = await db.query('task_checklists', where: 'task_id = ?', whereArgs: [taskId], orderBy: 'created_at ASC');
    return maps.map(TaskChecklist.fromJson).toList();
  }

  Future<void> saveCachedChecklist(TaskChecklist item) async {
    final db = await database;
    await db.insert('task_checklists', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCachedChecklist(String id) async {
    final db = await database;
    await db.delete('task_checklists', where: 'id = ?', whereArgs: [id]);
  }

  // --- COMMENT CACHE HELPERS ---
  Future<void> cacheComments(String taskId, List<TaskComment> comments) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('task_comments', where: 'task_id = ?', whereArgs: [taskId]);
      for (final c in comments) {
        await txn.insert('task_comments', c.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<TaskComment>> getCachedComments(String taskId) async {
    final db = await database;
    final maps = await db.query('task_comments', where: 'task_id = ?', whereArgs: [taskId], orderBy: 'created_at ASC');
    return maps.map(TaskComment.fromJson).toList();
  }

  Future<void> saveCachedComment(TaskComment comment) async {
    final db = await database;
    await db.insert('task_comments', comment.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCachedComment(String id) async {
    final db = await database;
    await db.delete('task_comments', where: 'id = ?', whereArgs: [id]);
  }

  // --- AUDITLOG CACHE HELPERS ---
  Future<void> cacheAuditLogs(String taskId, List<ActivityLog> logs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('audit_logs', where: 'entity_id = ?', whereArgs: [taskId]);
      for (final log in logs) {
        await txn.insert('audit_logs', log.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<ActivityLog>> getCachedAuditLogs(String taskId) async {
    final db = await database;
    final maps = await db.query('audit_logs', where: 'entity_id = ?', whereArgs: [taskId], orderBy: 'created_at DESC');
    return maps.map(ActivityLog.fromJson).toList();
  }

  Future<void> saveCachedAuditLog(ActivityLog log) async {
    final db = await database;
    await db.insert('audit_logs', log.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
