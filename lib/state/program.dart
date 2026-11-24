import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/gemini/gemini_client.dart';
import '../core/storage.dart';
import '../data/exercise_library.dart';
import '../models/workout.dart';
import 'context.dart';
import 'settings.dart';
import 'workouts.dart';

/// A training block (mesocycle): a few weeks of progressive overload, then a
/// deload week. When it ends, or a main lift stalls, the coach writes a new one
/// with different exercises for what your body needs next.
class ProgramDay {
  const ProgramDay(this.title, this.items);
  final String title;
  final List<({String id, int sets, int reps})> items;

  Map<String, dynamic> toJson() => {
    'title': title,
    'items': [for (final i in items) {'exerciseId': i.id, 'sets': i.sets, 'reps': i.reps}],
  };

  factory ProgramDay.fromJson(Map<String, dynamic> j) => ProgramDay(j['title'] as String, [
    for (final i in (j['items'] as List).cast<Map>())
      (id: i['exerciseId'] as String, sets: (i['sets'] as num).round(), reps: (i['reps'] as num).round()),
  ]);
}

class Program {
  const Program({required this.title, required this.why, required this.start, required this.weeks, required this.days, this.next = 0});

  final String title;
  final String why;
  final String start;
  final int weeks;
  final List<ProgramDay> days;

  /// Which day of the rotation comes next.
  final int next;

  DateTime get _start => DateTime.parse(start);

  int get week => (DateTime.now().difference(_start).inDays ~/ 7 + 1).clamp(1, 99);

  bool get over => week > weeks;

  bool get deload => week == weeks;

  String get phase {
    if (deload) return 'أسبوع تخفيف — جسمك بيبني';
    if (week == 1) return 'أسبوع تعوّد — أوزان مريحة';
    if (week >= weeks - 1) return 'أسبوع تقيل — اكسر أرقامك';
    return 'أسبوع زيادة — زوّد شوية';
  }

  Program advance() => Program(title: title, why: why, start: start, weeks: weeks, days: days, next: (next + 1) % days.length);

  Map<String, dynamic> toJson() => {
    'title': title,
    'why': why,
    'start': start,
    'weeks': weeks,
    'days': days.map((d) => d.toJson()).toList(),
    'next': next,
  };

  factory Program.fromJson(Map<String, dynamic> j) => Program(
    title: j['title'] as String,
    why: j['why'] as String,
    start: j['start'] as String,
    weeks: j['weeks'] as int,
    days: (j['days'] as List).map((d) => ProgramDay.fromJson(d as Map<String, dynamic>)).toList(),
    next: j['next'] as int? ?? 0,
  );
}

const _programSchema = {
  'type': 'OBJECT',
  'properties': {
    'title': {'type': 'STRING'},
    'why': {'type': 'STRING', 'description': 'جسمه محتاج إيه وليه البرنامج ده بالذات، جملتين بالمصري'},
    'weeks': {'type': 'INTEGER'},
    'days': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'title': {'type': 'STRING'},
          'items': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'exerciseId': {'type': 'STRING'},
                'sets': {'type': 'INTEGER'},
                'reps': {'type': 'INTEGER'},
              },
              'required': ['exerciseId', 'sets', 'reps'],
            },
          },
        },
        'required': ['title', 'items'],
      },
    },
  },
  'required': ['title', 'why', 'weeks', 'days'],
};

