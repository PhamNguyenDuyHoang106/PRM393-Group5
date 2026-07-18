import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
import '../../providers/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<MemberManagementScreen> createState() =>
      _MemberManagementScreenState();
}

class _MemberManagementScreenState
    extends ConsumerState<MemberManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDetails);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() {
    return ref
        .read(projectViewModelProvider.notifier)
        .loadProjectDetails(widget.projectId);
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(projectViewModelProvider.notifier)
        .addMember(projectId: widget.projectId, email: _emailController.text);

    if (success && mounted) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member added successfully.')),
      );
    }
  }

  Future<void> _confirmRemove(ProjectMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          'Remove ${member.name} from this project? Their account and other '
          'projects will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(projectViewModelProvider.notifier)
        .removeMember(projectId: widget.projectId, userId: member.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} removed from the project.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final projectState = ref.watch(projectViewModelProvider);
    final details = projectState.details?.project.id == widget.projectId
        ? projectState.details
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Members')),
      body: _buildBody(authState, projectState, details),
    );
  }

  Widget _buildBody(
    AuthState authState,
    ProjectState projectState,
    ProjectDetails? details,
  ) {
    if (authState.isLoading && authState.user == null) {
      return const LoadingWidget(message: 'Checking permissions...');
    }

    if (authState.user?.isManager != true) {
      return const _AccessDenied();
    }

    if (projectState.isLoadingDetails && details == null) {
      return const LoadingWidget(message: 'Loading project members...');
    }

    if (details == null) {
      return AppErrorDisplay(
        title: 'Members unavailable',
        error: projectState.errorMessage ?? 'Project not found.',
        onRetry: _loadDetails,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDetails,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text(
            details.project.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingXs),
          Text(
            '${details.members.length} member${details.members.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add a member',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSm),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Member email',
                        hintText: 'member@example.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      onFieldSubmitted: (_) {
                        if (!projectState.isSubmitting) _addMember();
                      },
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required';
                        if (!RegExp(
                          r"^[\w.!#$%&'*+/=?^_`{|}~-]+@[\w-]+(?:\.[\w-]+)+$",
                        ).hasMatch(email)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingMd),
                    FilledButton.icon(
                      onPressed: projectState.isSubmitting ? null : _addMember,
                      icon: projectState.isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add Member'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (projectState.errorMessage != null) ...[
            const SizedBox(height: AppConstants.paddingMd),
            _MemberError(message: projectState.errorMessage!),
          ],
          const SizedBox(height: AppConstants.paddingLg),
          Text(
            'Team members',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          if (details.members.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyWidget(
                title: 'No members found',
                message: 'Add a member using their email address.',
                icon: Icons.group_off_outlined,
              ),
            )
          else
            ...details.members.map(
              (member) => _MemberTile(
                member: member,
                isOwner: member.id == details.project.ownerId,
                isBusy: projectState.isSubmitting,
                onRemove: () => _confirmRemove(member),
              ),
            ),
          const SizedBox(height: AppConstants.paddingLg),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.isBusy,
    required this.onRemove,
  });

  final ProjectMember member;
  final bool isOwner;
  final bool isBusy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSm),
      child: ListTile(
        leading: CircleAvatar(child: Text(_initials(member.name))),
        title: Text(member.name),
        subtitle: Text('${member.email}\n${member.role}'),
        isThreeLine: true,
        trailing: isOwner
            ? const Chip(label: Text('Owner'))
            : IconButton(
                tooltip: 'Remove member',
                onPressed: isBusy ? null : onRemove,
                icon: Icon(
                  Icons.person_remove_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
      ),
    );
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _MemberError extends ConsumerWidget {
  const _MemberError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () =>
                ref.read(projectViewModelProvider.notifier).clearError(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

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
              'Manager access required',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            const Text(
              'Only managers can add or remove project members.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
