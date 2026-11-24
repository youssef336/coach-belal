import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/gemini/gemini_client.dart';
import '../core/gemini/prompts.dart';
import '../core/storage.dart';
import '../data/exercise_library.dart';
import '../models/meal.dart';
import 'chat.dart';
import 'context.dart';
import 'meals.dart';
import 'profile.dart';
import 'program.dart';
import 'settings.dart';
import 'workouts.dart';

class ShoppingItem {
  const ShoppingItem(this.name, this.qty, this.price, this.tip);
  final String name;
  final String qty;
  final int price;
  final String tip;
}

/// One-tap things the coach does for you.
class CoachActions {
  CoachActions(this.ref);
  final Ref ref;

  GeminiClient get _ai => ref.read(geminiProvider);

  /// Today's meals, ready to swipe. Cached for the day.
  Future<List<FoodIdea>> dayPlan({bool fresh = false}) async {
    final key = 'plan_${dayKey(DateTime.now())}';
    final cached = Storage.box('cache').get(key);
    if (cached != null && !fresh) {
      return (jsonDecode(cached) as List).map((e) => FoodIdea.fromJson(e as Map<String, dynamic>)).toList();
    }
    final t = ref.read(todayTotalsProvider);
    final out = await _ai.json(
      system: buildCoachSystem(ref),
      schema: dayPlanSchema,
      turns: [
        GeminiTurn('user', [
          GeminiPart.text(
            'جهزلي باقي أكل النهارده. أنا أكلت لحد دلوقتي ${t.kcal} سعر و${t.protein}ج بروتين. '
            'اديني لكل وجبة فاضلة (فطار لو لسه بدري، غدا، عشا، وسناك) اختيارين سهلين ورخاص من مصر، '
            'وفي why جملة قصيرة بتقنعني. slot = اسم الوجبة.',
          ),
        ]),
      ],
    );
    final ideas = ((out['options'] as List?) ?? const []).map((e) => FoodIdea.fromJson(e as Map<String, dynamic>)).toList();
    await Storage.box('cache').put(key, jsonEncode(ideas.map((e) => e.toJson()).toList()));
    return ideas;
  }

  /// "الكوتش يختار لي": the next day of your training block. Builds a new
  /// block first when there is none, it ended, or you stalled. Works offline too.
  Future<String> pickWorkout() async {
    final wn = ref.read(workoutsProvider.notifier);
    final program = ref.read(programProvider.notifier);
    final reason = program.changeReason();
    if (reason != null) {
      try {
        await program.generate();
      } on CoachError {
        // Keep the old block (or fall back below).
      }
    }
    final fromProgram = await program.planToday();
    if (fromProgram != null) return reason == null ? fromProgram : '$reason — جهزتلك برنامج جديد. $fromProgram';
    try {
      final out = await _ai.json(
        system: buildCoachSystem(ref),
        schema: workoutSchema,
        turns: [
          const GeminiTurn('user', [
            GeminiPart.text(
              'ابنيلي تمرين النهارده (45-60 دقيقة) حسب هدفي وإيه اللي اتمرنته الأيام اللي فاتت، '
              'متكررش نفس العضلة لو اتمرنت امبارح. الأوزان من آخر مرة + زيادة صغيرة لو قدرت. '
              'وفي note جملة تحفيز قصيرة.',
            ),
          ]),
        ],
      );
      final w = out['workout'] as Map?;
      final items = plannedFrom(ref, (w?['items'] as List?) ?? const []);
      if (items.isNotEmpty) {
        await wn.setToday(w?['title'] as String? ?? 'تمرين الكوتش', items);
        return out['note'] as String? ?? 'يلا بينا';
      }
    } on CoachError {
      // Fall through to the offline rotation.
    }
    final title = wn.nextSplitTitle();
    await wn.setToday(title, splitTemplates[title]!.map(wn.plan).toList());
    return 'جهزتلك $title — يلا';
  }

