import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/rings.dart';
import '../../state/meals.dart';
import '../../state/profile.dart';

class TodayRings extends ConsumerWidget {
  const TodayRings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final t = ref.watch(todayTotalsProvider);
    if (p == null) return const SizedBox.shrink();
    final kcalGoal = p.targetCalories, proteinGoal = p.targetProtein, budget = p.dailyBudget;
    return GlassCard(
      child: Row(
        children: [
          ActivityRings(
            rings: [
              RingData(t.kcal / kcalGoal, AppColors.lime),
              RingData(t.protein / proteinGoal, AppColors.orange),
              RingData(t.price / (budget == 0 ? 1 : budget), AppColors.sky),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line('سعرات', '${t.kcal}', '/ $kcalGoal', AppColors.lime),
                const SizedBox(height: 8),
                _Line('بروتين', '${t.protein}ج', '/ $proteinGoal', AppColors.orange),
                const SizedBox(height: 8),
                _Line('صرفت', '${t.price}ج', '/ $budget', AppColors.sky),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, this.of, this.color);
  final String label, value, of;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            TextSpan(text: ' $of', style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
}
