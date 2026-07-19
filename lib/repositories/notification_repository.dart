import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/db_helper.dart';
import '../models/notification.dart';

class NotificationRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<List<AppNotification>> getNotifications({String? userId, String? role}) async {
    try {
      final cached = await _dbHelper.getCachedNotifications(userId: userId);
      
      final prefs = await SharedPreferences.getInstance();
      final hasSeeded = prefs.getBool('notifs_seeded_${userId ?? "default"}') ?? false;

      if (hasSeeded) {
        return cached;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (userId != null) {
        final isManager = role?.toLowerCase() == 'manager';
        final seed = [
          AppNotification(
            id: 'notif_${userId}_001',
            userId: userId,
            title: isManager ? 'New Member Joined Project' : 'New Task Assigned',
            message: isManager
                ? 'Nguyen Member has accepted the invitation to join project "Smart Task App".'
                : 'You have been assigned to "Integrate Dio Client" by Hoang Manager.',
            readStatus: 0,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ];

        await _dbHelper.cacheNotifications(seed);
        await prefs.setBool('notifs_seeded_$userId', true);
        return seed;
      }
      
      return cached;
    } catch (_) {
      return await _dbHelper.getCachedNotifications(userId: userId);
    }
  }

  Future<void> markAsRead(AppNotification notification) async {
    final updated = notification.copyWith(readStatus: 1);
    await _dbHelper.cacheNotifications([updated]);

    try {
      // Put read status to API
      // await _dioClient.dio.put('/notifications/${notification.id}', data: updated.toJson());
    } catch (_) {
      // Suppress network errors
    }
  }

  Future<void> markAllAsRead() async {
    final notifs = await _dbHelper.getCachedNotifications();
    final updated = notifs.map((n) => n.copyWith(readStatus: 1)).toList();
    await _dbHelper.cacheNotifications(updated);

    try {
      // Put read status to API
      // await _dioClient.dio.put('/notifications/read-all');
    } catch (_) {
      // Suppress network errors
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );

    try {
      // Delete notification on API
      // await _dioClient.dio.delete('/notifications/$notificationId');
    } catch (_) {
      // Suppress network errors
    }
  }
}
