import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/exercise_library.dart';
import '../../state/game.dart';

/// This week's boss: your old record on a big lift.
class BossCard extends ConsumerWidget {
  const BossCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boss = ref.watch(bossProvider);
    if (boss == null) {
      return const GlassCard(
        child: Row(
          children: [
            Icon(Icons.shield_moon_rounded, color: AppColors.orange, size: 34),
            SizedBox(width: 12),
            Expanded(child: Text('الزعيم بيظهر بعد أول أسبوع تمرين: هيبقى رقمك القديم في تمرين أساسي، واكسره عشان تهزمه.', style: TextStyle(color: AppColors.muted, height: 1.6))),
          ],
        ),
      );
    }
    final ex = exerciseById(boss.exerciseId);
    final t = boss.target;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const RadialGradient(colors: [Color(0xFF3A1410), AppColors.surface], radius: 1.2, center: Alignment.topCenter),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(boss.defeated ? 'الزعيم اتهزم 🏆' : 'زعيم الأسبوع', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
              const Spacer(),
              const Text('🦍', style: TextStyle(fontSize: 30)),
            ],
          ),
          Text('${ex.arabic} ${t.kg.toStringAsFixed(t.kg % 1 == 0 ? 0 : 1)} × ${t.reps}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(
            boss.defeated ? 'كسرت رقمك. الأسبوع الجاي زعيم أقوى.' : 'رقمك القديم. اعمل أكتر منه (وزن أو عدات) تهزمه.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('صحة الزعيم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${(boss.health * 100).round()}%', style: const TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: boss.health),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 14, color: const Color(0xFFFF5A3D), backgroundColor: Colors.white10),
            ),
          ),
          if (boss.best != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'أحسن سِت ليك الأسبوع ده: ${boss.best!.kg.toStringAsFixed(boss.best!.kg % 1 == 0 ? 0 : 1)} × ${boss.best!.reps}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
