import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const brand = _BrandColors();
  static const text = _TextColors();
  static const surface = _SurfaceColors();
  static const status = _StatusColors();
  static const honeycomb = _HoneycombColors();

  // Legacy aliases for existing app code.
  static const primary = _BrandColors.primary;
  static const accent = _BrandColors.accent;
  static const background = _BrandColors.background;
  static const backgroundDark = _BrandColors.backgroundDark;
  static const buttonText = _BrandColors.buttonText;

  static const textPrimary = _TextColors.primary;
  static const textSecondary = _TextColors.secondary;
  static const textTertiary = _TextColors.tertiary;
  static const textOnWhite = _TextColors.onWhite;
  static const textOnDark = _TextColors.onDark;

  static const surfaceWhite = _SurfaceColors.white;
  static const surfaceWhiteSoft = _SurfaceColors.whiteSoft;
  static const surfaceWhiteMuted = _SurfaceColors.whiteMuted;
  static const surfaceWhiteFaint = _SurfaceColors.whiteFaint;
  static const whiteOverlay = _SurfaceColors.white;
  static const warmPanel = _SurfaceColors.warmPanel;
  static const warmPanelBorder = _SurfaceColors.warmPanelBorder;
  static const shadowSoft = _SurfaceColors.shadowSoft;

  static const warning = _StatusColors.warning;
  static const danger = _StatusColors.danger;
  static const statusPending = _StatusColors.pending;
  static const mutedBlack = _StatusColors.mutedBlack;

  static const honeycombLinkLight = _HoneycombColors.linkLight;
  static const honeycombLinkDark = _HoneycombColors.linkDark;
  static const honeycombGlowLight = _HoneycombColors.glowLight;
  static const honeycombGlowDark = _HoneycombColors.glowDark;
  static const honeycombNodeLight = _HoneycombColors.nodeLight;
  static const honeycombNodeDark = _HoneycombColors.nodeDark;
  static const honeycombCoreLight = _HoneycombColors.coreLight;
  static const honeycombCoreDark = _HoneycombColors.coreDark;
  static const honeycombReflexLight = _HoneycombColors.reflexLight;
  static const honeycombReflexDark = _HoneycombColors.reflexDark;
  static const honeycombSpecialNode = _HoneycombColors.specialNode;

  static const glassTintLight = _SurfaceColors.glassTintLight;
  static const glassBorderLight = _SurfaceColors.glassBorderLight;
  static const glassTintDark = _SurfaceColors.glassTintDark;
  static const glassBorderDark = _SurfaceColors.glassBorderDark;

  /// Single source of truth for the animated honeycomb background.
  /// Keep the palette derivation in one place so theme-specific changes stay consistent.
  static HoneycombThemeData honeycombPalette(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return HoneycombThemeData(
      linkColor: isDark
          ? scheme.primary.withValues(alpha: 0.32)
          : AppColors.honeycombLinkLight,
      glowColor: isDark
          ? scheme.primary.withValues(alpha: 0.28)
          : AppColors.honeycombGlowLight,
      nodeColor: isDark
          ? scheme.onSurface.withValues(alpha: 0.85)
          : AppColors.honeycombNodeLight,
      coreColor: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.80)
          : AppColors.honeycombCoreLight,
      reflexColor: isDark
          ? AppColors.honeycombReflexDark
          : AppColors.honeycombReflexLight,
      specialNodeColor: AppColors.honeycombSpecialNode,
    );
  }
}

class _BrandColors {
  const _BrandColors();

  static const primary = Color(0xFFD9A441);
  static const accent = Color(0xFF477A6B);
  static const background = Color(0xFFF5F1E8);
  static const backgroundDark = Color(0xFF182522);
  static const buttonText = Color.fromARGB(102, 5, 236, 86);
}

class _TextColors {
  const _TextColors();

  static const primary = Color(0xFF263A35);
  static const secondary = Color(0xFF5B6A66);
  static const tertiary = Color(0xFF6C7A8A);
  static const onWhite = Color(0xFF263A35);
  static const onDark = Color(0xFFF0F3EF);
}

class _SurfaceColors {
  const _SurfaceColors();

  static const white = Color(0xFFFFFFFF);
  static const whiteSoft = Color(0xB3FFFFFF);
  static const whiteMuted = Color(0x66FFFFFF);
  static const whiteFaint = Color(0x29FFFFFF);
  static const warmPanel = Color(0xFFD7CFAF);
  static const warmPanelBorder = Color(0xFFB6A87E);
  static const shadowSoft = Color(0x0A000000);
  static const glassTintLight = Color(0x66FFFFFF);
  static const glassBorderLight = Color(0x99FFFFFF);
  static const glassTintDark = Color(0x33000000);
  static const glassBorderDark = Color(0x668FAFA5);
}

class _StatusColors {
  const _StatusColors();

  static const warning = Color(0xFFFFA000);
  static const danger = Color(0xFFE53935);
  static const pending = Color(0xFF607D8B);
  static const mutedBlack = Color(0x8A000000);
}

class _HoneycombColors {
  const _HoneycombColors();

  static const linkLight = Color(0x38FFFFFF);
  static const linkDark = Color(0x52D9A441);
  static const glowLight = Color(0x59F7D57B);
  static const glowDark = Color(0x47D9A441);
  static const nodeLight = Color(0xBFFFFFFF);
  static const nodeDark = Color(0xD9F5F1E8);
  static const coreLight = Color(0xCCFDE8B4);
  static const coreDark = Color(0xCCD9A441);
  static const reflexLight = Color(0x1AFFFFFF);
  static const reflexDark = Color(0x14FFFFFF);
  static const specialNode = Color(0xF0A4D9A0);
}

class HoneycombThemeData {
  final Color linkColor;
  final Color glowColor;
  final Color nodeColor;
  final Color coreColor;
  final Color reflexColor;
  final Color specialNodeColor;

  const HoneycombThemeData({
    required this.linkColor,
    required this.glowColor,
    required this.nodeColor,
    required this.coreColor,
    required this.reflexColor,
    required this.specialNodeColor,
  });

  /// Convenience constructor used by the animation layer.
  /// It intentionally delegates to the central palette builder to avoid duplicate logic.
  factory HoneycombThemeData.fromTheme(ThemeData theme) =>
      AppColors.honeycombPalette(theme);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HoneycombThemeData &&
        other.linkColor == linkColor &&
        other.glowColor == glowColor &&
        other.nodeColor == nodeColor &&
        other.coreColor == coreColor &&
        other.reflexColor == reflexColor &&
        other.specialNodeColor == specialNodeColor;
  }

  @override
  int get hashCode => Object.hash(
    linkColor,
    glowColor,
    nodeColor,
    coreColor,
    reflexColor,
    specialNodeColor,
  );
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0, md = 20.0, lg = 28.0;
}

class AppTheme {
  AppTheme._();

  static HoneycombThemeData honeycombTheme(ThemeData theme) =>
      AppColors.honeycombPalette(theme);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceWhiteSoft,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      labelStyle: TextStyle(color: AppColors.accent.withValues(alpha: 0.85)),
      hintStyle: TextStyle(color: AppColors.accent.withValues(alpha: 0.6)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md, // Added explicit horizontal padding
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 2, // Controls the shadow depth
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceWhiteFaint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: TextStyle(
        color: AppColors.surfaceWhite.withValues(alpha: 0.75),
      ),
      hintStyle: TextStyle(
        color: AppColors.surfaceWhite.withValues(alpha: 0.5),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textOnDark),
    ),
  );
}
