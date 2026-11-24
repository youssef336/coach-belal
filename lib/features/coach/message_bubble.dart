import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/voice.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/chat_message.dart';
import '../../models/meal.dart';
import '../../state/chat.dart';
import '../home/shell.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final me = !m.fromCoach;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 310),
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: me ? const Color(0xFF1F6F4A) : (m.error ? AppColors.danger.withValues(alpha: 0.18) : AppColors.surface2),
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(20),
          topEnd: const Radius.circular(20),
          bottomStart: Radius.circular(me ? 6 : 20),
          bottomEnd: Radius.circular(me ? 20 : 6),
        ),
      ),
      child: Text(m.text, style: const TextStyle(fontSize: 15, height: 1.6)),
    );

    return Column(
      crossAxisAlignment: me ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onLongPress: m.fromCoach ? () => CoachVoice.instance.say(m.text) : null,
          child: bubble,
        ),
        if (m.eaten.isNotEmpty) _EatenCard(items: m.eaten),
        if (m.swap != null) _SwapCard(message: m),
        if (m.workoutTitle != null)
          _ActionCard(
            icon: Icons.fitness_center_rounded,
            text: 'جهزتلك: ${m.workoutTitle}',
            button: 'يلا',
            onTap: () => ref.read(tabProvider.notifier).go(Tabs.gym),
          ),
      ],
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15, curve: Curves.easeOut);
  }
}

class _EatenCard extends StatelessWidget {
  const _EatenCard({required this.items});
  final List<FoodIdea> items;

  @override
  Widget build(BuildContext context) {
    int sum(int Function(FoodIdea) f) => items.fold(0, (s, x) => s + f(x));
    return Container(
      width: 310,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.lime, size: 18),
                const SizedBox(width: 6),
                const Expanded(child: Text('سجلتها', style: TextStyle(fontWeight: FontWeight.w800))),
                Text('${sum((f) => f.price)} ج تقريبًا', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            for (final f in items)
              Text('• ${f.title}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: StatTile(label: 'سعر', value: '${sum((f) => f.kcal)}')),
                const SizedBox(width: 6),
                Expanded(child: StatTile(label: 'بروتين', value: '${sum((f) => f.protein)}', color: AppColors.orange)),
                const SizedBox(width: 6),
                Expanded(child: StatTile(label: 'كارب', value: '${sum((f) => f.carbs)}')),
                const SizedBox(width: 6),
                Expanded(child: StatTile(label: 'دهون', value: '${sum((f) => f.fat)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwapCard extends ConsumerWidget {
  const _SwapCard({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = message.swap!;
    final ate = message.eaten.fold<int>(0, (sum, f) => sum + f.price);
    final saving = ate - s.price;
    return Container(
      width: 310,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF23331A), AppColors.surface], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.lime, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text('البديل: ${s.title}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.lime))),
            ],
          ),
          if (s.why.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(s.why, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          const SizedBox(height: 6),
          Text('${s.kcal} سعر · ${s.protein}ج بروتين · ${s.price} ج', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  saving > 0 ? 'هتوفر $saving ج' : 'أنسب لهدفك',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.lime, fontSize: 13),
                ),
              ),
              message.swapTaken
                  ? const Text('اتفقنا ✓', style: TextStyle(fontWeight: FontWeight.w800))
                  : FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(chatProvider.notifier).takeSwap(message);
                      },
                      child: const Text('تمام'),
                    ),
            ],
          ),
          const Text('الأسعار تقريبية', style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.text, required this.button, required this.onTap});
  final IconData icon;
  final String text, button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: 310,
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: GlassCard(
      padding: const EdgeInsets.all(12),
      radius: 22,
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800))),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(70, 40)), onPressed: onTap, child: Text(button)),
        ],
      ),
    ),
  );
}
