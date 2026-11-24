import '../../data/exercise_library.dart';

/// The coach's voice. Every call starts from here.
const coachPersona = '''
إنت "كوتش بلال": أحسن كوتش جيم وتغذية في العالم، مصري، بتتكلم عامية مصرية خفيفة الدم.
إنت صاحب المتدرب بس صارم: بتشجعه وتهزر معاه، ومبتطبلش له لو غلط. ردودك قصيرة (2-4 جمل)، واضحة، ومن غير محاضرات.
المتدرب كسلان جدًا: اقترح دايمًا أسهل حاجة تتعمل، من غير طبيخ معقد، وبأكل موجود في أي سوبرماركت أو عربية فول في مصر.
الأسعار بالجنيه المصري وتقريبية حسب أسعار مصر الحالية. لو مش متأكد من سعر قول "تقريبًا".
العلم الحقيقي بس: مفيش مكملات خرافية ولا وعود سحرية. لو في حاجة طبية (ألم، دوخة، مرض) قوله يروح لدكتور.
بتفضّل الأكل المصري الرخيص: بيض، فول، طعمية، عدس، جبنة قريش، زبادي، تونة، سردين، فراخ، كبدة، رز، عيش بلدي، بطاطس، شوفان محلي، موز.
''';

String coachSystem({required String profile, required String history, required String priceNotes, required bool ramadan}) =>
    '''
$coachPersona

بيانات المتدرب:
$profile

آخر أيام (أكل وتمرين):
$history

${priceNotes.isEmpty ? '' : 'أسعار حديثة من السوق (استخدمها):\n$priceNotes\n'}
${ramadan ? 'دلوقتي رمضان: قسّم الأكل على الفطار والسحور، والتمرين قبل الفطار بساعة أو بعد التراويح.\n' : ''}
قواعد الرد (JSON):
- reply: ردك بالمصري.
- mood: مزاجك من المتدرب.
- eaten: لو المتدرب قال إنه أكل أو شرب حاجة (أو بعت صورة أكله)، فككها هنا بالكميات والسعرات والماكروز والسعر التقريبي. لو مقالش إنه أكل سيبها فاضية.
- swap: لو في بديل أرخص أو أنسب لهدفه للي أكله، حطه هنا مع السبب في why. غير كده null.
- weightKg: لو قال وزنه الجديد.
- workout: لو طلب تمرين، أو بعت صورة جهاز، ابنيله تمرين من القايمة دي بس (exerciseId لازم يكون منها):
${exerciseLibrary.map((e) => '${e.id}=${e.arabic}').join('، ')}
''';

const _food = {
  'type': 'OBJECT',
  'properties': {
    'title': {'type': 'STRING'},
    'kcal': {'type': 'INTEGER'},
    'protein': {'type': 'INTEGER'},
    'carbs': {'type': 'INTEGER'},
    'fat': {'type': 'INTEGER'},
    'price': {'type': 'INTEGER', 'description': 'السعر التقريبي بالجنيه المصري'},
    'why': {'type': 'STRING'},
    'slot': {'type': 'STRING'},
  },
  'required': ['title', 'kcal', 'protein', 'carbs', 'fat', 'price'],
};

const _workout = {
  'type': 'OBJECT',
  'nullable': true,
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
          'kg': {'type': 'NUMBER'},
        },
        'required': ['exerciseId', 'sets', 'reps', 'kg'],
      },
    },
  },
  'required': ['title', 'items'],
};

const chatSchema = {
  'type': 'OBJECT',
  'properties': {
    'reply': {'type': 'STRING'},
    'mood': {
      'type': 'STRING',
      'enum': ['happy', 'proud', 'neutral', 'worried', 'sideeye'],
    },
    'eaten': {'type': 'ARRAY', 'items': _food},
    'swap': {..._food, 'nullable': true},
    'weightKg': {'type': 'NUMBER', 'nullable': true},
    'workout': _workout,
  },
  'required': ['reply', 'mood', 'eaten'],
};

const dayPlanSchema = {
  'type': 'OBJECT',
  'properties': {
    'options': {
      'type': 'ARRAY',
      'description': 'لكل وجبة (فطار، غدا، عشا، سناك) اختيارين، slot فيه اسم الوجبة',
      'items': _food,
    },
  },
  'required': ['options'],
};

const workoutSchema = {
  'type': 'OBJECT',
  'properties': {'workout': _workout, 'note': {'type': 'STRING'}},
  'required': ['workout', 'note'],
};

const shoppingSchema = {
  'type': 'OBJECT',
  'properties': {
    'items': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING'},
          'qty': {'type': 'STRING'},
          'price': {'type': 'INTEGER'},
          'tip': {'type': 'STRING'},
        },
        'required': ['name', 'qty', 'price'],
      },
    },
    'note': {'type': 'STRING'},
  },
  'required': ['items', 'note'],
};
