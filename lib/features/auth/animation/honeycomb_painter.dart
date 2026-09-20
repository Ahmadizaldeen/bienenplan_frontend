import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'honeycomb_theme.dart';

/// Repräsentiert einen einzelnen Knotenpunkt im Netz
class NetworkNode {
  final Offset relativePosition; // Relative Position (0.0 bis 1.0)
  final double pulseOffset; // Phasenverschiebung für das Pulsieren
  final bool isSpecial; // Hebt z. B. den zentralen Knoten optisch hervor

  const NetworkNode({
    required this.relativePosition,
    required this.pulseOffset,
    this.isSpecial = false,
  });
}

/// Repräsentiert die Verbindung zwischen zwei Knoten
class NetworkLink {
  final int startNodeIndex;
  final int endNodeIndex;

  const NetworkLink(this.startNodeIndex, this.endNodeIndex);
}

// Zeichnet ein animiertes Honigwaben-ähnliches Netzwerk.
// Der Painter ist bewusst rein auf Rendering fokussiert und bekommt seine Farben über ein Theme-Objekt.
class HoneycombPainter extends CustomPainter {
  final double progress;
  final HoneycombThemeData themeData;

  static const List<NetworkNode> nodes = [
    NetworkNode(relativePosition: Offset(0.08, 0.20), pulseOffset: 0.10),
    NetworkNode(relativePosition: Offset(0.24, 0.12), pulseOffset: 0.35),
    NetworkNode(relativePosition: Offset(0.42, 0.22), pulseOffset: 0.80),
    NetworkNode(relativePosition: Offset(0.67, 0.12), pulseOffset: 0.15),
    NetworkNode(relativePosition: Offset(0.90, 0.24), pulseOffset: 0.60),
    NetworkNode(relativePosition: Offset(0.14, 0.48), pulseOffset: 0.45),
    NetworkNode(relativePosition: Offset(0.35, 0.42), pulseOffset: 0.90),
    NetworkNode(relativePosition: Offset(0.62, 0.47), pulseOffset: 0.25, isSpecial: true),
    NetworkNode(relativePosition: Offset(0.84, 0.53), pulseOffset: 0.70),
    NetworkNode(relativePosition: Offset(0.07, 0.80), pulseOffset: 0.05),
    NetworkNode(relativePosition: Offset(0.28, 0.88), pulseOffset: 0.50),
    NetworkNode(relativePosition: Offset(0.52, 0.76), pulseOffset: 0.85),
    NetworkNode(relativePosition: Offset(0.76, 0.88), pulseOffset: 0.30),
    NetworkNode(relativePosition: Offset(0.94, 0.76), pulseOffset: 0.65),
  ];

  static const List<NetworkLink> links = [
    NetworkLink(0, 1), NetworkLink(0, 9), NetworkLink(1, 2), NetworkLink(2, 3),
    NetworkLink(3, 4), NetworkLink(4, 13), NetworkLink(0, 5), NetworkLink(7, 12),
    NetworkLink(1, 6), NetworkLink(2, 6), NetworkLink(2, 7), NetworkLink(3, 7),
    NetworkLink(4, 8), NetworkLink(5, 6), NetworkLink(6, 7), NetworkLink(7, 8),
    NetworkLink(5, 9), NetworkLink(6, 10), NetworkLink(7, 11), NetworkLink(8, 13),
    NetworkLink(9, 10), NetworkLink(10, 11), NetworkLink(11, 12), NetworkLink(12, 13),
    NetworkLink(1, 3), NetworkLink(10, 12)
  ];

  late final Paint _linkPaint;
  late final Paint _glowPaint;
  late final Paint _nodePaint;
  late final Paint _corePaint;
  late final Paint _reflexPaint;

  HoneycombPainter({required this.progress, required this.themeData}) {
    _linkPaint = Paint()
      ..color = themeData.linkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _glowPaint = Paint()..style = PaintingStyle.fill;
    _nodePaint = Paint()..style = PaintingStyle.fill;
    _corePaint = Paint()..style = PaintingStyle.fill;
    _reflexPaint = Paint()..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Die Knoten liegen relativ zum Container vor; hier werden sie in echte Pixelkoordinaten umgerechnet.

    final absolutePoints = nodes
        .map(
          (node) => Offset(
            node.relativePosition.dx * size.width,
            node.relativePosition.dy * size.height,
          ),
        )
        .toList(growable: false);

    _drawGlassReflex(canvas, size);
    _drawLinks(canvas, absolutePoints);
    _drawTravelingLights(canvas, absolutePoints);
    _drawNodes(canvas, absolutePoints);
  }

