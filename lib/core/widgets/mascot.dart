import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The coach himself: a lime face with an orange headband and a mood.
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = 'happy', this.size = 56, this.bounce = true});

  /// happy · proud · neutral · worried · sideeye · sleepy
  final String mood;
  final double size;
  final bool bounce;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.bounce) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, -3 * Curves.easeInOut.transform(_c.value)),
      child: child,
    ),
    child: CustomPaint(size: Size.square(widget.size), painter: MascotPainter(widget.mood)),
  );
}

class MascotPainter extends CustomPainter {
  MascotPainter(this.mood);
  final String mood;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 56;
    canvas.scale(s);
    final ink = Paint()
      ..color = AppColors.bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = AppColors.bg;

    canvas.drawCircle(const Offset(28, 28), 26, Paint()..color = AppColors.lime);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(6, 14, 44, 7), const Radius.circular(3.5)),
      Paint()..color = AppColors.orange,
    );

    switch (mood) {
      case 'proud':
      case 'happy':
        canvas.drawArc(const Rect.fromLTWH(15, 27, 10, 8), math.pi, math.pi, false, ink);
        canvas.drawArc(const Rect.fromLTWH(31, 27, 10, 8), math.pi, math.pi, false, ink);
      case 'sleepy':
        canvas.drawLine(const Offset(16, 31), const Offset(24, 31), ink);
        canvas.drawLine(const Offset(32, 31), const Offset(40, 31), ink);
      case 'sideeye':
        canvas.drawLine(const Offset(15, 29), const Offset(25, 29), ink);
        canvas.drawLine(const Offset(31, 29), const Offset(41, 29), ink);
        canvas.drawCircle(const Offset(17.5, 32), 2.6, fill);
        canvas.drawCircle(const Offset(33.5, 32), 2.6, fill);
      default:
        canvas.drawCircle(const Offset(20, 31), 3.2, fill);
        canvas.drawCircle(const Offset(36, 31), 3.2, fill);
    }

    final mouth = Path();
    switch (mood) {
      case 'proud':
        mouth
          ..moveTo(17, 38)
          ..quadraticBezierTo(28, 50, 39, 38)
          ..close();
        canvas.drawPath(mouth, fill);
      case 'worried':
        mouth
          ..moveTo(20, 44)
          ..quadraticBezierTo(28, 38, 36, 44);
        canvas.drawPath(mouth, ink);
      case 'sideeye':
      case 'sleepy':
        canvas.drawLine(const Offset(22, 41), const Offset(34, 41), ink);
      default:
        mouth
          ..moveTo(19, 39)
          ..quadraticBezierTo(28, 46, 37, 39);
        canvas.drawPath(mouth, ink);
    }
  }

  @override
  bool shouldRepaint(MascotPainter old) => old.mood != mood;
}