class ProgramNotifier extends Notifier<Program?> {
  @override
  Program? build() {
    final raw = Storage.box('cache').get('program');
    return raw == null ? null : Program.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _save(Program? p) async {
    state = p;
    if (p == null) {
      await Storage.box('cache').delete('program');
    } else {
      await Storage.box('cache').put('program', jsonEncode(p.toJson()));
    }
  }

  /// Main lifts whose best set hasn't gone up in the last 3 weeks.
  List<String> stalledLifts() {
    final workouts = ref.read(workoutsProvider).values.toList();
    final cut = dayKey(DateTime.now().subtract(const Duration(days: 21)));
    final out = <String>[];
    for (final id in bossLifts) {
      double before = 0, after = 0;
      for (final w in workouts) {
        for (final e in w.items.where((e) => e.exerciseId == id)) {
          for (final s in e.done) {
            if (w.day.compareTo(cut) < 0) {
              if (s.e1rm > before) before = s.e1rm;
            } else if (s.e1rm > after) {
              after = s.e1rm;
            }
          }
        }
      }
      if (before > 0 && after > 0 && after <= before) out.add(exerciseById(id).arabic);
    }
    return out;
  }

  /// Why the coach wants a new block now (null = keep going).
  String? changeReason() {
    final p = state;
    if (p == null) return 'لسه معندكش برنامج';
    if (p.over) return 'البرنامج خلص (${p.weeks} أسابيع)';
    final stalled = stalledLifts();
    if (stalled.length >= 2 && p.week >= 3) return 'وقفت في ${stalled.join(' و')} — جسمك اتعود';
    return null;
  }

  /// Hard sets per muscle over the last 4 weeks: what the coach reads to find
  /// what your body is missing.
  String muscleVolume() {
    final cut = dayKey(DateTime.now().subtract(const Duration(days: 28)));
    final sets = {for (final m in Muscle.values) m: 0};
    for (final w in ref.read(workoutsProvider).values.where((w) => w.day.compareTo(cut) >= 0)) {
      for (final e in w.items) {
        final m = exerciseById(e.exerciseId).muscle;
        sets[m] = sets[m]! + e.done.length;
      }
    }
    if (sets.values.every((v) => v == 0)) return 'لسه مفيش تاريخ تمرين (مبتدئ في التطبيق).';
    return sets.entries.map((e) => '${e.key.label}: ${e.value} سِت (${(e.value / 4).toStringAsFixed(1)} في الأسبوع)').join('، ');
  }

  /// Ask the coach for a new block. The coach decides what your body needs;
  /// [focus] (optional) is a wish, [bodyPhoto] (optional) lets him see you.
  Future<Program> generate({String focus = '', Uint8List? bodyPhoto, String photoMime = 'image/jpeg'}) async {
    final old = state;
    final stalled = stalledLifts();
    final profile = buildCoachSystem(ref, includeProgram: false);
    final out = await ref.read(geminiProvider).json(
      system: profile,
      schema: _programSchema,
      temperature: 0.8,
      turns: [
        GeminiTurn('user', [
          if (bodyPhoto != null) GeminiPart.media(bodyPhoto, photoMime),
          GeminiPart.text(
            'إنت الكوتش وإنت اللي تقرر جسمي محتاج إيه — أنا مش فاهم. '
            'حلّل: طولي ووزني وهدفي، وحجم التمرين لكل عضلة في آخر 4 أسابيع (${muscleVolume()})، '
            'والعضلات اللي أقل من 10 سِتات في الأسبوع محتاجة شغل أكتر. '
            '${bodyPhoto == null ? '' : 'ودي صورة جسمي: شوف العضلات المتأخرة والتوازن (كتف/صدر/ضهر/رجل) وابني عليها، ومتعلقش على الصورة غير باحترام. '}'
            'ابنيلي برنامج جيم جديد (mesocycle) من 4 لـ 6 أسابيع، آخر أسبوع فيه تخفيف. '
            'عدد أيام التمرين في الدورة = أيام الجيم بتاعتي. كل يوم 5-7 تمارين، 45-60 دقيقة. '
            'اختار التقسيمة الأنسب لمستوايا وهدفي (فول بادي / أبر لوور / بوش بول ليجز). '
            '${old == null ? '' : 'البرنامج اللي فات كان "${old.title}" بالتمارين دي: ${old.days.expand((d) => d.items).map((i) => i.id).toSet().join('، ')} — غيّر التمارين (بدائل لنفس العضلة) عشان جسمي ميتعودش، وخلي الأساسيات بس. '}'
            '${stalled.isEmpty ? '' : 'أنا واقف في: ${stalled.join('، ')} — عالج ده (تغيير زاوية، عدات، أو تمرين مساعد). '}'
            '${focus.isEmpty ? '' : 'عايز أركز على: $focus. '}'
            'ركّز على العضلات الضعيفة عندي حسب تاريخ تمريني (اللي بتمرنه قليل). exerciseId من القايمة بس.',
          ),
        ]),
      ],
    );
    final known = exerciseLibrary.map((e) => e.id).toSet();
    final days = [
      for (final d in ((out['days'] as List?) ?? const []).cast<Map<String, dynamic>>())
        ProgramDay(d['title'] as String? ?? 'يوم', [
          for (final i in ((d['items'] as List?) ?? const []).cast<Map>())
            if (known.contains(i['exerciseId'])) (id: i['exerciseId'] as String, sets: ((i['sets'] as num?) ?? 3).round(), reps: ((i['reps'] as num?) ?? 10).round()),
        ]),
    ].where((d) => d.items.isNotEmpty).toList();
    if (days.isEmpty) throw const CoachError('الكوتش مقدرش يبني البرنامج، جرّب تاني');
    final p = Program(
      title: out['title'] as String? ?? 'برنامج جديد',
      why: out['why'] as String? ?? '',
      start: dayKey(DateTime.now()),
      weeks: ((out['weeks'] as num?) ?? 5).round().clamp(3, 8),
      days: days,
    );
    await _save(p);
    return p;
  }

  /// Puts the next day of the block into today's workout.
  /// Deload week: fewer sets, 10% lighter.
  Future<String?> planToday() async {
    final p = state;
    if (p == null) return null;
    final day = p.days[p.next % p.days.length];
    final wn = ref.read(workoutsProvider.notifier);
    final items = <PlannedExercise>[
      for (final i in day.items)
        () {
          final planned = wn.plan(i.id, sets: i.sets, reps: i.reps);
          if (p.deload) {
            planned
              ..sets = (i.sets * 0.6).ceil().clamp(1, 10)
              ..kg = (planned.kg * 0.9 / 2.5).round() * 2.5;
          }
          return planned;
        }(),
    ];
    await wn.setToday(day.title, items);
    await _save(p.advance());
    return '${day.title} — أسبوع ${p.week} من ${p.weeks}';
  }

  Future<void> clear() => _save(null);
}

final programProvider = NotifierProvider<ProgramNotifier, Program?>(ProgramNotifier.new);
