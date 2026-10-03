import 'package:flutter/material.dart';

import '../application/task_text_parser.dart';
import '../data/task_model.dart';
import '../../../core/theme/app_theme.dart';

class TaskItemWidget extends StatelessWidget {
  final Task task;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onTap;
  final bool showContainerBadge;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.onStatusChanged,
    this.onTap,
    this.showContainerBadge = true,
  });

  Color _getStatusColor(String status, ColorScheme scheme) {
    switch (status.trim().toLowerCase()) {
      case 'done':
        return scheme.primary;
      case 'in_progress':
        return scheme.secondary;
      case 'open':
      case 'pending':
      default:
        return scheme.onSurfaceVariant;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'done':
        return 'Erledigt';
      case 'in_progress':
        return 'In Bearbeitung';
      case 'open':
      case 'pending':
      case '':
        return 'Offen';
      default:
        return status.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(task.status, scheme);
    final descriptionBody = taskDescriptionBody(task.title, task.description);
    final statusBadge = Container(
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showContainerBadge) ...[
                Text(
                  task.containerTitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  statusBadge,
                ],
              ),
              if (descriptionBody.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  descriptionBody,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
