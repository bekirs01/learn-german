import 'package:lingo_core/core/l10n/ui_catalog.dart';
import 'package:lingo_core/core/l10n/ui_keys.dart';
import 'package:lingo_core/data/language_codes.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/validation.dart';

abstract final class LanguagePackValidator {
  static ValidationReport validate({
    required ProductConfig product,
    required LanguagePack pack,
    required List<AlphabetUnit> alphabet,
    required List<ContentCategory> wordCategories,
    required List<ContentCategory> phraseCategories,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required List<TranslationBundle> translations,
    List<ValidationIssue> parseIssues = const <ValidationIssue>[],
  }) {
    final List<ValidationIssue> issues = List<ValidationIssue>.from(
      parseIssues,
    );
    _languageCodes(product, pack, issues);
    _duplicateIds(
      alphabet: alphabet,
      wordCategories: wordCategories,
      phraseCategories: phraseCategories,
      words: words,
      phrases: phrases,
      issues: issues,
    );
    _categories(
      wordCategories: wordCategories,
      phraseCategories: phraseCategories,
      words: words,
      phrases: phrases,
      issues: issues,
    );
    _translations(
      product: product,
      pack: pack,
      alphabet: alphabet,
      wordCategories: wordCategories,
      phraseCategories: phraseCategories,
      words: words,
      phrases: phrases,
      translations: translations,
      issues: issues,
    );
    _pronunciation(
      alphabet: alphabet,
      words: words,
      phrases: phrases,
      scriptFamily: pack.scriptFamily,
      issues: issues,
    );
    _quizReady(
      alphabet: alphabet,
      words: words,
      phrases: phrases,
      translations: translations,
      defaultLanguage: product.defaultTranslationLanguage,
      issues: issues,
    );
    _germanNounFields(words, issues);
    _assetIndex(pack, issues);
    _categoryAssets(
      wordCategories: wordCategories,
      phraseCategories: phraseCategories,
      issues: issues,
    );
    return ValidationReport(List<ValidationIssue>.unmodifiable(issues));
  }

