import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final projects = ref.watch(projectViewModelProvider).projects;
    final tasks = ref.watch(taskViewModelProvider).tasks;

    final projectCount = projects.length;
    final totalTasksCount = tasks.length;
    final completedTasksCount = tasks.where((t) => t.status == 'DONE').length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pState = ref.read(projectViewModelProvider);
      if (pState.projects.isEmpty && !pState.isLoadingProjects && pState.errorMessage == null) {
        ref.read(projectViewModelProvider.notifier).loadProjects();
      }
      final tState = ref.read(taskViewModelProvider);
      if (tState.tasks.isEmpty && !tState.isLoadingTasks && tState.errorMessage == null) {
        ref.read(taskViewModelProvider.notifier).loadTasks();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectViewModelProvider.notifier).loadProjects();
          await ref.read(taskViewModelProvider.notifier).loadTasks();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, ${user?.name ?? "Manager"}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Total Projects',
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
                      'Total Tasks',
                      totalTasksCount.toString(),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push('/stats'),
                    child: const Text('View Charts'),
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
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
