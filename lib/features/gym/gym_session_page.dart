import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/mascot.dart';
import '../../data/exercise_library.dart';
import '../../models/workout.dart';
import '../../state/game.dart';
import '../../state/workouts.dart';
import 'demo/exercise_demo.dart';
import 'how_to_video_button.dart';

/// Gym mode: one giant button. Rest timer starts on its own and buzzes.
class GymSessionPage extends ConsumerStatefulWidget {
  const GymSessionPage({super.key});

  @override
  ConsumerState<GymSessionPage> createState() => _GymSessionPageState();
}

class _GymSessionPageState extends ConsumerState<GymSessionPage> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  Timer? _timer;
  int _rest = 0, _restFull = 90;
  double? _kg;
  int? _reps;
  final _started = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_rest > 0) {
        setState(() => _rest--);
        if (_rest == 0) _buzz();
      } else {
        setState(() {}); // session clock
      }
    });
  }

  Future<void> _buzz() async {
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  int? _current(WorkoutDay w) {
    for (var i = 0; i < w.items.length; i++) {
      if (w.items[i].done.length < w.items[i].sets) return i;
    }
    return null;
  }

  Future<void> _done(WorkoutDay w, int i) async {
    final e = w.items[i];
    HapticFeedback.heavyImpact();
    final bossBefore = ref.read(bossProvider)?.defeated ?? false;
    await ref.read(workoutsProvider.notifier).logSet(i, LoggedSet(_kg ?? e.kg, _reps ?? e.reps));
    final boss = ref.read(bossProvider);
    if (!bossBefore && (boss?.defeated ?? false)) {
      _confetti.play();
      if (mounted) _showBossDown();
    }
    final updated = ref.read(todayWorkoutProvider)!;
    if (_current(updated) == null) {
      await ref.read(workoutsProvider.notifier).finish();
      _confetti.play();
      setState(() => _rest = 0);
      return;
    }
    setState(() {
      _restFull = e.reps <= 8 ? 120 : 75;
      _rest = _restFull;
      if (_current(updated) != i) {
        _kg = null;
        _reps = null;
      }
    });
  }

  void _showBossDown() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('هزمت الزعيم! 🦍', style: TextStyle(fontWeight: FontWeight.w900)),
      content: const Text('كسرت رقمك القديم. الكوتش فخور بيك.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('أكيد'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(todayWorkoutProvider);
    if (w == null) return const Scaffold(body: Center(child: Text('مفيش تمرين')));
    final cur = _current(w);
    final elapsed = DateTime.now().difference(_started);
    final clock = '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(w.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(clock, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800))))],
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: cur == null ? _finished(w) : _active(w, cur),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [AppColors.lime, AppColors.orange, AppColors.sky, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  Widget _finished(WorkoutDay w) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Mascot(mood: 'proud', size: 140),
        const SizedBox(height: 20),
        const Text('خلصت يا وحش!', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        Text('${w.setsDone} سِت · +${w.setsDone * 5 + 50} XP', style: const TextStyle(color: AppColors.lime, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('روّح كُل بروتين')),
      ],
    ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 900.ms),
  );

  Widget _active(WorkoutDay w, int i) {
    final e = w.items[i];
    final ex = exerciseById(e.exerciseId);
    final kg = _kg ?? e.kg;
    final reps = _reps ?? e.reps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('تمرين ${i + 1} من ${w.items.length}', style: const TextStyle(color: AppColors.muted)),
        Row(
          children: [
            Expanded(child: Text(ex.arabic, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
            HowToVideoButton(exercise: ex),
          ],
        ),
        Text('${ex.name} · ${ex.tip}', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 10),
        ExerciseDemo(exerciseId: e.exerciseId, height: 160),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var k = 0; k < e.sets; k++)
              Expanded(
                child: Container(
                  height: 54,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  decoration: BoxDecoration(
                    color: k < e.done.length ? AppColors.lime : (k == e.done.length ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    k < e.done.length ? '${_fmt(e.done[k].kg)}ك × ${e.done[k].reps}' : '${k + 1}',
                    style: TextStyle(fontWeight: FontWeight.w900, color: k < e.done.length ? AppColors.bg : AppColors.text),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Center(
            child: _rest > 0
                ? _restView()
                : GestureDetector(
                    onTap: () => _done(w, i),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.lime.withValues(alpha: 0.12), spreadRadius: 16),
                          BoxShadow(color: AppColors.lime.withValues(alpha: 0.05), spreadRadius: 34),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('خلصت السِت', style: TextStyle(color: AppColors.bg, fontSize: 32, fontWeight: FontWeight.w900)),
                          Text('${_fmt(kg)} كيلو × $reps', style: TextStyle(color: AppColors.bg.withValues(alpha: 0.75), fontSize: 17, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ).animate(key: ValueKey(e.done.length)).scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut, duration: 700.ms),
          ),
        ),
        Row(
          children: [
            _Mini(label: 'كيلو', onMinus: () => setState(() => _kg = math.max(0, kg - 2.5)), onPlus: () => setState(() => _kg = kg + 2.5)),
            const SizedBox(width: 10),
            _Mini(label: 'عدات', onMinus: () => setState(() => _reps = math.max(1, reps - 1)), onPlus: () => setState(() => _reps = reps + 1)),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'تراجع',
              onPressed: () => ref.read(workoutsProvider.notifier).undoSet(i),
              icon: const Icon(Icons.undo_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _restView() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(
        dimension: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: _rest / _restFull,
                strokeWidth: 14,
                color: AppColors.sky,
                backgroundColor: AppColors.sky.withValues(alpha: 0.15),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('$_rest', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Text('ريّح.. هيهزلك لما يخلص', style: TextStyle(color: AppColors.muted)),
      TextButton(onPressed: () => setState(() => _rest = 0), child: const Text('جاهز خلاص')),
    ],
  );
}

String _fmt(double kg) => kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1);

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.onMinus, required this.onPlus});
  final String label;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 52,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          IconButton(tooltip: '$label أقل', onPressed: onMinus, icon: const Icon(Icons.remove_rounded)),
          Expanded(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
          IconButton(tooltip: '$label أكتر', onPressed: onPlus, icon: const Icon(Icons.add_rounded)),
        ],
      ),
    ),
  );
}
