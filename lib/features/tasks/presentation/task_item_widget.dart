import 'package:flutter/material.dart';

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

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'done':
        return AppColors.accent;
      case 'in_progress':
        return AppColors.primary;
      case 'open':
      case 'pending':
      default:
        return AppColors.statusPending;
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
    final statusColor = _getStatusColor(task.status);
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
            color: AppColors.surfaceWhiteSoft.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppColors.surfaceWhiteSoft.withValues(alpha: 0.15),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 300;
              final details = Column(
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
                  Text(
                    task.title,
                    maxLines: 2,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    details,
                    const SizedBox(height: AppSpacing.sm),
                    statusBadge,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: AppSpacing.sm),
                  statusBadge,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
