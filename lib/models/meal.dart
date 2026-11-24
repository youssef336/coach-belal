class MealEntry {
  const MealEntry({
    required this.id,
    required this.at,
    required this.title,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.price,
    this.saved = 0,
  });

  final String id;
  final DateTime at;
  final String title;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  /// Approximate cost in Egyptian pounds.
  final int price;

  /// Pounds saved by taking the coach's cheaper swap.
  final int saved;

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'title': title,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'price': price,
    'saved': saved,
  };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    id: j['id'] as String,
    at: DateTime.parse(j['at'] as String),
    title: j['title'] as String,
    kcal: _int(j['kcal']),
    protein: _int(j['protein']),
    carbs: _int(j['carbs']),
    fat: _int(j['fat']),
    price: _int(j['price']),
    saved: _int(j['saved']),
  );
}

/// A food the coach suggests (a swap, or one card of the day plan).
class FoodIdea {
  const FoodIdea({
    required this.title,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.price,
    this.why = '',
    this.slot = '',
  });

  final String title;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final int price;
  final String why;
  final String slot;

  Map<String, dynamic> toJson() => {
    'title': title,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'price': price,
    'why': why,
    'slot': slot,
  };

  factory FoodIdea.fromJson(Map<String, dynamic> j) => FoodIdea(
    title: (j['title'] as String?) ?? '',
    kcal: _int(j['kcal']),
    protein: _int(j['protein']),
    carbs: _int(j['carbs']),
    fat: _int(j['fat']),
    price: _int(j['price']),
    why: (j['why'] as String?) ?? '',
    slot: (j['slot'] as String?) ?? '',
  );
}

int _int(Object? v) => v is num ? v.round() : int.tryParse('$v') ?? 0;
