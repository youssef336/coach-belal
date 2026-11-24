enum Goal {
  bulk('تضخيم', 'أزوّد عضل ووزن'),
  cut('تنشيف', 'أخسّ دهون'),
  recomp('شكل أنضف', 'عضل أكتر ودهون أقل'),
  fit('لياقة', 'صحة وطاقة');

  const Goal(this.label, this.hint);
  final String label;
  final String hint;
}

enum Activity {
  sitting(1.2, 'قاعد معظم اليوم'),
  light(1.375, 'بتحرك شوية'),
  active(1.55, 'نشيط'),
  athlete(1.725, 'شغلي تعب');

  const Activity(this.factor, this.label);
  final double factor;
  final String label;
}

class Profile {
  const Profile({
    required this.name,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.male,
    required this.activity,
    required this.goal,
    required this.targetKg,
    required this.monthlyBudget,
    required this.gymDays,
    this.calorieAdjust = 0,
  });

  final String name;
  final double heightCm;
  final double weightKg;
  final int age;
  final bool male;
  final Activity activity;
  final Goal goal;
  final double targetKg;
  final int monthlyBudget;
  final int gymDays;

  /// Weekly correction the coach applies when the scale doesn't move.
  final int calorieAdjust;

  /// Mifflin-St Jeor resting burn.
  double get bmr => 10 * weightKg + 6.25 * heightCm - 5 * age + (male ? 5 : -161);

  double get tdee => bmr * activity.factor;

  int get targetCalories {
    final base = switch (goal) {
      Goal.bulk => tdee + 350,
      Goal.cut => tdee - 500,
      Goal.recomp => tdee - 150,
      Goal.fit => tdee,
    };
    return (base + calorieAdjust).round();
  }

  int get targetProtein {
    final perKg = switch (goal) {
      Goal.bulk => 2.0,
      Goal.cut => 2.2,
      Goal.recomp => 2.0,
      Goal.fit => 1.6,
    };
    return (weightKg * perKg).round();
  }

  int get targetFat => (targetCalories * 0.25 / 9).round();

  int get targetCarbs => ((targetCalories - targetProtein * 4 - targetFat * 9) / 4).round();

  /// Litres of water a day (35 ml per kg).
  double get targetWaterL => (weightKg * 0.035 * 2).round() / 2;

  int get dailyBudget => (monthlyBudget / 30).round();

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  Profile copyWith({double? weightKg, int? calorieAdjust, Goal? goal, double? targetKg}) => Profile(
    name: name,
    heightCm: heightCm,
    weightKg: weightKg ?? this.weightKg,
    age: age,
    male: male,
    activity: activity,
    goal: goal ?? this.goal,
    targetKg: targetKg ?? this.targetKg,
    monthlyBudget: monthlyBudget,
    gymDays: gymDays,
    calorieAdjust: calorieAdjust ?? this.calorieAdjust,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'age': age,
    'male': male,
    'activity': activity.name,
    'goal': goal.name,
    'targetKg': targetKg,
    'monthlyBudget': monthlyBudget,
    'gymDays': gymDays,
    'calorieAdjust': calorieAdjust,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] as String,
    heightCm: (j['heightCm'] as num).toDouble(),
    weightKg: (j['weightKg'] as num).toDouble(),
    age: j['age'] as int,
    male: j['male'] as bool,
    activity: Activity.values.byName(j['activity'] as String),
    goal: Goal.values.byName(j['goal'] as String),
    targetKg: (j['targetKg'] as num).toDouble(),
    monthlyBudget: j['monthlyBudget'] as int,
    gymDays: j['gymDays'] as int,
    calorieAdjust: (j['calorieAdjust'] as int?) ?? 0,
  );

  /// One paragraph the coach reads before every answer.
  String describe() =>
      'الاسم: $name. ${male ? 'ذكر' : 'أنثى'}، $age سنة، الطول ${heightCm.round()} سم، '
      'الوزن ${weightKg.toStringAsFixed(1)} كجم، الهدف: ${goal.label} (${goal.hint})، '
      'الوزن المستهدف ${targetKg.toStringAsFixed(0)} كجم، النشاط: ${activity.label}، '
      'الجيم $gymDays أيام في الأسبوع، ميزانية الأكل $monthlyBudget جنيه في الشهر '
      '(حوالي $dailyBudget في اليوم). الهدف اليومي: $targetCalories سعر، '
      '$targetProtein جرام بروتين، $targetCarbs كارب، $targetFat دهون.';
}
