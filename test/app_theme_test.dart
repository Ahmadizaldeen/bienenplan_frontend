import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/core/theme/app_theme.dart';

void main() {
  test('light theme keeps text and primary actions readable', () {
    final theme = AppTheme.light;
    final scheme = theme.colorScheme;

    expect(_contrastRatio(scheme.onSurface, scheme.surface), greaterThan(7));
    expect(_contrastRatio(scheme.onPrimary, scheme.primary), greaterThan(4.5));
    expect(theme.textTheme.bodyLarge?.fontSize, 16);
    expect(theme.textTheme.bodyMedium?.fontSize, 15);
  });

  test('dark theme keeps text and primary actions readable', () {
    final theme = AppTheme.dark;
    final scheme = theme.colorScheme;

    expect(_contrastRatio(scheme.onSurface, scheme.surface), greaterThan(7));
    expect(_contrastRatio(scheme.onPrimary, scheme.primary), greaterThan(4.5));
    expect(theme.textTheme.bodyLarge?.fontSize, 16);
    expect(theme.textTheme.bodyMedium?.fontSize, 15);
  });

  test('themes use neutral backgrounds and readable semantic colors', () {
    expect(AppTheme.light.colorScheme.surface, AppPalette.lightBackground);
    expect(AppTheme.dark.colorScheme.surface, AppPalette.darkBackground);

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      expect(
        _contrastRatio(scheme.onSurfaceVariant, scheme.surfaceContainer),
        greaterThan(4.5),
      );
      expect(
        _contrastRatio(scheme.onSecondary, scheme.secondary),
        greaterThan(4.5),
      );
      expect(_contrastRatio(scheme.onError, scheme.error), greaterThan(4.5));
      expect(theme.cardTheme.color, scheme.surfaceContainer);
      expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainer);
      expect(theme.inputDecorationTheme.fillColor, scheme.surfaceContainer);
    }
  });

  test('frontend defines only twelve central base colors', () {
    final colorConstructor = RegExp(
      r'\bColor(?:\.(?:fromARGB|fromRGBO|from))?\s*\(',
    );
    final fixedMaterialColor = RegExp(r'\bColors\.(?!transparent\b)\w+');
    var baseColorCount = 0;

    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      final constructors = colorConstructor.allMatches(source).length;
      if (file.path
          .replaceAll('\\', '/')
          .endsWith('/core/theme/app_theme.dart')) {
        baseColorCount = constructors;
      } else {
        expect(constructors, 0, reason: 'Fixed colors in ${file.path}');
      }
      expect(fixedMaterialColor.hasMatch(source), isFalse, reason: file.path);
    }

    expect(baseColorCount, 12);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
