import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
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
    final strings = AppStrings(ref.watch(settingsViewModelProvider).isVietnamese);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectId == null ? strings.myTasksTitle : strings.projectTasksTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: strings.searchTitleOrDescription,
                  leading: const Icon(Icons.search_rounded),
                  elevation: WidgetStateProperty.all(0),
                  onChanged: ref
                      .read(taskViewModelProvider.notifier)
                      .setSearchQuery,
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: strings.clearSearch,
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
                        label: strings.filterAll,
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
                            label: strings.categoryLabel(status),
                            selected: state.statusFilter == status,
                            onSelected: () => ref
                                .read(taskViewModelProvider.notifier)
                                .setStatusFilter(status),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSm),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _StatusChip(
                        label: strings.filterAll,
                        selected: state.priorityFilter == null,
                        onSelected: () => ref
                            .read(taskViewModelProvider.notifier)
                            .setPriorityFilter(null),
                      ),
                      for (final priority in const [
                        'LOW',
                        'MEDIUM',
                        'HIGH',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _StatusChip(
                            label: strings.categoryLabel(priority),
                            selected: state.priorityFilter == priority,
                            onSelected: () => ref
                                .read(taskViewModelProvider.notifier)
                                .setPriorityFilter(priority),
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
      body: _buildBody(state, strings),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final created = await context.push<bool>('/tasks/create');
                      // createTask already upserts; reload from cache-aware API.
                      if (created == true && mounted) await _refresh();
                    },
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.newTaskButton),
            )
          : null,
    );
  }

  Widget _buildBody(TaskState state, AppStrings strings) {
    if (state.isLoadingTasks && state.tasks.isEmpty) {
      return LoadingWidget(message: strings.loadingTasks);
    }
    if (state.errorMessage != null && state.tasks.isEmpty) {
      return AppErrorDisplay(
        title: strings.unableToLoadTasks,
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
                title: state.tasks.isEmpty ? strings.noTasksYet : strings.noTasksFound,
                message: state.tasks.isEmpty
                    ? (widget.projectId == null
                          ? strings.createTaskAndAssign
                          : strings.noTasksInProject)
                    : strings.tryAnotherSearchOrFilter,
                icon: Icons.task_alt_rounded,
              ),
            )
          else
            ...tasks.map(
              (task) => TaskCard(
                task: task,
                onTap: () => context.push('/tasks/${task.id}'),
                strings: strings,
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
