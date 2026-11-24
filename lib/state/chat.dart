import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/gemini/gemini_client.dart';
import '../core/gemini/prompts.dart';
import '../core/storage.dart';
import '../core/voice.dart';
import '../data/exercise_library.dart';
import '../models/chat_message.dart';
import '../models/meal.dart';
import '../models/workout.dart';
import 'context.dart';
import 'meals.dart';
import 'profile.dart';
import 'settings.dart';
import 'workouts.dart';

const _uuid = Uuid();

class ChatState {
  const ChatState({this.messages = const [], this.thinking = false});
  final List<ChatMessage> messages;
  final bool thinking;

  String get mood => messages.lastWhere((m) => m.fromCoach, orElse: _hello).mood;
}

ChatMessage _hello() => ChatMessage(
  id: 'hello',
  fromCoach: true,
  at: DateTime.now(),
  mood: 'happy',
  text: 'أهلًا يا بطل! ابعتلي فويس بأي حاجة أكلتها، أو صوّر طبقك، وأنا هحسب كل حاجة. ولو عايز تمرين قولي "أنا في الجيم".',
);

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final all = Storage.readAll('chat').map(ChatMessage.fromJson).toList()..sort((a, b) => a.at.compareTo(b.at));
    return ChatState(messages: all.isEmpty ? [_hello()] : all);
  }

  Future<void> _add(ChatMessage m) async {
    await Storage.writeMap('chat', m.id, m.toJson());
    state = ChatState(messages: [...state.messages, m], thinking: state.thinking);
  }

  /// Send text, a voice note, a photo or a short video. The coach answers,
  /// logs what you ate, updates your weight and builds workouts on its own.
  Future<void> send({String text = '', Uint8List? media, String? mimeType, ChatKind kind = ChatKind.text}) async {
    if (state.thinking) return;
    final label = switch (kind) {
      ChatKind.voice => '🎙️ فويس',
      ChatKind.image => text.isEmpty ? '📸 صورة' : '📸 $text',
      ChatKind.video => '🎥 فيديو — $text',
      ChatKind.text => text,
    };
    await _add(ChatMessage(id: _uuid.v4(), fromCoach: false, at: DateTime.now(), text: label, kind: kind));
    state = ChatState(messages: state.messages, thinking: true);

    try {
      final history = state.messages.where((m) => !m.error && m.id != 'hello').toList();
      final recent = history.length > 13 ? history.sublist(history.length - 13, history.length - 1) : history.sublist(0, history.length - 1);
      final turns = <GeminiTurn>[
        for (final m in recent) GeminiTurn(m.fromCoach ? 'model' : 'user', [GeminiPart.text(m.text)]),
        GeminiTurn('user', [
          if (media != null) GeminiPart.media(media, mimeType!),
          GeminiPart.text(_framing(kind, text)),
        ]),
      ];
      final out = await ref.read(geminiProvider).json(system: buildCoachSystem(ref), turns: turns, schema: chatSchema);
      await _apply(out);
    } on CoachError catch (e) {
      await _add(ChatMessage(id: _uuid.v4(), fromCoach: true, at: DateTime.now(), text: e.message, mood: 'worried', error: true));
    } finally {
      state = ChatState(messages: state.messages);
    }
  }

  String _framing(ChatKind kind, String text) => switch (kind) {
    ChatKind.voice => 'ده فويس مني بالمصري، افهمه ورد عليه. ${text.isEmpty ? '' : text}',
    ChatKind.image => text.isEmpty ? 'دي صورة أكلي اللي أكلته دلوقتي، احسبها.' : text,
    ChatKind.video => text,
    ChatKind.text => text,
  };

  Future<void> _apply(Map<String, dynamic> out) async {
    final eaten = ((out['eaten'] as List?) ?? const []).map((e) => FoodIdea.fromJson(e as Map<String, dynamic>)).toList();
    final swap = out['swap'] is Map ? FoodIdea.fromJson(out['swap'] as Map<String, dynamic>) : null;
    for (final f in eaten) {
      await ref.read(mealsProvider.notifier).logIdea(f);
    }
    final kg = out['weightKg'];
    if (kg is num && kg > 30 && kg < 250) {
      await ref.read(weightsProvider.notifier).log(kg.toDouble());
    }
    String? workoutTitle;
    final w = out['workout'];
    if (w is Map && (w['items'] as List?)?.isNotEmpty == true) {
      workoutTitle = w['title'] as String? ?? 'تمرين من الكوتش';
      await ref.read(workoutsProvider.notifier).setToday(workoutTitle, plannedFrom(ref, w['items'] as List));
    }
    final reply = (out['reply'] as String?)?.trim() ?? '';
    await _add(
      ChatMessage(
        id: _uuid.v4(),
        fromCoach: true,
        at: DateTime.now(),
        text: reply,
        mood: out['mood'] as String? ?? 'neutral',
        eaten: eaten,
        swap: swap != null && swap.title.isNotEmpty ? swap : null,
        workoutTitle: workoutTitle,
      ),
    );
    if (ref.read(settingsProvider).voiceReplies && reply.isNotEmpty) {
      CoachVoice.instance.say(reply);
    }
  }

  /// "تمام" on a swap card: next time counts it, and the saving is tracked.
  Future<void> takeSwap(ChatMessage m) async {
    final swap = m.swap;
    if (swap == null || m.swapTaken) return;
    final ate = m.eaten.fold<int>(0, (s, f) => s + f.price);
    await ref.read(mealsProvider.notifier).logIdea(
      FoodIdea(title: '✓ هبدّل لـ ${swap.title}', kcal: 0, protein: 0, carbs: 0, fat: 0, price: 0),
      saved: (ate - swap.price).clamp(0, 100000),
    );
    final updated = m.copyWith(swapTaken: true);
    await Storage.writeMap('chat', m.id, updated.toJson());
    state = ChatState(messages: [for (final x in state.messages) x.id == m.id ? updated : x], thinking: state.thinking);
  }

  Future<void> clear() async {
    await Storage.box('chat').clear();
    state = ChatState(messages: [_hello()]);
  }
}

/// Turns the model's workout items into planned exercises, dropping unknown ids.
List<PlannedExercise> plannedFrom(Ref ref, List items) {
  final known = exerciseLibrary.map((e) => e.id).toSet();
  final wn = ref.read(workoutsProvider.notifier);
  return [
    for (final raw in items.cast<Map>())
      if (known.contains(raw['exerciseId']))
        wn.plan(
          raw['exerciseId'] as String,
          sets: (raw['sets'] as num?)?.round(),
          reps: (raw['reps'] as num?)?.round(),
          kg: (raw['kg'] as num?)?.toDouble(),
        ),
  ];
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
