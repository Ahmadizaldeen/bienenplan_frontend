import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/project_model.dart';

class ProjectInfoScreen extends StatelessWidget {
  const ProjectInfoScreen({super.key, this.project});

  final Project? project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(project?.name ?? 'Projektstatistiken')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Projektstatistiken',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 400;
              final cardWidth = compact
                  ? (constraints.maxWidth - 2 * AppSpacing.sm) / 3
                  : 160.0;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ProjectStatCard(
                    label: 'Aktiv',
                    value: '18',
                    color: scheme.secondary,
                    width: cardWidth,
                    compact: compact,
                  ),
                  _ProjectStatCard(
                    label: 'Erledigt',
                    value: '42',
                    color: scheme.primary,
                    width: cardWidth,
                    compact: compact,
                  ),
                  _ProjectStatCard(
                    label: 'Heute',
                    value: '06',
                    color: scheme.onSurfaceVariant,
                    width: cardWidth,
                    compact: compact,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Weitere Statistiken folgen.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProjectStatCard extends StatelessWidget {
  const _ProjectStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.width,
    required this.compact,
  });

  final String label;
  final String value;
  final Color color;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
