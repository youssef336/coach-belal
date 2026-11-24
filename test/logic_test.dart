import 'package:coach_belal/models/meal.dart';
import 'package:coach_belal/models/profile.dart';
import 'package:coach_belal/models/workout.dart';
import 'package:coach_belal/state/game.dart';
import 'package:coach_belal/state/program.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _p({Goal goal = Goal.bulk, int adjust = 0}) => Profile(
  name: 'يوسف',
  heightCm: 175,
  weightKg: 75,
  age: 27,
  male: true,
  activity: Activity.light,
  goal: goal,
  targetKg: 80,
  monthlyBudget: 4500,
  gymDays: 4,
  calorieAdjust: adjust,
);

void main() {
  group('nutrition targets', () {
    test('Mifflin-St Jeor BMR for a 75 kg / 175 cm / 27 y man', () {
      // 10*75 + 6.25*175 - 5*27 + 5 = 1713.75
      expect(_p().bmr, closeTo(1713.75, 0.01));
    });

    test('bulk adds a surplus, cut a deficit, adjust applies on top', () {
      final tdee = _p().tdee;
      expect(_p().targetCalories, (tdee + 350).round());
      expect(_p(goal: Goal.cut).targetCalories, (tdee - 500).round());
      expect(_p(adjust: 150).targetCalories, (tdee + 500).round());
    });

    test('macros add back up to the calorie target', () {
      final p = _p();
      final kcal = p.targetProtein * 4 + p.targetCarbs * 4 + p.targetFat * 9;
      expect(kcal, closeTo(p.targetCalories, 12));
      expect(p.targetProtein, 150);
    });

    test('profile survives a round trip through JSON', () {
      final p = Profile.fromJson(_p(goal: Goal.recomp, adjust: -100).toJson());
      expect(p.goal, Goal.recomp);
      expect(p.calorieAdjust, -100);
      expect(p.dailyBudget, 150);
    });
  });

  group('food parsing from the model', () {
    test('numbers come back as ints whatever the model sends', () {
      final f = FoodIdea.fromJson({'title': 'فول', 'kcal': 350.6, 'protein': '21', 'carbs': 40, 'fat': null, 'price': 15});
      expect(f.kcal, 351);
      expect(f.protein, 21);
      expect(f.fat, 0);
    });
  });

  group('game', () {
    test('levels need more XP each time and name the tier', () {
      expect(levelFor(0).number, 1);
      expect(levelFor(0).title, 'بطاطس كنبة');
      expect(levelFor(149).number, 1);
      expect(levelFor(150).number, 2);
      final l5 = levelFor(1000);
      expect(l5.to - l5.from, greaterThan(150));
    });

    test('streak counts back from yesterday when today is still empty', () {
      final now = DateTime(2026, 11, 24, 10);
      MealEntry m(DateTime d) => MealEntry(id: '$d', at: d, title: 'x', kcal: 1, protein: 1, carbs: 1, fat: 1, price: 1);
      final meals = [m(DateTime(2026, 11, 23, 9)), m(DateTime(2026, 11, 22, 9)), m(DateTime(2026, 11, 20, 9))];
      expect(streakFor(meals, const [], now), 2);
      expect(streakFor([...meals, m(DateTime(2026, 11, 24, 8))], const [], now), 3);
    });

    test('boss compares sets by estimated one-rep max', () {
      expect(const LoggedSet(80, 5).e1rm, closeTo(93.33, 0.01));
      final boss = Boss(exerciseId: 'bench', target: const LoggedSet(80, 5), best: const LoggedSet(80, 6), defeated: true);
      expect(boss.health, 0);
      final close = Boss(exerciseId: 'bench', target: const LoggedSet(80, 5), best: const LoggedSet(77.5, 5), defeated: false);
      expect(close.health, inExclusiveRange(0.0, 1.0));
    });
  });

  group('program (mesocycle)', () {
    test('rotates days and survives JSON', () {
      final p = Program(
        title: 'Upper / Lower',
        why: 'x',
        start: '2026-11-24',
        weeks: 5,
        days: const [
          ProgramDay('Upper', [(id: 'bench', sets: 4, reps: 8)]),
          ProgramDay('Lower', [(id: 'squat', sets: 4, reps: 8)]),
        ],
      );
      final next = Program.fromJson(p.advance().advance().advance().toJson());
      expect(next.next, 1);
      expect(next.days.last.items.single.id, 'squat');
    });

    test('a workout day keeps its sets after a round trip', () {
      final w = WorkoutDay(day: '2026-11-24', title: 'Push', items: [PlannedExercise(exerciseId: 'bench', sets: 3, reps: 8, kg: 60, done: [const LoggedSet(60, 8)])]);
      final back = WorkoutDay.fromJson(w.toJson());
      expect(back.setsDone, 1);
      expect(back.setsPlanned, 3);
    });
  });
}
