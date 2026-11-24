import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Everything lives on the phone. Each record is stored as a JSON string so
/// the same code runs on Android (files) and the web PWA (IndexedDB).
class Storage {
  Storage._();

  static const _boxNames = ['profile', 'meals', 'workouts', 'weights', 'chat', 'settings', 'cache'];
  static final Map<String, Box<String>> _boxes = {};

  static Future<void> init() async {
    await Hive.initFlutter('coach_belal');
    for (final name in _boxNames) {
      _boxes[name] = await Hive.openBox<String>(name);
    }
  }

  static Box<String> box(String name) => _boxes[name]!;

  static Map<String, dynamic>? readMap(String boxName, String key) {
    final raw = box(boxName).get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> writeMap(String boxName, String key, Map<String, dynamic> value) =>
      box(boxName).put(key, jsonEncode(value));

  static List<Map<String, dynamic>> readAll(String boxName) => box(boxName).values
      .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
      .toList();

  static Future<void> delete(String boxName, String key) => box(boxName).delete(key);

  /// A full backup: every box, every record, as one JSON document.
  static String exportAll() {
    final out = <String, dynamic>{'app': 'coach_belal', 'version': 1};
    for (final name in _boxNames) {
      out[name] = Map<String, String>.from(box(name).toMap().cast<String, String>());
    }
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  static Future<void> importAll(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    if (data['app'] != 'coach_belal') {
      throw const FormatException('not a Coach Belal backup');
    }
    for (final name in _boxNames) {
      final records = data[name];
      if (records is! Map) continue;
      await box(name).clear();
      await box(name).putAll(records.map((k, v) => MapEntry(k as String, v as String)));
    }
  }

  static Future<void> wipe() async {
    for (final b in _boxes.values) {
      await b.clear();
    }
  }
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
