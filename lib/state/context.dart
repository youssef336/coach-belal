import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/gemini/prompts.dart';
import '../core/storage.dart';
import '../data/exercise_library.dart';
import 'meals.dart';
import 'profile.dart';
import 'program.dart';
import 'settings.dart';
import 'workouts.dart';

/// What the coach knows before every answer: profile, last 14 days, prices.
String buildCoachSystem(Ref ref, {bool includeProgram = true}) {
  final profile = ref.read(profileProvider);
  final meals = ref.read(mealsProvider);
  final workouts = ref.read(workoutsProvider);
  final settings = ref.read(settingsProvider);
  final now = DateTime.now();

  final lines = <String>[];
  for (var i = 13; i >= 0; i--) {
    final day = dayKey(now.subtract(Duration(days: i)));
    final t = totalsFor(meals, day);
    final w = workouts[day];
    if (t.count == 0 && (w == null || w.setsDone == 0)) continue;
    final label = i == 0 ? 'النهارده' : (i == 1 ? 'امبارح' : day);
    final food = t.count == 0
        ? 'مسجلش أكل'
        : '${t.kcal} سعر، ${t.protein}ج بروتين، ${t.price} جنيه';
    final gym = w == null || w.setsDone == 0
        ? 'من غير جيم'
        : 'جيم: ${w.title} (${w.items.where((e) => e.done.isNotEmpty).map((e) => '${exerciseById(e.exerciseId).arabic} ${e.done.last.kg}×${e.done.last.reps}').join('، ')})';
    lines.add('- $label: $food. $gym');
  }
  final todayMeals = meals.where((m) => dayKey(m.at) == dayKey(now)).map((m) => m.title).join('، ');
  if (todayMeals.isNotEmpty) lines.add('أكل النهارده بالتفصيل: $todayMeals');
  final program = includeProgram ? ref.read(programProvider) : null;
  if (program != null) {
    lines.add('برنامجه الحالي: ${program.title} — أسبوع ${program.week} من ${program.weeks} (${program.phase}).');
  }
  lines.add('الساعة دلوقتي ${now.hour}:${now.minute.toString().padLeft(2, '0')}.');

  return coachSystem(
    profile: profile?.describe() ?? 'لسه مدخلش بياناته',
    history: lines.isEmpty ? 'لسه مفيش تاريخ — أول يوم.' : lines.join('\n'),
    priceNotes: Storage.box('cache').get('priceNotes') ?? '',
    ramadan: settings.ramadan,
  );
}
