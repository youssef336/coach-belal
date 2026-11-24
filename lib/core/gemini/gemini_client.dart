import 'dart:convert';
import 'dart:typed_data';

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

  Future<String> _generate(Map<String, dynamic> body, {int attempt = 0}) async {
    if (apiKey.trim().isEmpty) {
      throw const CoachError('محتاج مفتاح Gemini الأول — من الإعدادات');
    }
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse('$_base/$model:generateContent'),
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
        return _generate(body, attempt: attempt + 1);
      }
      throw const CoachError('سيرفرات Google زحمة دلوقتي، جرّب بعد دقيقة');
    }
    if (res.statusCode == 429) {
      throw const CoachError('خلصت الحصة المجانية للنهارده أو للدقيقة دي، استنى شوية');
    }
    if (res.statusCode == 400 || res.statusCode == 403) {
      final body = res.body;
      if (body.contains('API_KEY') || body.contains('API key')) {
        throw const CoachError('مفتاح Gemini مش شغال، راجعه في الإعدادات');
      }
      throw const CoachError('الطلب ده مينفعش، جرّب صورة أو كلام أقصر');
    }
    if (res.statusCode == 404) {
      throw const CoachError('اسم الموديل غلط، غيّره من الإعدادات');
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
