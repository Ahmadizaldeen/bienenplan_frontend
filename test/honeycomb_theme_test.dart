import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/features/auth/animation/honeycomb_theme.dart';

void main() {
  // Validiert, dass die Honeycomb-Farben aus dem aktuellen Theme sauber abgeleitet werden.
  test('HoneycombThemeData resolves a palette from theme colors', () {
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.light,
      ),
    );

    final palette = HoneycombThemeData.fromTheme(lightTheme);

    expect(palette.linkColor.a, lessThan(1.0));
    expect(palette.nodeColor.a, greaterThan(0.0));
    expect(palette.glowColor.a, greaterThan(0.0));
    expect(palette.specialNodeColor.a, greaterThan(0.0));
  });
}
