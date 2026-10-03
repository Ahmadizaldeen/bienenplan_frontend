import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';

class ProjectOverviewHeader extends StatefulWidget {
  const ProjectOverviewHeader({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  State<ProjectOverviewHeader> createState() => _ProjectOverviewHeaderState();
}

class _ProjectOverviewHeaderState extends State<ProjectOverviewHeader> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isExpanded)
            LayoutBuilder(
              builder: (context, constraints) {
                final titleSize = constraints.maxWidth < 320 ? 22.0 : 28.0;
                return Text(
                  'Projektübersicht',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: scheme.primary),
                    hintText: 'Suche nach Aufgaben oder Projekten',
                    filled: true,
                    fillColor: scheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                key: const ValueKey('project-overview-refresh'),
                tooltip: 'Aktualisieren',
                onPressed: widget.onRefresh,
                icon: Icon(Icons.refresh, color: scheme.primary),
              ),
              IconButton(
                key: const ValueKey('project-overview-toggle'),
                tooltip: _isExpanded
                    ? 'Projektübersicht einklappen'
                    : 'Projektübersicht ausklappen',
                onPressed: () => setState(() {
                  _isExpanded = !_isExpanded;
                }),
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          // Die Kennzahlen klappen ein; das Suchfeld bleibt dauerhaft sichtbar.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                color: scheme.secondary,
                                width: cardWidth,
                                compact: compact,
                              ),
                              _MiniStatCard(
                                label: 'Erledigt',
                                value: '42',
                                color: scheme.primary,
                                width: cardWidth,
                                compact: compact,
                              ),
                              _MiniStatCard(
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
                    ],
                  )
                : const SizedBox.shrink(),
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
