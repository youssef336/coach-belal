import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import 'demo_poses.dart';

/// The coach (headband and all) doing the exercise in a slow loop. Offline.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({super.key, required this.exerciseId, this.height = 150});

  final String exerciseId;
  final double height;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  Demo? get _demo => exerciseDemos[widget.exerciseId];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _duration)..repeat(reverse: true);
  }

  Duration get _duration => Duration(milliseconds: ((_demo?.seconds ?? 1.4) * 1000).round());

  @override
  void didUpdateWidget(ExerciseDemo old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId) {
      _c
        ..duration = _duration
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = _demo;
    if (demo == null) return SizedBox(height: widget.height);
    return Container(
      height: widget.height,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(24)),
      child: Directionality(
        // Poses are drawn facing right; keep them that way in Arabic too.
        textDirection: TextDirection.ltr,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: DemoPainter(demo, Curves.easeInOut.transform(_c.value)),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class DemoPainter extends CustomPainter {
  DemoPainter(this.demo, this.t);

  final Demo demo;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the 100×100 stage, centred.
    final s = (size.height < size.width ? size.height : size.width) / 100;
    canvas
      ..save()
      ..translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2)
      ..scale(s);

    Offset? j(String k) {
      final a = demo.a[k], b = demo.b[k];
      if (a == null) return null;
      return Offset.lerp(a, b ?? a, t);
    }

    final floor = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(4, 93), const Offset(96, 93), floor);

    final prop = Paint()..color = const Color(0xFF3A434C);
    for (final r in demo.stage) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), prop);
    }

    final cable = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    if (demo.prop == Prop.cable) {
      if (demo.anchor != null && j('ha') != null) canvas.drawLine(demo.anchor!, j('ha')!, cable);
      if (demo.anchor2 != null && j('ha2') != null) canvas.drawLine(demo.anchor2!, j('ha2')!, cable);
    }

    Paint limb(bool far) => Paint()
      ..color = far ? AppColors.text.withValues(alpha: 0.35) : AppColors.text
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void chain(List<String> keys, {bool far = false}) {
      final pts = keys.map(j).toList();
      if (pts.any((p) => p == null)) return;
      final path = Path()..moveTo(pts.first!.dx, pts.first!.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p!.dx, p.dy);
      }
      canvas.drawPath(path, limb(far));
    }

    final front = demo.a.containsKey('sh2');
    if (front) {
      final sh = Offset.lerp(j('sh'), j('sh2'), 0.5)!;
      final torso = Paint()
        ..color = AppColors.lime.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawPath(
        Path()
          ..moveTo(j('sh')!.dx, j('sh')!.dy)
          ..lineTo(j('sh2')!.dx, j('sh2')!.dy)
          ..lineTo(j('hip2')!.dx, j('hip2')!.dy)
          ..lineTo(j('hip')!.dx, j('hip')!.dy)
          ..close(),
        torso,
      );
      chain(['sh', 'el', 'ha']);
      chain(['sh2', 'el2', 'ha2']);
      chain(['hip', 'kn', 'ft']);
      chain(['hip2', 'kn2', 'ft2']);
      _head(canvas, j('head')!, sh);
      _props(canvas, [j('ha'), j('ha2')]);
    } else {
      chain(['hip', 'kn2', 'ft2'], far: true);
      chain(['sh', 'el2', 'ha2'], far: true);
      final torso = Paint()
        ..color = AppColors.lime
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(j('sh')!, j('hip')!, torso);
      chain(['hip', 'kn', 'ft']);
      chain(['sh', 'el', 'ha']);
      _head(canvas, j('head')!, j('sh')!);
      _props(canvas, [j('ha')]);
    }
    canvas.restore();
  }

  void _head(Canvas canvas, Offset head, Offset neck) {
    canvas.drawLine(
      head,
      neck,
      Paint()
        ..color = AppColors.text
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(head, 6.5, Paint()..color = AppColors.lime);
    // The coach's orange headband.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: head.translate(0, -2.2), width: 13, height: 2.6), const Radius.circular(1.3)),
      Paint()..color = AppColors.orange,
    );
  }

  void _props(Canvas canvas, List<Offset?> hands) {
    final plate = Paint()..color = AppColors.orange;
    final hole = Paint()..color = AppColors.bg;
    for (final h in hands.whereType<Offset>()) {
      switch (demo.prop) {
        case Prop.barbell:
          canvas
            ..drawCircle(h, 7.5, plate)
            ..drawCircle(h, 2, hole);
        case Prop.dumbbell:
          canvas
            ..drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h, width: 9, height: 5), const Radius.circular(2)), plate)
            ..drawCircle(h, 1.2, hole);
        case Prop.cable:
          canvas.drawCircle(h, 2.2, Paint()..color = AppColors.muted);
        case Prop.none:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(DemoPainter old) => old.t != t || old.demo != demo;
}
