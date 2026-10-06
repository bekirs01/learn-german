import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lingo_core/core/audio/expected_audio.dart';
import 'package:lingo_core/data/content_asset_paths.dart';
import 'package:lingo_core/data/content_json.dart';
import 'package:lingo_core/data/language_pack_validator.dart';
import 'package:lingo_core/data/product_config_json.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/validation.dart';

final class LocalContentRepository implements ContentRepository {
  LocalContentRepository({
    required ProductConfig product,
    required LanguagePack pack,
    required List<AlphabetUnit> alphabet,
    required List<ContentCategory> wordCategories,
    required List<ContentCategory> phraseCategories,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required List<TranslationBundle> translationBundles,
    ValidationReport validation = ValidationReport.empty,
  }) : _product = product,
       _pack = pack,
       _alphabet = alphabet,
       _wordCategories = wordCategories,
       _phraseCategories = phraseCategories,
       _words = words,
       _phrases = phrases,
       _translationBundles = translationBundles,
       _alphabetById = <String, AlphabetUnit>{
         for (final AlphabetUnit unit in alphabet) unit.id: unit,
       },
       _wordCategoriesById = <String, ContentCategory>{
         for (final ContentCategory category in wordCategories)
           category.id: category,
       },
       _phraseCategoriesById = <String, ContentCategory>{
         for (final ContentCategory category in phraseCategories)
           category.id: category,
       },
       _wordsById = <String, WordEntry>{
         for (final WordEntry word in words) word.id: word,
       },
       _phrasesById = <String, PhraseEntry>{
         for (final PhraseEntry phrase in phrases) phrase.id: phrase,
       },
       _wordsByCategory = _groupWords(words),
       _phrasesByCategory = _groupPhrases(phrases),
       _translationsByLanguage = <String, Map<String, String>>{
         for (final TranslationBundle bundle in translationBundles)
           bundle.languageCode: bundle.strings,
       },
       _favoriteIds = <String>{},
       _learnedIds = <String>{},
       _validation = validation {
    _restoreFavorites();
    _restoreLearned();
  }

  final ProductConfig _product;
  final LanguagePack _pack;
  final List<AlphabetUnit> _alphabet;
  final List<ContentCategory> _wordCategories;
  final List<ContentCategory> _phraseCategories;
  final List<WordEntry> _words;
  final List<PhraseEntry> _phrases;
  final List<TranslationBundle> _translationBundles;
  final Map<String, AlphabetUnit> _alphabetById;
  final Map<String, ContentCategory> _wordCategoriesById;
  final Map<String, ContentCategory> _phraseCategoriesById;
  final Map<String, WordEntry> _wordsById;
  final Map<String, PhraseEntry> _phrasesById;
  final Map<String, List<WordEntry>> _wordsByCategory;
  final Map<String, List<PhraseEntry>> _phrasesByCategory;
  final Map<String, Map<String, String>> _translationsByLanguage;
  final Set<String> _favoriteIds;
  final Set<String> _learnedIds;
  final ValidationReport _validation;

  static LocalContentRepository? _cached;
  static Future<LocalContentRepository>? _inFlight;

  static LocalContentRepository? get cached => _cached;

  @visibleForTesting
  static void clearCache() {
    _cached = null;
    _inFlight = null;
    ProductConfig.reset();
  }

  static Future<LocalContentRepository> load({AssetBundle? bundle}) {
    if (bundle != null) {
      return _read(bundle);
    }
    final LocalContentRepository? cached = _cached;
    if (cached != null) {
      cached.syncFavoritesFromPreferences();
      cached.syncLearnedFromPreferences();
      return cached._pruneStoredUserState().then((_) => cached);
    }
    final Future<LocalContentRepository>? inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final Future<LocalContentRepository> loading = _read(rootBundle).then((
      LocalContentRepository repo,
    ) {
      _cached = repo;
      return repo;
    });
    _inFlight = loading;
    return loading.whenComplete(() {
      _inFlight = null;
    });
  }

