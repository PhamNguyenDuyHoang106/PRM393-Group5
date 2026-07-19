import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
import '../../providers/providers.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/project_card.dart';

enum _ProjectSort { newest, oldest, nameAscending, nameDescending }

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _ProjectSort _sort = _ProjectSort.newest;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref
        .read(projectViewModelProvider.notifier)
        .loadProjects(requireFresh: true);
  }

  List<Project> _visibleProjects(
    List<Project> projects,
    String? currentUserId,
    bool isManager,
  ) {
    if (currentUserId == null) return const [];
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = projects.where((project) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          project.name.toLowerCase().contains(normalizedQuery) ||
          project.description.toLowerCase().contains(normalizedQuery);
      final isOwned = project.ownerId == currentUserId;
      final matchesRole = isManager ? isOwned : !isOwned;
      return matchesQuery && matchesRole;
    }).toList();

    filtered.sort((first, second) {
      return switch (_sort) {
        _ProjectSort.newest => second.createdAt.compareTo(first.createdAt),
        _ProjectSort.oldest => first.createdAt.compareTo(second.createdAt),
        _ProjectSort.nameAscending => first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        ),
        _ProjectSort.nameDescending => second.name.toLowerCase().compareTo(
          first.name.toLowerCase(),
        ),
      };
    });
    return filtered;
  }

  Future<void> _openCreate() async {
    final created = await context.push<String>('/projects/create');
    if (created != null) await _refresh();
  }

  Future<void> _openEdit(Project project) async {
    final changed = await context.push<bool>('/projects/${project.id}/edit');
    if (changed == true) await _refresh();
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Delete project?'),
        content: Text(
          '“${project.name}” and its cached tasks will be removed. '
          'This action cannot be undone.',
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
    if (!mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('“${project.name}” deleted.')));
    }
  }

  void _resetView() {
    _searchController.clear();
    setState(() {
      _query = '';
      _sort = _ProjectSort.newest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final canCreateProject = user?.isManager ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(canCreateProject ? 'Managed Projects' : 'My Projects'),
        actions: [
          IconButton(
            tooltip: 'Refresh projects',
            onPressed: projectState.isLoadingProjects ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(projectState, user?.id, canCreateProject),
      floatingActionButton: canCreateProject
          ? FloatingActionButton.extended(
              onPressed: projectState.isSubmitting ? null : _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            )
          : null,
    );
  }

  Widget _buildBody(ProjectState state, String? currentUserId, bool isManager) {
    if (state.isLoadingProjects && state.projects.isEmpty) {
      return const LoadingWidget(message: 'Loading projects...');
    }
    if (state.errorMessage != null && state.projects.isEmpty) {
      return AppErrorDisplay(
        title: 'Unable to load projects',
        error: state.errorMessage!,
        onRetry: _refresh,
      );
    }

    final projects = _visibleProjects(state.projects, currentUserId, isManager);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingMd,
          AppConstants.paddingSm,
          AppConstants.paddingMd,
          96,
        ),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search projects',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            children: [
              Expanded(
                child: Text(
                  isManager
                      ? 'Projects you manage'
                      : 'Projects you participate in',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _ProjectSortButton(
                sort: _sort,
                onChanged: (value) => setState(() => _sort = value),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppConstants.paddingMd),
            _ProjectListWarning(message: state.errorMessage!),
          ],
          const SizedBox(height: AppConstants.paddingMd),
          Row(
            children: [
              Text(
                '${projects.length} ${projects.length == 1 ? 'project' : 'projects'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (_query.isNotEmpty || _sort != _ProjectSort.newest)
                TextButton(onPressed: _resetView, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSm),
          if (projects.isEmpty)
            const SizedBox(
              height: 360,
              child: EmptyWidget(
                title: 'No matching projects',
                message: 'Try changing your search or sorting option.',
                icon: Icons.folder_off_outlined,
              ),
            )
          else
            ...projects.map((project) {
              final isOwner = project.ownerId == currentUserId;
              return ProjectCard(
                project: project,
                onTap: () => context.push('/projects/${project.id}'),
                onEdit: isOwner ? () => _openEdit(project) : null,
                onDelete: isOwner ? () => _confirmDelete(project) : null,
              );
            }),
        ],
      ),
    );
  }
}

class _ProjectSortButton extends StatelessWidget {
  const _ProjectSortButton({required this.sort, required this.onChanged});

  final _ProjectSort sort;
  final ValueChanged<_ProjectSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = switch (sort) {
      _ProjectSort.newest => 'Newest',
      _ProjectSort.oldest => 'Oldest',
      _ProjectSort.nameAscending => 'Name A–Z',
      _ProjectSort.nameDescending => 'Name Z–A',
    };
    return PopupMenuButton<_ProjectSort>(
      tooltip: 'Sort projects',
      initialValue: sort,
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ProjectSort.newest, child: Text('Newest first')),
        PopupMenuItem(value: _ProjectSort.oldest, child: Text('Oldest first')),
        PopupMenuItem(
          value: _ProjectSort.nameAscending,
          child: Text('Name A–Z'),
        ),
        PopupMenuItem(
          value: _ProjectSort.nameDescending,
          child: Text('Name Z–A'),
        ),
      ],
      child: Chip(
        avatar: const Icon(Icons.sort_rounded, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _ProjectListWarning extends StatelessWidget {
  const _ProjectListWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.orange),
          const SizedBox(width: AppConstants.paddingSm),
          Expanded(
            child: Text(
              '$message Showing saved data when available.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
