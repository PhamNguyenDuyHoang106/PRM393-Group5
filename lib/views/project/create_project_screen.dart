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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authViewModelProvider).user;
    if (user == null || !user.isManager) return;

    final project = await ref
        .read(projectViewModelProvider.notifier)
        .createProject(
          name: _nameController.text,
          description: _descriptionController.text,
          ownerId: user.id,
        );

    if (project != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project "${project.name}" created.')),
      );
      context.pop(project.id);
    }
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
      return Scaffold(
        appBar: AppBar(title: const Text('Create Project')),
        body: const _ProjectAccessDenied(
          message: 'Only managers can create projects.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start a new project',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSm),
                Text(
                  'Give your team a clear project name and a short description.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXl),
                if (projectState.errorMessage != null) ...[
                  _InlineProjectError(
                    message: projectState.errorMessage!,
                    onDismiss: () => ref
                        .read(projectViewModelProvider.notifier)
                        .clearError(),
                  ),
                  const SizedBox(height: AppConstants.paddingMd),
                ],
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Project Name',
                  hintText: 'e.g. Mobile App Redesign',
                  prefixIcon: Icons.folder_outlined,
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
                Text(
                  'Description',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppConstants.paddingXs),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Describe the project goals and scope',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if ((value?.trim().length ?? 0) > 500) {
                      return 'Description must not exceed 500 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingLg),
                CustomButton(
                  text: 'Create Project',
                  icon: Icons.add_rounded,
                  isLoading: projectState.isSubmitting,
                  onPressed: _createProject,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectAccessDenied extends StatelessWidget {
  const _ProjectAccessDenied({required this.message});

  final String message;

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
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
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