  static Future<LocalContentRepository> _read(AssetBundle assets) async {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final ProductConfig product = await _loadProduct(assets, issues);
    ProductConfig.bind(product);
    final ContentAssetPaths paths = ContentAssetPaths(product.contentPackPath);

    final List<String> payloads = await Future.wait(<Future<String>>[
      _loadString(assets, paths.languagePack, issues, '{}'),
      _loadString(assets, paths.alphabet, issues, '{"units":[]}'),
      _loadString(assets, paths.wordCategories, issues, '{"items":[]}'),
      _loadString(assets, paths.words, issues, '{"items":[]}'),
      _loadString(assets, paths.phraseCategories, issues, '{"items":[]}'),
      _loadString(assets, paths.phrases, issues, '{"items":[]}'),
    ]);

    LanguagePack pack;
    try {
      pack = parseLanguagePack(_decode(payloads[0]), product, issues);
    } on FormatException {
      issues.add(
        const ValidationIssue(
          code: ValidationCodes.malformedEntry,
          message: 'language_pack.json is malformed.',
        ),
      );
      pack = parseLanguagePack(<String, Object?>{}, product, issues);
    }
    final List<ContentCategory> wordCategories = parseCategories(
      _decode(payloads[2]),
      pack,
      'word_categories',
      issues,
    );
    final List<ContentCategory> phraseCategories = parseCategories(
      _decode(payloads[4]),
      pack,
      'phrase_categories',
      issues,
    );
    final List<WordEntry> words = parseWords(
      _decode(payloads[3]),
      pack,
      <String>{
        for (final ContentCategory category in wordCategories) category.id,
      },
      issues,
    );
    final List<PhraseEntry> phrases = parsePhrases(
      _decode(payloads[5]),
      pack,
      <String>{
        for (final ContentCategory category in phraseCategories) category.id,
      },
      issues,
    );
    final List<AlphabetUnit> alphabet = pack.hasAlphabet
        ? parseAlphabet(_decode(payloads[1]), pack, issues)
        : const <AlphabetUnit>[];

    final List<String> translationCodes = pack.translationLanguageCodes.isEmpty
        ? <String>[pack.defaultTranslationLanguageCode]
        : pack.translationLanguageCodes;
    final List<TranslationBundle> bundles = <TranslationBundle>[];
    for (final String code in translationCodes) {
      try {
        final String raw = await assets.loadString(paths.translation(code));
        bundles.add(parseTranslationBundle(_decode(raw), issues));
      } on Object catch (_) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.missingTranslation,
            message: 'Could not load translation file for "$code".',
            id: code,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    final List<TranslationBundle> frozenBundles =
        List<TranslationBundle>.unmodifiable(bundles);
    final ValidationReport report = LanguagePackValidator.validate(
      product: product,
      pack: pack,
      alphabet: alphabet,
      wordCategories: wordCategories,
      phraseCategories: phraseCategories,
      words: words,
      phrases: phrases,
      translations: frozenBundles,
      parseIssues: issues,
    );

    final LocalContentRepository repo = LocalContentRepository(
      product: product,
      pack: pack,
      alphabet: alphabet,
      wordCategories: wordCategories,
      phraseCategories: phraseCategories,
      words: words,
      phrases: phrases,
      translationBundles: frozenBundles,
      validation: report,
    );
    await repo._pruneStoredUserState();
    return repo;
  }

  static Future<ProductConfig> _loadProduct(
    AssetBundle assets,
    List<ValidationIssue> issues,
  ) async {
    try {
      final String raw = await assets.loadString(ProductConfig.assetPath);
      return parseProductConfig(_decode(raw), issues);
    } on Object catch (_) {
      issues.add(
        const ValidationIssue(
          code: ValidationCodes.malformedEntry,
          message:
              'Product configuration was missing or unreadable; using fallback.',
          severity: ValidationSeverity.warning,
        ),
      );
      return ProductConfig.fallback;
    }
  }

  static Future<String> _loadString(
    AssetBundle assets,
    String path,
    List<ValidationIssue> issues,
    String fallback,
  ) async {
    try {
      return await assets.loadString(path);
    } on Object catch (_) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.malformedEntry,
          message: 'Missing content file "$path".',
          severity: ValidationSeverity.warning,
        ),
      );
      return fallback;
    }
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return <String, Object?>{};
    }
  }

  static Map<String, List<WordEntry>> _groupWords(List<WordEntry> words) {
    final Map<String, List<WordEntry>> grouped = <String, List<WordEntry>>{};
    for (final WordEntry word in words) {
      grouped.putIfAbsent(word.categoryId, () => <WordEntry>[]).add(word);
    }
    return grouped.map(
      (String key, List<WordEntry> value) => MapEntry<String, List<WordEntry>>(
        key,
        List<WordEntry>.unmodifiable(value),
      ),
    );
  }

  static Map<String, List<PhraseEntry>> _groupPhrases(
    List<PhraseEntry> phrases,
  ) {
    final Map<String, List<PhraseEntry>> grouped =
        <String, List<PhraseEntry>>{};
    for (final PhraseEntry phrase in phrases) {
      grouped.putIfAbsent(phrase.categoryId, () => <PhraseEntry>[]).add(phrase);
    }
    return grouped.map(
      (String key, List<PhraseEntry> value) =>
          MapEntry<String, List<PhraseEntry>>(
            key,
            List<PhraseEntry>.unmodifiable(value),
          ),
    );
  }

  @override
  ProductConfig get product => _product;

  @override
  bool get pronunciationEnabled => _product.featureFlags.audio;

  @override
  String? pronunciationAssetFor(String id) {
    final String languageCode = ExpectedAudio.languageFolderOf(_product);
    final AlphabetUnit? unit = _alphabetById[id];
    if (unit != null) {
      return ExpectedAudio.resolveDeclaredOrExpected(
        declared: unit.audioAsset,
        contentId: unit.id,
        languageCode: languageCode,
      );
    }
    final WordEntry? word = _wordsById[id];
    if (word != null) {
      return ExpectedAudio.resolveDeclaredOrExpected(
        declared: word.audioAsset,
        contentId: word.id,
        languageCode: languageCode,
      );
    }
    final PhraseEntry? phrase = _phrasesById[id];
    if (phrase != null) {
      return ExpectedAudio.resolveDeclaredOrExpected(
        declared: phrase.audioAsset,
        contentId: phrase.id,
        languageCode: languageCode,
      );
    }
    return ExpectedAudio.pathForId(id, languageCode: languageCode);
  }

  @override
  LanguagePack get pack => _pack;

  @override
  List<AlphabetUnit> get alphabet => _alphabet;

  @override
  List<ContentCategory> get wordCategories => _wordCategories;

  @override
  List<ContentCategory> get phraseCategories => _phraseCategories;

  @override
  List<TranslationBundle> get translationBundles => _translationBundles;

  @override
  ValidationReport get validation => _validation;

  @override
  Set<String> get favoriteIds => Set<String>.unmodifiable(_favoriteIds);

  @override
  Set<String> get learnedIds => Set<String>.unmodifiable(_learnedIds);

  @override
  List<WordEntry> wordsForCategory(String categoryId) {
    return _wordsByCategory[categoryId] ?? const <WordEntry>[];
  }

  @override
  List<PhraseEntry> phrasesForCategory(String categoryId) {
    return _phrasesByCategory[categoryId] ?? const <PhraseEntry>[];
  }

  @override
  AlphabetUnit? alphabetUnitById(String id) => _alphabetById[id];

  @override
  WordEntry? wordById(String id) => _wordsById[id];

  @override
  PhraseEntry? phraseById(String id) => _phrasesById[id];

  @override
  ContentCategory? wordCategoryById(String id) => _wordCategoriesById[id];

  @override
  ContentCategory? phraseCategoryById(String id) => _phraseCategoriesById[id];

  @override
  String? translation(String id, {String? languageCode}) {
    final String code = languageCode ?? _pack.defaultTranslationLanguageCode;
    final String? direct = _usable(_translationsByLanguage[code]?[id]);
    if (direct != null) {
      return direct;
    }
    if (code == _pack.defaultTranslationLanguageCode) {
      return null;
    }
    return _usable(
      _translationsByLanguage[_pack.defaultTranslationLanguageCode]?[id],
    );
  }

  static String? _usable(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  String labelFor(String id, String fallback, {String? languageCode}) {
    return translation(id, languageCode: languageCode) ?? fallback;
  }

  @override
  bool isFavorite(String id) => _favoriteIds.contains(id);

  @override
  void setFavorite(String id, bool value) {
    final bool isWord = _wordsById.containsKey(id);
    final bool isPhrase = _phrasesById.containsKey(id);
    if (!isWord && !isPhrase) {
      return;
    }
    final UserPreferences prefs = UserPreferences.instance;
    if (value) {
      _favoriteIds.add(id);
      if (isWord) {
        unawaited(prefs.addFavoriteWord(id));
      } else {
        unawaited(prefs.addFavoritePhrase(id));
      }
    } else {
      _favoriteIds.remove(id);
      if (isWord) {
        unawaited(prefs.removeFavoriteWord(id));
      } else {
        unawaited(prefs.removeFavoritePhrase(id));
      }
    }
  }

  @override
  bool isLearned(String id) => _learnedIds.contains(id);

  @override
  void setLearned(String id, bool value) {
    final bool isWord = _wordsById.containsKey(id);
    final bool isPhrase = _phrasesById.containsKey(id);
    if (!isWord && !isPhrase) {
      return;
    }
    final UserPreferences prefs = UserPreferences.instance;
    if (value) {
      _learnedIds.add(id);
      if (isWord) {
        unawaited(prefs.addLearnedWord(id));
      } else {
        unawaited(prefs.addLearnedPhrase(id));
      }
    } else {
      _learnedIds.remove(id);
      if (isWord) {
        unawaited(prefs.removeLearnedWord(id));
      } else {
        unawaited(prefs.removeLearnedPhrase(id));
      }
    }
  }

  void _restoreFavorites() {
    final UserPreferences prefs = UserPreferences.instance;
    final Set<String> knownWords = _wordsById.keys.toSet();
    final Set<String> knownPhrases = _phrasesById.keys.toSet();
    _favoriteIds
      ..addAll(prefs.getFavoriteWordIds().intersection(knownWords))
      ..addAll(prefs.getFavoritePhraseIds().intersection(knownPhrases));
  }

  void _restoreLearned() {
    final UserPreferences prefs = UserPreferences.instance;
    final Set<String> knownWords = _wordsById.keys.toSet();
    final Set<String> knownPhrases = _phrasesById.keys.toSet();
    _learnedIds
      ..addAll(prefs.getLearnedWordIds().intersection(knownWords))
      ..addAll(prefs.getLearnedPhraseIds().intersection(knownPhrases));
  }

  void syncFavoritesFromPreferences() {
    _favoriteIds.clear();
    _restoreFavorites();
  }

  void syncLearnedFromPreferences() {
    _learnedIds.clear();
    _restoreLearned();
  }

  Future<void> _pruneStoredUserState() async {
    await _pruneStoredFavorites();
    await _pruneStoredLearned();
    await UserPreferences.instance.pruneUnknownWrongAnswers(_knownContentIds());
  }

  Set<String> _knownContentIds() {
    return <String>{
      ..._alphabetById.keys,
      ..._wordsById.keys,
      ..._phrasesById.keys,
    };
  }

  Future<void> _pruneStoredFavorites() {
    return UserPreferences.instance.pruneUnknownFavorites(
      wordIds: _wordsById.keys.toSet(),
      phraseIds: _phrasesById.keys.toSet(),
    );
  }

  Future<void> _pruneStoredLearned() {
    return UserPreferences.instance.pruneUnknownLearned(
      wordIds: _wordsById.keys.toSet(),
      phraseIds: _phrasesById.keys.toSet(),
    );
  }

  @override
  List<QuizReadyItem> get quizItems {
    final String languageCode = ExpectedAudio.languageFolderOf(_product);
    final List<QuizReadyItem> items = <QuizReadyItem>[
      for (final AlphabetUnit unit in _alphabet)
        if (unit.quizEnabled)
          QuizReadyItem(
            id: unit.id,
            kind: QuizContentKind.alphabet,
            prompt: unit.glyph,
            pronunciation: unit.pronunciation,
            romanization: unit.romanization,
            imageAsset: unit.imageAsset,
            audioAsset: ExpectedAudio.resolveDeclaredOrExpected(
              declared: unit.audioAsset,
              contentId: unit.id,
              languageCode: languageCode,
            ),
            answersByLanguage: _answersFor(unit.id, extra: unit.pronunciation),
          ),
      for (final WordEntry word in _words)
        if (word.quizEnabled)
          QuizReadyItem(
            id: word.id,
            kind: QuizContentKind.word,
            prompt: word.text,
            pronunciation: word.pronunciation,
            romanization: word.romanization,
            imageAsset: word.imageAsset,
            audioAsset: ExpectedAudio.resolveDeclaredOrExpected(
              declared: word.audioAsset,
              contentId: word.id,
              languageCode: languageCode,
            ),
            answersByLanguage: _answersFor(word.id),
          ),
      for (final PhraseEntry phrase in _phrases)
        if (phrase.quizEnabled)
          QuizReadyItem(
            id: phrase.id,
            kind: QuizContentKind.phrase,
            prompt: phrase.text,
            pronunciation: phrase.pronunciation,
            romanization: phrase.romanization,
            imageAsset: phrase.imageAsset,
            audioAsset: ExpectedAudio.resolveDeclaredOrExpected(
              declared: phrase.audioAsset,
              contentId: phrase.id,
              languageCode: languageCode,
            ),
            answersByLanguage: _answersFor(phrase.id),
          ),
    ];
    return List<QuizReadyItem>.unmodifiable(items);
  }

  Map<String, String> _answersFor(String id, {String? extra}) {
    final Map<String, String> answers = <String, String>{};
    for (final TranslationBundle bundle in _translationBundles) {
      final String? value = bundle.strings[id];
      if (value != null) {
        answers[bundle.languageCode] = value;
      }
    }
    if (extra != null && extra.isNotEmpty) {
      answers.putIfAbsent('pronunciation', () => extra);
    }
    return Map<String, String>.unmodifiable(answers);
  }
}
