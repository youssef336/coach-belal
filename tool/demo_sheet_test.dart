// Renders every exercise demo (start | end) into one image for review.
// Run: flutter test tool/demo_sheet_test.dart  → build/demo_sheet.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coach_belal/core/theme.dart';
import 'package:coach_belal/features/gym/demo/demo_poses.dart';
import 'package:coach_belal/features/gym/demo/exercise_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo sheet', (tester) async {
    await tester.runAsync(() async {
      const cell = 160.0, cols = 4;
      final ids = exerciseDemos.keys.toList();
      final rows = (ids.length / cols).ceil();
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(Rect.fromLTWH(0, 0, cols * cell * 2, rows * cell), Paint()..color = AppColors.bg);
      for (var i = 0; i < ids.length; i++) {
        final x = (i % cols) * cell * 2, y = (i ~/ cols) * cell;
        for (final t in [0.0, 1.0]) {
          c.save();
          c.translate(x + t * cell, y);
          DemoPainter(exerciseDemos[ids[i]]!, t).paint(c, const Size(cell, cell));
          c.restore();
        }
        final tp = TextPainter(text: TextSpan(text: ids[i], style: const TextStyle(color: Colors.white, fontSize: 12)), textDirection: TextDirection.ltr)..layout();
        tp.paint(c, Offset(x + 4, y + 2));
        c.drawLine(Offset(x + cell * 2, y), Offset(x + cell * 2, y + cell), Paint()..color = Colors.white24);
      }
      final img = await rec.endRecording().toImage((cols * cell * 2).round(), (rows * cell).round());
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/demo_sheet.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
