import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref
          .read(projectViewModelProvider.notifier)
          .loadProjectDetails(widget.projectId),
      ref
          .read(taskViewModelProvider.notifier)
          .loadTasks(projectId: widget.projectId),
    ]);
  }

  Future<void> _openEditor() async {
    final changed = await context.push<bool>(
      '/projects/${widget.projectId}/edit',
    );
    if (changed == true) await _refresh();
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Delete project?'),
        content: Text(
          'Delete “${project.name}”? Its tasks and member links will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await ref
        .read(projectViewModelProvider.notifier)
        .deleteProject(project.id);
    if (!mounted || !deleted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('“${project.name}” deleted.')));
    context.go('/projects');
  }

  void _openTasks(String? status) {
    final notifier = ref.read(taskViewModelProvider.notifier);
    if (status == null) {
      notifier.setStatusFilter(null);
    } else {
      notifier.setStatusFilter(status);
    }
    context.go('/tasks?projectId=${Uri.encodeComponent(widget.projectId)}');
  }

  Future<void> _copyProjectId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Project ID copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectViewModelProvider);
    final taskState = ref.watch(taskViewModelProvider);
    final currentUser = ref.watch(authViewModelProvider).user;
    final details = state.details?.project.id == widget.projectId
        ? state.details
        : null;
    final isOwner = details?.project.ownerId == currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Edit project',
              onPressed: state.isSubmitting ? null : _openEditor,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (isOwner && details != null)
            PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (value) {
                if (value == 'members') {
                  context.push('/projects/${widget.projectId}/members');
                } else if (value == 'delete') {
                  _deleteProject(details.project);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'members',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.manage_accounts_outlined),
                    title: Text('Manage members'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Delete project',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(state, details, taskState.tasks, isOwner),
    );
  }

  Widget _buildBody(
    ProjectState state,
    ProjectDetails? details,
    List<Task> allTasks,
    bool isOwner,
  ) {
    if (state.isLoadingDetails && details == null) {
      return const LoadingWidget(message: 'Loading project details...');
    }
    if (details == null) {
      return AppErrorDisplay(
        title: 'Project unavailable',
        error: state.errorMessage ?? 'Project not found.',
        onRetry: _refresh,
      );
    }

    final project = details.project;
    final tasks = allTasks
        .where((task) => task.projectId == widget.projectId)
        .toList();
    final todo = tasks.where((task) => task.status == 'TODO').length;
    final inProgress = tasks
        .where((task) => task.status == 'IN_PROGRESS')
        .length;
    final done = tasks.where((task) => task.status == 'DONE').length;
    final completion = tasks.isEmpty
        ? 0
        : ((done / tasks.length) * 100).round();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          _ProjectHero(project: project),
          const SizedBox(height: AppConstants.paddingMd),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Project ID',
                    value: project.id,
                    onTap: () => _copyProjectId(project.id),
                  ),
                  const Divider(height: AppConstants.paddingLg),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Created',
                    value: _formatDate(project.createdAt),
                  ),
                  const Divider(height: AppConstants.paddingLg),
                  _DetailRow(
                    icon: Icons.people_outline_rounded,
                    label: 'Members',
                    value: '${details.members.length}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          _SectionTitle(
            title: 'Task progress',
            actionLabel: 'View all',
            onAction: () => _openTasks(null),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppConstants.paddingSm,
            mainAxisSpacing: AppConstants.paddingSm,
            childAspectRatio: 1.7,
            children: [
              _TaskMetric(
                label: 'All tasks',
                value: '${tasks.length}',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _openTasks(null),
              ),
              _TaskMetric(
                label: 'Completed',
                value: '$completion%',
                color: AppConstants.doneColor,
                onTap: () => _openTasks('DONE'),
              ),
              _TaskMetric(
                label: 'To do',
                value: '$todo',
                color: AppConstants.todoColor,
                onTap: () => _openTasks('TODO'),
              ),
              _TaskMetric(
                label: 'In progress',
                value: '$inProgress',
                color: AppConstants.inProgressColor,
                onTap: () => _openTasks('IN_PROGRESS'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLg),
          _SectionTitle(
            title: 'Project members',
            actionLabel: isOwner ? 'Manage' : null,
            onAction: isOwner
                ? () => context.push('/projects/${widget.projectId}/members')
                : null,
          ),
          const SizedBox(height: AppConstants.paddingSm),
          if (details.members.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingLg),
                child: Text(
                  'No member information is available yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: details.members.take(5).map((member) {
                  final owner = member.id == project.ownerId;
                  return ListTile(
                    leading: CircleAvatar(child: Text(_initials(member.name))),
                    title: Text(member.name),
                    subtitle: Text(member.email),
                    trailing: owner
                        ? const Chip(label: Text('Owner'))
                        : Text(member.role),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: () => _openTasks(null),
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('View Project Tasks'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.folder_copy_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 34,
          ),
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            project.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          Text(
            project.description.isEmpty
                ? 'No description provided.'
                : project.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _TaskMetric extends StatelessWidget {
  const _TaskMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingXs),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppConstants.paddingMd),
            Expanded(child: Text(label)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppConstants.paddingXs),
              const Icon(Icons.copy_rounded, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
