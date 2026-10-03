import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Glass-like Container ohne BackdropFilter.
///
/// Diese Variante erzeugt keinen Shader und ist damit plattformneutral robust
/// auf Web, Android, iOS und Desktop. Der Look bleibt "glass" durch eine
/// stärkere Frost-Optik mit transparenter Oberfläche, Leuchtrand und weichem
/// Schatten, ohne das Render-System zu belasten.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.md,
    this.blurSigma = 20,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tint = scheme.surfaceContainer;
    final border = scheme.outlineVariant;
    final shadow = scheme.shadow.withValues(alpha: isDark ? 0.18 : 0.08);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: tint,
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: blurSigma / 1.5,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint, scheme.surfaceContainerLow],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
