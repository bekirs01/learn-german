import 'package:flutter/foundation.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_keys.dart';
import 'package:lingo_core/core/l10n/ui_tables.dart';

/// Built-in learner-language tables for application chrome.
///
/// Content meanings stay in translation bundles. Screens look up [UiKeys]
/// here so a future language can be added without rewriting widgets.
abstract final class UiCatalog {
  static const String fallbackLanguageCode = LearnerLanguages.fallbackCode;

  static final Map<String, Map<String, String>> _builtin = builtInUiTables();

  static final Map<String, Map<String, String>> _extra =
      <String, Map<String, String>>{};

  static Iterable<String> get languageCodes {
    return <String>{
      ...LearnerLanguages.orderedCodes,
      ..._builtin.keys,
      ..._extra.keys,
    };
  }

  static Map<String, String> stringsFor(String languageCode) {
    return Map<String, String>.unmodifiable(
      _table(languageCode) ?? const <String, String>{},
    );
  }

  /// True when a built-in or registered UI table exists for [languageCode].
  static bool hasTable(String languageCode) {
    return _table(languageCode) != null;
  }

  /// Chrome keys that are missing or blank in the table for [languageCode].
  static List<String> missingChromeKeys(String languageCode) {
    final Map<String, String> table =
        _table(languageCode) ?? const <String, String>{};
    return <String>[
      for (final String key in UiKeys.chrome)
        if (_usable(table[key]) == null) key,
    ];
  }

  /// Resolves [key] from an optional pack overlay, then [languageCode], then
  /// English, then a readable fallback.
  static String resolve(
    String key, {
    String? languageCode,
    Map<String, String> overlay = const <String, String>{},
    Map<String, String> params = const <String, String>{},
  }) {
    final String? packed = _usable(overlay[key]);
    if (packed != null) {
      return _apply(packed, params);
    }
    final String? requested = _usable(_lookup(languageCode, key));
    if (requested != null) {
      return _apply(requested, params);
    }
    final String? english = _usable(_lookup(fallbackLanguageCode, key));
    if (english != null) {
      return _apply(english, params);
    }
    return _apply(_readableFallback(key), params);
  }

  static bool has(
    String key, {
    String? languageCode,
    Map<String, String> overlay = const <String, String>{},
  }) {
    return _usable(overlay[key]) != null ||
        _usable(_lookup(languageCode, key)) != null ||
        _usable(_lookup(fallbackLanguageCode, key)) != null;
  }

  static void register(String languageCode, Map<String, String> strings) {
    final String code = LearnerLanguages.baseCode(languageCode);
    if (code.isEmpty) {
      return;
    }
    _extra[code] = Map<String, String>.unmodifiable(strings);
  }

  @visibleForTesting
  static void resetForTest() {
    _extra.clear();
  }

  static Map<String, String>? _table(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return null;
    }
    final String code = LearnerLanguages.baseCode(languageCode);
    return _extra[code] ?? _builtin[code];
  }

  static String? _lookup(String? languageCode, String key) {
    return _table(languageCode)?[key];
  }

  static String? _usable(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _apply(String template, Map<String, String> params) {
    String result = template;
    params.forEach((String name, String value) {
      result = result.replaceAll('{$name}', value);
    });
    return result;
  }

  static String _readableFallback(String key) {
    final int dot = key.lastIndexOf('.');
    final String leaf = dot >= 0 && dot < key.length - 1
        ? key.substring(dot + 1)
        : key;
    final String spaced = leaf.replaceAll('_', ' ').trim();
    if (spaced.isEmpty) {
      return key;
    }
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
