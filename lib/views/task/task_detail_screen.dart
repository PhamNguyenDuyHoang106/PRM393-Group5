import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTask);
  }

  Future<void> _loadTask() {
    return ref.read(taskViewModelProvider.notifier).loadTask(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskViewModelProvider);
    final task = state.selectedTask?.id == widget.taskId
        ? state.selectedTask
        : null;
    final currentUser = ref.watch(authViewModelProvider).user;
    final strings = AppStrings(ref.watch(settingsViewModelProvider).isVietnamese);
    final isManager = currentUser?.isManager == true;
    final isAssigned = task != null && task.assignedTo == currentUser?.id;
    final canUpdateStatus = isManager || isAssigned;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.taskDetailTitle),
        actions: [
          if (task != null && isManager) ...[
            IconButton(
              tooltip: strings.editTaskTooltip,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditor(task),
            ),
            IconButton(
              tooltip: strings.deleteTaskTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _openDelete(task),
            ),
          ],
          if (task != null && canUpdateStatus && !isManager)
            IconButton(
              tooltip: strings.updateStatusTooltip,
              icon: const Icon(Icons.assignment_outlined),
              onPressed: () => _openStatus(task),
            ),
        ],
      ),
      body: _buildBody(
        state,
        task,
        canUpdateStatus: canUpdateStatus,
        isManager: isManager,
        strings: strings,
      ),
    );
  }

  Future<void> _openEditor(Task task) async {
    final updated = await context.push<bool>('/tasks/${task.id}/edit');
    if (updated == true) await _loadTask();
  }

  Future<void> _openStatus(Task task) async {
    final updated = await context.push<bool>('/tasks/${task.id}/status');
    if (updated == true) await _loadTask();
  }

  Future<void> _openDelete(Task task) async {
    await context.push<bool>('/tasks/${task.id}/delete');
  }

  Widget _buildBody(
    TaskState state,
    Task? task, {
    required bool canUpdateStatus,
    required bool isManager,
    required AppStrings strings,
  }) {
    if (state.isLoadingDetails && task == null) {
      return LoadingWidget(message: strings.loadingTaskDetails);
    }
    if (task == null) {
      return AppErrorDisplay(
        title: strings.taskUnavailable,
        error: state.errorMessage ?? strings.taskNotFound,
        onRetry: _loadTask,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTask,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 38,
                  color: Colors.white,
                ),
                const SizedBox(height: AppConstants.paddingMd),
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(label: strings.categoryLabel(task.priority)),
                    _Badge(label: strings.categoryLabel(task.status)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.description_outlined,
                    label: strings.descriptionLabel,
                    value: task.description.isEmpty
                        ? strings.noDescriptionProvided
                        : task.description,
                  ),
                  const Divider(height: AppConstants.paddingLg),
                  _DetailRow(
                    icon: Icons.folder_outlined,
                    label: strings.projectIdLabel,
                    value: task.projectId,
                  ),
                  const Divider(height: AppConstants.paddingLg),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: strings.assignedToLabel,
                    value: task.assignedTo ?? strings.unassigned,
                  ),
                  const Divider(height: AppConstants.paddingLg),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: strings.dueDateLabel,
                    value: task.dueDate == null
                        ? strings.noDueDate
                        : _formatDate(task.dueDate!),
                  ),
                  const Divider(height: AppConstants.paddingLg),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: strings.createdLabel,
                    value: _formatDate(task.createdAt),
                  ),
                ],
              ),
            ),
          ),
          if (canUpdateStatus || isManager) ...[
            const SizedBox(height: AppConstants.paddingLg),
            if (isManager) ...[
              FilledButton.icon(
                onPressed: () => _openEditor(task),
                icon: const Icon(Icons.edit_outlined),
                label: Text(strings.editTaskButton),
              ),
              const SizedBox(height: AppConstants.paddingSm),
              FilledButton.icon(
                onPressed: () => _openStatus(task),
                icon: const Icon(Icons.assignment_outlined),
                label: Text(strings.updateStatusButton),
              ),
              const SizedBox(height: AppConstants.paddingSm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _openDelete(task),
                icon: const Icon(Icons.delete_outline),
                label: Text(strings.deleteTaskButton),
              ),
            ] else
              FilledButton.icon(
                onPressed: () => _openStatus(task),
                icon: const Icon(Icons.assignment_outlined),
                label: Text(strings.updateStatusButton),
              ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppConstants.paddingMd),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
