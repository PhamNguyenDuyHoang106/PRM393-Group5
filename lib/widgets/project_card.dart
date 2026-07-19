import 'package:flutter/material.dart';
import '../models/project.dart';
import '../core/constants/app_constants.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<_ProjectCardAction>(
                      tooltip: 'Project actions',
                      padding: EdgeInsets.zero,
                      onSelected: (action) {
                        if (action == _ProjectCardAction.edit) {
                          onEdit?.call();
                        } else {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: _ProjectCardAction.edit,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: _ProjectCardAction.delete,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSm),
              Text(
                project.description.isNotEmpty
                    ? project.description
                    : 'No description provided.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppConstants.textSecondaryDark
                      : AppConstants.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingMd),
              Row(
                children: [
                  Icon(
                    Icons.person_pin_outlined,
                    size: 16,
                    color: isDark
                        ? AppConstants.primaryDark
                        : AppConstants.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Created on: ${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppConstants.textSecondaryDark
                          : AppConstants.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProjectCardAction { edit, delete }
