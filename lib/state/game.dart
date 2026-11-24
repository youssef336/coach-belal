import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage.dart';
import '../data/exercise_library.dart';
import '../models/meal.dart';
import '../models/workout.dart';
import 'meals.dart';
import 'workouts.dart';

class Level {
  const Level(this.number, this.title, this.from, this.to);
  final int number;
  final String title;
  final int from;
  final int to;
}

const _titles = ['بطاطس كنبة', 'صحي من النوم', 'ماشي في السكة', 'مش هيّن', 'وحش الجيم', 'أسطورة'];

/// Each level needs a bit more XP than the last.
Level levelFor(int xp) {
  var need = 150;
  var from = 0;
  var n = 1;
  while (xp >= from + need) {
    from += need;
    need = (need * 1.25).round();
    n++;
  }
  final title = _titles[((n - 1) ~/ 3).clamp(0, _titles.length - 1)];
  return Level(n, title, from, from + need);
}

class GameState {
  const GameState({required this.xp, required this.level, required this.streak, required this.strength, required this.endurance, required this.discipline, required this.totalSaved});

  final int xp;
  final Level level;
  final int streak;
  final int strength;
  final int endurance;
  final int discipline;
  final int totalSaved;

  double get levelProgress => (xp - level.from) / (level.to - level.from);
}

int _xpFor(List<MealEntry> meals, Iterable<WorkoutDay> workouts) {
  var xp = meals.length * 10;
  for (final w in workouts) {
    xp += w.setsDone * 5;
    if (w.finished) xp += 50;
  }
  xp += meals.fold<int>(0, (s, m) => s + m.saved) ~/ 5;
  return xp;
}

int streakFor(List<MealEntry> meals, Iterable<WorkoutDay> workouts, DateTime now) {
  final active = <String>{...meals.map((m) => dayKey(m.at)), ...workouts.where((w) => w.setsDone > 0).map((w) => w.day)};
  var d = DateTime(now.year, now.month, now.day);
  // Today not logged yet doesn't break the streak.
  if (!active.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
  var n = 0;
  while (active.contains(dayKey(d))) {
    n++;
    d = d.subtract(const Duration(days: 1));
  }
  return n;
}

final gameProvider = Provider<GameState>((ref) {
  final meals = ref.watch(mealsProvider);
  final workouts = ref.watch(workoutsProvider).values;
  final xp = _xpFor(meals, workouts);
  final sets = workouts.fold<int>(0, (n, w) => n + w.setsDone);
  final sessions = workouts.where((w) => w.finished).length;
  final days = <String>{...meals.map((m) => dayKey(m.at))}.length;
  return GameState(
    xp: xp,
    level: levelFor(xp),
    streak: streakFor(meals, workouts, DateTime.now()),
    strength: sets ~/ 4,
    endurance: sessions * 3,
    discipline: days * 2 + sessions,
    totalSaved: meals.fold(0, (s, m) => s + m.saved),
  );
});

class Boss {
  const Boss({required this.exerciseId, required this.target, required this.best, required this.defeated});

  final String exerciseId;

  /// The old record to beat.
  final LoggedSet target;

  /// Your best since the boss appeared (this week).
  final LoggedSet? best;
  final bool defeated;

  /// Boss health left, 0..1.
  double get health {
    if (defeated) return 0;
    if (best == null) return 1;
    final ratio = best!.e1rm / target.e1rm;
    // 85% of the record = full health, 100% = dead.
    return (1 - ((ratio - 0.85) / 0.15)).clamp(0.05, 1.0);
  }
}

/// The weekly boss: your best set on a big lift from before this week.
final bossProvider = Provider<Boss?>((ref) {
  final workouts = ref.watch(workoutsProvider).values.toList();
  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday + 1) % 7));
  final startKey = dayKey(weekStart);

  LoggedSet? bestBefore(String id) {
    LoggedSet? best;
    for (final w in workouts.where((w) => w.day.compareTo(startKey) < 0)) {
      for (final e in w.items.where((e) => e.exerciseId == id)) {
        for (final s in e.done) {
          if (s.kg > 0 && (best == null || s.e1rm > best.e1rm)) best = s;
        }
      }
    }
    return best;
  }

  LoggedSet? bestThisWeek(String id) {
    LoggedSet? best;
    for (final w in workouts.where((w) => w.day.compareTo(startKey) >= 0)) {
      for (final e in w.items.where((e) => e.exerciseId == id)) {
        for (final s in e.done) {
          if (best == null || s.e1rm > best.e1rm) best = s;
        }
      }
    }
    return best;
  }

  for (final id in bossLifts) {
    final target = bestBefore(id);
    if (target == null) continue;
    final best = bestThisWeek(id);
    return Boss(exerciseId: id, target: target, best: best, defeated: best != null && best.e1rm > target.e1rm);
  }
  return null;
});
