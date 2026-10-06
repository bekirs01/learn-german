/// Writing-system family for a language pack. Not every language uses an
/// alphabet; [none] covers packs that skip a character inventory.
enum ScriptFamily {
  latin,
  cyrillic,
  arabic,
  han,
  japanese,
  korean,
  other,
  none,
}

enum ContentTextDirection { ltr, rtl }

enum QuizContentKind { alphabet, word, phrase }

/// Replaceable offline pack that drives the app without code changes.
final class LanguagePack {
  const LanguagePack({
    required this.id,
    required this.name,
    required this.version,
    required this.targetLanguageCode,
    required this.targetLanguageName,
    required this.scriptFamily,
    required this.textDirection,
    required this.hasAlphabet,
    required this.defaultTranslationLanguageCode,
    required this.translationLanguageCodes,
    required this.assetIndex,
  });

  final String id;
  final String name;
  final String version;

  /// BCP-47 code of the language being learned.
  final String targetLanguageCode;
  final String targetLanguageName;
  final ScriptFamily scriptFamily;
  final ContentTextDirection textDirection;
  final bool hasAlphabet;
  final String defaultTranslationLanguageCode;
  final List<String> translationLanguageCodes;

  /// Maps a stable asset ID to a bundled file path.
  final Map<String, String> assetIndex;

  String? assetPathFor(String? assetId) {
    if (assetId == null || assetId.isEmpty) {
      return null;
    }
    return assetIndex[assetId];
  }
}

/// One character, letter, or other written unit. [glyph] may be a single
/// code point or a grapheme cluster (Hangul syllable, ligature, etc.).
final class AlphabetUnit {
  const AlphabetUnit({
    required this.id,
    required this.glyph,
    required this.sortOrder,
    required this.quizEnabled,
    this.pronunciation,
    this.speechText,
    this.romanization,
    this.example,
    this.imageAsset,
    this.audioAsset,
  });

  final String id;
  final String glyph;
  final String? pronunciation;

  /// Dedicated TTS text for this unit (the letter itself: "A", "Ä", "ß").
  /// Automatic playback and the speaker button both speak this field.
  /// When omitted, [glyph] is spoken. Never the example word, pronunciation
  /// cue, or an accessibility/UI label.
  final String? speechText;
  final String? romanization;

  /// A short target-language example word, when one helps teach the glyph.
  final String? example;
  final String? imageAsset;
  final String? audioAsset;
  final int sortOrder;
  final bool quizEnabled;
}

final class ContentCategory {
  const ContentCategory({
    required this.id,
    required this.title,
    required this.sortOrder,
    this.imageAsset,
    this.audioAsset,
    this.artKind,
  });

  final String id;
  final String title;
  final String? imageAsset;
  final String? audioAsset;

  /// Optional illustration token for painted fallback art.
  final String? artKind;
  final int sortOrder;
}

final class WordEntry {
  const WordEntry({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.sortOrder,
    required this.quizEnabled,
    this.pronunciation,
    this.romanization,
    this.imageAsset,
    this.audioAsset,
    this.grammaticalGender,
    this.plural,
  });

  final String id;
  final String categoryId;
  final String text;
  final String? pronunciation;
  final String? romanization;
  final String? imageAsset;
  final String? audioAsset;

  /// Nominative definite article for German nouns: `der`, `die`, `das`.
  /// Use `none` for words that are not gendered nouns.
  final String? grammaticalGender;

  /// Nominative plural with article, for example `die Häuser`.
  final String? plural;
  final int sortOrder;
  final bool quizEnabled;
}

final class PhraseEntry {
  const PhraseEntry({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.sortOrder,
    required this.quizEnabled,
    this.pronunciation,
    this.romanization,
    this.imageAsset,
    this.audioAsset,
  });

  final String id;
  final String categoryId;
  final String text;
  final String? pronunciation;
  final String? romanization;
  final String? imageAsset;
  final String? audioAsset;
  final int sortOrder;
  final bool quizEnabled;
}

final class TranslationBundle {
  const TranslationBundle({
    required this.languageCode,
    required this.languageName,
    required this.strings,
  });

  final String languageCode;
  final String languageName;
  final Map<String, String> strings;
}

/// Flat item a quiz feature can consume without parsing content files.
final class QuizReadyItem {
  const QuizReadyItem({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.answersByLanguage,
    this.pronunciation,
    this.romanization,
    this.imageAsset,
    this.audioAsset,
  });

  final String id;
  final QuizContentKind kind;
  final String prompt;
  final String? pronunciation;
  final String? romanization;
  final String? imageAsset;
  final String? audioAsset;
  final Map<String, String> answersByLanguage;
}
