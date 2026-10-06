import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lingo_core/data/language_codes.dart';
import 'package:lingo_core/data/preference_store.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/domain/wrong_answers.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:lingo_core/data/preference_store.dart';

/// Central offline store for the small amount of user state Lingo products
/// actually need. Feature code must go through these methods, never the
/// underlying [PreferenceStore].
///
/// Values are hydrated once from disk and then served from memory so screens
/// can read without repeating I/O.
final class UserPreferences extends ChangeNotifier {
  UserPreferences({PreferenceStore? store})
    : _store = store ?? MemoryPreferenceStore() {
    _hydrate();
  }

  static const String defaultTranslationLanguage = 'en';
  static const int schemaVersion = 1;

  static const String _schemaVersionKey = 'lingo.user.schemaVersion';
  static const String _translationLanguageKey =
      'lingo.user.translationLanguage';
  static const String _favoriteWordIdsKey = 'lingo.user.favoriteWordIds';
  static const String _favoritePhraseIdsKey = 'lingo.user.favoritePhraseIds';
  static const String _learnedWordIdsKey = 'lingo.user.learnedWordIds';
  static const String _learnedPhraseIdsKey = 'lingo.user.learnedPhraseIds';
  static const String _wrongAnswersKey = 'lingo.user.wrongAnswers';
  static const String _soundEnabledKey = 'lingo.user.soundEnabled';
  static const String _hapticsEnabledKey = 'lingo.user.hapticsEnabled';
  static const String _watchDraftKey = 'lingo.user.watchDraft';

  /// Process-wide instance. [bootstrap] replaces it with device storage.
  static UserPreferences instance = UserPreferences();

  final PreferenceStore _store;
  Future<void> _writeChain = Future<void>.value();

  late String _translationLanguage;
  late LinkedHashSet<String> _favoriteWordIds;
  late LinkedHashSet<String> _favoritePhraseIds;
  late LinkedHashSet<String> _learnedWordIds;
  late LinkedHashSet<String> _learnedPhraseIds;
  late LinkedHashMap<String, WrongAnswerRecord> _wrongAnswers;
  late bool _soundEnabled;
  late bool _hapticsEnabled;
  late WatchCompanionDraft _watchDraft;

  Future<void> _enqueueWrite(Future<void> Function() action) {
    final Future<void> run = _writeChain.then((_) => action());
    _writeChain = run.catchError((Object _) => Future<void>.value());
    return run;
  }

