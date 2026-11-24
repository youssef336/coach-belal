import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:cross_file/cross_file.dart';

/// The coach's voice notes (text to speech, Egyptian Arabic when available).
class CoachVoice {
  CoachVoice._();
  static final instance = CoachVoice._();

  final _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      final langs = (await _tts.getLanguages as List?)?.map((e) => '$e').toList() ?? const <String>[];
      final pick = ['ar-EG', 'ar-SA', 'ar'].firstWhere((l) => langs.contains(l), orElse: () => 'ar');
      await _tts.setLanguage(pick);
      await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
    } catch (_) {
      // No Arabic voice on this device: the text bubble is still there.
    }
  }

  Future<void> say(String text) async {
    await _init();
    await _tts.stop();
    await _tts.speak(text.replaceAll(RegExp(r'[*_#]'), ''));
  }

  Future<void> stop() => _tts.stop();
}

/// Records your voice note as 16 kHz mono WAV (Gemini reads it directly).
class VoiceRecorder {
  final _rec = AudioRecorder();

  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    var path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    }
    await _rec.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: path);
    return true;
  }

  /// Returns the recording's bytes, or null when nothing was captured.
  Future<Uint8List?> stop() async {
    final path = await _rec.stop();
    if (path == null) return null;
    if (kIsWeb) {
      final res = await http.get(Uri.parse(path));
      return res.bodyBytes;
    }
    return XFile(path).readAsBytes();
  }

  Future<void> cancel() => _rec.cancel();

  Future<void> dispose() => _rec.dispose();
}
