import 'package:lingo_core/core/audio/speech_text.dart';
import 'package:lingo_core/core/audio/target_speech_locale.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/product_config.dart';

/// Curriculum kind that owns a bundled pronunciation file.
enum ExpectedAudioKind { alphabet, words, phrases }

/// One deterministic pronunciation recording the pipeline must eventually ship.
final class ExpectedAudioItem {
  const ExpectedAudioItem({
    required this.contentId,
    required this.kind,
    required this.audioKey,
    required this.filename,
    required this.assetPath,
    this.speechText,
    this.declaredAudioAsset,
  });

  final String contentId;
  final ExpectedAudioKind kind;

  /// Stable lookup key. Always the content ID in this product.
  final String audioKey;
  final String filename;
  final String assetPath;
  final String? speechText;

  /// Pack-declared `audioAsset` when present. May differ from [assetPath].
  final String? declaredAudioAsset;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'contentId': contentId,
      'kind': kind.name,
      'audioKey': audioKey,
      'filename': filename,
      'assetPath': assetPath,
      'speechText': speechText,
      if (declaredAudioAsset != null) 'declaredAudioAsset': declaredAudioAsset,
    };
  }
}

/// Structural problems in the expected-audio map. Missing WAV files are
/// reported separately so the next generation phase can fill them.
final class ExpectedAudioIssues {
  const ExpectedAudioIssues({
    this.duplicateAudioKeys = const <String>[],
    this.filenameCollisions = const <String>[],
    this.invalidCharacters = const <String>[],
    this.missingMappings = const <String>[],
    this.orphanDeclaredAssets = const <String>[],
  });

  final List<String> duplicateAudioKeys;
  final List<String> filenameCollisions;
  final List<String> invalidCharacters;
  final List<String> missingMappings;
  final List<String> orphanDeclaredAssets;

  bool get isEmpty {
    return duplicateAudioKeys.isEmpty &&
        filenameCollisions.isEmpty &&
        invalidCharacters.isEmpty &&
        missingMappings.isEmpty &&
        orphanDeclaredAssets.isEmpty;
  }

  Map<String, List<String>> toJson() {
    return <String, List<String>>{
      'duplicateAudioKeys': duplicateAudioKeys,
      'filenameCollisions': filenameCollisions,
      'invalidCharacters': invalidCharacters,
      'missingMappings': missingMappings,
      'orphanDeclaredAssets': orphanDeclaredAssets,
    };
  }
}

final class ExpectedAudioInventory {
  const ExpectedAudioInventory({
    required this.locale,
    required this.languageCode,
    required this.items,
    required this.issues,
  });

  final String locale;
  final String languageCode;
  final List<ExpectedAudioItem> items;
  final ExpectedAudioIssues issues;

  int get count => items.length;

  bool get isStructurallyValid => issues.isEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'languageCode': languageCode,
      'extension': ExpectedAudio.extension,
      'provider': 'native_tts',
      'voice': <String, Object?>{
        'preferredVoiceName':
            ProductConfig.current.speechProfile.preferredVoiceName,
        'preferredVoiceNames':
            ProductConfig.current.speechProfile.preferredVoiceNames,
        'preferredGender':
            ProductConfig.current.speechProfile.preferredGender.name,
        'rate': ProductConfig.current.speechProfile.resolvedRate,
        'pitch': ProductConfig.current.speechProfile.resolvedPitch,
      },
      'count': count,
      'items': <Map<String, Object?>>[
        for (final ExpectedAudioItem item in items) item.toJson(),
      ],
      'issues': issues.toJson(),
    };
  }
}

/// Deterministic German (or cloned-language) pronunciation paths.
///
/// Filenames are ASCII because content IDs are ASCII. German letters in
/// `text` / `speechText` stay in metadata and are never used as filenames.
abstract final class ExpectedAudio {
  static const String extension = 'wav';
  static const String root = 'assets/audio';

  static final RegExp _filenameChar = RegExp(r'[a-zA-Z0-9._-]');

  /// BCP-47 tag the recordings and TTS must use.
  static String localeOf(ProductConfig product) {
    return TargetSpeechLocale.resolve(product: product);
  }

  /// Folder segment under [root]. `de-DE` → `de`.
  static String languageFolderOf(ProductConfig product) {
    return TargetSpeechLocale.languageCode(localeOf(product));
  }

  static ExpectedAudioKind? kindForId(String contentId) {
    if (contentId.startsWith('letter.')) {
      return ExpectedAudioKind.alphabet;
    }
    if (contentId.startsWith('word.')) {
      return ExpectedAudioKind.words;
    }
    if (contentId.startsWith('phrase.')) {
      return ExpectedAudioKind.phrases;
    }
    return null;
  }

