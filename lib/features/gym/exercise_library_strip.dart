import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/exercise_library.dart';
import '../../models/workout.dart';
import '../../state/workouts.dart';

/// The exercise cards. Long-press and drag one up into today, or just tap it.
class ExerciseLibraryStrip extends ConsumerStatefulWidget {
  const ExerciseLibraryStrip({super.key, required this.hovering});
  final bool hovering;

  @override
  ConsumerState<ExerciseLibraryStrip> createState() => _ExerciseLibraryStripState();
}

class _ExerciseLibraryStripState extends ConsumerState<ExerciseLibraryStrip> {
  Muscle _muscle = Muscle.chest;

  @override
  Widget build(BuildContext context) {
    final list = exerciseLibrary.where((e) => e.muscle == _muscle).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          widget.hovering ? 'سيبه هنا' : 'مكتبة التمارين — دوس أو اسحب لفوق',
          style: TextStyle(color: widget.hovering ? AppColors.lime : AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            children: [
              for (final m in Muscle.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    label: Text(m.label),
                    selected: m == _muscle,
                    onSelected: (_) => setState(() => _muscle = m),
                    selectedColor: AppColors.lime,
                    showCheckmark: false,
                    labelStyle: TextStyle(color: m == _muscle ? AppColors.bg : AppColors.text, fontWeight: FontWeight.w700, fontSize: 13),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final ex = list[i];
              final card = _Card(ex: ex);
              return LongPressDraggable<String>(
                data: ex.id,
                onDragStarted: HapticFeedback.mediumImpact,
                feedback: Material(color: Colors.transparent, child: Transform.rotate(angle: -0.05, child: _Card(ex: ex, lifted: true))),
                childWhenDragging: Opacity(opacity: 0.3, child: card),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(workoutsProvider.notifier).addToToday(ex.id);
                    toast(context, 'ضفت ${ex.arabic}');
                  },
                  child: card,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.ex, this.lifted = false});
  final Exercise ex;
  final bool lifted;

  @override
  Widget build(BuildContext context) => Container(
    width: 128,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: lifted ? AppColors.lime : AppColors.surface2,
      borderRadius: BorderRadius.circular(18),
      boxShadow: lifted ? [const BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))] : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(ex.arabic, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: lifted ? AppColors.bg : AppColors.text)),
        Text(ex.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: lifted ? AppColors.bg : AppColors.muted)),
        Text('${ex.sets}×${ex.reps}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: lifted ? AppColors.bg : AppColors.lime)),
      ],
    ),
  );
}
