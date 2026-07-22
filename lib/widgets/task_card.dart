import 'package:flutter/material.dart';
import '../models/task.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_strings.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final AppStrings? strings;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.strings,
  });

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppConstants.priorityHigh;
      case 'MEDIUM':
        return AppConstants.priorityMedium;
      case 'LOW':
      default:
        return AppConstants.priorityLow;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DONE':
        return AppConstants.doneColor;
      case 'IN_PROGRESS':
        return AppConstants.inProgressColor;
      case 'TODO':
      default:
        return AppConstants.todoColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = strings ?? const AppStrings(false);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.categoryLabel(task.priority),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(task.priority),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSm),
              Text(
                task.description.isNotEmpty ? task.description : s.noDescriptionProvided,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.dueDate != null
                            ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                            : s.noDeadline,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.categoryLabel(task.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(task.status),
                      ),
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
