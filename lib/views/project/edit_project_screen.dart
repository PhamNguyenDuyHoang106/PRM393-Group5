import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
import '../../providers/providers.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class EditProjectScreen extends ConsumerStatefulWidget {
  const EditProjectScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _initialName = '';
  String _initialDescription = '';
  bool _isHydrating = false;
  bool _allowPop = false;

  bool get _hasChanges =>
      _nameController.text.trim() != _initialName ||
      _descriptionController.text.trim() != _initialDescription;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_formChanged);
    _descriptionController.addListener(_formChanged);
    Future.microtask(_loadProject);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_formChanged)
      ..dispose();
    _descriptionController
      ..removeListener(_formChanged)
      ..dispose();
    super.dispose();
  }

  void _formChanged() {
    if (!_isHydrating && mounted) setState(() {});
  }

  Future<void> _loadProject() async {
    await ref
        .read(projectViewModelProvider.notifier)
        .loadProjectDetails(widget.projectId);
    if (!mounted) return;
    final details = ref.read(projectViewModelProvider).details;
    if (details?.project.id == widget.projectId) {
      _hydrate(details!.project);
    }
  }

  void _hydrate(Project project) {
    _isHydrating = true;
    _initialName = project.name;
    _initialDescription = project.description;
    _nameController.text = project.name;
    _descriptionController.text = project.description;
    _isHydrating = false;
    if (mounted) setState(() {});
  }

  void _reset() {
    _isHydrating = true;
    _nameController.text = _initialName;
    _descriptionController.text = _initialDescription;
    _isHydrating = false;
    ref.read(projectViewModelProvider.notifier).clearError();
    setState(() {});
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_hasChanges || !_formKey.currentState!.validate()) return;

    final updated = await ref
        .read(projectViewModelProvider.notifier)
        .updateProject(
          projectId: widget.projectId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
    if (!mounted || updated == null) return;
    _hydrate(updated);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Project changes saved.')));
    _allowPop = true;
    context.pop(true);
  }

  Future<void> _delete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_forever_outlined,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Delete project permanently?'),
        content: Text(
          '“${project.name}” and all related tasks will be deleted. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep project'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await ref
        .read(projectViewModelProvider.notifier)
        .deleteProject(widget.projectId);
    if (!mounted || !deleted) return;
    _allowPop = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('“${project.name}” deleted.')));
    context.go('/projects');
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved project changes. Leave without saving them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cancel() async {
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => _allowPop = true);
    context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final details = state.details?.project.id == widget.projectId
        ? state.details
        : null;
    final canEdit =
        user?.isManager == true &&
        details != null &&
        details.project.ownerId == user?.id;

    return PopScope(
      canPop: _allowPop || !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard();
        if (!context.mounted) return;
        if (shouldDiscard) {
          setState(() => _allowPop = true);
          context.pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Project'),
          actions: [
            if (canEdit)
              TextButton(
                onPressed: state.isSubmitting || !_hasChanges ? null : _reset,
                child: const Text('Reset'),
              ),
          ],
        ),
        body: _buildBody(state, details, canEdit),
      ),
    );
  }

  Widget _buildBody(ProjectState state, ProjectDetails? details, bool canEdit) {
    if (state.isLoadingDetails && details == null) {
      return const LoadingWidget(message: 'Loading project...');
    }
    if (details == null) {
      return AppErrorDisplay(
        title: 'Project unavailable',
        error: state.errorMessage ?? 'Project not found.',
        onRetry: _loadProject,
      );
    }
    if (!canEdit) {
      return const _EditAccessDenied();
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMd,
                  ),
                ),
                child: const Icon(Icons.edit_note_rounded),
              ),
              const SizedBox(width: AppConstants.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update project details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _hasChanges
                          ? 'Unsaved changes'
                          : 'Everything is up to date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _hasChanges
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingXl),
          if (state.errorMessage != null) ...[
            _EditError(
              message: state.errorMessage!,
              onDismiss: () =>
                  ref.read(projectViewModelProvider.notifier).clearError(),
            ),
            const SizedBox(height: AppConstants.paddingMd),
          ],
          TextFormField(
            controller: _nameController,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Project name',
              prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
            ),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return 'Project name is required';
              if (name.length < 3) {
                return 'Project name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.paddingMd),
          TextFormField(
            controller: _descriptionController,
            minLines: 5,
            maxLines: 8,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the project goals and scope',
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                tooltip: 'Clear description',
                onPressed: state.isSubmitting
                    ? null
                    : _descriptionController.clear,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Card(
            child: ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Project members'),
              subtitle: Text(
                '${details.members.length} people in this project',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: state.isSubmitting
                  ? null
                  : () => context.push('/projects/${widget.projectId}/members'),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          CustomButton(
            text: 'Save Changes',
            icon: Icons.save_outlined,
            isLoading: state.isSubmitting,
            onPressed: _hasChanges ? _save : null,
          ),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton(
            onPressed: state.isSubmitting ? null : _cancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(height: AppConstants.paddingXl),
          const Divider(),
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            'Danger zone',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXs),
          Text(
            'Deleting a project also removes its task and member links.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppConstants.paddingMd),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: state.isSubmitting
                ? null
                : () => _delete(details.project),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Project'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
        ],
      ),
    );
  }
}

class _EditError extends StatelessWidget {
  const _EditError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded),
          const SizedBox(width: AppConstants.paddingSm),
          Expanded(child: Text(message)),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _EditAccessDenied extends StatelessWidget {
  const _EditAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
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
              'Owner access required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingSm),
            const Text(
              'Only the project owner can edit or delete this project.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
