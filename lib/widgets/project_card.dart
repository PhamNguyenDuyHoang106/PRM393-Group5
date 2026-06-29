import 'package:flutter/material.dart';
import '../models/project.dart';
import '../core/constants/app_constants.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
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
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingSm),
              Text(
                project.description.isNotEmpty ? project.description : 'No description provided.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
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
                    color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Created on: ${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
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
