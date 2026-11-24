import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

class BigSlider extends StatelessWidget {
  const BigSlider({super.key, required this.label, required this.unit, required this.value, required this.min, required this.max, required this.onChanged, this.step = 1});

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = step < 1 ? value.toStringAsFixed(1) : value.round().toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.muted))),
              Text(shown, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.lime, height: 1)),
              const SizedBox(width: 6),
              Text(unit, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              activeTrackColor: AppColors.lime,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppColors.lime,
              overlayColor: AppColors.lime.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              onChanged: (v) {
                if (v != value) HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
