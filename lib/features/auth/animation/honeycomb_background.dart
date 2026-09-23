import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'honeycomb_painter.dart';

// Die eigentliche Render- und Animationslogik für den Hintergrund.
// Diese Klasse ist für das Zeichnen und die Wiederholungsanimation zuständig.
class HoneycombBackground extends StatefulWidget {
  const HoneycombBackground({super.key});

  @override
  State<HoneycombBackground> createState() => _HoneycombBackgroundState();
}

class _HoneycombBackgroundState extends State<HoneycombBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Die Hintergrundbewegung läuft in einer Endlosschleife, damit das Muster nie zur Ruhe kommt.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Die Farbcodierung für den Hintergrund kommt zentral aus dem AppTheme.
    final themeData = AppTheme.honeycombTheme(Theme.of(context));

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Das eigentliche Canvas wird hier im Hintergrund gemalt und nicht als Teil der Formularlogik verwaltet.
          return SizedBox.expand(
            child: CustomPaint(
              painter: HoneycombPainter(
                progress: _controller.value,
                themeData: themeData,
              ),
            ),
          );
        },
      ),
    );
  }
}
