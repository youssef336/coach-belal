import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage.dart';
import '../data/exercise_library.dart';
import '../models/workout.dart';

class WorkoutsNotifier extends Notifier<Map<String, WorkoutDay>> {
  @override
  Map<String, WorkoutDay> build() {
    final all = Storage.readAll('workouts').map(WorkoutDay.fromJson);
    return {for (final w in all) w.day: w};
  }

  String get _today => dayKey(DateTime.now());

  WorkoutDay? get today => state[_today];

  Future<void> _save(WorkoutDay w) async {
    await Storage.writeMap('workouts', w.day, w.toJson());
    state = {...state, w.day: w};
  }

  /// The weight to suggest: last logged top set, +2.5 kg if every rep was hit.
  double suggestKg(String exerciseId) {
    final days = state.values.where((w) => w.day != _today).toList()..sort((a, b) => b.day.compareTo(a.day));
    for (final d in days) {
      for (final e in d.items.where((e) => e.exerciseId == exerciseId && e.done.isNotEmpty)) {
        final top = e.done.map((s) => s.kg).reduce((a, b) => a > b ? a : b);
        final allHit = e.done.length >= e.sets && e.done.every((s) => s.reps >= e.reps);
        return allHit && top > 0 ? top + 2.5 : top;
      }
    }
    return exerciseById(exerciseId).startKg;
  }

  PlannedExercise plan(String exerciseId, {int? sets, int? reps, double? kg}) {
    final ex = exerciseById(exerciseId);
    return PlannedExercise(exerciseId: exerciseId, sets: sets ?? ex.sets, reps: reps ?? ex.reps, kg: kg ?? suggestKg(exerciseId));
  }

  Future<void> setToday(String title, List<PlannedExercise> items) =>
      _save(WorkoutDay(day: _today, title: title, items: items));

  Future<void> addToToday(String exerciseId, {int? at}) async {
    final w = today ?? WorkoutDay(day: _today, title: 'تمرين النهارده', items: []);
    final p = plan(exerciseId);
    if (at == null || at > w.items.length) {
      w.items.add(p);
    } else {
      w.items.insert(at, p);
    }
    await _save(w);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final w = today;
    if (w == null) return;
    final item = w.items.removeAt(oldIndex);
    w.items.insert(newIndex.clamp(0, w.items.length), item);
    await _save(w);
  }

  Future<void> removeAt(int index) async {
    final w = today;
    if (w == null) return;
    w.items.removeAt(index);
    await _save(w);
  }

  Future<void> updateItem(int index, {int? sets, int? reps, double? kg}) async {
    final w = today;
    if (w == null) return;
    final e = w.items[index];
    if (sets != null) e.sets = sets.clamp(1, 10);
    if (reps != null) e.reps = reps.clamp(1, 100);
    if (kg != null) e.kg = kg < 0 ? 0 : kg;
    await _save(w);
  }

  Future<void> logSet(int index, LoggedSet set) async {
    final w = today;
    if (w == null) return;
    w.items[index].done.add(set);
    await _save(w);
  }

  Future<void> undoSet(int index) async {
    final w = today;
    if (w == null || w.items[index].done.isEmpty) return;
    w.items[index].done.removeLast();
    await _save(w);
  }

  Future<void> finish() async {
    final w = today;
    if (w == null) return;
    w.finished = true;
    await _save(w);
  }

  /// Offline "coach picks for me": rotate push / pull / legs after the last one done.
  String nextSplitTitle() {
    final titles = splitTemplates.keys.toList();
    final done = state.values.where((w) => w.day != _today && w.setsDone > 0).toList()..sort((a, b) => b.day.compareTo(a.day));
    if (done.isEmpty) return titles.first;
    final last = titles.indexOf(done.first.title);
    return titles[(last + 1) % titles.length];
  }
}

final workoutsProvider = NotifierProvider<WorkoutsNotifier, Map<String, WorkoutDay>>(WorkoutsNotifier.new);

final todayWorkoutProvider = Provider<WorkoutDay?>((ref) => ref.watch(workoutsProvider)[dayKey(DateTime.now())]);
