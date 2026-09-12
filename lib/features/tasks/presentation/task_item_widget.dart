import 'package:flutter/material.dart';

import '../data/task_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';

class TaskItemWidget extends StatelessWidget {
  final Task task;
  final VoidCallback? onStatusChanged;
  final bool showContainerBadge;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.onStatusChanged,
    this.showContainerBadge = true,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return AppColors.accent;
      case 'in_progress':
        return AppColors.primary;
      case 'pending':
      default:
        return Colors.blueGrey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 'Erledigt';
      case 'in_progress':
        return 'In Bearbeitung';
      case 'pending':
        return 'Offen';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container Title Badge & Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showContainerBadge)
                  Expanded(
                    child: Text(
                      task.containerTitle.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(task.status),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              task.title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Description
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: AppSpacing.lg),

            // Meta Info (Creator & Deadline)
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  task.creatorName.trim(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                // Safe access using formattedDeadline getter (prevents null errors)
                Text(
                  task.formattedDeadline,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: task.deadline != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}