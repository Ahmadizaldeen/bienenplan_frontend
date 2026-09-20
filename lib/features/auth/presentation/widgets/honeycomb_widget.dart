import 'package:flutter/material.dart';

import '../../animation/honeycomb_background.dart';

// Kompatibilitäts-Wrapper für bestehende Aufrufe.
// Die eigentliche Logik liegt jetzt in der separaten Hintergrund-Komponente.
class AnimatedHoneycombWidget extends StatelessWidget {
  const AnimatedHoneycombWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const HoneycombBackground();
  }
}