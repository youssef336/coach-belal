import 'meal.dart';

enum ChatKind { text, voice, image, video }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromCoach,
    required this.at,
    required this.text,
    this.kind = ChatKind.text,
    this.mood = 'neutral',
    this.eaten = const [],
    this.swap,
    this.swapTaken = false,
    this.workoutTitle,
    this.error = false,
  });

  final String id;
  final bool fromCoach;
  final DateTime at;
  final String text;
  final ChatKind kind;
  final String mood;
  final List<FoodIdea> eaten;
  final FoodIdea? swap;
  final bool swapTaken;
  final String? workoutTitle;
  final bool error;

  ChatMessage copyWith({bool? swapTaken}) => ChatMessage(
    id: id,
    fromCoach: fromCoach,
    at: at,
    text: text,
    kind: kind,
    mood: mood,
    eaten: eaten,
    swap: swap,
    swapTaken: swapTaken ?? this.swapTaken,
    workoutTitle: workoutTitle,
    error: error,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromCoach': fromCoach,
    'at': at.toIso8601String(),
    'text': text,
    'kind': kind.name,
    'mood': mood,
    'eaten': eaten.map((e) => e.toJson()).toList(),
    'swap': swap?.toJson(),
    'swapTaken': swapTaken,
    'workoutTitle': workoutTitle,
    'error': error,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    fromCoach: j['fromCoach'] as bool,
    at: DateTime.parse(j['at'] as String),
    text: j['text'] as String,
    kind: ChatKind.values.byName(j['kind'] as String? ?? 'text'),
    mood: j['mood'] as String? ?? 'neutral',
    eaten: ((j['eaten'] as List?) ?? const []).map((e) => FoodIdea.fromJson(e as Map<String, dynamic>)).toList(),
    swap: j['swap'] == null ? null : FoodIdea.fromJson(j['swap'] as Map<String, dynamic>),
    swapTaken: j['swapTaken'] as bool? ?? false,
    workoutTitle: j['workoutTitle'] as String?,
    error: j['error'] as bool? ?? false,
  );
}
