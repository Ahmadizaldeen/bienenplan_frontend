import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';

class ProjectOverviewHeader extends StatelessWidget {
  const ProjectOverviewHeader({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleSize = constraints.maxWidth < 320 ? 22.0 : 28.0;
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Projektübersicht',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, color: AppColors.accent),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.accent),
              hintText: 'Suche nach Aufgaben oder Projekten',
              filled: true,
              fillColor: AppColors.surfaceWhiteSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 400;
              final cardWidth = compact
                  ? (constraints.maxWidth - 2 * AppSpacing.sm) / 3
                  : 120.0;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MiniStatCard(
                    label: 'Aktiv',
                    value: '18',
                    color: AppColors.primary,
                    width: cardWidth,
                    compact: compact,
                  ),
                  _MiniStatCard(
                    label: 'Erledigt',
                    value: '42',
                    color: AppColors.accent,
                    width: cardWidth,
                    compact: compact,
                  ),
                  _MiniStatCard(
                    label: 'Heute',
                    value: '06',
                    color: AppColors.textTertiary,
                    width: cardWidth,
                    compact: compact,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
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
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhiteSoft.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