  // Ein diagonaler Reflektionseffekt erzeugt den Eindruck von Glas und Bewegung im Hintergrund.
  void _drawGlassReflex(Canvas canvas, Size size) {
    final reflexProgress = (progress * 1.35) % 1.0;
    final reflexX = -size.width * 0.35 + size.width * 1.7 * reflexProgress;

    final reflexPath = Path()
      ..moveTo(reflexX, -size.height * 0.1)
      ..lineTo(reflexX + size.width * 0.16, -size.height * 0.1)
      ..lineTo(reflexX - size.width * 0.28, size.height * 1.1)
      ..lineTo(reflexX - size.width * 0.44, size.height * 1.1)
      ..close();

    _reflexPaint.color = themeData.reflexColor;
    canvas.drawPath(reflexPath, _reflexPaint);
  }

  // Die Verbindungslinien bilden das Grundgerüst des Knotennetzwerks und erzeugen die "Wabenstruktur".
  void _drawLinks(Canvas canvas, List<Offset> points) {
    for (final link in links) {
      final start = points[link.startNodeIndex];
      final end = points[link.endNodeIndex];
      final control = _calculateControlPoint(start, end);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      canvas.drawPath(path, _linkPaint);
    }
  }

  // Die Lichtpunkte gleiten entlang der Linien und erzeugen die fließende Bewegungswirkung.
  void _drawTravelingLights(Canvas canvas, List<Offset> points) {
    for (var i = 0; i < links.length; i++) {
      final link = links[i];
      final start = points[link.startNodeIndex];
      final end = points[link.endNodeIndex];
      final control = _calculateControlPoint(start, end);

      final lightProgress = (progress * 0.9 + i * 0.047) % 1.0;
      final lightPos = _calculateQuadraticPoint(start, control, end, lightProgress);

      _glowPaint.color = themeData.glowColor.withValues(alpha: 0.40);
      _nodePaint.color = themeData.coreColor.withValues(alpha: 0.82);

      canvas.drawCircle(lightPos, 7.0, _glowPaint);
      canvas.drawCircle(lightPos, 1.8, _nodePaint);
    }
  }

  // Jedes Netzglied pulsiert leicht; der spezielle Knoten erhält zusätzlich einen stärkeren Fokus.
  void _drawNodes(Canvas canvas, List<Offset> points) {
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final nodeData = nodes[i];
      final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2 + nodeData.pulseOffset * math.pi * 2);

      final glowColor = nodeData.isSpecial
          ? themeData.specialNodeColor.withValues(alpha: 0.26 + pulse * 0.18)
          : themeData.glowColor.withValues(alpha: 0.18 + pulse * 0.18);
      final bodyColor = nodeData.isSpecial
          ? themeData.specialNodeColor.withValues(alpha: 0.82 + pulse * 0.08)
          : themeData.nodeColor.withValues(alpha: 0.54 + pulse * 0.14);
      final coreColor = nodeData.isSpecial
          ? themeData.specialNodeColor.withValues(alpha: 0.95)
          : themeData.coreColor.withValues(alpha: 0.78 + pulse * 0.12);

      _glowPaint.color = glowColor;
      _nodePaint.color = bodyColor;
      _corePaint.color = coreColor;

      final baseRadius = nodeData.isSpecial ? 4.5 : 3.2;
      final coreRadius = nodeData.isSpecial ? 2.0 : 1.3;

      canvas.drawCircle(point, 13.0 + pulse * 4.0, _glowPaint);
      canvas.drawCircle(point, baseRadius, _nodePaint);
      canvas.drawCircle(point, coreRadius, _corePaint);
    }
  }

  Offset _calculateControlPoint(Offset start, Offset end) {
    final direction = end - start;
    return Offset(
      (start.dx + end.dx) / 2 - direction.dy * 0.08,
      (start.dy + end.dy) / 2 + direction.dx * 0.08,
    );
  }

  Offset _calculateQuadraticPoint(Offset start, Offset control, Offset end, double t) {
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;

    return Offset(
      uu * start.dx + 2 * u * t * control.dx + tt * end.dx,
      uu * start.dy + 2 * u * t * control.dy + tt * end.dy,
    );
  }

  @override
  bool shouldRepaint(covariant HoneycombPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.themeData != themeData;
  }
}