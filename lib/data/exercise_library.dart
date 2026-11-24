import '../models/workout.dart';

/// The cards you drag into today's workout.
const exerciseLibrary = <Exercise>[
  // Chest
  Exercise('bench', 'Bench Press', 'بنش مستوي', Muscle.chest, sets: 4, reps: 8, startKg: 40, tip: 'لوّح الكتف لورا وانزل للصدر'),
  Exercise('incline_db', 'Incline DB Press', 'دمبل عالي', Muscle.chest, sets: 3, reps: 10, startKg: 14, tip: 'زاوية 30 درجة كفاية'),
  Exercise('chest_fly', 'Cable Fly', 'كابل فلاي', Muscle.chest, sets: 3, reps: 12, startKg: 10, tip: 'حضن شجرة، كوعك ثابت'),
  Exercise('pushup', 'Push-up', 'ضغط', Muscle.chest, sets: 3, reps: 15, startKg: 0, tip: 'جسمك لوح واحد'),
  Exercise('dips', 'Dips', 'متوازي', Muscle.chest, sets: 3, reps: 10, startKg: 0, tip: 'ميل لقدام للصدر'),
  // Back
  Exercise('deadlift', 'Deadlift', 'ديدلفت', Muscle.back, sets: 3, reps: 5, startKg: 60, tip: 'ضهرك مستقيم، ادفع بالرجل'),
  Exercise('lat_pulldown', 'Lat Pulldown', 'سحب عالي', Muscle.back, sets: 4, reps: 10, startKg: 40, tip: 'اسحب بكوعك مش بإيدك'),
  Exercise('seated_row', 'Seated Row', 'سحب أرضي', Muscle.back, sets: 3, reps: 12, startKg: 35, tip: 'صدرك لقدام وضم لوحك'),
  Exercise('bb_row', 'Barbell Row', 'منشار بار', Muscle.back, sets: 3, reps: 8, startKg: 40, tip: 'انحني 45 درجة'),
  Exercise('pullup', 'Pull-up', 'عقلة', Muscle.back, sets: 3, reps: 6, startKg: 0, tip: 'دقنك فوق العقلة'),
  Exercise('db_row', 'One-arm DB Row', 'منشار دمبل', Muscle.back, sets: 3, reps: 10, startKg: 16, tip: 'اسحب للوسط'),
  // Legs
  Exercise('squat', 'Squat', 'سكوات', Muscle.legs, sets: 4, reps: 8, startKg: 50, tip: 'انزل لحد ما فخدك يوازي الأرض'),
  Exercise('leg_press', 'Leg Press', 'دفع رجل', Muscle.legs, sets: 3, reps: 12, startKg: 80, tip: 'متقفلش ركبتك فوق'),
  Exercise('rdl', 'Romanian Deadlift', 'رومانيان', Muscle.legs, sets: 3, reps: 10, startKg: 40, tip: 'حس بشد ورا الفخد'),
  Exercise('lunges', 'Walking Lunges', 'لانجز', Muscle.legs, sets: 3, reps: 12, startKg: 10, tip: 'ركبتك متعديش صوابعك'),
  Exercise('leg_ext', 'Leg Extension', 'رفرفة أمامي', Muscle.legs, sets: 3, reps: 12, startKg: 30, tip: 'اقفل ثانية فوق'),
  Exercise('leg_curl', 'Leg Curl', 'رفرفة خلفي', Muscle.legs, sets: 3, reps: 12, startKg: 25, tip: 'انزل ببطء'),
  Exercise('calf', 'Calf Raise', 'سمانة', Muscle.legs, sets: 4, reps: 15, startKg: 40, tip: 'مطّ تحت وشد فوق'),
  // Shoulders
  Exercise('ohp', 'Overhead Press', 'ضغط كتف', Muscle.shoulders, sets: 4, reps: 8, startKg: 25, tip: 'بطنك مشدودة'),
  Exercise('lateral', 'Lateral Raise', 'رفرفة جانبي', Muscle.shoulders, sets: 4, reps: 15, startKg: 6, tip: 'ارفع لحد الكتف بس'),
  Exercise('face_pull', 'Face Pull', 'فيس بول', Muscle.shoulders, sets: 3, reps: 15, startKg: 15, tip: 'اسحب لوشك وافتح'),
  Exercise('rear_delt', 'Rear Delt Fly', 'خلفي كتف', Muscle.shoulders, sets: 3, reps: 15, startKg: 6, tip: 'خفيف ومظبوط'),
  // Arms
  Exercise('bb_curl', 'Barbell Curl', 'باي بار', Muscle.arms, sets: 3, reps: 10, startKg: 20, tip: 'متمرجحش ضهرك'),
  Exercise('hammer', 'Hammer Curl', 'هامر', Muscle.arms, sets: 3, reps: 12, startKg: 10, tip: 'كفك لجوه'),
  Exercise('pushdown', 'Triceps Pushdown', 'تراي كابل', Muscle.arms, sets: 3, reps: 12, startKg: 20, tip: 'كوعك لازق في جنبك'),
  Exercise('skull', 'Skull Crusher', 'تراي بار', Muscle.arms, sets: 3, reps: 10, startKg: 15, tip: 'انزل ورا راسك'),
  Exercise('preacher', 'Preacher Curl', 'باي مسند', Muscle.arms, sets: 3, reps: 10, startKg: 15, tip: 'افرد على الآخر'),
  // Core
  Exercise('plank', 'Plank (sec)', 'بلانك (ثانية)', Muscle.core, sets: 3, reps: 45, startKg: 0, tip: 'الأرقام هنا ثواني'),
  Exercise('crunch', 'Cable Crunch', 'بطن كابل', Muscle.core, sets: 3, reps: 15, startKg: 20, tip: 'لف ضهرك مش وسطك'),
  Exercise('leg_raise', 'Hanging Leg Raise', 'رفع رجل', Muscle.core, sets: 3, reps: 12, startKg: 0, tip: 'من غير مرجحة'),
  // Cardio
  Exercise('treadmill', 'Incline Walk (min)', 'مشي مايل (دقيقة)', Muscle.cardio, sets: 1, reps: 20, startKg: 0, tip: 'ميل 10 وسرعة 5'),
  Exercise('bike', 'Bike (min)', 'عجلة (دقيقة)', Muscle.cardio, sets: 1, reps: 15, startKg: 0, tip: 'نفَس منتظم'),
];

Exercise exerciseById(String id) => exerciseLibrary.firstWhere((e) => e.id == id, orElse: () => exerciseLibrary.first);

/// Offline fallback when there's no AI: a push / pull / legs rotation.
const splitTemplates = <String, List<String>>{
  'صدر + كتف + تراي': ['bench', 'incline_db', 'ohp', 'lateral', 'pushdown'],
  'ضهر + باي': ['lat_pulldown', 'seated_row', 'db_row', 'face_pull', 'bb_curl', 'hammer'],
  'رجل + بطن': ['squat', 'leg_press', 'rdl', 'leg_curl', 'calf', 'plank'],
};

/// Lifts that can become the weekly boss.
const bossLifts = ['bench', 'squat', 'deadlift', 'ohp', 'lat_pulldown', 'bb_row', 'leg_press'];
