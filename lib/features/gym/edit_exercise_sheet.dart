import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/exercise_library.dart';
import '../../state/workouts.dart';
import 'demo/exercise_demo.dart';
import 'how_to_video_button.dart';

/// Plus / minus steppers: no keyboard in the gym.
Future<void> showEditExercise(BuildContext context, WidgetRef ref, int index) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
  builder: (_) => _EditSheet(index: index),
);

class _EditSheet extends ConsumerWidget {
  const _EditSheet({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(todayWorkoutProvider);
    if (w == null || index >= w.items.length) return const SizedBox.shrink();
    final e = w.items[index];
    final ex = exerciseById(e.exerciseId);
    final n = ref.read(workoutsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(ex.arabic, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                HowToVideoButton(exercise: ex),
              ],
            ),
            Text('${ex.name} · ${ex.tip}', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            ExerciseDemo(exerciseId: e.exerciseId, height: 140),
            const SizedBox(height: 12),
            Stepper3(label: 'سِتات', value: '${e.sets}', onMinus: () => n.updateItem(index, sets: e.sets - 1), onPlus: () => n.updateItem(index, sets: e.sets + 1)),
            Stepper3(label: 'عدات', value: '${e.reps}', onMinus: () => n.updateItem(index, reps: e.reps - 1), onPlus: () => n.updateItem(index, reps: e.reps + 1)),
            Stepper3(label: 'وزن (كيلو)', value: e.kg.toStringAsFixed(e.kg % 1 == 0 ? 0 : 1), onMinus: () => n.updateItem(index, kg: e.kg - 2.5), onPlus: () => n.updateItem(index, kg: e.kg + 2.5)),
          ],
        ),
      ),
    );
  }
}

class Stepper3 extends StatelessWidget {
  const Stepper3({super.key, required this.label, required this.value, required this.onMinus, required this.onPlus});
  final String label, value;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: AppColors.muted))),
        IconButton.filledTonal(
          tooltip: 'أقل',
          onPressed: () {
            HapticFeedback.selectionClick();
            onMinus();
          },
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(width: 72, child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.lime))),
        IconButton.filledTonal(
          tooltip: 'أكتر',
          onPressed: () {
            HapticFeedback.selectionClick();
            onPlus();
          },
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
  );
}