  /// Loads the on-device key-value store. Falls back to memory if unavailable.
  static Future<UserPreferences> bootstrap() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      instance = UserPreferences(store: SharedPreferencesStore(prefs));
    } on Object {
      instance = UserPreferences();
    }
    return instance;
  }

  @visibleForTesting
  static void resetForTest({PreferenceStore? store}) {
    instance = UserPreferences(store: store ?? MemoryPreferenceStore());
  }

  @visibleForTesting
  Future<void> flushWrites() => _writeChain;

  String getSelectedTranslationLanguage() => _translationLanguage;

  /// Picks the stored language when it is still offered; otherwise English,
  /// then the first available code.
  String resolvedTranslationLanguage(Iterable<String> availableCodes) {
    final List<String> codes = <String>[
      for (final String code in availableCodes) code,
    ];
    if (codes.contains(_translationLanguage)) {
      return _translationLanguage;
    }
    if (codes.contains(defaultTranslationLanguage)) {
      return defaultTranslationLanguage;
    }
    return codes.isEmpty ? defaultTranslationLanguage : codes.first;
  }

  Future<void> setSelectedTranslationLanguage(String languageCode) {
    final String? normalized = _normalizeLanguageCode(languageCode);
    if (normalized == null || normalized == _translationLanguage) {
      return Future<void>.value();
    }
    _translationLanguage = normalized;
    notifyListeners();
    return _enqueueWrite(() => _write(_translationLanguageKey, normalized));
  }

  Set<String> getFavoriteWordIds() {
    return Set<String>.unmodifiable(_favoriteWordIds);
  }

  Future<void> addFavoriteWord(String id) {
    return _addFavorite(_favoriteWordIds, _favoriteWordIdsKey, id);
  }

  Future<void> removeFavoriteWord(String id) {
    return _removeFavorite(_favoriteWordIds, _favoriteWordIdsKey, id);
  }

  Set<String> getFavoritePhraseIds() {
    return Set<String>.unmodifiable(_favoritePhraseIds);
  }

  Future<void> addFavoritePhrase(String id) {
    return _addFavorite(_favoritePhraseIds, _favoritePhraseIdsKey, id);
  }

  Future<void> removeFavoritePhrase(String id) {
    return _removeFavorite(_favoritePhraseIds, _favoritePhraseIdsKey, id);
  }

  Set<String> getLearnedWordIds() {
    return Set<String>.unmodifiable(_learnedWordIds);
  }

  Future<void> addLearnedWord(String id) {
    return _addFavorite(_learnedWordIds, _learnedWordIdsKey, id);
  }

  Future<void> removeLearnedWord(String id) {
    return _removeFavorite(_learnedWordIds, _learnedWordIdsKey, id);
  }

  Set<String> getLearnedPhraseIds() {
    return Set<String>.unmodifiable(_learnedPhraseIds);
  }

  Future<void> addLearnedPhrase(String id) {
    return _addFavorite(_learnedPhraseIds, _learnedPhraseIdsKey, id);
  }

  Future<void> removeLearnedPhrase(String id) {
    return _removeFavorite(_learnedPhraseIds, _learnedPhraseIdsKey, id);
  }

  List<WrongAnswerRecord> getWrongAnswers() {
    return List<WrongAnswerRecord>.unmodifiable(_wrongAnswers.values);
  }

  int getWrongAnswerCount() => _wrongAnswers.length;

  WrongAnswerRecord? wrongAnswerById(String id) {
    final String? normalized = _normalizeId(id);
    if (normalized == null) {
      return null;
    }
    return _wrongAnswers[normalized];
  }

  /// Adds [contentId] or increments an existing miss. Never duplicates.
  Future<void> recordWrongAnswer({
    required String contentId,
    required QuizContentKind kind,
    QuizType? quizType,
    int? atMillis,
  }) {
    final String? id = _normalizeId(contentId);
    if (id == null) {
      return Future<void>.value();
    }
    final int stamp = atMillis ?? DateTime.now().millisecondsSinceEpoch;
    final WrongAnswerRecord? existing = _wrongAnswers[id];
    if (existing == null) {
      _wrongAnswers[id] = WrongAnswerRecord(
        contentId: id,
        kind: kind,
        wrongCount: 1,
        lastWrongAtMillis: stamp,
        lastQuizType: quizType,
      );
    } else {
      _wrongAnswers[id] = existing.incremented(
        quizType: quizType,
        atMillis: stamp,
      );
    }
    notifyListeners();
    return _enqueueWrite(_persistWrongAnswers);
  }

  /// Removes a stored miss after a later correct answer for the same ID.
  Future<void> recordCorrectAnswer(String contentId) {
    final String? id = _normalizeId(contentId);
    if (id == null || !_wrongAnswers.containsKey(id)) {
      return Future<void>.value();
    }
    _wrongAnswers.remove(id);
    notifyListeners();
    return _enqueueWrite(_persistWrongAnswers);
  }

  /// Drops miss records whose content IDs are no longer in the pack.
  Future<void> pruneUnknownWrongAnswers(Set<String> knownIds) {
    final LinkedHashMap<String, WrongAnswerRecord> next =
        LinkedHashMap<String, WrongAnswerRecord>();
    for (final MapEntry<String, WrongAnswerRecord> entry
        in _wrongAnswers.entries) {
      if (knownIds.contains(entry.key)) {
        next[entry.key] = entry.value;
      }
    }
    if (next.length == _wrongAnswers.length) {
      return Future<void>.value();
    }
    _wrongAnswers = next;
    notifyListeners();
    return _enqueueWrite(_persistWrongAnswers);
  }

  bool getSoundEnabled() => _soundEnabled;

  Future<void> setSoundEnabled(bool enabled) {
    if (_soundEnabled == enabled) {
      return Future<void>.value();
    }
    _soundEnabled = enabled;
    notifyListeners();
    return _enqueueWrite(() => _write(_soundEnabledKey, enabled));
  }

  bool getHapticsEnabled() => _hapticsEnabled;

  WatchCompanionDraft getWatchDraft() => _watchDraft;

  Future<void> setWatchDraft(WatchCompanionDraft draft) {
    _watchDraft = WatchCompanionDraft(
      filter: draft.filter,
      wordIds: Set<String>.unmodifiable(draft.wordIds),
      phraseIds: Set<String>.unmodifiable(draft.phraseIds),
      scheduleEnabled: draft.scheduleEnabled,
      windowStartMinutes: draft.windowStartMinutes,
      windowEndMinutes: draft.windowEndMinutes,
      deliveriesPerDay: draft.deliveriesPerDay,
      lastSyncOutcome: draft.lastSyncOutcome,
      lastSyncAtEpochMs: draft.lastSyncAtEpochMs,
      lastSyncedLearnerLanguage: draft.lastSyncedLearnerLanguage,
    );
    notifyListeners();
    return _enqueueWrite(_persistWatchDraft);
  }

  Future<void> setHapticsEnabled(bool enabled) {
    if (_hapticsEnabled == enabled) {
      return Future<void>.value();
    }
    _hapticsEnabled = enabled;
    notifyListeners();
    return _enqueueWrite(() => _write(_hapticsEnabledKey, enabled));
  }

  /// Drops favorite IDs that are no longer in the bundled catalog.
  Future<void> pruneUnknownFavorites({
    required Set<String> wordIds,
    required Set<String> phraseIds,
  }) {
    final LinkedHashSet<String> words = LinkedHashSet<String>.of(
      _favoriteWordIds.where(wordIds.contains),
    );
    final LinkedHashSet<String> phrases = LinkedHashSet<String>.of(
      _favoritePhraseIds.where(phraseIds.contains),
    );
    if (words.length == _favoriteWordIds.length &&
        phrases.length == _favoritePhraseIds.length) {
      return Future<void>.value();
    }
    _favoriteWordIds = words;
    _favoritePhraseIds = phrases;
    notifyListeners();
    return _enqueueWrite(() async {
      await _writeIdSet(_favoriteWordIdsKey, words);
      await _writeIdSet(_favoritePhraseIdsKey, phrases);
    });
  }

  /// Drops learned IDs that are no longer in the bundled catalog.
  Future<void> pruneUnknownLearned({
    required Set<String> wordIds,
    required Set<String> phraseIds,
  }) {
    final LinkedHashSet<String> words = LinkedHashSet<String>.of(
      _learnedWordIds.where(wordIds.contains),
    );
    final LinkedHashSet<String> phrases = LinkedHashSet<String>.of(
      _learnedPhraseIds.where(phraseIds.contains),
    );
    if (words.length == _learnedWordIds.length &&
        phrases.length == _learnedPhraseIds.length) {
      return Future<void>.value();
    }
    _learnedWordIds = words;
    _learnedPhraseIds = phrases;
    notifyListeners();
    return _enqueueWrite(() async {
      await _writeIdSet(_learnedWordIdsKey, words);
      await _writeIdSet(_learnedPhraseIdsKey, phrases);
    });
  }

  void _hydrate() {
    _translationLanguage = _readLanguage(_store.read(_translationLanguageKey));
    _favoriteWordIds = LinkedHashSet<String>.of(
      _readIdSet(_store.read(_favoriteWordIdsKey)),
    );
    _favoritePhraseIds = LinkedHashSet<String>.of(
      _readIdSet(_store.read(_favoritePhraseIdsKey)),
    );
    _learnedWordIds = LinkedHashSet<String>.of(
      _readIdSet(_store.read(_learnedWordIdsKey)),
    );
    _learnedPhraseIds = LinkedHashSet<String>.of(
      _readIdSet(_store.read(_learnedPhraseIdsKey)),
    );
    _wrongAnswers = _readWrongAnswers(_store.read(_wrongAnswersKey));
    _soundEnabled = _readBool(_store.read(_soundEnabledKey), true);
    _hapticsEnabled = _readBool(_store.read(_hapticsEnabledKey), true);
    _watchDraft = _readWatchDraft(_store.read(_watchDraftKey));
  }

  Future<void> _persistWatchDraft() {
    return _write(_watchDraftKey, jsonEncode(_watchDraft.toJson()));
  }

  WatchCompanionDraft _readWatchDraft(Object? raw) {
    if (raw is Map) {
      return WatchCompanionDraft.tryParse(raw);
    }
    if (raw is String) {
      try {
        return WatchCompanionDraft.tryParse(jsonDecode(raw));
      } on FormatException {
        return WatchCompanionDraft.initial;
      }
    }
    return WatchCompanionDraft.initial;
  }

  Future<void> _persistWrongAnswers() {
    return _write(
      _wrongAnswersKey,
      jsonEncode(<Map<String, Object?>>[
        for (final WrongAnswerRecord record in _wrongAnswers.values)
          record.toJson(),
      ]),
    );
  }

  LinkedHashMap<String, WrongAnswerRecord> _readWrongAnswers(Object? raw) {
    final LinkedHashMap<String, WrongAnswerRecord> records =
        LinkedHashMap<String, WrongAnswerRecord>();
    final List<Object?>? items = _asObjectList(raw);
    if (items == null) {
      return records;
    }
    for (final Object? item in items) {
      final WrongAnswerRecord? record = WrongAnswerRecord.tryParse(item);
      if (record == null || records.containsKey(record.contentId)) {
        continue;
      }
      records[record.contentId] = record;
    }
    return records;
  }

  List<Object?>? _asObjectList(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is List) {
      return List<Object?>.from(raw);
    }
    if (raw is String) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is List) {
          return List<Object?>.from(decoded);
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  Future<void> _addFavorite(LinkedHashSet<String> ids, String key, String id) {
    final String? normalized = _normalizeId(id);
    if (normalized == null || !ids.add(normalized)) {
      return Future<void>.value();
    }
    notifyListeners();
    return _enqueueWrite(() => _writeIdSet(key, Set<String>.unmodifiable(ids)));
  }

  Future<void> _removeFavorite(
    LinkedHashSet<String> ids,
    String key,
    String id,
  ) {
    final String? normalized = _normalizeId(id);
    if (normalized == null || !ids.remove(normalized)) {
      return Future<void>.value();
    }
    notifyListeners();
    return _enqueueWrite(() => _writeIdSet(key, Set<String>.unmodifiable(ids)));
  }

  Future<void> _writeIdSet(String key, Set<String> ids) {
    return _write(key, List<String>.unmodifiable(ids));
  }

  Future<void> _write(String key, Object value) async {
    await _ensureSchemaVersion();
    await _store.write(key, value);
  }

  Future<void> _ensureSchemaVersion() async {
    final Object? raw = _store.read(_schemaVersionKey);
    if (raw is int && raw >= schemaVersion) {
      return;
    }
    await _store.write(_schemaVersionKey, schemaVersion);
  }

  String _readLanguage(Object? raw) {
    return _normalizeLanguageCode(raw) ?? defaultTranslationLanguage;
  }

  String? _normalizeLanguageCode(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final String trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty || !isSupportedLanguageCode(trimmed)) {
      return null;
    }
    return trimmed;
  }

  Set<String> _readIdSet(Object? raw) {
    final List<String>? values = _asStringList(raw);
    if (values == null) {
      return <String>{};
    }
    final Set<String> ids = <String>{};
    for (final String value in values) {
      final String? id = _normalizeId(value);
      if (id != null) {
        ids.add(id);
      }
    }
    return ids;
  }

  List<String>? _asStringList(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is List) {
      return <String>[
        for (final Object? item in raw)
          if (item is String) item,
      ];
    }
    if (raw is String) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is List) {
          return <String>[
            for (final Object? item in decoded)
              if (item is String) item,
          ];
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  String? _normalizeId(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final String id = raw.trim();
    if (id.isEmpty) {
      return null;
    }
    return id;
  }

  bool _readBool(Object? raw, bool fallback) {
    if (raw is bool) {
      return raw;
    }
    return fallback;
  }
}
