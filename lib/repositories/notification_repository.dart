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

  // ─── Helper: unwrap NestJS { success, data } envelope ────────────────────
  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ─── GET /notifications ───────────────────────────────────────────────────
  Future<List<AppNotification>> getNotifications({bool isOnline = true}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/notifications');
        final raw = _unwrap(response.data);
        if (raw is! List) throw const FormatException('Invalid notifications response.');
        final notifs = (raw)
            .whereType<Map>()
            .map((json) => AppNotification.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        await _dbHelper.cacheNotifications(notifs);
        return notifs;
      } catch (_) {}
    }
    return _dbHelper.getCachedNotifications();
  }

  // ─── GET /notifications/unread-count ─────────────────────────────────────
  Future<int> getUnreadCount({bool isOnline = true}) async {
    if (isOnline) {
      try {
        final response = await _dio.get('/notifications/unread-count');
        final raw = _unwrap(response.data);
        if (raw is Map && raw.containsKey('unreadCount')) {
          return (raw['unreadCount'] as num).toInt();
        }
      } catch (_) {}
    }
    final cached = await _dbHelper.getCachedNotifications();
    return cached.where((n) => n.readStatus == 0).length;
  }

  // ─── PUT /notifications/:id/read ─────────────────────────────────────────
  Future<void> markAsRead(AppNotification notification) async {
    final updated = notification.copyWith(readStatus: 1);
    await _dbHelper.cacheNotifications([updated]);

    try {
      await _dio.put('/notifications/${notification.id}/read');
    } catch (_) {
      // Notification read status is non-critical — suppress network errors.
    }
  }

  // ─── PUT /notifications/read-all ─────────────────────────────────────────
  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
      // Refresh local cache after marking all as read
      final cached = await _dbHelper.getCachedNotifications();
      final allRead = cached.map((n) => n.copyWith(readStatus: 1)).toList();
      await _dbHelper.cacheNotifications(allRead);
    } catch (_) {}
  }
}
