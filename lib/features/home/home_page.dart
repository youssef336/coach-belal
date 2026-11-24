import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/mascot.dart';
import '../../state/chat.dart';
import '../../state/game.dart';
import '../../state/meals.dart';
import '../../state/profile.dart';
import '../coach/voice_sheet.dart';
import 'shell.dart';
import 'today_card.dart';
import 'today_rings.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الفل';
    if (h < 18) return 'عامل إيه';
    return 'مساء الفل';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider.select((p) => p?.name ?? ''));
    final streak = ref.watch(gameProvider.select((g) => g.streak));
    final mood = ref.watch(chatProvider.select((c) => c.mood));
    final mealsToday = ref.watch(todayTotalsProvider.select((t) => t.count));
    final shownMood = mealsToday == 0 && DateTime.now().hour > 13 ? 'sideeye' : mood;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Mascot(mood: shownMood, size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_greeting()} يا $name', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    Text(
                      mealsToday == 0 ? 'لسه مقولتليش أكلت إيه' : 'الكوتش متابعك النهارده',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              _StreakPill(streak: streak),
            ],
          ),
          const SizedBox(height: 18),
          const TodayRings(),
          const SizedBox(height: 14),
          const TodayCard(),
          const SizedBox(height: 26),
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                recordAndSend(context, ref);
              },
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.orange.withValues(alpha: 0.18), spreadRadius: 14),
                    BoxShadow(color: AppColors.orange.withValues(alpha: 0.07), spreadRadius: 28),
                  ],
                ),
                child: const Icon(Icons.mic_rounded, size: 50, color: AppColors.bg, semanticLabel: 'قول أكلت إيه'),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.04, duration: 1200.ms),
            ),
          ),
          const SizedBox(height: 34),
          const Center(child: Text('دوس وقول أكلت إيه.. بس كده', style: TextStyle(color: AppColors.muted))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _QuickButton(icon: Icons.photo_camera_rounded, label: 'صوّر', onTap: () => snapAndSend(context, ref))),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickButton(
                  icon: Icons.replay_rounded,
                  label: 'زي امبارح',
                  onTap: () async {
                    final n = await ref.read(mealsProvider.notifier).repeatYesterday();
                    if (context.mounted) toast(context, n == 0 ? 'امبارح مسجلتش أكل' : 'سجلت $n حاجات زي امبارح');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickButton(
                  icon: Icons.fitness_center_rounded,
                  label: 'أنا في الجيم',
                  solid: true,
                  onTap: () => ref.read(tabProvider.notifier).go(Tabs.gym),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
    child: Row(
      children: [
        const Icon(Icons.local_fire_department_rounded, color: AppColors.orange, size: 18),
        const SizedBox(width: 2),
        Text('$streak', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFB37F))),
      ],
    ),
  );
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.icon, required this.label, required this.onTap, this.solid = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) => Material(
    color: solid ? AppColors.text : Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: solid ? AppColors.bg : AppColors.lime),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: solid ? AppColors.bg : AppColors.text),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
