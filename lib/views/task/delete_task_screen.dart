import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class DeleteTaskScreen extends ConsumerStatefulWidget {
  const DeleteTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<DeleteTaskScreen> createState() => _DeleteTaskScreenState();
}

class _DeleteTaskScreenState extends ConsumerState<DeleteTaskScreen> {
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() {
    return ref.read(taskViewModelProvider.notifier).loadTask(widget.taskId);
  }

  Future<void> _delete(Task task) async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirm deletion before continuing.'),
        ),
      );
      return;
    }

    final deleted = await ref
        .read(taskViewModelProvider.notifier)
        .deleteTask(task.id);
    if (!mounted) return;

    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“${task.title}” deleted.')),
      );
      context.go('/tasks');
      return;
    }

    final error = ref.read(taskViewModelProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Could not delete task.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final task = state.selectedTask?.id == widget.taskId
        ? state.selectedTask
        : null;
    final isManager = user?.isManager == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Delete Task')),
      body: _buildBody(state, task, isManager: isManager),
    );
  }

  Widget _buildBody(
    TaskState state,
    Task? task, {
    required bool isManager,
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
    if (!isManager) {
      return const AppErrorDisplay(
        title: 'Access denied',
        error: 'Only managers can delete tasks.',
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        children: [
          Icon(Icons.delete_forever_outlined, size: 56, color: scheme.error),
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            'Delete this task permanently?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          Text(
            'This action cannot be undone. Related offline sync entries for '
            'this task will also be cleared.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${task.status.replaceAll('_', ' ')}'),
                  Text('Priority: ${task.priority}'),
                  Text('Assignee: ${task.assignedTo ?? 'Unassigned'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          CheckboxListTile(
            value: _confirmed,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I understand this task will be deleted forever.'),
            onChanged: state.isSubmitting
                ? null
                : (value) => setState(() => _confirmed = value ?? false),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              state.errorMessage!,
              style: TextStyle(color: scheme.error),
            ),
          ],
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: state.isSubmitting ? null : () => _delete(task),
            icon: state.isSubmitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onError,
                    ),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(state.isSubmitting ? 'Deleting...' : 'Delete permanently'),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton(
            onPressed: state.isSubmitting ? null : () => context.pop(false),
            child: const Text('Keep task'),
          ),
        ],
      ),
    );
  }
}
