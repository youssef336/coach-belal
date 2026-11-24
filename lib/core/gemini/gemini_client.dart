import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A friendly error the UI can show as-is (never the raw HTTP body).
class CoachError implements Exception {
  const CoachError(this.message);
  final String message;
  @override
  String toString() => message;
}

class GeminiPart {
  const GeminiPart.text(this.text) : bytes = null, mimeType = null;
  const GeminiPart.media(Uint8List this.bytes, String this.mimeType) : text = null;

  final String? text;
  final Uint8List? bytes;
  final String? mimeType;

  Map<String, dynamic> toJson() => text != null
      ? {'text': text}
      : {
          'inlineData': {'mimeType': mimeType, 'data': base64Encode(bytes!)},
        };
}

class GeminiTurn {
  const GeminiTurn(this.role, this.parts);
  final String role; // 'user' | 'model'
  final List<GeminiPart> parts;

  Map<String, dynamic> toJson() => {'role': role, 'parts': parts.map((p) => p.toJson()).toList()};
}

/// Talks to Google's free Gemini API straight from the phone (or browser).
/// The key is the user's own, pasted in Settings and kept on the device.
class GeminiClient {
  GeminiClient({required this.apiKey, required this.model, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _http;

  static const _base = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Structured answer: the model must return JSON matching [schema].
  Future<Map<String, dynamic>> json({
    required String system,
    required List<GeminiTurn> turns,
    required Map<String, dynamic> schema,
    double temperature = 0.7,
  }) async {
    final text = await _generate({
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': turns.map((t) => t.toJson()).toList(),
      'generationConfig': {
        'temperature': temperature,
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      },
    });
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } on FormatException {
      throw const CoachError('الكوتش رد بحاجة ملخبطة، جرّب تاني');
    }
  }

  /// Free text, optionally grounded with Google Search (for today's prices).
  Future<String> text({required String system, required List<GeminiTurn> turns, bool search = false}) =>
      _generate({
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
        'contents': turns.map((t) => t.toJson()).toList(),
        if (search)
          'tools': [
            {'google_search': <String, dynamic>{}},
          ],
      });

  /// Models tried after the user's own, in order. Each model has its own free
  /// quota on Google's side, so when one runs out the next usually still works.
  static const fallbackModels = ['gemini-2.5-flash', 'gemini-2.5-flash-lite', 'gemini-flash-lite-latest'];

  /// Models that ran out of free quota, and when to try them again.
  /// Shared by every client so a new key/settings rebuild doesn't re-hit them.
  static final _restingUntil = <String, DateTime>{};

  /// Longest wait we accept in-line when Google says "retry in Ns".
  static const _maxInlineWait = Duration(seconds: 20);

  @visibleForTesting
  static void resetQuotaMemory() => _restingUntil.clear();

  List<String> get _chain {
    final now = DateTime.now();
    final all = <String>{model.trim(), ...fallbackModels}.where((m) => m.isNotEmpty).toList();
    final awake = all.where((m) => !(_restingUntil[m]?.isAfter(now) ?? false)).toList();
    return awake.isEmpty ? all : awake;
  }

  Future<String> _generate(Map<String, dynamic> body) async {
    if (apiKey.trim().isEmpty) {
      throw const CoachError('محتاج مفتاح Gemini الأول — من الإعدادات');
    }
    CoachError? last;
    for (final m in _chain) {
      try {
        return await _generateWith(m, body);
      } on _TryNextModel catch (e) {
        last = e.error;
      }
    }
    throw last ?? const CoachError('حصلت مشكلة، جرّب تاني');
  }

  Future<String> _generateWith(String m, Map<String, dynamic> body, {int attempt = 0}) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse('$_base/$m:generateContent'),
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey.trim()},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      throw const CoachError('مفيش نت أو الكوتش مش بيرد، جرّب كمان شوية');
    }

    if (res.statusCode == 503 || res.statusCode == 500) {
      if (attempt < 2) {
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        return _generateWith(m, body, attempt: attempt + 1);
      }
      throw const _TryNextModel(CoachError('سيرفرات Google زحمة دلوقتي، جرّب بعد دقيقة'));
    }
    if (res.statusCode == 429) {
      final q = QuotaInfo.parse(res.body);
      // Per-minute limit with a short wait: wait it out once on the same model.
      if (!q.daily && attempt == 0 && q.retryAfter != null && q.retryAfter! <= _maxInlineWait) {
        await Future<void>.delayed(q.retryAfter!);
        return _generateWith(m, body, attempt: attempt + 1);
      }
      _restingUntil[m] = DateTime.now().add(q.daily ? const Duration(hours: 6) : (q.retryAfter ?? const Duration(minutes: 1)));
      throw _TryNextModel(
        CoachError(
          q.daily
              ? 'خلصت الحصة المجانية بتاعة النهارده على كل الموديلات، جرّب بكره'
              : 'Google بيقول استنى ${q.retryAfter?.inSeconds ?? 60} ثانية وجرّب تاني',
        ),
      );
    }
    if (res.statusCode == 400 || res.statusCode == 403) {
      final body = res.body;
      if (body.contains('API_KEY') || body.contains('API key')) {
        throw const CoachError('مفتاح Gemini مش شغال، راجعه في الإعدادات');
      }
      throw const CoachError('الطلب ده مينفعش، جرّب صورة أو كلام أقصر');
    }
    if (res.statusCode == 404) {
      throw const _TryNextModel(CoachError('اسم الموديل غلط، غيّره من الإعدادات'));
    }
    if (res.statusCode != 200) {
      throw CoachError('حصلت مشكلة (${res.statusCode})، جرّب تاني');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const CoachError('الكوتش سكت.. جرّب تقولها بطريقة تانية');
    }
    final parts = ((candidates.first as Map)['content'] as Map?)?['parts'] as List? ?? const [];
    final out = parts.map((p) => (p as Map)['text'] as String? ?? '').join();
    if (out.trim().isEmpty) {
      throw const CoachError('الكوتش سكت.. جرّب تقولها بطريقة تانية');
    }
    return out;
  }
}

class _TryNextModel implements Exception {
  const _TryNextModel(this.error);
  final CoachError error;
}

/// What a Gemini 429 says: which limit was hit and how long Google wants us to wait.
class QuotaInfo {
  const QuotaInfo({required this.daily, this.retryAfter});

  /// The per-day limit (or a model with no free quota at all) — waiting minutes won't help.
  final bool daily;
  final Duration? retryAfter;

  static QuotaInfo parse(String body) {
    var daily = false;
    Duration? retry;
    try {
      final details = ((jsonDecode(body) as Map)['error'] as Map?)?['details'] as List? ?? const [];
      for (final d in details.whereType<Map>()) {
        final type = '${d['@type']}';
        if (type.endsWith('RetryInfo')) {
          final s = double.tryParse('${d['retryDelay']}'.replaceAll('s', ''));
          if (s != null) retry = Duration(milliseconds: (s * 1000).ceil());
        } else if (type.endsWith('QuotaFailure')) {
          for (final v in (d['violations'] as List? ?? const []).whereType<Map>()) {
            final id = '${v['quotaId']}';
            final limit = '${v['quotaValue'] ?? ''}';
            if (id.contains('PerDay') || limit == '0') daily = true;
          }
        }
      }
    } catch (_) {
      // Unknown shape: treat as a short per-minute limit.
    }
    return QuotaInfo(daily: daily, retryAfter: retry);
  }
}
