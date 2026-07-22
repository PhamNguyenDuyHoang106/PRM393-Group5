import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
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
    final strings = AppStrings(ref.read(settingsViewModelProvider).isVietnamese);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.projectChangesSaved)));
    _allowPop = true;
    context.pop(true);
  }

  Future<void> _delete(Project project) async {
    final strings = AppStrings(ref.read(settingsViewModelProvider).isVietnamese);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_forever_outlined,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(strings.deleteProjectPermanentlyQuestion),
        content: Text(strings.deleteProjectPermanentlyBody(project.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.keepProject),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.deletePermanently),
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
    ).showSnackBar(SnackBar(content: Text(strings.projectDeletedMsg(project.name))));
    context.go('/projects');
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final strings = AppStrings(ref.read(settingsViewModelProvider).isVietnamese);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.discardChangesQuestion),
            content: Text(strings.discardChangesBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.keepEditing),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.discard),
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
    final strings = AppStrings(ref.watch(settingsViewModelProvider).isVietnamese);
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
          title: Text(strings.editProjectTitle),
          actions: [
            if (canEdit)
              TextButton(
                onPressed: state.isSubmitting || !_hasChanges ? null : _reset,
                child: Text(strings.reset),
              ),
          ],
        ),
        body: _buildBody(state, details, canEdit, strings),
      ),
    );
  }

  Widget _buildBody(ProjectState state, ProjectDetails? details, bool canEdit, AppStrings strings) {
    if (state.isLoadingDetails && details == null) {
      return LoadingWidget(message: strings.loadingProject);
    }
    if (details == null) {
      return AppErrorDisplay(
        title: strings.projectUnavailable,
        error: state.errorMessage ?? strings.projectNotFound,
        onRetry: _loadProject,
      );
    }
    if (!canEdit) {
      return _EditAccessDenied(strings: strings);
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
                      strings.updateProjectDetails,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _hasChanges
                          ? strings.unsavedChanges
                          : strings.everythingUpToDate,
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
              strings: strings,
              onDismiss: () =>
                  ref.read(projectViewModelProvider.notifier).clearError(),
            ),
            const SizedBox(height: AppConstants.paddingMd),
          ],
          TextFormField(
            controller: _nameController,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: strings.projectNameLabel,
              prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
            ),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return strings.projectNameRequired;
              if (name.length < 3) {
                return strings.projectNameMinLength;
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
              labelText: strings.descriptionLabel,
              hintText: strings.describeProjectHint,
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                tooltip: strings.clearDescriptionTooltip,
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
              title: Text(strings.projectMembersSection),
              subtitle: Text(strings.peopleInProject(details.members.length)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: state.isSubmitting
                  ? null
                  : () => context.push('/projects/${widget.projectId}/members'),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          CustomButton(
            text: strings.saveChanges,
            icon: Icons.save_outlined,
            isLoading: state.isSubmitting,
            onPressed: _hasChanges ? _save : null,
          ),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton(
            onPressed: state.isSubmitting ? null : _cancel,
            child: Text(strings.cancel),
          ),
          const SizedBox(height: AppConstants.paddingXl),
          const Divider(),
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            strings.dangerZone,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXs),
          Text(
            strings.deletingProjectAlsoRemoves,
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
            label: Text(strings.deleteProjectButton),
          ),
          const SizedBox(height: AppConstants.paddingLg),
        ],
      ),
    );
  }
}

class _EditError extends StatelessWidget {
  const _EditError({required this.message, required this.onDismiss, required this.strings});

  final String message;
  final VoidCallback onDismiss;
  final AppStrings strings;

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
            tooltip: strings.dismiss,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _EditAccessDenied extends StatelessWidget {
  const _EditAccessDenied({required this.strings});

  final AppStrings strings;

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
              strings.ownerAccessRequired,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Text(
              strings.onlyOwnerCanEditOrDelete,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
