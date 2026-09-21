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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? AppColors.glassTintDark : AppColors.glassTintLight;
    final border = isDark
        ? AppColors.glassBorderDark
        : AppColors.glassBorderLight;
    final glow = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.18);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.20);
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);

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
          BoxShadow(
            color: glow,
            blurRadius: blurSigma / 2,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlight,
            Colors.white.withValues(alpha: isDark ? 0.02 : 0.08),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
