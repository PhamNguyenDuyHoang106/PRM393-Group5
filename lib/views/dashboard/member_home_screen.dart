import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
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
    final strings = AppStrings(settingsState.isVietnamese);

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
        title: Text(strings.memberHomeTitle),
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
                title: strings.unableToLoadData,
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
                      strings.greeting(user?.name ?? 'Member'),
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
                            strings.myProjects,
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
                            strings.tasksAssigned,
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
                            strings.completedTasks,
                            completedTasksCount.toString(),
                            Icons.check_circle,
                            Colors.green,
                            '/tasks',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.progressStatistics,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/stats'),
                    child: Text(strings.viewCharts),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildOverallProgressBar(assignedTasksCount, completedTasksCount, strings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgressBar(int total, int completed, AppStrings strings) {
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
                Text(
                  strings.overallCompletionRate,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              strings.tasksCompletedOf(completed, total),
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
