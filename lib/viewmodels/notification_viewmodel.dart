import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';

/// Chế độ lọc thông báo trên màn Notification Center
enum NotificationFilter {
  all,
  unread,
  read,
}

/// State cho màn Notification Center.
class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? errorMessage;
  final NotificationFilter activeFilter;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.activeFilter = NotificationFilter.all,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
    NotificationFilter? activeFilter,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  /// Danh sách thông báo đã được lọc theo activeFilter
  List<AppNotification> get filteredNotifications {
    switch (activeFilter) {
      case NotificationFilter.unread:
        return notifications.where((n) => !n.isRead).toList();
      case NotificationFilter.read:
        return notifications.where((n) => n.isRead).toList();
      case NotificationFilter.all:
        return notifications;
    }
  }

  /// Số thông báo chưa đọc
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Kiểm tra có thông báo nào không
  bool get isEmpty => filteredNotifications.isEmpty;

  /// Label cho unread badge
  String get unreadBadgeLabel {
    if (unreadCount == 0) return '';
    if (unreadCount > 99) return '99+';
    return unreadCount.toString();
  }
}

/// ViewModel cho màn Notification Center.
/// Quản lý load, đọc, xoá và lọc thông báo.
class NotificationViewModel extends StateNotifier<NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationViewModel(this._notificationRepository)
      : super(NotificationState()) {
    loadNotifications();
  }

  /// Tải danh sách thông báo khi vào màn.
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifs = await _notificationRepository.getNotifications();
      // Sắp xếp mới nhất lên đầu
      notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(notifications: notifs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Đánh dấu một thông báo là đã đọc.
  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return; // Bỏ qua nếu đã đọc rồi
    await _notificationRepository.markAsRead(notification);

    // Cập nhật state ngay lập tức (optimistic update)
    final updated = state.notifications.map((n) {
      return n.id == notification.id ? n.copyWith(readStatus: 1) : n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  /// Đánh dấu tất cả thông báo là đã đọc.
  Future<void> markAllAsRead() async {
    await _notificationRepository.markAllAsRead();

    final updated =
        state.notifications.map((n) => n.copyWith(readStatus: 1)).toList();
    state = state.copyWith(notifications: updated);
  }

  /// Xoá một thông báo khỏi danh sách (sau khi swipe-to-dismiss).
  Future<void> deleteNotification(String notificationId) async {
    // Optimistic: xoá khỏi state trước
    final updated =
        state.notifications.where((n) => n.id != notificationId).toList();
    state = state.copyWith(notifications: updated);

    // Gọi repository xoá backend/cache
    await _notificationRepository.deleteNotification(notificationId);
  }

  /// Thay đổi bộ lọc hiển thị.
  void setFilter(NotificationFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  /// Reload thông báo (pull-to-refresh).
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Xoá thông báo lỗi.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
