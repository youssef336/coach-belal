import 'dart:convert';

import 'package:coach_belal/core/gemini/gemini_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _quota429({String quotaId = 'GenerateRequestsPerDayPerProjectPerModel-FreeTier', String? retry}) => jsonEncode({
  'error': {
    'code': 429,
    'status': 'RESOURCE_EXHAUSTED',
    'details': [
      {
        '@type': 'type.googleapis.com/google.rpc.QuotaFailure',
        'violations': [
          {'quotaId': quotaId, 'quotaValue': '20'},
        ],
      },
      if (retry != null) {'@type': 'type.googleapis.com/google.rpc.RetryInfo', 'retryDelay': retry},
    ],
  },
});

final _ok = jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': 'أهلًا'},
        ],
      },
    },
  ],
});

String _modelOf(http.Request r) => r.url.pathSegments.last.split(':').first;

Future<String> _ask(GeminiClient c) => c.text(
  system: 's',
  turns: const [
    GeminiTurn('user', [GeminiPart.text('hi')]),
  ],
);

void main() {
  setUp(GeminiClient.resetQuotaMemory);

  test('daily quota on one model falls back to the next model', () async {
    final hits = <String>[];
    final c = GeminiClient(
      apiKey: 'k',
      model: 'gemini-flash-latest',
      httpClient: MockClient((r) async {
        hits.add(_modelOf(r));
        return _modelOf(r) == 'gemini-flash-latest' ? http.Response(_quota429(), 429) : http.Response.bytes(utf8.encode(_ok), 200);
      }),
    );
    expect(await _ask(c), 'أهلًا');
    expect(hits, ['gemini-flash-latest', 'gemini-2.5-flash']);

    // The exhausted model is skipped on the next call.
    hits.clear();
    await _ask(c);
    expect(hits, ['gemini-2.5-flash']);
  });

  test('short per-minute limit is waited out on the same model', () async {
    var n = 0;
    final c = GeminiClient(
      apiKey: 'k',
      model: 'gemini-2.5-flash',
      httpClient: MockClient((r) async {
        n++;
        return n == 1
            ? http.Response(_quota429(quotaId: 'GenerateRequestsPerMinutePerProjectPerModel-FreeTier', retry: '0.01s'), 429)
            : http.Response.bytes(utf8.encode(_ok), 200);
      }),
    );
    expect(await _ask(c), 'أهلًا');
    expect(n, 2);
  });

  test('every model out of daily quota gives the daily message', () async {
    final c = GeminiClient(
      apiKey: 'k',
      model: 'gemini-2.5-flash',
      httpClient: MockClient((r) async => http.Response(_quota429(), 429)),
    );
    expect(
      _ask(c),
      throwsA(isA<CoachError>().having((e) => e.message, 'message', contains('النهارده'))),
    );
  });

  test('QuotaInfo reads retryDelay and per-day ids', () {
    final q = QuotaInfo.parse(_quota429(quotaId: 'PerMinute', retry: '7.5s'));
    expect(q.daily, isFalse);
    expect(q.retryAfter, const Duration(milliseconds: 7500));
    expect(QuotaInfo.parse(_quota429()).daily, isTrue);
    expect(QuotaInfo.parse('not json').daily, isFalse);
  });
}
