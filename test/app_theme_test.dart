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
