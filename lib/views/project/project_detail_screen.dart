import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
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
    Future.microtask(_loadDetails);
  }

  Future<void> _loadDetails() {
    return ref
        .read(projectViewModelProvider.notifier)
        .loadProjectDetails(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectViewModelProvider);
    final currentUser = ref.watch(authViewModelProvider).user;
    final details = state.details?.project.id == widget.projectId
        ? state.details
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          if (details != null && currentUser?.isManager == true)
            IconButton(
              tooltip: 'Manage members',
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () =>
                  context.push('/projects/${widget.projectId}/members'),
            ),
        ],
      ),
      body: _buildBody(state, details),
    );
  }

  Widget _buildBody(ProjectState state, ProjectDetails? details) {
    if (state.isLoadingDetails && details == null) {
      return const LoadingWidget(message: 'Loading project details...');
    }

    if (details == null) {
      return AppErrorDisplay(
        title: 'Project unavailable',
        error: state.errorMessage ?? 'Project not found.',
        onRetry: _loadDetails,
      );
    }

    final project = details.project;
    return RefreshIndicator(
      onRefresh: _loadDetails,
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
                  Icons.folder_copy_outlined,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: AppConstants.paddingMd),
                Text(
                  project.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSm),
                Text(
                  project.description.isEmpty
                      ? 'No description provided.'
                      : project.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
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
                    icon: Icons.badge_outlined,
                    label: 'Project ID',
                    value: project.id,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project members',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (ref.watch(authViewModelProvider).user?.isManager == true)
                TextButton(
                  onPressed: () =>
                      context.push('/projects/${widget.projectId}/members'),
                  child: const Text('Manage'),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSm),
          if (details.members.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingLg),
                child: Text(
                  'No member information is available offline yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: details.members.take(4).map((member) {
                  final isOwner = member.id == project.ownerId;
                  return ListTile(
                    leading: CircleAvatar(child: Text(_initials(member.name))),
                    title: Text(member.name),
                    subtitle: Text(member.email),
                    trailing: isOwner
                        ? const Chip(label: Text('Owner'))
                        : Text(member.role),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: () => context.go('/tasks'),
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
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppConstants.paddingMd),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
