import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_strings.dart';
import '../../providers/providers.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../models/notification.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      ref.read(notificationViewModelProvider.notifier).loadNotifications(
        userId: user?.id,
        role: user?.role,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationViewModelProvider);
    final notifier = ref.read(notificationViewModelProvider.notifier);
    final strings = AppStrings(ref.watch(settingsViewModelProvider).isVietnamese);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.notificationsTitle),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, color: Colors.blue),
              label: Text(strings.markAllAsRead, style: const TextStyle(color: Colors.blue)),
              onPressed: () => notifier.markAllAsRead(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(state, notifier, strings),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.isEmpty
                    ? _buildEmptyState(strings)
                    : _buildNotificationsList(state, notifier, strings),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(NotificationState state, NotificationViewModel notifier, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            label: Text(strings.filterAll),
            selected: state.activeFilter == NotificationFilter.all,
            onSelected: (_) => notifier.setFilter(NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('${strings.filterUnread} (${state.unreadCount})'),
            selected: state.activeFilter == NotificationFilter.unread,
            onSelected: (_) => notifier.setFilter(NotificationFilter.unread),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(strings.filterRead),
            selected: state.activeFilter == NotificationFilter.read,
            onSelected: (_) => notifier.setFilter(NotificationFilter.read),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            strings.noNotificationsFound,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationState state, NotificationViewModel notifier, AppStrings strings) {
    final list = state.filteredNotifications;

    return RefreshIndicator(
      onRefresh: () {
        final user = ref.read(authViewModelProvider).user;
        return notifier.refresh(userId: user?.id, role: user?.role);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final notif = list[index];

          return Dismissible(
            key: Key(notif.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              notifier.deleteNotification(notif.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.notificationDeleted)),
              );
            },
            child: ListTile(
              onTap: () {
                notifier.markAsRead(notif);
                _showNotificationDetailsDialog(context, notif, strings);
              },
              leading: Icon(
                notif.readStatus == 1 ? Icons.drafts : Icons.mark_as_unread,
                color: notif.readStatus == 1 ? Colors.grey : Colors.blue,
              ),
              title: Text(
                notif.title,
                style: TextStyle(
                  fontWeight: notif.readStatus == 1 ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(notif.message),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notif.createdAt, strings),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.zero,
            ),
          );
        },
      ),
    );
  }

  void _showNotificationDetailsDialog(BuildContext context, AppNotification notif, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          notif.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notif.message,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                strings.receivedAt(_formatTime(notif.createdAt, strings)),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.close, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, AppStrings strings) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return strings.justNow;
    if (diff.inMinutes < 60) return strings.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return strings.hoursAgo(diff.inHours);
    return '${time.day}/${time.month}/${time.year}';
  }
}
