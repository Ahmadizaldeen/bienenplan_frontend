import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._();

  static const lightBackground = Color(0xFFF7F7F2);
  static const lightSurface = Color(0xFFFFFFFA);
  static const lightText = Color(0xFF242424);
  static const lightMuted = Color(0xFF626262);
  static const darkBackground = Color(0xFF202020);
  static const darkSurface = Color(0xFF2B2B2B);
  static const darkText = Color(0xFFF2F2EE);
  static const darkMuted = Color(0xFFB9B9B4);
  static const accent = Color(0xFF126B5B);
  static const accentLight = Color(0xFF72D7B6);
  static const warning = Color(0xFFE8BF68);
  static const danger = Color(0xFFB3261E);
}

class AppColors {
  AppColors._();

  static const brand = _BrandColors();
  static const text = _TextColors();
  static const surface = _SurfaceColors();
  static const status = _StatusColors();
  static const honeycomb = _HoneycombColors();
  static const register = _RegisterColors();

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
    final scheme = theme.colorScheme;

    return HoneycombThemeData(
      linkColor: scheme.outline.withValues(alpha: 0.22),
      glowColor: scheme.primary.withValues(alpha: 0.14),
      nodeColor: scheme.onSurface.withValues(alpha: 0.5),
      coreColor: scheme.primaryContainer.withValues(alpha: 0.8),
      reflexColor: scheme.onSurface.withValues(alpha: 0.06),
      specialNodeColor: scheme.primary.withValues(alpha: 0.75),
    );
  }
}

class _BrandColors {
  const _BrandColors();

  static const primary = AppPalette.lightMuted;
  static const accent = AppPalette.accent;
  static const background = AppPalette.lightBackground;
  static const backgroundDark = AppPalette.darkBackground;
  static const buttonText = AppPalette.lightText;
}

class _TextColors {
  const _TextColors();

  static const primary = AppPalette.lightText;
  static const secondary = AppPalette.lightMuted;
  static const tertiary = AppPalette.lightMuted;
  static const onWhite = AppPalette.lightText;
  static const onDark = AppPalette.darkText;
}

class _SurfaceColors {
  const _SurfaceColors();

  static const white = AppPalette.lightSurface;
  static const whiteSoft = AppPalette.lightBackground;
  static const whiteMuted = AppPalette.lightBackground;
  static const whiteFaint = AppPalette.lightSurface;
  static const warmPanel = AppPalette.lightSurface;
  static const warmPanelBorder = AppPalette.lightMuted;
  static const shadowSoft = AppPalette.darkBackground;
  static const glassTintLight = AppPalette.lightSurface;
  static const glassBorderLight = AppPalette.lightMuted;
  static const glassTintDark = AppPalette.darkSurface;
  static const glassBorderDark = AppPalette.darkMuted;
}

class _StatusColors {
  const _StatusColors();

  static const warning = AppPalette.warning;
  static const danger = AppPalette.danger;
  static const pending = AppPalette.lightMuted;
  static const mutedBlack = AppPalette.lightMuted;
}

class _HoneycombColors {
  const _HoneycombColors();

  static const linkLight = AppPalette.lightMuted;
  static const linkDark = AppPalette.darkMuted;
  static const glowLight = AppPalette.accent;
  static const glowDark = AppPalette.accentLight;
  static const nodeLight = AppPalette.lightMuted;
  static const nodeDark = AppPalette.darkMuted;
  static const coreLight = AppPalette.lightSurface;
  static const coreDark = AppPalette.darkSurface;
  static const reflexLight = AppPalette.lightSurface;
  static const reflexDark = AppPalette.darkText;
  static const specialNode = AppPalette.accentLight;
}

class _RegisterColors {
  const _RegisterColors();

  final backgroundStart = AppPalette.darkBackground;
  final backgroundCenter = AppPalette.darkSurface;
  final backgroundEnd = AppPalette.darkBackground;
  final lightDeep = AppPalette.accentLight;
  final lightAccent = AppPalette.warning;
  final lightMuted = AppPalette.darkMuted;
  final iconTint = AppPalette.accentLight;
  final heading = AppPalette.darkText;
  final body = AppPalette.darkMuted;
  final iconSurface = AppPalette.darkSurface;
  final iconBorder = AppPalette.darkMuted;
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

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return base
        .copyWith(
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
          bodySmall: base.bodySmall?.copyWith(fontSize: 14, height: 1.4),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(
          bodyColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          displayColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        );
  }

  static ColorScheme _colorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? AppPalette.darkBackground
        : AppPalette.lightBackground;
    final surface = isDark ? AppPalette.darkSurface : AppPalette.lightSurface;
    final foreground = isDark ? AppPalette.darkText : AppPalette.lightText;
    final muted = isDark ? AppPalette.darkMuted : AppPalette.lightMuted;
    final accent = isDark ? AppPalette.accentLight : AppPalette.accent;
    final secondary = isDark
        ? AppPalette.warning
        : Color.lerp(AppPalette.warning, AppPalette.lightText, 0.55)!;
    final error = isDark
        ? Color.lerp(AppPalette.danger, AppPalette.darkText, 0.65)!
        : AppPalette.danger;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );

    return scheme.copyWith(
      primary: accent,
      onPrimary: isDark ? AppPalette.darkBackground : AppPalette.lightSurface,
      primaryContainer: Color.lerp(surface, accent, 0.14),
      onPrimaryContainer: foreground,
      secondary: secondary,
      onSecondary: isDark ? AppPalette.darkBackground : AppPalette.lightSurface,
      secondaryContainer: Color.lerp(surface, secondary, 0.14),
      onSecondaryContainer: foreground,
      tertiary: muted,
      onTertiary: background,
      tertiaryContainer: surface,
      onTertiaryContainer: foreground,
      surface: background,
      surfaceDim: Color.lerp(background, foreground, 0.06),
      surfaceBright: surface,
      surfaceContainerLowest: background,
      surfaceContainerLow: Color.lerp(background, surface, 0.5),
      surfaceContainer: surface,
      surfaceContainerHigh: Color.lerp(surface, foreground, 0.04),
      surfaceContainerHighest: Color.lerp(surface, foreground, 0.08),
      onSurface: foreground,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: Color.lerp(surface, muted, 0.3),
      error: error,
      onError: isDark ? AppPalette.darkBackground : AppPalette.lightSurface,
      errorContainer: Color.lerp(surface, error, 0.14),
      onErrorContainer: foreground,
      inverseSurface: isDark ? AppPalette.lightSurface : AppPalette.darkSurface,
      onInverseSurface: isDark ? AppPalette.lightText : AppPalette.darkText,
      inversePrimary: isDark ? AppPalette.accent : AppPalette.accentLight,
      surfaceTint: Colors.transparent,
      shadow: AppPalette.darkBackground,
      scrim: AppPalette.darkBackground,
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final scheme = _colorScheme(brightness);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(brightness),
      primaryTextTheme: _textTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        titleTextStyle: _textTheme(brightness).titleLarge,
        contentTextStyle: _textTheme(brightness).bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    );
  }
}
