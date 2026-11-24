import 'dart:ui';

/// Hand-made exercise animations: two key poses per exercise on a 100×100
/// stage (floor at y = 92), played back and forth. No video files: they work
/// offline and add almost nothing to the app.
///
/// Joints: head, sh (shoulder), el, ha (hand), hip, kn, ft. A `2` suffix is the
/// far side (drawn dimmer), used for front views and walking.
typedef Pose = Map<String, Offset>;

enum Prop { barbell, dumbbell, cable, none }

class Demo {
  const Demo(this.a, this.b, {this.prop = Prop.none, this.anchor, this.anchor2, this.stage = const [], this.seconds = 1.4});

  final Pose a;
  final Pose b;
  final Prop prop;

  /// Where the cable comes from.
  final Offset? anchor;
  final Offset? anchor2;

  /// Static scenery: rectangles (bench, bars, seat) as left, top, width, height.
  final List<Rect> stage;
  final double seconds;
}

const _o = Offset.new;

// Standing, side view, facing right.
const Pose _stand = {
  'head': Offset(50, 14), 'sh': Offset(50, 27), 'el': Offset(50, 40), 'ha': Offset(51, 53),
  'hip': Offset(50, 53), 'kn': Offset(51, 72), 'ft': Offset(50, 92),
};

// Standing, front view.
const Pose _front = {
  'head': Offset(50, 13), 'sh': Offset(41, 27), 'sh2': Offset(59, 27),
  'el': Offset(39, 40), 'ha': Offset(39, 53), 'el2': Offset(61, 40), 'ha2': Offset(61, 53),
  'hip': Offset(45, 53), 'hip2': Offset(55, 53), 'kn': Offset(44, 72), 'kn2': Offset(56, 72),
  'ft': Offset(44, 92), 'ft2': Offset(56, 92),
};

Pose _with(Pose base, Pose changes) => {...base, ...changes};

const _benchFlat = Rect.fromLTWH(18, 64, 56, 5);

// Lying on a flat bench, head on the left.
const Pose _lying = {
  'head': Offset(22, 57), 'sh': Offset(31, 60), 'hip': Offset(58, 60),
  'kn': Offset(72, 54), 'ft': Offset(78, 92),
};