  /// ASCII filename for a content ID. Umlauts and ß in spoken text stay
  /// out of the path; IDs are already ASCII in this pack.
  static String filenameFor(String contentId) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in contentId.runes) {
      final String character = String.fromCharCode(rune);
      if (_filenameChar.hasMatch(character)) {
        buffer.write(character);
      } else {
        buffer.write('_');
      }
    }
    final String stem = buffer.toString();
    if (stem.isEmpty) {
      return 'item.$extension';
    }
    return '$stem.$extension';
  }

  static bool hasValidFilenameCharacters(String contentId) {
    if (contentId.trim().isEmpty) {
      return false;
    }
    return filenameFor(contentId) == '$contentId.$extension';
  }

  static String? pathForId(String contentId, {String? languageCode}) {
    final ExpectedAudioKind? kind = kindForId(contentId);
    if (kind == null) {
      return null;
    }
    return pathForKind(kind, contentId, languageCode: languageCode);
  }

  static String pathForKind(
    ExpectedAudioKind kind,
    String contentId, {
    String? languageCode,
  }) {
    final String folder =
        languageCode ?? languageFolderOf(ProductConfig.current);
    return '$root/$folder/${kind.name}/${filenameFor(contentId)}';
  }

  /// Declared pack path wins. Otherwise the deterministic expected path.
  static String? resolveDeclaredOrExpected({
    required String? declared,
    required String contentId,
    String? languageCode,
  }) {
    final String? trimmed = declared?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return pathForId(contentId, languageCode: languageCode);
  }

  static ExpectedAudioInventory build({
    required ProductConfig product,
    required List<AlphabetUnit> alphabet,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
  }) {
    final String locale = localeOf(product);
    final String languageCode = languageFolderOf(product);
    final List<ExpectedAudioItem> items = <ExpectedAudioItem>[
      for (final AlphabetUnit unit in alphabet)
        ExpectedAudioItem(
          contentId: unit.id,
          kind: ExpectedAudioKind.alphabet,
          audioKey: unit.id,
          filename: filenameFor(unit.id),
          assetPath: pathForKind(
            ExpectedAudioKind.alphabet,
            unit.id,
            languageCode: languageCode,
          ),
          speechText:
              SpeechTextNormalizer.clean(unit.speechText) ??
              SpeechTextNormalizer.clean(unit.glyph),
          declaredAudioAsset: _usable(unit.audioAsset),
        ),
      for (final WordEntry word in words)
        ExpectedAudioItem(
          contentId: word.id,
          kind: ExpectedAudioKind.words,
          audioKey: word.id,
          filename: filenameFor(word.id),
          assetPath: pathForKind(
            ExpectedAudioKind.words,
            word.id,
            languageCode: languageCode,
          ),
          speechText: SpeechTextNormalizer.clean(word.text),
          declaredAudioAsset: _usable(word.audioAsset),
        ),
      for (final PhraseEntry phrase in phrases)
        ExpectedAudioItem(
          contentId: phrase.id,
          kind: ExpectedAudioKind.phrases,
          audioKey: phrase.id,
          filename: filenameFor(phrase.id),
          assetPath: pathForKind(
            ExpectedAudioKind.phrases,
            phrase.id,
            languageCode: languageCode,
          ),
          speechText: SpeechTextNormalizer.clean(phrase.text),
          declaredAudioAsset: _usable(phrase.audioAsset),
        ),
    ];

    return ExpectedAudioInventory(
      locale: locale,
      languageCode: languageCode,
      items: List<ExpectedAudioItem>.unmodifiable(items),
      issues: analyze(
        items: items,
        alphabet: alphabet,
        words: words,
        phrases: phrases,
      ),
    );
  }

  static ExpectedAudioInventory buildFrom(ContentRepository content) {
    return build(
      product: content.product,
      alphabet: content.alphabet,
      words: <WordEntry>[
        for (final ContentCategory category in content.wordCategories)
          ...content.wordsForCategory(category.id),
      ],
      phrases: <PhraseEntry>[
        for (final ContentCategory category in content.phraseCategories)
          ...content.phrasesForCategory(category.id),
      ],
    );
  }

  static ExpectedAudioIssues analyze({
    required List<ExpectedAudioItem> items,
    required List<AlphabetUnit> alphabet,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
  }) {
    final List<String> duplicateAudioKeys = <String>[];
    final List<String> filenameCollisions = <String>[];
    final List<String> invalidCharacters = <String>[];
    final Set<String> seenKeys = <String>{};
    final Map<String, String> pathOwners = <String, String>{};

    for (final ExpectedAudioItem item in items) {
      if (!seenKeys.add(item.audioKey)) {
        duplicateAudioKeys.add(item.audioKey);
      }
      if (!hasValidFilenameCharacters(item.contentId)) {
        invalidCharacters.add(item.contentId);
      }
      final String? previous = pathOwners[item.assetPath];
      if (previous != null && previous != item.contentId) {
        filenameCollisions.add(item.assetPath);
      } else {
        pathOwners[item.assetPath] = item.contentId;
      }
    }

    final Set<String> mappedIds = <String>{
      for (final ExpectedAudioItem item in items) item.contentId,
    };
    final List<String> missingMappings = <String>[
      for (final AlphabetUnit unit in alphabet)
        if (!mappedIds.contains(unit.id)) unit.id,
      for (final WordEntry word in words)
        if (!mappedIds.contains(word.id)) word.id,
      for (final PhraseEntry phrase in phrases)
        if (!mappedIds.contains(phrase.id)) phrase.id,
    ];

    final Set<String> expectedPaths = <String>{
      for (final ExpectedAudioItem item in items) item.assetPath,
    };
    final List<String> orphanDeclaredAssets = <String>[];
    void considerDeclared(String id, String? declared) {
      final String? path = _usable(declared);
      if (path == null) {
        return;
      }
      if (!expectedPaths.contains(path) && !pathOwners.containsKey(path)) {
        orphanDeclaredAssets.add('$id → $path');
      }
    }

    for (final AlphabetUnit unit in alphabet) {
      considerDeclared(unit.id, unit.audioAsset);
    }
    for (final WordEntry word in words) {
      considerDeclared(word.id, word.audioAsset);
    }
    for (final PhraseEntry phrase in phrases) {
      considerDeclared(phrase.id, phrase.audioAsset);
    }

    return ExpectedAudioIssues(
      duplicateAudioKeys: List<String>.unmodifiable(duplicateAudioKeys),
      filenameCollisions: List<String>.unmodifiable(filenameCollisions),
      invalidCharacters: List<String>.unmodifiable(invalidCharacters),
      missingMappings: List<String>.unmodifiable(missingMappings),
      orphanDeclaredAssets: List<String>.unmodifiable(orphanDeclaredAssets),
    );
  }

  static String? _usable(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
