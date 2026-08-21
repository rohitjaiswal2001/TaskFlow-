import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedEntry {
  const CachedEntry({required this.payload, required this.savedAt});

  final Object? payload;
  final DateTime savedAt;
}

abstract interface class CacheStore {
  Future<CachedEntry?> read(String key);

  Future<void> write(String key, Object payload);

  Future<void> remove(String key);

  Future<void> clearAll();
}

class PrefsCacheStore implements CacheStore {
  PrefsCacheStore(this._prefs);

  static const _prefix = 'cache::';

  final SharedPreferences _prefs;

  @override
  Future<CachedEntry?> read(String key) async {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CachedEntry(
        payload: decoded['payload'],
        savedAt: DateTime.parse(decoded['saved_at'] as String),
      );
    } catch (_) {
      await remove(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object payload) async {
    final envelope = jsonEncode({
      'saved_at': DateTime.now().toIso8601String(),
      'payload': payload,
    });
    await _prefs.setString('$_prefix$key', envelope);
  }

  @override
  Future<void> remove(String key) async => _prefs.remove('$_prefix$key');

  @override
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

class InMemoryCacheStore implements CacheStore {
  final Map<String, CachedEntry> _entries = {};

  @override
  Future<void> clearAll() async => _entries.clear();

  @override
  Future<CachedEntry?> read(String key) async => _entries[key];

  @override
  Future<void> remove(String key) async => _entries.remove(key);

  @override
  Future<void> write(String key, Object payload) async {
    _entries[key] = CachedEntry(payload: payload, savedAt: DateTime.now());
  }
}

abstract final class CacheKeys {
  static String projects(String orgId) => 'projects.$orgId';

  static String tasks(String orgId, String? projectId) =>
      'tasks.$orgId.${projectId ?? 'all'}';

  static String members(String orgId) => 'members.$orgId';

  static String notifications(String userId) => 'notifications.$userId';
}
