import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// Big tappable tiles, two per row.
class ChoiceGrid<T> extends StatelessWidget {
  const ChoiceGrid({super.key, required this.values, required this.selected, required this.label, required this.onPick, this.sub});

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final String Function(T)? sub;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: sub == null ? 2.4 : 1.6,
    children: [
      for (final v in values)
        Material(
          color: v == selected ? AppColors.lime : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              onPick(v);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label(v),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: v == selected ? AppColors.bg : AppColors.text),
                  ),
                  if (sub != null)
                    Text(
                      sub!(v),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: v == selected ? AppColors.bg.withValues(alpha: 0.7) : AppColors.muted),
                    ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
