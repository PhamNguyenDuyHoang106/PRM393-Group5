import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/project_card.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(projectViewModelProvider.notifier).loadProjects(),
    );
  }

  Future<void> _refresh() {
    return ref.read(projectViewModelProvider.notifier).loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final canCreateProject = authState.user?.isManager ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _buildBody(projectState),
      floatingActionButton: canCreateProject
          ? FloatingActionButton.extended(
              onPressed: projectState.isSubmitting
                  ? null
                  : () => context.push('/projects/create'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            )
          : null,
    );
  }

  Widget _buildBody(ProjectState state) {
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingMd,
          AppConstants.paddingMd,
          AppConstants.paddingMd,
          96,
        ),
        children: [
          if (state.errorMessage != null) ...[
            _ProjectListWarning(message: state.errorMessage!),
            const SizedBox(height: AppConstants.paddingMd),
          ],
          if (state.projects.isEmpty)
            const SizedBox(
              height: 420,
              child: EmptyWidget(
                title: 'No projects yet',
                message: 'Projects assigned to you will appear here.',
                icon: Icons.folder_open_rounded,
              ),
            )
          else
            ...state.projects.map(
              (project) => ProjectCard(
                project: project,
                onTap: () => context.push('/projects/${project.id}'),
              ),
            ),
        ],
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
