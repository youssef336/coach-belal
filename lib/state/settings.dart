import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/gemini/gemini_client.dart';
import '../core/storage.dart';

class Settings {
  const Settings({this.apiKey = '', this.model = defaultModel, this.voiceReplies = true, this.ramadan = false});

  static const defaultModel = 'gemini-flash-latest';

  final String apiKey;
  final String model;
  final bool voiceReplies;
  final bool ramadan;

  bool get hasKey => apiKey.trim().isNotEmpty;

  Settings copyWith({String? apiKey, String? model, bool? voiceReplies, bool? ramadan}) => Settings(
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    voiceReplies: voiceReplies ?? this.voiceReplies,
    ramadan: ramadan ?? this.ramadan,
  );

  Map<String, dynamic> toJson() => {'apiKey': apiKey, 'model': model, 'voiceReplies': voiceReplies, 'ramadan': ramadan};

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
    apiKey: j['apiKey'] as String? ?? '',
    model: j['model'] as String? ?? defaultModel,
    voiceReplies: j['voiceReplies'] as bool? ?? true,
    ramadan: j['ramadan'] as bool? ?? false,
  );
}

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final raw = Storage.readMap('settings', 'main');
    return raw == null ? const Settings() : Settings.fromJson(raw);
  }

  Future<void> update(Settings next) async {
    state = next;
    await Storage.writeMap('settings', 'main', next.toJson());
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

final geminiProvider = Provider<GeminiClient>((ref) {
  final s = ref.watch(settingsProvider);
  return GeminiClient(apiKey: s.apiKey, model: s.model);
});
