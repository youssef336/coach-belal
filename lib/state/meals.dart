import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/storage.dart';
import '../models/meal.dart';

const _uuid = Uuid();

class DayTotals {
  const DayTotals({this.kcal = 0, this.protein = 0, this.carbs = 0, this.fat = 0, this.price = 0, this.saved = 0, this.count = 0});

  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final int price;
  final int saved;
  final int count;

  DayTotals add(MealEntry m) => DayTotals(
    kcal: kcal + m.kcal,
    protein: protein + m.protein,
    carbs: carbs + m.carbs,
    fat: fat + m.fat,
    price: price + m.price,
    saved: saved + m.saved,
    count: count + 1,
  );
}

class MealsNotifier extends Notifier<List<MealEntry>> {
  @override
  List<MealEntry> build() =>
      Storage.readAll('meals').map(MealEntry.fromJson).toList()..sort((a, b) => a.at.compareTo(b.at));

  Future<MealEntry> logIdea(FoodIdea f, {int saved = 0, DateTime? at}) async {
    final m = MealEntry(
      id: _uuid.v4(),
      at: at ?? DateTime.now(),
      title: f.title,
      kcal: f.kcal,
      protein: f.protein,
      carbs: f.carbs,
      fat: f.fat,
      price: f.price,
      saved: saved,
    );
    await Storage.writeMap('meals', m.id, m.toJson());
    state = [...state, m];
    return m;
  }

  Future<void> remove(String id) async {
    await Storage.delete('meals', id);
    state = state.where((m) => m.id != id).toList();
  }

  /// The laziest button in the app: eat what you ate yesterday.
  Future<int> repeatYesterday() async {
    final y = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final yesterday = state.where((m) => dayKey(m.at) == y).toList();
    for (final m in yesterday) {
      await logIdea(
        FoodIdea(title: m.title, kcal: m.kcal, protein: m.protein, carbs: m.carbs, fat: m.fat, price: m.price),
      );
    }
    return yesterday.length;
  }
}

final mealsProvider = NotifierProvider<MealsNotifier, List<MealEntry>>(MealsNotifier.new);

DayTotals totalsFor(List<MealEntry> meals, String day) =>
    meals.where((m) => dayKey(m.at) == day).fold(const DayTotals(), (t, m) => t.add(m));

final todayTotalsProvider = Provider<DayTotals>((ref) {
  final meals = ref.watch(mealsProvider);
  return totalsFor(meals, dayKey(DateTime.now()));
});

final todayMealsProvider = Provider<List<MealEntry>>((ref) {
  final today = dayKey(DateTime.now());
  return ref.watch(mealsProvider).where((m) => dayKey(m.at) == today).toList().reversed.toList();
});
