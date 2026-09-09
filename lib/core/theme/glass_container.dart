import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Wiederverwendbare Glass-Oberfläche (BackdropFilter-basiert).
/// Bewusst OHNE Drittanbieter-Paket implementiert -> volle Kontrolle
/// über Performance und keine Abhängigkeit von instabilen Packages.
///
/// Regel: max. 2 verschachtelte GlassContainer im selben Baum,
/// sonst leidet die Render-Performance auf schwächeren Geräten.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.md,
    this.blurSigma = 20, // 
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? AppColors.glassTintDark : AppColors.glassTintLight;
    final border = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}