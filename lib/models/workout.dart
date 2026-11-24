enum Muscle {
  chest('صدر'),
  back('ضهر'),
  legs('رجل'),
  shoulders('كتف'),
  arms('دراع'),
  core('بطن'),
  cardio('كارديو');

  const Muscle(this.label);
  final String label;
}

class Exercise {
  const Exercise(this.id, this.name, this.arabic, this.muscle, {this.sets = 3, this.reps = 10, this.startKg = 10, this.tip = ''});

  final String id;
  final String name;
  final String arabic;
  final Muscle muscle;
  final int sets;
  final int reps;
  final double startKg;
  final String tip;
}

/// One exercise placed in today's workout.
class PlannedExercise {
  PlannedExercise({required this.exerciseId, required this.sets, required this.reps, required this.kg, List<LoggedSet>? done})
    : done = done ?? [];

  final String exerciseId;
  int sets;
  int reps;
  double kg;
  final List<LoggedSet> done;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'reps': reps,
    'kg': kg,
    'done': done.map((s) => s.toJson()).toList(),
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> j) => PlannedExercise(
    exerciseId: j['exerciseId'] as String,
    sets: j['sets'] as int,
    reps: j['reps'] as int,
    kg: (j['kg'] as num).toDouble(),
    done: (j['done'] as List).map((e) => LoggedSet.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class LoggedSet {
  const LoggedSet(this.kg, this.reps);

  final double kg;
  final int reps;

  /// Epley estimated one-rep max: how the boss fight compares sets.
  double get e1rm => reps <= 1 ? kg : kg * (1 + reps / 30);

  Map<String, dynamic> toJson() => {'kg': kg, 'reps': reps};

  factory LoggedSet.fromJson(Map<String, dynamic> j) => LoggedSet((j['kg'] as num).toDouble(), j['reps'] as int);
}

class WorkoutDay {
  WorkoutDay({required this.day, required this.title, required this.items, this.finished = false});

  final String day;
  String title;
  final List<PlannedExercise> items;
  bool finished;

  int get setsDone => items.fold(0, (n, e) => n + e.done.length);

  int get setsPlanned => items.fold(0, (n, e) => n + e.sets);

  Map<String, dynamic> toJson() => {
    'day': day,
    'title': title,
    'items': items.map((e) => e.toJson()).toList(),
    'finished': finished,
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
    day: j['day'] as String,
    title: j['title'] as String,
    items: (j['items'] as List).map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>)).toList(),
    finished: j['finished'] as bool? ?? false,
  );
}
