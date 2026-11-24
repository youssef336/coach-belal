import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/gemini/gemini_client.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../core/widgets/mascot.dart';
import '../../data/exercise_library.dart';
import '../../state/coach_actions.dart';
import '../../state/meals.dart';
import '../../state/profile.dart';
import '../../state/workouts.dart';

class _Slide {
  const _Slide(this.top, this.big, this.sub, this.bg, this.fg);
  final String top, big, sub;
  final Color bg, fg;
}

/// Your week as a story. Tap to go on, share the last card.
class WrappedPage extends ConsumerStatefulWidget {
  const WrappedPage({super.key});

  @override
  ConsumerState<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends ConsumerState<WrappedPage> {
  final _shot = GlobalKey();
  int _i = 0;
  String? _review;

  late final List<_Slide> _slides = _build();
  late final String _stats;

  List<_Slide> _build() {
    final now = DateTime.now();
    final from = dayKey(now.subtract(const Duration(days: 6)));
    final meals = ref.read(mealsProvider).where((m) => dayKey(m.at).compareTo(from) >= 0).toList();
    final workouts = ref.read(workoutsProvider).values.where((w) => w.day.compareTo(from) >= 0 && w.setsDone > 0).toList();
    final weights = ref.read(weightsProvider);
    final p = ref.read(profileProvider);

    final inWeek = weights.where((w) => w.day.compareTo(from) >= 0).toList();
    final before = weights.where((w) => w.day.compareTo(from) < 0).toList();
    final start = before.isNotEmpty ? before.last.kg : (inWeek.isNotEmpty ? inWeek.first.kg : null);
    final end = inWeek.isNotEmpty ? inWeek.last.kg : null;
    final delta = start != null && end != null ? end - start : null;

    final counts = <String, int>{};
    for (final m in meals.where((m) => m.kcal > 0)) {
      counts[m.title] = (counts[m.title] ?? 0) + 1;
    }
    final top = counts.entries.isEmpty ? null : (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    final days = meals.map((m) => dayKey(m.at)).toSet().length;
    final avgProtein = days == 0 ? 0 : meals.fold<int>(0, (s, m) => s + m.protein) ~/ days;
    final saved = meals.fold<int>(0, (s, m) => s + m.saved);
    final spent = meals.fold<int>(0, (s, m) => s + m.price);

    String best = '—';
    double bestE = 0;
    for (final w in workouts) {
      for (final e in w.items) {
        for (final s in e.done) {
          if (s.kg > 0 && s.e1rm > bestE) {
            bestE = s.e1rm;
            best = '${exerciseById(e.exerciseId).arabic} ${s.kg.toStringAsFixed(s.kg % 1 == 0 ? 0 : 1)}×${s.reps}';
          }
        }
      }
    }

    _stats = 'تغيير الوزن: ${delta?.toStringAsFixed(1) ?? 'مش متسجل'} كجم. أيام سجل فيها أكل: $days من 7. '
        'متوسط البروتين: $avgProtein (الهدف ${p?.targetProtein}). أيام جيم: ${workouts.length} من ${p?.gymDays}. '
        'أقوى سِت: $best. صرف على الأكل: $spent ج، وفّر: $saved ج. أكتر أكلة: ${top?.key ?? '—'}.';

    return [
      _Slide('أسبوعك مع الكوتش', delta == null ? '?' : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}', delta == null ? 'اتوزن الأسبوع الجاي عشان نعرف' : 'كيلو الأسبوع ده', AppColors.lime, AppColors.bg),
      _Slide('أكتر أكلة', top == null ? '—' : '${top.value}×', top?.key ?? 'مسجلتش أكل', AppColors.orange, AppColors.bg),
      _Slide('البروتين', '$avgProtein', 'جرام في اليوم (الهدف ${p?.targetProtein ?? '?'})', AppColors.surface2, AppColors.orange),
      _Slide('الجيم', '${workouts.length} من ${p?.gymDays ?? '?'}', 'أقوى سِت: $best', AppColors.sky, AppColors.bg),
      _Slide('الفلوس', '$saved ج', 'وفرتهم بالبدائل · صرفت $spent ج', AppColors.surface2, AppColors.lime),
    ];
  }

  Future<void> _loadReview() async {
    if (_review != null) return;
    setState(() => _review = '...');
    try {
      final r = await ref.read(coachActionsProvider).weeklyReview(_stats);
      if (mounted) setState(() => _review = r.trim());
    } on CoachError catch (e) {
      if (mounted) setState(() => _review = e.message);
    }
  }

  void _next() {
    if (_i < _slides.length) {
      setState(() => _i++);
      if (_i == _slides.length) _loadReview();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _share() async {
    final boundary = _shot.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final img = await boundary.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: 'coach_wrapped.png')], text: 'أسبوعي مع Coach Belal 💪'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _i >= _slides.length;
    final s = last ? null : _slides[_i];
    final bg = s?.bg ?? AppColors.lime;
    final fg = s?.fg ?? AppColors.bg;
    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var k = 0; k <= _slides.length; k++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsetsDirectional.only(end: 5),
                          decoration: BoxDecoration(color: fg.withValues(alpha: k <= _i ? 1 : 0.25), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: RepaintBoundary(
                    key: _shot,
                    child: Container(
                      color: bg,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: last ? _reviewView(fg) : _slideView(s!),
                    ),
                  ),
                ),
                if (last)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.bg, foregroundColor: AppColors.text, minimumSize: const Size.fromHeight(56)),
                          onPressed: _share,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('شيّرها'),
                        ),
                      ),
                    ],
                  )
                else
                  Text('دوس عشان تكمّل', style: TextStyle(color: fg.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slideView(_Slide s) => Column(
    key: ValueKey(_i),
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(s.top, style: TextStyle(color: s.fg, fontSize: 20, fontWeight: FontWeight.w800)),
      FittedBox(child: Text(s.big, style: TextStyle(color: s.fg, fontSize: 110, fontWeight: FontWeight.w900, height: 1.2))),
      Text(s.sub, style: TextStyle(color: s.fg, fontSize: 24, fontWeight: FontWeight.w800, height: 1.4)),
    ],
  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);

  Widget _reviewView(Color fg) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Mascot(mood: 'sideeye', size: 90),
      const SizedBox(height: 16),
      Text('رأي الكوتش بصراحة', style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Text(
        _review == null || _review == '...' ? 'الكوتش بيفكر..' : _review!,
        style: TextStyle(color: fg, fontSize: 19, height: 1.7, fontWeight: FontWeight.w600),
      ),
    ],
  ).animate().fadeIn();
}
