import 'package:flutter/material.dart';

import '../data/task_model.dart';
import '../../../core/theme/app_theme.dart';

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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    if (task.description.trim().isNotEmpty)
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                  ],
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                _getStatusLabel(task.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
