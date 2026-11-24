// Draws the app icons from the mascot painter.
// Run: flutter test tool/make_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coach_belal/core/theme.dart';
import 'package:coach_belal/core/widgets/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _icon(String path, int size, {double pad = 0.12, bool round = false}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final s = size.toDouble();
  final bg = Paint()..color = AppColors.bg;
  if (round) {
    c.drawCircle(Offset(s / 2, s / 2), s / 2, bg);
  } else {
    c.drawRect(Rect.fromLTWH(0, 0, s, s), bg);
  }
  final inner = s * (1 - 2 * pad);
  c.translate(s * pad, s * pad);
  MascotPainter('proud').paint(c, Size.square(inner));
  final img = await rec.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('make icons', (tester) async {
    await tester.runAsync(() async {
      await _icon('web/icons/Icon-192.png', 192);
      await _icon('web/icons/Icon-512.png', 512);
      await _icon('web/icons/Icon-maskable-192.png', 192, pad: 0.2);
      await _icon('web/icons/Icon-maskable-512.png', 512, pad: 0.2);
      await _icon('web/favicon.png', 32, pad: 0.02);
      const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final e in android.entries) {
        await _icon('android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', e.value, pad: 0.08, round: true);
      }
    });
  });
}
