import '../core/database/db_helper.dart';
import '../models/notification.dart';

class NotificationRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<List<AppNotification>> getNotifications() async {
    try {
      // final response = await _dioClient.dio.get('/notifications');
      // final List data = response.data;
      // final List<AppNotification> notifs = data.map((json) => AppNotification.fromJson(json)).toList();

      await Future.delayed(const Duration(milliseconds: 500));
      final notifs = [
        AppNotification(
          id: 'notif_001',
          userId: 'usr_7719',
          title: 'New Task Assigned',
          message: 'You have been assigned to Integrate Dio Client by Hoang Manager.',
          readStatus: 0,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];

      await _dbHelper.cacheNotifications(notifs);
      return notifs;
    } catch (_) {
      return await _dbHelper.getCachedNotifications();
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
