import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class UpdateTaskStatusScreen extends ConsumerStatefulWidget {
  const UpdateTaskStatusScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<UpdateTaskStatusScreen> createState() =>
      _UpdateTaskStatusScreenState();
}

class _UpdateTaskStatusScreenState
    extends ConsumerState<UpdateTaskStatusScreen> {
  static const _statuses = ['TODO', 'IN_PROGRESS', 'DONE'];

  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await ref.read(taskViewModelProvider.notifier).loadTask(widget.taskId);
    if (!mounted) return;
    final task = ref.read(taskViewModelProvider).selectedTask;
    if (task != null && task.id == widget.taskId) {
      setState(() => _selectedStatus ??= task.status);
    }
  }

  Future<void> _save(Task task) async {
    final status = _selectedStatus;
    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a status before saving.')),
      );
      return;
    }
    if (status == task.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status is already up to date.')),
      );
      return;
    }

    final updated = await ref
        .read(taskViewModelProvider.notifier)
        .updateTask(task.copyWith(status: status));
    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${status.replaceAll('_', ' ')}.'),
        ),
      );
      context.pop(true);
      return;
    }

    final error = ref.read(taskViewModelProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Could not update status.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final task = state.selectedTask?.id == widget.taskId
        ? state.selectedTask
        : null;
    final canUpdate =
        user != null &&
        (user.isManager || (task != null && task.assignedTo == user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Update Status')),
      body: _buildBody(state, task, canUpdate: canUpdate),
    );
  }

  Widget _buildBody(
    TaskState state,
    Task? task, {
    required bool canUpdate,
  }) {
    if (state.isLoadingDetails && task == null) {
      return const LoadingWidget(message: 'Loading task...');
    }
    if (task == null) {
      return AppErrorDisplay(
        title: 'Task unavailable',
        error: state.errorMessage ?? 'Task not found.',
        onRetry: _load,
      );
    }
    if (!canUpdate) {
      return const AppErrorDisplay(
        title: 'Access denied',
        error: 'Only the assignee or a manager can update this task status.',
      );
    }

    final selected = _selectedStatus ?? task.status;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current status: ${task.status.replaceAll('_', ' ')}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text(
            'Select new status',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          ..._statuses.map((status) {
            final isSelected = selected == status;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(status.replaceAll('_', ' ')),
                subtitle: Text(_statusHint(status)),
                onTap: state.isSubmitting
                    ? null
                    : () => setState(() => _selectedStatus = status),
              ),
            );
          }),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppConstants.paddingLg),
          CustomButton(
            text: 'Save Status',
            icon: Icons.check_circle_outline,
            isLoading: state.isSubmitting,
            onPressed: () => _save(task),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton(
            onPressed: state.isSubmitting ? null : () => context.pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _statusHint(String status) {
    switch (status) {
      case 'TODO':
        return 'Not started yet';
      case 'IN_PROGRESS':
        return 'Currently being worked on';
      case 'DONE':
        return 'Completed';
      default:
        return '';
    }
  }
}
