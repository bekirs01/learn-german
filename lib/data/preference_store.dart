import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight key-value backend used by [UserPreferences].
///
/// Production uses [SharedPreferencesStore]. Tests inject
/// [MemoryPreferenceStore] so UI never talks to storage directly.
abstract interface class PreferenceStore {
  Object? read(String key);

  Future<void> write(String key, Object value);

  Future<void> remove(String key);
}

final class MemoryPreferenceStore implements PreferenceStore {
  MemoryPreferenceStore([Map<String, Object?>? seed])
    : _values = Map<String, Object?>.of(seed ?? const <String, Object?>{});

  final Map<String, Object?> _values;

  @override
  Object? read(String key) => _values[key];

  @override
  Future<void> write(String key, Object value) {
    _values[key] = value;
    return Future<void>.value();
  }

  @override
  Future<void> remove(String key) {
    _values.remove(key);
    return Future<void>.value();
  }
}

final class SharedPreferencesStore implements PreferenceStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Object? read(String key) => _prefs.get(key);

  @override
  Future<void> write(String key, Object value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
      return;
    }
    if (value is int) {
      await _prefs.setInt(key, value);
      return;
    }
    if (value is String) {
      await _prefs.setString(key, value);
      return;
    }
    if (value is List<String>) {
      await _prefs.setStringList(key, value);
      return;
    }
    if (value is List) {
      await _prefs.setStringList(key, <String>[
        for (final Object? item in value) item.toString(),
      ]);
    }
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