  static void _languageCodes(
    ProductConfig product,
    LanguagePack pack,
    List<ValidationIssue> issues,
  ) {
    _checkCode(product.targetLanguageCode, 'targetLanguageCode', issues);
    if (product.speechLocale != null) {
      _checkCode(product.speechLocale!, 'speechLocale', issues);
    }
    if (product.speechProfile.locale != null) {
      _checkCode(product.speechProfile.locale!, 'speech.locale', issues);
    }
    _checkCode(
      product.defaultTranslationLanguage,
      'defaultTranslationLanguage',
      issues,
    );
    _checkCode(pack.targetLanguageCode, 'pack.targetLanguageCode', issues);
    _checkCode(
      pack.defaultTranslationLanguageCode,
      'pack.defaultTranslationLanguageCode',
      issues,
    );
    for (final String code in product.supportedTranslationLanguages) {
      _checkCode(code, 'supportedTranslationLanguages', issues);
    }
    for (final String code in pack.translationLanguageCodes) {
      _checkCode(code, 'translationLanguageCodes', issues);
    }
    if (!product.supportedTranslationLanguages.contains(
      product.defaultTranslationLanguage,
    )) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.unsupportedLanguageCode,
          message:
              'Default translation language "${product.defaultTranslationLanguage}" is not in supportedTranslationLanguages.',
        ),
      );
    }
    if (product.targetLanguageCode != pack.targetLanguageCode) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.languageMismatch,
          message:
              'Product target language "${product.targetLanguageCode}" does not match pack "${pack.targetLanguageCode}".',
        ),
      );
    }
    if (product.defaultTranslationLanguage !=
        pack.defaultTranslationLanguageCode) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.languageMismatch,
          message:
              'Product default translation language "${product.defaultTranslationLanguage}" does not match pack "${pack.defaultTranslationLanguageCode}".',
          severity: ValidationSeverity.warning,
        ),
      );
    }
    final Set<String> productCodes = product.supportedTranslationLanguages
        .toSet();
    final Set<String> packCodes = pack.translationLanguageCodes.toSet();
    if (productCodes.length != packCodes.length ||
        !productCodes.containsAll(packCodes)) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.languageMismatch,
          message:
              'supportedTranslationLanguages and translationLanguageCodes do not match.',
          severity: ValidationSeverity.warning,
        ),
      );
    }
  }

  static void _checkCode(
    String code,
    String field,
    List<ValidationIssue> issues,
  ) {
    if (isSupportedLanguageCode(code)) {
      return;
    }
    issues.add(
      ValidationIssue(
        code: ValidationCodes.unsupportedLanguageCode,
        message: 'Unsupported language code "$code" in $field.',
        id: code,
      ),
    );
  }

  static void _duplicateIds({
    required List<AlphabetUnit> alphabet,
    required List<ContentCategory> wordCategories,
    required List<ContentCategory> phraseCategories,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required List<ValidationIssue> issues,
  }) {
    final Set<String> seen = <String>{};
    void consider(String id, String label) {
      if (!seen.add(id)) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.duplicateId,
            message: 'Duplicate $label ID "$id".',
            id: id,
          ),
        );
      }
    }

    for (final AlphabetUnit unit in alphabet) {
      consider(unit.id, 'alphabet');
    }
    for (final ContentCategory category in wordCategories) {
      consider(category.id, 'word category');
    }
    for (final ContentCategory category in phraseCategories) {
      consider(category.id, 'phrase category');
    }
    for (final WordEntry word in words) {
      consider(word.id, 'word');
    }
    for (final PhraseEntry phrase in phrases) {
      consider(phrase.id, 'phrase');
    }
  }

  static void _categories({
    required List<ContentCategory> wordCategories,
    required List<ContentCategory> phraseCategories,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required List<ValidationIssue> issues,
  }) {
    if (wordCategories.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: ValidationCodes.missingCategories,
          message: 'Word categories are missing.',
        ),
      );
    }
    if (phraseCategories.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: ValidationCodes.missingCategories,
          message: 'Phrase categories are missing.',
        ),
      );
    }

    final Set<String> wordCategoryIds = <String>{
      for (final ContentCategory category in wordCategories) category.id,
    };
    final Set<String> phraseCategoryIds = <String>{
      for (final ContentCategory category in phraseCategories) category.id,
    };

    for (final WordEntry word in words) {
      if (!wordCategoryIds.contains(word.categoryId)) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.invalidCategoryReference,
            message:
                'Word "${word.id}" references missing category "${word.categoryId}".',
            id: word.id,
          ),
        );
      }
    }
    for (final PhraseEntry phrase in phrases) {
      if (!phraseCategoryIds.contains(phrase.categoryId)) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.invalidCategoryReference,
            message:
                'Phrase "${phrase.id}" references missing category "${phrase.categoryId}".',
            id: phrase.id,
          ),
        );
      }
    }

    final Map<String, int> wordCounts = <String, int>{};
    for (final WordEntry word in words) {
      wordCounts[word.categoryId] = (wordCounts[word.categoryId] ?? 0) + 1;
    }
    for (final ContentCategory category in wordCategories) {
      if ((wordCounts[category.id] ?? 0) == 0) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.emptyCategory,
            message: 'Word category "${category.id}" has no words.',
            id: category.id,
          ),
        );
      }
    }

    final Map<String, int> phraseCounts = <String, int>{};
    for (final PhraseEntry phrase in phrases) {
      phraseCounts[phrase.categoryId] =
          (phraseCounts[phrase.categoryId] ?? 0) + 1;
    }
    for (final ContentCategory category in phraseCategories) {
      if ((phraseCounts[category.id] ?? 0) == 0) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.emptyCategory,
            message: 'Phrase category "${category.id}" has no phrases.',
            id: category.id,
          ),
        );
      }
    }
  }

  static void _translations({
    required ProductConfig product,
    required LanguagePack pack,
    required List<AlphabetUnit> alphabet,
    required List<ContentCategory> wordCategories,
    required List<ContentCategory> phraseCategories,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required List<TranslationBundle> translations,
    required List<ValidationIssue> issues,
  }) {
    TranslationBundle? bundleFor(String code) {
      for (final TranslationBundle bundle in translations) {
        if (bundle.languageCode == code) {
          return bundle;
        }
      }
      return null;
    }

    final Set<String> expectedCodes = <String>{
      ...pack.translationLanguageCodes,
      ...product.supportedTranslationLanguages,
    };

    final Set<String> contentIds = <String>{
      for (final ContentCategory category in wordCategories) category.id,
      for (final ContentCategory category in phraseCategories) category.id,
      for (final WordEntry word in words) word.id,
      for (final PhraseEntry phrase in phrases) phrase.id,
      for (final AlphabetUnit unit in alphabet)
        if (unit.example != null && unit.example!.trim().isNotEmpty) unit.id,
    };

    for (final String code in expectedCodes) {
      final TranslationBundle? bundle = bundleFor(code);
      if (bundle == null) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.missingTranslation,
            message: 'Translation bundle "$code" is missing.',
            id: code,
            severity: ValidationSeverity.warning,
          ),
        );
        continue;
      }
      _uiCoverage(code, bundle, issues);
      _contentCoverage(
        bundle: bundle,
        contentIds: contentIds,
        wordCategories: wordCategories,
        phraseCategories: phraseCategories,
        words: words,
        phrases: phrases,
        alphabet: alphabet,
        issues: issues,
      );
    }

    final TranslationBundle? defaults = bundleFor(
      product.defaultTranslationLanguage,
    );
    if (defaults == null) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.missingTranslation,
          message:
              'Default translation bundle "${product.defaultTranslationLanguage}" is missing.',
          id: product.defaultTranslationLanguage,
        ),
      );
    }
  }

  static void _uiCoverage(
    String code,
    TranslationBundle bundle,
    List<ValidationIssue> issues,
  ) {
    final bool hasUiTable = UiCatalog.hasTable(code);
    final List<String> missingCatalogKeys = hasUiTable
        ? UiCatalog.missingChromeKeys(code)
        : UiKeys.chrome;
    final List<String> missing = <String>[];
    for (final String key in missingCatalogKeys) {
      final String? packed = bundle.strings[key];
      if (packed != null && packed.trim().isNotEmpty) {
        continue;
      }
      missing.add(key);
    }
    if (!hasUiTable && missing.length == UiKeys.chrome.length) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.missingUiBundle,
          message:
              'UI localization bundle is missing for "$code". Add a UI catalog or chrome keys such as ${UiKeys.navAlphabet}.',
          id: code,
          severity: ValidationSeverity.warning,
        ),
      );
      return;
    }
    for (final String key in missing) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.missingUiKey,
          message: 'Missing $code UI string for "$key".',
          id: key,
          severity: ValidationSeverity.warning,
        ),
      );
    }
  }

  static void _contentCoverage({
    required TranslationBundle bundle,
    required Set<String> contentIds,
    required List<ContentCategory> wordCategories,
    required List<ContentCategory> phraseCategories,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required List<AlphabetUnit> alphabet,
    required List<ValidationIssue> issues,
  }) {
    void requireKey(String id, String label) {
      if (!bundle.strings.containsKey(id)) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.missingTranslation,
            message:
                'Missing ${bundle.languageCode} translation for $label "$id".',
            id: id,
            severity: ValidationSeverity.warning,
          ),
        );
        return;
      }
      final String value = bundle.strings[id] ?? '';
      if (value.trim().isEmpty) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.blankTranslation,
            message:
                'Blank ${bundle.languageCode} translation for $label "$id".',
            id: id,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    for (final ContentCategory category in wordCategories) {
      requireKey(category.id, 'word category');
    }
    for (final ContentCategory category in phraseCategories) {
      requireKey(category.id, 'phrase category');
    }
    for (final WordEntry word in words) {
      requireKey(word.id, 'word');
    }
    for (final PhraseEntry phrase in phrases) {
      requireKey(phrase.id, 'phrase');
    }
    for (final AlphabetUnit unit in alphabet) {
      final String? example = unit.example?.trim();
      if (example == null || example.isEmpty) {
        continue;
      }
      requireKey(unit.id, 'alphabet example');
    }

    for (final MapEntry<String, String> entry in bundle.strings.entries) {
      final String key = entry.key;
      if (UiKeys.isUiKey(key)) {
        if (entry.value.trim().isEmpty) {
          issues.add(
            ValidationIssue(
              code: ValidationCodes.blankTranslation,
              message: 'Blank ${bundle.languageCode} UI string for "$key".',
              id: key,
              severity: ValidationSeverity.warning,
            ),
          );
        }
        continue;
      }
      if (!contentIds.contains(key)) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.staleTranslation,
            message: 'Stale ${bundle.languageCode} translation ID "$key".',
            id: key,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }
  }

  static final RegExp _ipaPronunciation = RegExp(r'^/.+/$');

  static void _pronunciation({
    required List<AlphabetUnit> alphabet,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required ScriptFamily scriptFamily,
    required List<ValidationIssue> issues,
  }) {
    final bool expectIpa =
        scriptFamily == ScriptFamily.latin ||
        scriptFamily == ScriptFamily.cyrillic;

    void checkSpokenForm(String id, String? value, String label) {
      if (value == null || value.isEmpty) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.invalidPronunciation,
            message: 'Invalid $label pronunciation for "$id".',
            id: id,
            severity: ValidationSeverity.warning,
          ),
        );
        return;
      }
      if (expectIpa && !_ipaPronunciation.hasMatch(value)) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.invalidPronunciation,
            message: 'Invalid $label pronunciation for "$id".',
            id: id,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    for (final WordEntry word in words) {
      if (word.quizEnabled) {
        checkSpokenForm(word.id, word.pronunciation, 'word');
      }
    }
    for (final PhraseEntry phrase in phrases) {
      if (phrase.quizEnabled) {
        checkSpokenForm(phrase.id, phrase.pronunciation, 'phrase');
      }
    }
    for (final AlphabetUnit unit in alphabet) {
      if (!unit.quizEnabled) {
        continue;
      }
      final String? pronunciation = unit.pronunciation;
      final String? romanization = unit.romanization;
      final bool hasCue =
          (pronunciation != null && pronunciation.isNotEmpty) ||
          (romanization != null && romanization.isNotEmpty);
      if (!hasCue) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.invalidPronunciation,
            message: 'Alphabet unit "${unit.id}" is missing pronunciation.',
            id: unit.id,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }
  }

  static void _quizReady({
    required List<AlphabetUnit> alphabet,
    required List<WordEntry> words,
    required List<PhraseEntry> phrases,
    required List<TranslationBundle> translations,
    required String defaultLanguage,
    required List<ValidationIssue> issues,
  }) {
    Map<String, String> stringsFor(String code) {
      for (final TranslationBundle bundle in translations) {
        if (bundle.languageCode == code) {
          return bundle.strings;
        }
      }
      return const <String, String>{};
    }

    final Map<String, String> defaults = stringsFor(defaultLanguage);

    void requireAnswer(String id, String prompt, String label) {
      if (prompt.isEmpty) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.quizNotReady,
            message: '$label "$id" has an empty quiz prompt.',
            id: id,
          ),
        );
        return;
      }
      final String? answer = defaults[id];
      if (answer == null || answer.isEmpty) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.quizNotReady,
            message: '$label "$id" is quiz-enabled without a translation.',
            id: id,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    for (final AlphabetUnit unit in alphabet) {
      if (unit.quizEnabled && unit.glyph.isEmpty) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.quizNotReady,
            message: 'Alphabet unit "${unit.id}" has an empty quiz prompt.',
            id: unit.id,
          ),
        );
      }
    }
    for (final WordEntry word in words) {
      if (word.quizEnabled) {
        requireAnswer(word.id, word.text, 'Word');
      }
    }
    for (final PhraseEntry phrase in phrases) {
      if (phrase.quizEnabled) {
        requireAnswer(phrase.id, phrase.text, 'Phrase');
      }
    }
  }

  static const Set<String> _allowedGenders = <String>{
    'der',
    'die',
    'das',
    'none',
  };

  static void _germanNounFields(
    List<WordEntry> words,
    List<ValidationIssue> issues,
  ) {
    for (final WordEntry word in words) {
      final String? gender = word.grammaticalGender;
      if (gender != null && !_allowedGenders.contains(gender)) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.malformedEntry,
            message:
                'Word "${word.id}" has invalid grammaticalGender "$gender".',
            id: word.id,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }
  }

  static void _categoryAssets({
    required List<ContentCategory> wordCategories,
    required List<ContentCategory> phraseCategories,
    required List<ValidationIssue> issues,
  }) {
    void requireAsset(ContentCategory category, String label) {
      final String? asset = category.imageAsset;
      if (asset != null && asset.isNotEmpty) {
        return;
      }
      issues.add(
        ValidationIssue(
          code: ValidationCodes.missingAssetReference,
          message: '$label "${category.id}" is missing an illustration asset.',
          id: category.id,
          severity: ValidationSeverity.warning,
        ),
      );
    }

    for (final ContentCategory category in wordCategories) {
      requireAsset(category, 'Word category');
    }
    for (final ContentCategory category in phraseCategories) {
      requireAsset(category, 'Phrase category');
    }
  }

  static void _assetIndex(LanguagePack pack, List<ValidationIssue> issues) {
    for (final MapEntry<String, String> entry in pack.assetIndex.entries) {
      if (entry.value.isEmpty) {
        issues.add(
          ValidationIssue(
            code: ValidationCodes.missingAssetReference,
            message: 'Asset ID "${entry.key}" has an empty path.',
            id: entry.key,
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }
  }
}
