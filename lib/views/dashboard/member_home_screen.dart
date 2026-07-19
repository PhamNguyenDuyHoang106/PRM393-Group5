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

    final projectCount = stats?.totalProjects ?? 0;
    final assignedTasksCount = stats?.myTasks ?? 0;
    final completedTasksCount = stats?.completedTasks ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dashboardState.statistics == null &&
          !dashboardState.isLoading &&
          dashboardState.errorMessage == null) {
        ref.read(dashboardViewModelProvider.notifier).loadStatistics();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardViewModelProvider.notifier).refreshData();
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
                  ],
                ),
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