  /// This week's supermarket list with the cheapest Egyptian options.
  Future<(List<ShoppingItem>, String)> shoppingList() async {
    final out = await _ai.json(
      system: buildCoachSystem(ref),
      schema: shoppingSchema,
      turns: [
        const GeminiTurn('user', [
          GeminiPart.text(
            'اعملي لستة سوبرماركت لأسبوع كامل تكفي هدفي وميزانيتي، بأرخص اختيارات في مصر '
            '(كميات واضحة وسعر تقريبي لكل حاجة، وفي tip نصيحة توفير لو في). وفي note الإجمالي ونصيحة.',
          ),
        ]),
      ],
    );
    final items = ((out['items'] as List?) ?? const [])
        .cast<Map>()
        .map((e) => ShoppingItem('${e['name']}', '${e['qty'] ?? ''}', (e['price'] as num?)?.round() ?? 0, '${e['tip'] ?? ''}'))
        .toList();
    return (items, out['note'] as String? ?? '');
  }

  /// Google-search today's Egyptian prices; every later answer uses them.
  Future<String> refreshPrices() async {
    final notes = await _ai.text(
      system: 'إنت باحث أسعار. رد بقايمة قصيرة: الصنف — السعر بالجنيه — المصدر.',
      search: true,
      turns: [
        const GeminiTurn('user', [
          GeminiPart.text(
            'دوّر على أسعار النهارده في مصر (سوبرماركت أو أسواق) لـ: كرتونة بيض، كيلو صدور فراخ، كيلو فول، '
            'علبة تونة، كيلو جبنة قريش، كيلو رز، رغيف عيش بلدي مدعم وحر، كيلو عدس، زبادي، كيلو شوفان، '
            'كيلو موز، كيلو بطاطس، كيلو كبدة، علبة سردين، لتر لبن، واي بروتين 2 كيلو.',
          ),
        ]),
      ],
    );
    final stamped = '${dayKey(DateTime.now())}:\n$notes';
    await Storage.box('cache').put('priceNotes', stamped);
    return stamped;
  }

  /// Weekly check: the coach adjusts calories when the scale doesn't move.
  Future<String?> weeklyAdjust() async {
    final p = ref.read(profileProvider);
    final weights = ref.read(weightsProvider);
    if (p == null || weights.length < 2) return null;
    final lastKey = Storage.box('cache').get('lastAdjust');
    final week = dayKey(DateTime.now().subtract(const Duration(days: 7)));
    if (lastKey != null && lastKey.compareTo(week) > 0) return null;
    final recent = weights.where((w) => w.day.compareTo(week) >= 0).toList();
    final before = weights.where((w) => w.day.compareTo(week) < 0).toList();
    if (recent.isEmpty || before.isEmpty) return null;
    final change = recent.last.kg - before.last.kg;
    int delta = 0;
    String why = '';
    switch (p.goal.name) {
      case 'bulk' when change < 0.1:
        delta = 150;
        why = 'وزنك واقف، زودتلك 150 سعر في اليوم';
      case 'cut' when change > -0.2:
        delta = -150;
        why = 'الوزن مش بينزل، نقصتلك 150 سعر في اليوم';
      case 'cut' when change < -1.0:
        delta = 100;
        why = 'بتنزل بسرعة زيادة، زودتلك 100 سعر عشان متخسرش عضل';
    }
    await Storage.box('cache').put('lastAdjust', dayKey(DateTime.now()));
    if (delta == 0) return null;
    await ref.read(profileProvider.notifier).save(p.copyWith(calorieAdjust: p.calorieAdjust + delta));
    return why;
  }

  /// Honest weekly critique for the Wrapped story.
  Future<String> weeklyReview(String stats) => _ai.text(
    system: buildCoachSystem(ref),
    turns: [
      GeminiTurn('user', [
        GeminiPart.text('دي أرقام أسبوعي:\n$stats\nاديني رأيك بصراحة في 3 جمل بالمصري: حاجة كويسة، حاجة وحشة، وهدف الأسبوع الجاي.'),
      ]),
    ],
  );
}

final coachActionsProvider = Provider<CoachActions>(CoachActions.new);
