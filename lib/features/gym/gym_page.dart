import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/exercise_library.dart';
import '../../state/coach_actions.dart';
import '../../state/workouts.dart';
import '../coach/voice_sheet.dart';
import 'edit_exercise_sheet.dart';
import 'exercise_library_strip.dart';
import 'gym_session_page.dart';
import 'program_card.dart';

class GymPage extends ConsumerStatefulWidget {
  const GymPage({super.key});

  @override
  ConsumerState<GymPage> createState() => _GymPageState();
}

class _GymPageState extends ConsumerState<GymPage> {
  bool _picking = false;
  bool _hovering = false;

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final note = await ref.read(coachActionsProvider).pickWorkout();
      if (mounted) toast(context, note);
    } catch (_) {
      if (mounted) toast(context, 'حصلت مشكلة، جرّب تاني');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _start() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GymSessionPage()));

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(todayWorkoutProvider);
    final items = w?.items ?? const [];

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('الجيم', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
                          IconButton(tooltip: 'شوف أدائي', onPressed: () => formCheck(context, ref), icon: const Icon(Icons.videocam_rounded, color: AppColors.lime)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const ProgramCard(),
                      const SizedBox(height: 16),
                      if (items.isEmpty) ...[
                        FilledButton.icon(
                          onPressed: _picking ? null : _pick,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(76)),
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text(_picking ? 'الكوتش بيجهز..' : 'الكوتش يختار لي', style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(height: 8),
                        const Center(child: Text('أو اسحب تمارين من تحت لهنا', style: TextStyle(color: AppColors.muted))),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: Text(w!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                            Text('${w.setsDone}/${w.setsPlanned} سِت', style: const TextStyle(color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _start,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                          icon: Icon(w.finished ? Icons.check_rounded : Icons.play_arrow_rounded),
                          label: Text(w.finished ? 'خلص ✓ — افتحه' : (w.setsDone == 0 ? 'ابدأ' : 'كمّل'), style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(height: 6),
                        const Text('اسحب من ⋮⋮ ورتّب · دوس للتعديل · اسحب لجنب للمسح', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverReorderableList(
                    itemCount: items.length,
                    onReorderItem: (a, b) {
                      HapticFeedback.selectionClick();
                      ref.read(workoutsProvider.notifier).reorder(a, b);
                    },
                    itemBuilder: (_, i) {
                      final e = items[i];
                      final ex = exerciseById(e.exerciseId);
                      return Padding(
                        key: ValueKey('${e.exerciseId}-$i'),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: ValueKey('d-${e.exerciseId}-$i'),
                          onDismissed: (_) => ref.read(workoutsProvider.notifier).removeAt(i),
                          child: GlassCard(
                            radius: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            onTap: () => showEditExercise(context, ref, i),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.drag_indicator_rounded, color: AppColors.muted)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ex.arabic, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                      Text(ex.name, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${e.sets}×${e.reps}${e.kg > 0 ? ' · ${e.kg.toStringAsFixed(e.kg % 1 == 0 ? 0 : 1)}ك' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 8),
                                if (e.done.length >= e.sets) const Icon(Icons.check_circle_rounded, color: AppColors.lime, size: 20),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          ),
          DragTarget<String>(
            onWillAcceptWithDetails: (_) {
              setState(() => _hovering = true);
              return true;
            },
            onLeave: (_) => setState(() => _hovering = false),
            onAcceptWithDetails: (d) {
              setState(() => _hovering = false);
              HapticFeedback.mediumImpact();
              ref.read(workoutsProvider.notifier).addToToday(d.data);
            },
            builder: (_, _, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _hovering ? AppColors.lime.withValues(alpha: 0.15) : AppColors.surface,
                border: Border(top: BorderSide(color: _hovering ? AppColors.lime : AppColors.line, width: 2)),
              ),
              child: ExerciseLibraryStrip(hovering: _hovering),
            ),
          ),
        ],
      ),
    );
  }
}
