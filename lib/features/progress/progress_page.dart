import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/game.dart';
import '../../state/profile.dart';
import '../settings/settings_page.dart';
import 'boss_card.dart';
import 'weight_card.dart';
import 'wrapped_page.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    final p = ref.watch(profileProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(child: Text('التقدم', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
              IconButton(
                tooltip: 'الإعدادات',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassCard(
            color: AppColors.lime,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WrappedPage())),
            child: const Row(
              children: [
                Icon(Icons.auto_stories_rounded, color: AppColors.bg, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coach Wrapped', style: TextStyle(color: AppColors.bg, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('أسبوعك في قصة + رأي الكوتش بصراحة', style: TextStyle(color: AppColors.bg)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: AppColors.bg),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(18)),
                      child: Text('${g.level.number}', style: const TextStyle(color: AppColors.bg, fontSize: 24, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('لفل ${g.level.number} · ${g.xp} XP', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          Text(g.level.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.orange),
                    Text(' ${g.streak} يوم', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: g.levelProgress, minHeight: 10, color: AppColors.lime, backgroundColor: Colors.white12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: StatTile(label: 'قوة', value: '${g.strength}', color: AppColors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(label: 'تحمّل', value: '${g.endurance}', color: AppColors.sky)),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(label: 'التزام', value: '${g.discipline}', color: AppColors.lime)),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(label: 'وفّرت', value: '${g.totalSaved}ج', color: AppColors.lime)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const BossCard(),
          const SizedBox(height: 12),
          const WeightCard(),
          if (p != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              child: Text(
                'هدفك اليومي: ${p.targetCalories} سعر · ${p.targetProtein}ج بروتين · ${p.targetCarbs}ج كارب · ${p.targetFat}ج دهون'
                '${p.calorieAdjust == 0 ? '' : '\nالكوتش عدّل السعرات ${p.calorieAdjust > 0 ? '+' : ''}${p.calorieAdjust} حسب الميزان'}',
                style: const TextStyle(color: AppColors.muted, height: 1.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
