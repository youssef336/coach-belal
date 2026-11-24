import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/meal.dart';

const _tints = [
  [Color(0xFF3A2A14), Color(0xFF1A1410)],
  [Color(0xFF1F3A2A), Color(0xFF101A14)],
  [Color(0xFF14283A), Color(0xFF0E141C)],
  [Color(0xFF2E2A3A), Color(0xFF15131C)],
];

/// A meal card you can fling: right = ate it, left = show another.
class FoodSwipeCard extends StatefulWidget {
  const FoodSwipeCard({super.key, required this.idea, required this.onAte, required this.onSkip, this.tint = 0});

  final FoodIdea idea;
  final VoidCallback onAte;
  final VoidCallback onSkip;
  final int tint;

  @override
  State<FoodSwipeCard> createState() => _FoodSwipeCardState();
}

class _FoodSwipeCardState extends State<FoodSwipeCard> {
  double _dx = 0;

  void _end(DragEndDetails d) {
    final w = MediaQuery.sizeOf(context).width;
    final v = d.primaryVelocity ?? 0;
    if (_dx > w * 0.28 || v > 900) {
      widget.onAte();
    } else if (_dx < -w * 0.28 || v < -900) {
      widget.onSkip();
    }
    setState(() => _dx = 0);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.idea;
    final c = _tints[(f.title.length + widget.tint) % _tints.length];
    final hint = _dx > 40 ? 'أكلته ✓' : (_dx < -40 ? 'غيّره' : null);
    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _dx += d.delta.dx),
      onHorizontalDragEnd: _end,
      child: AnimatedContainer(
        duration: Duration(milliseconds: _dx == 0 ? 250 : 0),
        transform: Matrix4.translationValues(_dx, 0, 0)..rotateZ(_dx / 1200),
        transformAlignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: c, begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _dx > 40 ? AppColors.lime : (_dx < -40 ? Colors.white54 : AppColors.line), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(99)),
                  child: Text(f.slot.isEmpty ? 'وجبة' : f.slot, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                if (hint != null) Text(hint, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.lime, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 14),
            Text(f.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.3)),
            const SizedBox(height: 10),
            Text(f.why, style: const TextStyle(fontSize: 15, color: Color(0xFFD6DEE6), height: 1.6)),
            const Spacer(),
            Row(
              children: [
                _Box('${f.kcal}', 'سعر', AppColors.text),
                const SizedBox(width: 8),
                _Box('${f.protein}ج', 'بروتين', const Color(0xFFFFB37F)),
                const SizedBox(width: 8),
                _Box('${f.price}', 'جنيه تقريبًا', AppColors.lime),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box(this.value, this.label, this.color);
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFC9D3DD))),
        ],
      ),
    ),
  );
}
