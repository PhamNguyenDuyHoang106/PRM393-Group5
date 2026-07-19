import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final statsState = ref.watch(statisticsViewModelProvider);
    final stats = statsState.stats;

    final projectCount = stats?.totalProjects ?? 0;
    final totalTasksCount = stats?.totalTasks ?? 0;
    final completedTasksCount = stats?.completedTasks ?? 0;
    final completionRate = stats?.overallCompletionRate ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pState = ref.read(projectViewModelProvider);
      if (pState.projects.isEmpty && !pState.isLoadingProjects && pState.errorMessage == null) {
        ref.read(projectViewModelProvider.notifier).loadProjects();
      }
      final tState = ref.read(taskViewModelProvider);
      if (tState.tasks.isEmpty && !tState.isLoadingTasks && tState.errorMessage == null) {
        ref.read(taskViewModelProvider.notifier).loadTasks();
      }
      final sState = ref.read(statisticsViewModelProvider);
      if (sState.stats == null && !sState.isLoading && sState.errorMessage == null) {
        ref.read(statisticsViewModelProvider.notifier).loadDashboardStats();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Smart Task Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
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
          await ref.read(statisticsViewModelProvider.notifier).loadDashboardStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, ${user?.name ?? "Manager"}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              // ─── Simple Metric Grid ───
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Total Projects',
                      projectCount.toString(),
                      Icons.folder_outlined,
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
                      Icons.assignment_outlined,
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
                      Icons.check_circle_outline,
                      Colors.green,
                      '/tasks',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // ─── Completion Rate Progress Card ───
              if (stats != null && totalTasksCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Progress Tracker',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: completionRate / 100,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$completionRate%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/stats'),
                    child: const Text('View Charts', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
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
