import 'package:flutter/material.dart';

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

  static const primary = Color(0xFF8A5A00);
  static const accent = Color(0xFF126B5B);
  static const background = Color(0xFFF5F8F5);
  static const backgroundDark = Color(0xFF111B18);
  static const buttonText = Color(0xFF17221F);
}

class _TextColors {
  const _TextColors();

  static const primary = Color(0xFF17221F);
  static const secondary = Color(0xFF42534D);
  static const tertiary = Color(0xFF566861);
  static const onWhite = Color(0xFF17221F);
  static const onDark = Color(0xFFF1F5F2);
}

class _SurfaceColors {
  const _SurfaceColors();

  static const white = Color(0xFFFFFFFF);
  static const whiteSoft = Color(0xFFF0F4F1);
  static const whiteMuted = Color(0xFFE5ECE7);
  static const whiteFaint = Color(0x29FFFFFF);
  static const warmPanel = Color(0xFFF3E7C7);
  static const warmPanelBorder = Color(0xFFB18A3B);
  static const shadowSoft = Color(0x0A000000);
  static const glassTintLight = Color(0xD9FFFFFF);
  static const glassBorderLight = Color(0xE6FFFFFF);
  static const glassTintDark = Color(0xB3111B18);
  static const glassBorderDark = Color(0x665A8A7C);
}

class _StatusColors {
  const _StatusColors();

  static const warning = Color(0xFF9A6100);
  static const danger = Color(0xFFB3261E);
  static const pending = Color(0xFF526A72);
  static const mutedBlack = Color(0x8A000000);
}

class _HoneycombColors {
  const _HoneycombColors();

  static const linkLight = Color(0x38FFFFFF);
  static const linkDark = Color(0x5272D7B6);
  static const glowLight = Color(0x59E8BF68);
  static const glowDark = Color(0x4772D7B6);
  static const nodeLight = Color(0xBFFFFFFF);
  static const nodeDark = Color(0xD9E9F4EF);
  static const coreLight = Color(0xCCF8E8C1);
  static const coreDark = Color(0xCCE8BF68);
  static const reflexLight = Color(0x1AFFFFFF);
  static const reflexDark = Color(0x14FFFFFF);
  static const specialNode = Color(0xF072D7B6);
}

class _RegisterColors {
  const _RegisterColors();

  final backgroundStart = const Color(0xFF126B5B);
  final backgroundCenter = const Color(0xFF104B40);
  final backgroundEnd = const Color(0xFF102F2B);
  final lightDeep = const Color(0xFF72D7B6);
  final lightAccent = const Color(0xFFE8BF68);
  final lightMuted = const Color(0xFFD5F0E6);
  final iconTint = const Color(0xFFF3D58E);
  final heading = const Color(0xFFF6F8F5);
  final body = const Color(0xFFD7E7E0);
  final iconSurface = const Color(0x29FFFFFF);
  final iconBorder = const Color(0x6655A38D);
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
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    );

    return scheme.copyWith(
      primary: isDark ? const Color(0xFF72D7B6) : AppColors.accent,
      onPrimary: isDark ? const Color(0xFF073A30) : AppColors.surfaceWhite,
      primaryContainer: isDark
          ? const Color(0xFF17594A)
          : const Color(0xFFD2F1E8),
      onPrimaryContainer: isDark
          ? const Color(0xFFD5F4E8)
          : const Color(0xFF123B33),
      secondary: isDark ? const Color(0xFFF3C969) : AppColors.primary,
      onSecondary: isDark ? const Color(0xFF412C00) : AppColors.surfaceWhite,
      secondaryContainer: isDark
          ? const Color(0xFF5B430E)
          : const Color(0xFFF3E7C7),
      onSecondaryContainer: isDark
          ? const Color(0xFFFFE9B0)
          : const Color(0xFF493000),
      surface: isDark ? AppColors.backgroundDark : AppColors.background,
      onSurface: isDark ? AppColors.textOnDark : AppColors.textPrimary,
      onSurfaceVariant: isDark
          ? const Color(0xFFB9C9C2)
          : AppColors.textSecondary,
      outline: isDark ? const Color(0xFF82958D) : const Color(0xFF687873),
      outlineVariant: isDark
          ? const Color(0xFF3D5149)
          : const Color(0xFFCCD6D0),
      error: isDark ? const Color(0xFFFFB4A9) : AppColors.danger,
      onError: isDark ? const Color(0xFF690005) : AppColors.surfaceWhite,
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
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
        color: isDark ? const Color(0xFF1A2823) : AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1A2823)
            : AppColors.surfaceWhite,
        titleTextStyle: _textTheme(brightness).titleLarge,
        contentTextStyle: _textTheme(brightness).bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF263831),
        contentTextStyle: const TextStyle(color: AppColors.textOnDark),
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
        fillColor: isDark ? const Color(0xFF1A2823) : AppColors.surfaceWhite,
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
