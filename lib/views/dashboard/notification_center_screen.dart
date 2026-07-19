import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../viewmodels/notification_viewmodel.dart';

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
      ref.read(notificationViewModelProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationViewModelProvider);
    final notifier = ref.read(notificationViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, color: Colors.blue),
              label: const Text('Mark all as read', style: TextStyle(color: Colors.blue)),
              onPressed: () => notifier.markAllAsRead(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(state, notifier),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationsList(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(NotificationState state, NotificationViewModel notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: state.activeFilter == NotificationFilter.all,
            onSelected: (_) => notifier.setFilter(NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('Unread (${state.unreadCount})'),
            selected: state.activeFilter == NotificationFilter.unread,
            onSelected: (_) => notifier.setFilter(NotificationFilter.unread),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Read'),
            selected: state.activeFilter == NotificationFilter.read,
            onSelected: (_) => notifier.setFilter(NotificationFilter.read),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No notifications found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationState state, NotificationViewModel notifier) {
    final list = state.filteredNotifications;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
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
                const SnackBar(content: Text('Notification deleted')),
              );
            },
            child: ListTile(
              onTap: () => notifier.markAsRead(notif),
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
                    _formatTime(notif.createdAt),
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

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