final Map<String, Demo> exerciseDemos = {
  'bench': Demo(
    _with(_lying, {'el': _o(41, 66), 'ha': _o(34, 50)}),
    _with(_lying, {'el': _o(34, 40), 'ha': _o(34, 27)}),
    prop: Prop.barbell,
    stage: [_benchFlat],
  ),
  'incline_db': Demo(
    {'head': _o(27, 33), 'sh': _o(33, 42), 'hip': _o(58, 62), 'kn': _o(72, 56), 'ft': _o(78, 92), 'el': _o(44, 50), 'ha': _o(38, 36)},
    {'head': _o(27, 33), 'sh': _o(33, 42), 'hip': _o(58, 62), 'kn': _o(72, 56), 'ft': _o(78, 92), 'el': _o(38, 28), 'ha': _o(36, 15)},
    prop: Prop.dumbbell,
    stage: [Rect.fromLTWH(46, 64, 24, 5)],
  ),
  'chest_fly': Demo(
    _with(_front, {'el': _o(27, 31), 'ha': _o(15, 33), 'el2': _o(73, 31), 'ha2': _o(85, 33)}),
    _with(_front, {'el': _o(38, 40), 'ha': _o(48, 44), 'el2': _o(62, 40), 'ha2': _o(52, 44)}),
    prop: Prop.cable,
    anchor: _o(6, 16),
    anchor2: _o(94, 16),
  ),
  'pushup': Demo(
    {'head': _o(21, 60), 'sh': _o(30, 63), 'el': _o(30, 77), 'ha': _o(30, 91), 'hip': _o(56, 71), 'kn': _o(70, 80), 'ft': _o(85, 89)},
    {'head': _o(21, 76), 'sh': _o(30, 79), 'el': _o(41, 81), 'ha': _o(30, 91), 'hip': _o(56, 83), 'kn': _o(70, 86), 'ft': _o(85, 89)},
  ),
  'dips': Demo(
    {'head': _o(50, 22), 'sh': _o(50, 34), 'el': _o(51, 42), 'ha': _o(52, 51), 'hip': _o(50, 60), 'kn': _o(56, 74), 'ft': _o(47, 84)},
    {'head': _o(52, 34), 'sh': _o(50, 46), 'el': _o(39, 45), 'ha': _o(52, 51), 'hip': _o(49, 72), 'kn': _o(56, 84), 'ft': _o(46, 90)},
    stage: [Rect.fromLTWH(40, 51, 30, 3)],
  ),
  'deadlift': Demo(
    {'head': _o(68, 41), 'sh': _o(60, 47), 'el': _o(59, 65), 'ha': _o(58, 84), 'hip': _o(40, 60), 'kn': _o(57, 70), 'ft': _o(50, 92)},
    _with(_stand, {'ha': _o(51, 55)}),
    prop: Prop.barbell,
    seconds: 1.6,
  ),
  'rdl': Demo(
    {'head': _o(73, 42), 'sh': _o(64, 45), 'el': _o(64, 58), 'ha': _o(64, 71), 'hip': _o(38, 52), 'kn': _o(48, 72), 'ft': _o(50, 92)},
    _with(_stand, {'ha': _o(51, 55)}),
    prop: Prop.barbell,
    seconds: 1.6,
  ),
  'squat': Demo(
    _with(_stand, {'el': _o(41, 31), 'ha': _o(47, 24)}),
    {'head': _o(57, 33), 'sh': _o(52, 44), 'el': _o(43, 48), 'ha': _o(49, 41), 'hip': _o(33, 64), 'kn': _o(58, 70), 'ft': _o(50, 92)},
    prop: Prop.barbell,
    seconds: 1.6,
  ),
  'leg_press': Demo(
    {'head': _o(17, 51), 'sh': _o(24, 58), 'el': _o(32, 70), 'ha': _o(38, 78), 'hip': _o(40, 75), 'kn': _o(48, 52), 'ft': _o(63, 60)},
    {'head': _o(17, 51), 'sh': _o(24, 58), 'el': _o(32, 70), 'ha': _o(38, 78), 'hip': _o(40, 75), 'kn': _o(58, 60), 'ft': _o(76, 46)},
    stage: [Rect.fromLTWH(10, 78, 36, 5)],
  ),
  'lunges': Demo(
    {'head': _o(50, 14), 'sh': _o(50, 27), 'el': _o(50, 40), 'ha': _o(51, 53), 'hip': _o(50, 53), 'kn': _o(59, 72), 'ft': _o(64, 92), 'kn2': _o(43, 73), 'ft2': _o(34, 92)},
    {'head': _o(50, 26), 'sh': _o(50, 39), 'el': _o(50, 52), 'ha': _o(51, 65), 'hip': _o(50, 65), 'kn': _o(64, 68), 'ft': _o(64, 92), 'kn2': _o(45, 88), 'ft2': _o(32, 92)},
    prop: Prop.dumbbell,
  ),
  'leg_ext': Demo(
    {'head': _o(40, 28), 'sh': _o(40, 40), 'el': _o(43, 52), 'ha': _o(48, 64), 'hip': _o(42, 64), 'kn': _o(62, 64), 'ft': _o(62, 88)},
    {'head': _o(40, 28), 'sh': _o(40, 40), 'el': _o(43, 52), 'ha': _o(48, 64), 'hip': _o(42, 64), 'kn': _o(62, 64), 'ft': _o(85, 60)},
    stage: [Rect.fromLTWH(30, 66, 34, 5), Rect.fromLTWH(30, 30, 5, 36)],
  ),
  'leg_curl': Demo(
    {'head': _o(21, 54), 'sh': _o(30, 58), 'el': _o(28, 67), 'ha': _o(21, 66), 'hip': _o(56, 58), 'kn': _o(76, 58), 'ft': _o(95, 58)},
    {'head': _o(21, 54), 'sh': _o(30, 58), 'el': _o(28, 67), 'ha': _o(21, 66), 'hip': _o(56, 58), 'kn': _o(76, 58), 'ft': _o(79, 37)},
    stage: [Rect.fromLTWH(16, 62, 64, 5)],
  ),
  'calf': Demo(
    _with(_stand, {'el': _o(41, 31), 'ha': _o(47, 24)}),
    {'head': _o(50, 8), 'sh': _o(50, 21), 'el': _o(41, 25), 'ha': _o(47, 18), 'hip': _o(50, 47), 'kn': _o(51, 66), 'ft': _o(52, 86)},
    prop: Prop.barbell,
    seconds: 0.9,
  ),
  'ohp': Demo(
    _with(_stand, {'el': _o(45, 36), 'ha': _o(54, 25)}),
    _with(_stand, {'el': _o(52, 14), 'ha': _o(51, 2)}),
    prop: Prop.barbell,
  ),
  'lateral': Demo(
    _front,
    _with(_front, {'el': _o(28, 28), 'ha': _o(17, 29), 'el2': _o(72, 28), 'ha2': _o(83, 29)}),
    prop: Prop.dumbbell,
  ),
  'face_pull': Demo(
    _with(_stand, {'el': _o(65, 27), 'ha': _o(80, 24)}),
    _with(_stand, {'el': _o(39, 22), 'ha': _o(54, 15)}),
    prop: Prop.cable,
    anchor: _o(96, 22),
  ),
  'rear_delt': Demo(
    _with(_front, {'el': _o(44, 44), 'ha': _o(48, 52), 'el2': _o(56, 44), 'ha2': _o(52, 52)}),
    _with(_front, {'el': _o(28, 30), 'ha': _o(16, 32), 'el2': _o(72, 30), 'ha2': _o(84, 32)}),
    prop: Prop.dumbbell,
  ),
  'bb_curl': Demo(
    _with(_stand, {'el': _o(50, 41), 'ha': _o(53, 55)}),
    _with(_stand, {'el': _o(50, 41), 'ha': _o(58, 29)}),
    prop: Prop.barbell,
  ),
  'hammer': Demo(
    _with(_stand, {'el': _o(50, 41), 'ha': _o(53, 55)}),
    _with(_stand, {'el': _o(50, 41), 'ha': _o(58, 29)}),
    prop: Prop.dumbbell,
  ),
  'preacher': Demo(
    {'head': _o(42, 20), 'sh': _o(44, 31), 'el': _o(57, 42), 'ha': _o(71, 54), 'hip': _o(40, 58), 'kn': _o(56, 62), 'ft': _o(56, 88)},
    {'head': _o(42, 20), 'sh': _o(44, 31), 'el': _o(57, 42), 'ha': _o(55, 26), 'hip': _o(40, 58), 'kn': _o(56, 62), 'ft': _o(56, 88)},
    prop: Prop.barbell,
    stage: [Rect.fromLTWH(52, 44, 16, 5), Rect.fromLTWH(30, 60, 20, 5)],
  ),
  'pushdown': Demo(
    _with(_stand, {'el': _o(51, 41), 'ha': _o(60, 31)}),
    _with(_stand, {'el': _o(51, 41), 'ha': _o(56, 56)}),
    prop: Prop.cable,
    anchor: _o(64, 0),
  ),
  'skull': Demo(
    _with(_lying, {'el': _o(36, 37), 'ha': _o(24, 45)}),
    _with(_lying, {'el': _o(36, 37), 'ha': _o(35, 24)}),
    prop: Prop.barbell,
    stage: [_benchFlat],
  ),
  'plank': Demo(
    {'head': _o(21, 70), 'sh': _o(30, 76), 'el': _o(30, 90), 'ha': _o(43, 90), 'hip': _o(56, 79), 'kn': _o(70, 83), 'ft': _o(85, 89)},
    {'head': _o(21, 69), 'sh': _o(30, 75), 'el': _o(30, 90), 'ha': _o(43, 90), 'hip': _o(56, 77), 'kn': _o(70, 82), 'ft': _o(85, 89)},
    seconds: 1.8,
  ),
  'crunch': Demo(
    {'head': _o(52, 28), 'sh': _o(50, 39), 'el': _o(57, 31), 'ha': _o(54, 22), 'hip': _o(48, 64), 'kn': _o(48, 90), 'ft': _o(29, 90)},
    {'head': _o(69, 55), 'sh': _o(62, 47), 'el': _o(69, 41), 'ha': _o(66, 33), 'hip': _o(46, 64), 'kn': _o(48, 90), 'ft': _o(29, 90)},
    prop: Prop.cable,
    anchor: _o(62, 0),
  ),
  'leg_raise': Demo(
    {'head': _o(50, 19), 'sh': _o(50, 27), 'el': _o(50, 16), 'ha': _o(50, 6), 'hip': _o(50, 53), 'kn': _o(51, 71), 'ft': _o(50, 89)},
    {'head': _o(48, 19), 'sh': _o(48, 27), 'el': _o(49, 16), 'ha': _o(50, 6), 'hip': _o(47, 53), 'kn': _o(65, 52), 'ft': _o(83, 51)},
    stage: [Rect.fromLTWH(28, 4, 44, 3)],
  ),
  'pullup': Demo(
    {'head': _o(50, 20), 'sh': _o(50, 28), 'el': _o(50, 17), 'ha': _o(50, 6), 'hip': _o(50, 54), 'kn': _o(55, 70), 'ft': _o(48, 80)},
    {'head': _o(50, 10), 'sh': _o(50, 20), 'el': _o(40, 18), 'ha': _o(50, 6), 'hip': _o(50, 46), 'kn': _o(55, 62), 'ft': _o(48, 72)},
    stage: [Rect.fromLTWH(28, 4, 44, 3)],
  ),
  'lat_pulldown': Demo(
    {'head': _o(50, 20), 'sh': _o(50, 31), 'el': _o(50, 18), 'ha': _o(50, 6), 'hip': _o(50, 57), 'kn': _o(67, 58), 'ft': _o(67, 82)},
    {'head': _o(51, 20), 'sh': _o(50, 31), 'el': _o(39, 37), 'ha': _o(50, 25), 'hip': _o(50, 57), 'kn': _o(67, 58), 'ft': _o(67, 82)},
    prop: Prop.cable,
    anchor: _o(50, 0),
    stage: [Rect.fromLTWH(38, 59, 22, 5)],
  ),
  'seated_row': Demo(
    {'head': _o(50, 24), 'sh': _o(45, 35), 'el': _o(60, 46), 'ha': _o(76, 54), 'hip': _o(36, 62), 'kn': _o(56, 54), 'ft': _o(72, 64)},
    {'head': _o(40, 22), 'sh': _o(38, 34), 'el': _o(30, 50), 'ha': _o(48, 54), 'hip': _o(36, 62), 'kn': _o(56, 54), 'ft': _o(72, 64)},
    prop: Prop.cable,
    anchor: _o(96, 56),
    stage: [Rect.fromLTWH(24, 64, 26, 5)],
  ),
  'bb_row': Demo(
    {'head': _o(70, 32), 'sh': _o(62, 38), 'el': _o(62, 51), 'ha': _o(62, 66), 'hip': _o(38, 50), 'kn': _o(46, 72), 'ft': _o(46, 92)},
    {'head': _o(70, 32), 'sh': _o(62, 38), 'el': _o(50, 45), 'ha': _o(57, 57), 'hip': _o(38, 50), 'kn': _o(46, 72), 'ft': _o(46, 92)},
    prop: Prop.barbell,
  ),
  'db_row': Demo(
    {'head': _o(72, 36), 'sh': _o(63, 40), 'el': _o(63, 53), 'ha': _o(63, 67), 'hip': _o(38, 46), 'kn': _o(40, 70), 'ft': _o(40, 92)},
    {'head': _o(72, 36), 'sh': _o(63, 40), 'el': _o(50, 44), 'ha': _o(58, 55), 'hip': _o(38, 46), 'kn': _o(40, 70), 'ft': _o(40, 92)},
    prop: Prop.dumbbell,
  ),
  'treadmill': Demo(
    {'head': _o(50, 12), 'sh': _o(50, 25), 'el': _o(57, 37), 'ha': _o(63, 46), 'el2': _o(44, 37), 'ha2': _o(40, 48), 'hip': _o(50, 51), 'kn': _o(58, 69), 'ft': _o(62, 86), 'kn2': _o(46, 70), 'ft2': _o(36, 90)},
    {'head': _o(50, 12), 'sh': _o(50, 25), 'el': _o(44, 37), 'ha': _o(40, 48), 'el2': _o(57, 37), 'ha2': _o(63, 46), 'hip': _o(50, 51), 'kn': _o(46, 70), 'ft': _o(36, 90), 'kn2': _o(58, 69), 'ft2': _o(62, 86)},
    seconds: 0.6,
  ),
  'bike': Demo(
    {'head': _o(57, 20), 'sh': _o(53, 30), 'el': _o(62, 40), 'ha': _o(70, 43), 'hip': _o(43, 52), 'kn': _o(60, 58), 'ft': _o(58, 82), 'kn2': _o(54, 62), 'ft2': _o(42, 72)},
    {'head': _o(57, 20), 'sh': _o(53, 30), 'el': _o(62, 40), 'ha': _o(70, 43), 'hip': _o(43, 52), 'kn': _o(54, 62), 'ft': _o(42, 72), 'kn2': _o(60, 58), 'ft2': _o(58, 82)},
    stage: [Rect.fromLTWH(36, 54, 14, 4), Rect.fromLTWH(41, 58, 4, 30), Rect.fromLTWH(68, 43, 6, 4)],
    seconds: 0.5,
  ),
};
