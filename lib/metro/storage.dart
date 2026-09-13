import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MetroStorage {
  static const _key = 'cairo_metro_full_app_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<void> _pending = Future<void>.value();

  Future<Map<String, dynamic>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Saved app data has an invalid format.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<void> save(Map<String, dynamic> data) {
    // Encode immediately so later UI changes cannot mutate this write.
    final encoded = jsonEncode(data);

    // Queue writes to avoid an older selection overwriting a newer one.
    final next = _pending.then(
      (_) => _preferences.setString(_key, encoded),
    );

    // Keep future writes working even if one write fails.
    _pending = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );

    return next;
  }
}
