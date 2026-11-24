import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/meals.dart';
import '../../state/profile.dart';
import '../coach/voice_sheet.dart';
import 'shopping_page.dart';
import 'swipe_plan_page.dart';

class FoodPage extends ConsumerWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(todayMealsProvider);
    final t = ref.watch(todayTotalsProvider);
    final p = ref.watch(profileProvider);
    final budget = p?.dailyBudget ?? 0;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('أكل النهارده', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: StatTile(label: 'سعر', value: '${t.kcal}', color: AppColors.lime)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'بروتين', value: '${t.protein}', color: AppColors.orange)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'صرفت / $budget', value: '${t.price}ج', color: t.price > budget ? AppColors.danger : AppColors.sky)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'وفّرت', value: '${t.saved}ج', color: AppColors.lime)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BigAction(
                  icon: Icons.swipe_rounded,
                  title: 'يومك جاهز',
                  sub: 'swipe وخلاص',
                  color: AppColors.lime,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SwipePlanPage())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigAction(
                  icon: Icons.shopping_basket_rounded,
                  title: 'لستة السوبرماركت',
                  sub: 'أرخص حاجات الأسبوع',
                  color: AppColors.orange,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShoppingPage())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => recordAndSend(context, ref), icon: const Icon(Icons.mic_rounded), label: const Text('قول بصوتك'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => snapAndSend(context, ref), icon: const Icon(Icons.photo_camera_rounded), label: const Text('صوّر طبقك'))),
            ],
          ),
          const SizedBox(height: 20),
          if (meals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('لسه مفيش أكل.. الكوتش مستني', style: TextStyle(color: AppColors.muted))),
            ),
          for (final m in meals)
            Dismissible(
              key: ValueKey(m.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete_rounded, color: AppColors.danger),
              ),
              onDismissed: (_) => ref.read(mealsProvider.notifier).remove(m.id),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  radius: 20,
                  child: Row(
                    children: [
                      Text(DateFormat('h:mm', 'en').format(m.at), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (m.kcal > 0) Text('${m.kcal} · ${m.protein}ج', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      if (m.saved > 0) Text('+${m.saved}ج', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          if (meals.isNotEmpty) const Text('اسحب أي أكلة عشان تمسحها', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({required this.icon, required this.title, required this.sub, required this.color, required this.onTap});
  final IconData icon;
  final String title, sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    color: color,
    onTap: onTap,
    radius: 24,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.bg, size: 28),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w900, fontSize: 17)),
        Text(sub, style: TextStyle(color: AppColors.bg.withValues(alpha: 0.7), fontSize: 12)),
      ],
    ),
  );
}
