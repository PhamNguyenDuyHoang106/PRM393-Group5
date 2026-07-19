import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/task_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(taskViewModelProvider.notifier)
          .loadTasks(projectId: widget.projectId),
    );
  }

  @override
  void didUpdateWidget(covariant TaskListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      Future.microtask(_refresh);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref
        .read(taskViewModelProvider.notifier)
        .loadTasks(projectId: widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskViewModelProvider);
    final canCreate = ref.watch(authViewModelProvider).user?.isManager ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectId == null ? 'My Tasks' : 'Project Tasks'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search title or description',
                  leading: const Icon(Icons.search_rounded),
                  elevation: WidgetStateProperty.all(0),
                  onChanged: ref
                      .read(taskViewModelProvider.notifier)
                      .setSearchQuery,
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(taskViewModelProvider.notifier)
                              .setSearchQuery('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSm),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _StatusChip(
                        label: 'All',
                        selected: state.statusFilter == null,
                        onSelected: () => ref
                            .read(taskViewModelProvider.notifier)
                            .setStatusFilter(null),
                      ),
                      for (final status in const [
                        'TODO',
                        'IN_PROGRESS',
                        'DONE',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _StatusChip(
                            label: status.replaceAll('_', ' '),
                            selected: state.statusFilter == status,
                            onSelected: () => ref
                                .read(taskViewModelProvider.notifier)
                                .setStatusFilter(status),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(state),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final created = await context.push<bool>('/tasks/create');
                      if (created == true) await _refresh();
                    },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New task'),
            )
          : null,
    );
  }

  Widget _buildBody(TaskState state) {
    if (state.isLoadingTasks && state.tasks.isEmpty) {
      return const LoadingWidget(message: 'Loading tasks...');
    }
    if (state.errorMessage != null && state.tasks.isEmpty) {
      return AppErrorDisplay(
        title: 'Unable to load tasks',
        error: state.errorMessage!,
        onRetry: _refresh,
      );
    }

    final tasks = state.filteredTasks;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (tasks.isEmpty)
            SizedBox(
              height: 380,
              child: EmptyWidget(
                title: state.tasks.isEmpty ? 'No tasks yet' : 'No tasks found',
                message: state.tasks.isEmpty
                    ? 'Tasks assigned to you will appear here.'
                    : 'Try another search term or status filter.',
                icon: Icons.task_alt_rounded,
              ),
            )
          else
            ...tasks.map(
              (task) => TaskCard(
                task: task,
                onTap: () => context.push('/tasks/${task.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
