import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_widget.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberEmailController = TextEditingController();
  final _memberEmailFocus = FocusNode();
  final List<String> _memberEmails = [];
  String? _memberEmailError;

  static final _emailPattern = RegExp(
    r"^[\w.!#$%&'*+/=?^_`{|}~-]+@[\w-]+(?:\.[\w-]+)+$",
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _memberEmailController.dispose();
    _memberEmailFocus.dispose();
    super.dispose();
  }

  Future<void> _addMemberEmail() async {
    final email = _memberEmailController.text.trim().toLowerCase();
    final currentEmail = ref
        .read(authViewModelProvider)
        .user
        ?.email
        .toLowerCase();
    String? error;
    if (email.isEmpty) {
      error = 'Enter an email before adding it';
    } else if (!_emailPattern.hasMatch(email)) {
      error = 'Enter a valid email address';
    } else if (email == currentEmail) {
      error = 'The project owner is added automatically';
    } else if (_memberEmails.contains(email)) {
      error = 'This email is already in the list';
    }

    setState(() => _memberEmailError = error);
    if (error != null) return;

    final validationError = await ref
        .read(projectViewModelProvider.notifier)
        .validateMemberEmail(email);
    if (!mounted) return;
    if (validationError != null) {
      setState(() => _memberEmailError = validationError);
      return;
    }

    setState(() {
      _memberEmails.add(email);
      _memberEmailController.clear();
    });
    _memberEmailFocus.requestFocus();
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _memberEmailController.clear();
    setState(() {
      _memberEmails.clear();
      _memberEmailError = null;
    });
    ref.read(projectViewModelProvider.notifier).clearError();
  }

  Future<void> _createProject() async {
    FocusScope.of(context).unfocus();
    if (_memberEmailController.text.trim().isNotEmpty) {
      await _addMemberEmail();
      if (!mounted || _memberEmailError != null) return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authViewModelProvider).user;
    if (user == null || !user.isManager) return;

    final project = await ref
        .read(projectViewModelProvider.notifier)
        .createProject(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          ownerId: user.id,
          memberEmails: _memberEmails,
        );

    if (!mounted || project == null) return;
    final warning = ref.read(projectViewModelProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          warning ??
              'Project “${project.name}” created${_memberEmails.isEmpty ? '.' : ' with invited members.'}',
        ),
      ),
    );
    context.pop(project.id);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final projectState = ref.watch(projectViewModelProvider);

    if (authState.isLoading && authState.user == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Checking permissions...'),
      );
    }
    if (authState.user?.isManager != true) {
      return const _ProjectAccessDenied();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
        actions: [
          TextButton(
            onPressed:
                projectState.isSubmitting || projectState.isValidatingMember
                ? null
                : _resetForm,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.paddingLg),
            children: [
              _SectionHeader(
                icon: Icons.folder_outlined,
                title: 'Project information',
                subtitle: 'Use a concise name and explain the project goal.',
              ),
              const SizedBox(height: AppConstants.paddingLg),
              if (projectState.errorMessage != null) ...[
                _InlineProjectError(
                  message: projectState.errorMessage!,
                  onDismiss: () =>
                      ref.read(projectViewModelProvider.notifier).clearError(),
                ),
                const SizedBox(height: AppConstants.paddingMd),
              ],
              CustomTextField(
                controller: _nameController,
                labelText: 'Project name',
                hintText: 'e.g. Mobile App Redesign',
                prefixIcon: Icons.drive_file_rename_outline_rounded,
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return 'Project name is required';
                  if (name.length < 3) {
                    return 'Project name must be at least 3 characters';
                  }
                  if (name.length > 100) {
                    return 'Project name must not exceed 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMd),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the project goals and scope',
                  alignLabelWithHint: true,
                  suffixIcon: IconButton(
                    tooltip: 'Clear description',
                    onPressed: _descriptionController.clear,
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLg),
              const Divider(),
              const SizedBox(height: AppConstants.paddingLg),
              _SectionHeader(
                icon: Icons.group_add_outlined,
                title: 'Initial members',
                subtitle:
                    'Optional. Each account is verified before it is added.',
              ),
              const SizedBox(height: AppConstants.paddingMd),
              TextField(
                controller: _memberEmailController,
                focusNode: _memberEmailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enabled:
                    !projectState.isSubmitting &&
                    !projectState.isValidatingMember,
                onSubmitted: (_) => _addMemberEmail(),
                onChanged: (_) {
                  if (_memberEmailError != null) {
                    setState(() => _memberEmailError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Member email',
                  hintText: 'member@example.com',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  errorText: _memberEmailError,
                  suffixIcon: projectState.isValidatingMember
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Add email',
                          onPressed: _addMemberEmail,
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                          ),
                        ),
                ),
              ),
              if (_memberEmails.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingMd),
                Wrap(
                  spacing: AppConstants.paddingSm,
                  runSpacing: AppConstants.paddingSm,
                  children: _memberEmails
                      .map(
                        (email) => InputChip(
                          avatar: const Icon(Icons.person_outline, size: 18),
                          label: Text(email),
                          onDeleted:
                              projectState.isSubmitting ||
                                  projectState.isValidatingMember
                              ? null
                              : () =>
                                    setState(() => _memberEmails.remove(email)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppConstants.paddingXl),
              CustomButton(
                text: _memberEmails.isEmpty
                    ? 'Create Project'
                    : 'Create & Add ${_memberEmails.length} Members',
                icon: Icons.add_task_rounded,
                isLoading: projectState.isSubmitting,
                onPressed: projectState.isValidatingMember
                    ? null
                    : _createProject,
              ),
              const SizedBox(height: AppConstants.paddingSm),
              TextButton(
                onPressed:
                    projectState.isSubmitting ||
                        projectState.isValidatingMember
                    ? null
                    : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppConstants.paddingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppConstants.paddingXs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectAccessDenied extends StatelessWidget {
  const _ProjectAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
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
                'Manager access required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.paddingSm),
              const Text(
                'Only managers can create projects.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineProjectError extends StatelessWidget {
  const _InlineProjectError({required this.message, required this.onDismiss});

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
