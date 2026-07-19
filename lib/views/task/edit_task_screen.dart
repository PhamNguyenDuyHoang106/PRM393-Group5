import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  const EditTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Task? _task;
  String _priority = 'MEDIUM';
  String _status = 'TODO';
  String? _assignedTo;
  DateTime? _dueDate;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await ref.read(taskViewModelProvider.notifier).loadTask(widget.taskId);
    if (!mounted) return;
    final task = ref.read(taskViewModelProvider).selectedTask;
    if (task == null || task.id != widget.taskId) return;
    _initializeForm(task);
    await ref
        .read(projectViewModelProvider.notifier)
        .loadProjectDetails(task.projectId);
  }

  void _initializeForm(Task task) {
    if (_initialized) return;
    _task = task;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _priority = task.priority;
    _status = task.status;
    _assignedTo = task.assignedTo;
    _dueDate = task.dueDate;
    _initialized = true;
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date != null && mounted) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _task == null) return;
    final isManager = ref.read(authViewModelProvider).user?.isManager == true;
    final updated = _task!.copyWith(
      title: isManager ? _titleController.text.trim() : _task!.title,
      description: isManager
          ? _descriptionController.text.trim()
          : _task!.description,
      priority: isManager ? _priority : _task!.priority,
      status: _status,
      assignedTo: isManager ? _assignedTo : _task!.assignedTo,
      dueDate: isManager ? _dueDate : _task!.dueDate,
      clearAssignedTo: isManager && _assignedTo == null,
      clearDueDate: isManager && _dueDate == null,
    );
    final result = await ref
        .read(taskViewModelProvider.notifier)
        .updateTask(updated);
    if (result != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task updated.')));
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskViewModelProvider);
    final projectState = ref.watch(projectViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final task = taskState.selectedTask?.id == widget.taskId
        ? taskState.selectedTask
        : null;
    if (!_initialized && task != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _initializeForm(task),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: _buildBody(taskState, projectState, user?.isManager == true),
    );
  }

  Widget _buildBody(
    TaskState taskState,
    ProjectState projectState,
    bool isManager,
  ) {
    if ((taskState.isLoadingDetails || !_initialized) && _task == null) {
      return const LoadingWidget(message: 'Loading task...');
    }
    if (_task == null) {
      return AppErrorDisplay(
        title: 'Task unavailable',
        error: taskState.errorMessage ?? 'Task not found.',
        onRetry: _load,
      );
    }

    final members = projectState.details?.project.id == _task!.projectId
        ? projectState.details!.members
        : const <ProjectMember>[];
    final assigneeExists = members.any((member) => member.id == _assignedTo);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isManager)
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingLg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMd,
                    ),
                  ),
                  child: const Text(
                    'Members can update task status. Other fields are manager-only.',
                  ),
                ),
              TextFormField(
                controller: _titleController,
                enabled: isManager,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  prefixIcon: Icon(Icons.task_outlined),
                ),
                validator: (value) {
                  if ((value?.trim().length ?? 0) < 3) {
                    return 'Task name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMd),
              TextFormField(
                controller: _descriptionController,
                enabled: isManager,
                minLines: 3,
                maxLines: 6,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMd),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const ['LOW', 'MEDIUM', 'HIGH']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: isManager
                    ? (value) => setState(() => _priority = value ?? _priority)
                    : null,
              ),
              const SizedBox(height: AppConstants.paddingMd),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.change_circle_outlined),
                ),
                items: const ['TODO', 'IN_PROGRESS', 'DONE']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              if (isManager) ...[
                const SizedBox(height: AppConstants.paddingMd),
                DropdownButtonFormField<String>(
                  key: ValueKey('assignee-${members.length}-$_assignedTo'),
                  initialValue: assigneeExists ? _assignedTo! : '',
                  decoration: const InputDecoration(
                    labelText: 'Assign Member',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Unassigned'),
                    ),
                    ...members.map(
                      (member) => DropdownMenuItem<String>(
                        value: member.id,
                        child: Text(member.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(
                    () => _assignedTo = value == null || value.isEmpty
                        ? null
                        : value,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMd),
                InkWell(
                  onTap: _pickDueDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: const Icon(Icons.event_outlined),
                      suffixIcon: _dueDate == null
                          ? null
                          : IconButton(
                              tooltip: 'Clear due date',
                              onPressed: () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    child: Text(
                      _dueDate == null ? 'No due date' : _formatDate(_dueDate!),
                    ),
                  ),
                ),
              ],
              if (taskState.errorMessage != null) ...[
                const SizedBox(height: AppConstants.paddingMd),
                Text(
                  taskState.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppConstants.paddingLg),
              CustomButton(
                text: 'Update Task',
                icon: Icons.save_outlined,
                isLoading: taskState.isSubmitting,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
