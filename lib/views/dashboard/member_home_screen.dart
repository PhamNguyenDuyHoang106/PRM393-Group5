import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/error_widget.dart';

class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final stats = dashboardState.statistics;

    // Watch settings and notifications for dynamic badge
    final settingsState = ref.watch(settingsViewModelProvider);
    final notificationState = ref.watch(notificationViewModelProvider);
    final isPushEnabled = settingsState.isPushNotificationEnabled;
    final unreadCount = notificationState.unreadCount;

    final projectCount = stats?.totalProjects ?? 0;
    final assignedTasksCount = stats?.myTasks ?? 0;
    final completedTasksCount = stats?.completedTasks ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dashboardState.statistics == null &&
          !dashboardState.isLoading &&
          dashboardState.errorMessage == null &&
          user != null) {
        ref.read(dashboardViewModelProvider.notifier).loadStatistics(
          userId: user.id,
          role: user.role,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Home'),
        actions: [
          IconButton(
            icon: isPushEnabled && unreadCount > 0
                ? Badge(
                    label: Text(unreadCount.toString()),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.notifications_none_outlined),
                  )
                : const Icon(Icons.notifications_none_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await ref.read(dashboardViewModelProvider.notifier).refreshData(
              userId: user.id,
              role: user.role,
            );
          }
        },
        child: dashboardState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : dashboardState.errorMessage != null && stats == null
            ? AppErrorDisplay(
                title: 'Unable to load your data',
                error: dashboardState.errorMessage!,
                onRetry: () => ref
                    .read(dashboardViewModelProvider.notifier)
                    .loadStatistics(),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, ${user?.name ?? "Member"}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            'My Projects',
                            projectCount.toString(),
                            Icons.folder,
                            Colors.blue,
                            '/projects',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            'Tasks Assigned',
                            assignedTasksCount.toString(),
                            Icons.assignment,
                            Colors.amber,
                            '/tasks',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            'Completed Tasks',
                            completedTasksCount.toString(),
                            Icons.check_circle,
                            Colors.green,
                            '/tasks',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildOverallProgressBar(assignedTasksCount, completedTasksCount),
                    const SizedBox(height: 20),

                    if (stats != null && stats.overdueTasksList.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'My Overdue Tasks',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stats.overdueTasksList.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final item = stats.overdueTasksList[i];
                            return ListTile(
                              dense: true,
                              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Due: ${_formatDueDate(item.dueDate)}'),
                              trailing: Chip(
                                label: Text(item.priority),
                                backgroundColor: Colors.red.shade50,
                                labelStyle: const TextStyle(color: Colors.red, fontSize: 11),
                              ),
                              onTap: () => context.push('/tasks/${item.id}'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (stats != null && stats.upcomingTasksList.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.event_available_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'My Upcoming Tasks',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stats.upcomingTasksList.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final item = stats.upcomingTasksList[i];
                            return ListTile(
                              dense: true,
                              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Due: ${_formatDueDate(item.dueDate)}'),
                              trailing: Chip(
                                label: Text(item.status),
                                backgroundColor: Colors.orange.shade50,
                                labelStyle: const TextStyle(color: Colors.orange, fontSize: 11),
                              ),
                              onTap: () => context.push('/tasks/${item.id}'),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildOverallProgressBar(int total, int completed) {
    final double percentage = total > 0 ? (completed / total) : 0.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overall Completion Rate',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed of $total tasks completed',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
