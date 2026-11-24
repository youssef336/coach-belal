import 'dart:math' as math;

import 'package:flutter/material.dart';

class RingData {
  const RingData(this.value, this.color);
  final double value; // 0..1 (over 1 draws a second lap)
  final Color color;
}

/// Apple-watch style rings that sweep in when the numbers change.
class ActivityRings extends StatelessWidget {
  const ActivityRings({super.key, required this.rings, this.size = 132, this.stroke = 11});

  final List<RingData> rings;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 1100),
    curve: Curves.easeOutCubic,
    builder: (_, t, _) => CustomPaint(size: Size.square(size), painter: _RingsPainter(rings, stroke, t)),
  );
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.rings, this.stroke, this.t);
  final List<RingData> rings;
  final double stroke;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < rings.length; i++) {
      final r = size.width / 2 - stroke / 2 - i * (stroke + 4);
      final rect = Rect.fromCircle(center: c, radius: r);
      final base = Paint()
        ..color = rings[i].color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawCircle(c, r, base);
      final sweep = (rings[i].value.clamp(0.0, 2.0)) * t * 2 * math.pi;
      if (sweep <= 0) continue;
      final p = Paint()
        ..color = rings[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t || old.rings != rings;
}
