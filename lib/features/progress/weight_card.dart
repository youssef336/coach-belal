import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/profile.dart';

class WeightCard extends ConsumerStatefulWidget {
  const WeightCard({super.key});

  @override
  ConsumerState<WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends ConsumerState<WeightCard> {
  double? _draft;

  @override
  Widget build(BuildContext context) {
    final weights = ref.watch(weightsProvider);
    final p = ref.watch(profileProvider);
    final current = weights.isEmpty ? (p?.weightKg ?? 70) : weights.last.kg;
    final draft = _draft ?? current;
    final recent = weights.length > 30 ? weights.sublist(weights.length - 30) : weights;
    final spots = [for (var i = 0; i < recent.length; i++) FlSpot(i.toDouble(), recent[i].kg)];
    final change = weights.length < 2 ? 0.0 : weights.last.kg - weights.first.kg;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('الوزن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              if (weights.length >= 2)
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} كيلو من البداية',
                  style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800),
                ),
            ],
          ),
          if (p != null) Text('الهدف ${p.targetKg.toStringAsFixed(0)} كيلو', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 12),
          if (spots.length >= 2)
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  extraLinesData: p == null ? null : ExtraLinesData(horizontalLines: [HorizontalLine(y: p.targetKg, color: AppColors.orange.withValues(alpha: 0.5), dashArray: [6, 6])]),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.lime,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppColors.lime.withValues(alpha: 0.12)),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text('اتوزن كل أسبوع والرسم هيظهر هنا', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(tooltip: 'أقل', onPressed: () => setState(() => _draft = draft - 0.1), icon: const Icon(Icons.remove_rounded)),
              Expanded(
                child: Text(
                  '${draft.toStringAsFixed(1)} كيلو',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton.filledTonal(tooltip: 'أكتر', onPressed: () => setState(() => _draft = draft + 0.1), icon: const Icon(Icons.add_rounded)),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(weightsProvider.notifier).log(double.parse(draft.toStringAsFixed(1)));
                  setState(() => _draft = null);
                  if (context.mounted) toast(context, 'سجلت وزنك');
                },
                child: const Text('سجّل'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
