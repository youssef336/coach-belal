import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gemini/gemini_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/mascot.dart';
import '../../models/meal.dart';
import '../../state/coach_actions.dart';
import '../../state/meals.dart';
import 'food_swipe_card.dart';

/// The coach's suggestions for the rest of today. Swipe right = ate it.
class SwipePlanPage extends ConsumerStatefulWidget {
  const SwipePlanPage({super.key});

  @override
  ConsumerState<SwipePlanPage> createState() => _SwipePlanPageState();
}

class _SwipePlanPageState extends ConsumerState<SwipePlanPage> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  List<List<FoodIdea>>? _slots;
  String? _error;
  int _i = 0, _alt = 0, _eaten = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _load({bool fresh = false}) async {
    setState(() {
      _slots = null;
      _error = null;
      _i = 0;
      _alt = 0;
    });
    try {
      final ideas = await ref.read(coachActionsProvider).dayPlan(fresh: fresh);
      final bySlot = <String, List<FoodIdea>>{};
      for (final f in ideas) {
        bySlot.putIfAbsent(f.slot.isEmpty ? 'وجبة' : f.slot, () => []).add(f);
      }
      if (mounted) setState(() => _slots = bySlot.values.toList());
    } on CoachError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _ate(FoodIdea f) async {
    HapticFeedback.mediumImpact();
    await ref.read(mealsProvider.notifier).logIdea(f);
    setState(() {
      _i++;
      _alt = 0;
      _eaten++;
    });
    if (_i >= _slots!.length) _confetti.play();
  }

  void _skip() {
    HapticFeedback.selectionClick();
    final slot = _slots![_i];
    setState(() {
      if (_alt + 1 < slot.length) {
        _alt++;
      } else {
        _i++;
        _alt = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots;
    return Scaffold(
      appBar: AppBar(
        title: const Text('يومك جاهز', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(tooltip: 'اقتراحات جديدة', onPressed: () => _load(fresh: true), icon: const Icon(Icons.refresh_rounded))],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: _error != null
                ? _Message(mood: 'worried', text: _error!, button: 'جرّب تاني', onTap: _load)
                : slots == null
                ? const _Message(mood: 'neutral', text: 'الكوتش بيجهزلك يومك..')
                : slots.isEmpty
                ? _Message(mood: 'proud', text: 'يومك خلصان أصلًا!', button: 'اقتراحات تانية', onTap: () => _load(fresh: true))
                : _i >= slots.length
                ? _Message(mood: 'proud', text: 'يومك اتقفل يا وحش\n+${_eaten * 10} XP', button: 'تمام', onTap: () => Navigator.pop(context))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('اسحب يمين لو أكلته، شمال عشان يغيّره', style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var k = 0; k < slots.length; k++)
                            Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsetsDirectional.only(end: 6),
                                decoration: BoxDecoration(
                                  color: k < _i ? AppColors.lime : (k == _i ? AppColors.text : Colors.white12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: FoodSwipeCard(
                          key: ValueKey('$_i-$_alt'),
                          idea: slots[_i][_alt],
                          tint: _alt,
                          onAte: () => _ate(slots[_i][_alt]),
                          onSkip: _skip,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoundButton(icon: Icons.autorenew_rounded, size: 72, color: AppColors.surface, iconColor: AppColors.text, label: 'غيّره', onTap: _skip),
                          const SizedBox(width: 32),
                          _RoundButton(icon: Icons.check_rounded, size: 92, color: AppColors.lime, iconColor: AppColors.bg, label: 'أكلته', onTap: () => _ate(slots[_i][_alt])),
                        ],
                      ),
                    ],
                  ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [AppColors.lime, AppColors.orange, AppColors.sky, Colors.white],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.size, required this.color, required this.iconColor, required this.label, required this.onTap});
  final IconData icon;
  final double size;
  final Color color, iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: size, child: Icon(icon, size: size * 0.42, color: iconColor, semanticLabel: label)),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.mood, required this.text, this.button, this.onTap});
  final String mood, text;
  final String? button;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Mascot(mood: mood, size: 120),
        const SizedBox(height: 18),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.5)),
        if (button != null) ...[
          const SizedBox(height: 18),
          GlassCard(onTap: onTap, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12), child: Text(button!, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ],
    ),
  );
}
