import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_widget.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _projectId;
  String? _assignedTo;
  String _priority = 'MEDIUM';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final currentUserId = ref.read(authViewModelProvider).user?.id;
      final notifier = ref.read(projectViewModelProvider.notifier);
      await notifier.loadProjects();
      if (!mounted) return;
      final projects = ref.read(projectViewModelProvider).projects;
      if (projects.isNotEmpty) {
        setState(() {
          _projectId = projects.first.id;
          _assignedTo = currentUserId;
        });
        await notifier.loadProjectDetails(projects.first.id);
        if (mounted) _preferAssignToSelf();
      } else if (currentUserId != null) {
        setState(() => _assignedTo = currentUserId);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _changeProject(String? projectId) async {
    if (projectId == null) return;
    final currentUserId = ref.read(authViewModelProvider).user?.id;
    setState(() {
      _projectId = projectId;
      _assignedTo = currentUserId;
    });
    await ref
        .read(projectViewModelProvider.notifier)
        .loadProjectDetails(projectId);
    if (!mounted) return;
    _preferAssignToSelf();
  }

  void _preferAssignToSelf() {
    final currentUserId = ref.read(authViewModelProvider).user?.id;
    if (currentUserId == null) return;
    final details = ref.read(projectViewModelProvider).details;
    if (details?.project.id != _projectId) return;
    final members = details!.members;
    if (members.any((member) => member.id == currentUserId)) {
      setState(() => _assignedTo = currentUserId);
    } else if (_assignedTo == null) {
      // Still default to self so the task appears in My Tasks offline.
      setState(() => _assignedTo = currentUserId);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date != null && mounted) setState(() => _dueDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _projectId == null) return;
    final user = ref.read(authViewModelProvider).user;
    if (user == null || !user.isManager) return;

    final task = await ref
        .read(taskViewModelProvider.notifier)
        .createTask(
          projectId: _projectId!,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          assignedTo: _assignedTo ?? user.id,
          dueDate: _dueDate,
        );
    if (task != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task "${task.title}" created.')));
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final projectState = ref.watch(projectViewModelProvider);
    final taskState = ref.watch(taskViewModelProvider);

    if (authState.isLoading && authState.user == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Checking permissions...'),
      );
    }
    if (authState.user?.isManager != true) {
      return const _TaskAccessDenied(
        title: 'Create Task',
        message: 'Only managers can create tasks.',
      );
    }

    final members = projectState.details?.project.id == _projectId
        ? projectState.details!.members
        : const <ProjectMember>[];
    final currentUser = authState.user;
    final assigneeItems = <DropdownMenuItem<String>>[
      ...members.map(
        (member) => DropdownMenuItem(
          value: member.id,
          child: Text(member.name),
        ),
      ),
    ];
    if (currentUser != null &&
        !assigneeItems.any((item) => item.value == currentUser.id)) {
      assigneeItems.insert(
        0,
        DropdownMenuItem(
          value: currentUser.id,
          child: Text('${currentUser.name} (me)'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Define the work',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLg),
                DropdownButtonFormField<String>(
                  key: ValueKey('project-$_projectId'),
                  initialValue: _projectId,
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  items: projectState.projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      )
                      .toList(),
                  onChanged: projectState.isLoadingProjects
                      ? null
                      : _changeProject,
                  validator: (value) =>
                      value == null ? 'Select a project' : null,
                ),
                const SizedBox(height: AppConstants.paddingMd),
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Task Name',
                  hintText: 'e.g. Integrate Dio Client',
                  prefixIcon: Icons.task_outlined,
                  validator: (value) {
                    final title = value?.trim() ?? '';
                    if (title.isEmpty) return 'Task name is required';
                    if (title.length < 3) {
                      return 'Task name must be at least 3 characters';
                    }
                    if (title.length > 120) {
                      return 'Task name must not exceed 120 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMd),
                TextFormField(
                  controller: _descriptionController,
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
                  key: ValueKey('member-${members.length}-$_assignedTo'),
                  initialValue: assigneeItems.any((item) => item.value == _assignedTo)
                      ? _assignedTo
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Assign Member',
                    prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                  ),
                  items: assigneeItems,
                  onChanged: projectState.isLoadingDetails
                      ? null
                      : (value) => setState(() => _assignedTo = value),
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
                  onChanged: (value) =>
                      setState(() => _priority = value ?? 'MEDIUM'),
                ),
                const SizedBox(height: AppConstants.paddingMd),
                InkWell(
                  onTap: _pickDueDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      _dueDate == null ? 'No due date' : _formatDate(_dueDate!),
                    ),
                  ),
                ),
                if (taskState.errorMessage != null) ...[
                  const SizedBox(height: AppConstants.paddingMd),
                  Text(
                    taskState.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.paddingLg),
                CustomButton(
                  text: 'Create Task',
                  icon: Icons.add_task_rounded,
                  isLoading: taskState.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
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

class _TaskAccessDenied extends StatelessWidget {
  const _TaskAccessDenied({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppConstants.paddingMd),
              Text(
                'Access denied',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.paddingSm),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
