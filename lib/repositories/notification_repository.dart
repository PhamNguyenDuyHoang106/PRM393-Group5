import 'package:dio/dio.dart';
import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../models/notification.dart';

class NotificationRepository {
  NotificationRepository({DbHelper? dbHelper, Dio? dio})
      : _dbHelper = dbHelper ?? DbHelper.instance,
        _dio = dio ?? DioClient.instance.dio;

  final DbHelper _dbHelper;
  final Dio _dio;

  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  Future<List<AppNotification>> getNotifications({String? userId, String? role}) async {
    try {
      final response = await _dio.get('/notifications');
      final raw = _unwrap(response.data);
      if (raw is! List) {
        throw const FormatException('Invalid notifications response.');
      }
      final notifications = raw
          .whereType<Map>()
          .map((json) => AppNotification.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      await _dbHelper.cacheNotifications(notifications);
      return notifications;
    } catch (_) {
      // Offline or API failure: fall back to the last synced local cache.
      return _dbHelper.getCachedNotifications(userId: userId);
    }
  }

  Future<void> markAsRead(AppNotification notification) async {
    final updated = notification.copyWith(readStatus: 1);
    await _dbHelper.cacheNotifications([updated]);

    try {
      await _dio.put('/notifications/${notification.id}/read');
    } catch (_) {
      // Suppress network errors; local state already reflects the change.
    }
  }

  Future<void> markAllAsRead() async {
    final notifs = await _dbHelper.getCachedNotifications();
    final updated = notifs.map((n) => n.copyWith(readStatus: 1)).toList();
    await _dbHelper.cacheNotifications(updated);

    try {
      await _dio.put('/notifications/read-all');
    } catch (_) {
      // Suppress network errors; local state already reflects the change.
    }
  }

  /// Local-only: the backend does not expose a delete endpoint, so dismissed
  /// notifications are only cleared from the offline cache.
  Future<void> deleteNotification(String notificationId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }
}
