import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/meals.dart';
import '../../state/profile.dart';
import '../../state/workouts.dart';
import '../food/swipe_plan_page.dart';
import 'shell.dart';

/// The one lime card: what's left to eat, what to train, what it costs.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final t = ref.watch(todayTotalsProvider);
    final w = ref.watch(todayWorkoutProvider);
    if (p == null) return const SizedBox.shrink();
    final proteinLeft = (p.targetProtein - t.protein).clamp(0, 999);
    final kcalLeft = (p.targetCalories - t.kcal).clamp(0, 99999);

    final food = proteinLeft == 0 && kcalLeft < 150
        ? 'الأكل خلص النهارده.. عاش'
        : 'فاضلك $kcalLeft سعر و$proteinLeft جرام بروتين';
    final gym = w == null
        ? 'تمرين: لسه، دوس «أنا في الجيم»'
        : w.finished
        ? 'تمرين: ${w.title} — خلص ✓'
        : 'تمرين: ${w.title} (${w.setsDone}/${w.setsPlanned} سِت)';

    return GlassCard(
      color: AppColors.lime,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SwipePlanPage())),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.bg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('النهارده بس كده', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.bg.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            _Row(Icons.restaurant_rounded, food),
            const SizedBox(height: 8),
            InkWell(onTap: () => ref.read(tabProvider.notifier).go(Tabs.gym), child: _Row(Icons.fitness_center_rounded, gym)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.bg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.swipe_rounded, size: 18, color: AppColors.bg),
                  SizedBox(width: 8),
                  Expanded(child: Text('دوس هنا والكوتش يجهزلك باقي يومك', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.bg))),
                  Icon(Icons.chevron_left_rounded, color: AppColors.bg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 22, color: AppColors.bg),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.bg))),
    ],
  );
}
