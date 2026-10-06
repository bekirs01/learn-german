import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_catalog.dart';
import 'package:lingo_core/core/l10n/ui_keys.dart';
import 'package:lingo_core/data/content_json.dart';
import 'package:lingo_core/data/language_codes.dart';
import 'package:lingo_core/data/language_pack_validator.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/product_config_json.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/validation.dart';

import 'support/memory_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
  });

  group('JSON decoding', () {
    test('parses product configuration', () {
      final ProductConfig product = parseProductConfig(
        jsonDecode(_productJson()),
      );
      expect(product.id, 'lingo_core');
      expect(product.targetLanguageCode, 'und');
      expect(product.writingSystem, WritingSystem.alphabet);
      expect(product.textDirection, ContentTextDirection.ltr);
      expect(product.contentPackPath, 'assets/content');
      expect(product.supportedTranslationLanguages, <String>['en']);
    });

    test('parses a language pack and entries', () {
      final List<ValidationIssue> issues = <ValidationIssue>[];
      final ProductConfig product = parseProductConfig(
        jsonDecode(_productJson()),
      );
      final LanguagePack pack = parseLanguagePack(
        jsonDecode(_packJson()),
        product,
        issues,
      );
      expect(pack.id, 'sample_core');
      expect(pack.scriptFamily, ScriptFamily.latin);
      expect(pack.assetIndex['words.animals'], contains('animals.png'));

      final List<AlphabetUnit> alphabet = parseAlphabet(
        jsonDecode(_alphabetJson()),
        pack,
        issues,
      );
      expect(alphabet.map((AlphabetUnit unit) => unit.glyph).toList(), <String>[
        'A',
        'B',
      ]);

      final List<ContentCategory> wordCategories = parseCategories(
        jsonDecode(_wordCategoriesJson()),
        pack,
        'word_categories',
        issues,
      );
      final List<WordEntry> words = parseWords(
        jsonDecode(_wordsJson()),
        pack,
        <String>{'word_category.animals'},
        issues,
      );
      expect(wordCategories.single.id, 'word_category.animals');
      expect(words.single.text, 'Cat');
      expect(issues, isEmpty);
    });

    test('ignores a bad optional field instead of crashing', () {
      final List<ValidationIssue> issues = <ValidationIssue>[];
      final LanguagePack pack = parseLanguagePack(
        <String, Object?>{
          'id': 'pack',
          'name': 'Pack',
          'version': '1',
          'scriptFamily': 12,
          'assetIndex': 'not-an-object',
        },
        ProductConfig.fallback,
        issues,
      );
      expect(pack.scriptFamily, ScriptFamily.other);
      expect(pack.assetIndex, isEmpty);

      final List<WordEntry> words = parseWords(
        <String, Object?>{
          'items': <Object?>[
            <String, Object?>{
              'id': 'word.cat',
              'categoryId': 'word_category.animals',
              'text': 'Cat',
              'audioAssetId': 3,
              'quizEnabled': 'yes',
            },
          ],
        },
        pack,
        <String>{'word_category.animals'},
        issues,
      );
      expect(words, hasLength(1));
      expect(words.single.audioAsset, isNull);
    });
  });

  group('repository loading', () {
    test('loads a pack from JSON assets', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(_validAssets()),
      );
      expect(repo.product.id, 'lingo_core');
      expect(repo.pack.id, 'sample_core');
      expect(repo.validation.hasErrors, isFalse);
      expect(repo.quizItems, isNotEmpty);
    });

    test('loads the bundled sample pack', () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      expect(repo.alphabet, isNotEmpty);
      expect(repo.wordCategories, isNotEmpty);
      expect(repo.phraseCategories, isNotEmpty);
      expect(repo.product.contentPackPath, 'assets/content');
      expect(repo.validation.hasErrors, isFalse);
      expect(repo.pack.translationLanguageCodes, LearnerLanguages.orderedCodes);
      expect(repo.pronunciationEnabled, isTrue);
      expect(repo.product.id, 'learn_german');
      expect(repo.product.displayName, 'Learn German for Beginners');
      expect(repo.product.targetLanguageCode, 'de');
      expect(repo.product.nativeLanguageName, 'Deutsch');
      expect(repo.product.speechLocale, 'de-DE');
      expect(repo.product.speechProfile.preferredVoiceName, 'Anna');
      expect(
        repo.product.speechProfile.preferredGender,
        PreferredSpeechGender.female,
      );
      expect(repo.product.speechProfile.rate, closeTo(0.47, 0.001));
      expect(TargetSpeechLocale.resolve(product: repo.product), 'de-DE');
      expect(
        repo.pronunciationAssetFor(repo.alphabet.first.id),
        'assets/audio/de/alphabet/letter.a.wav',
      );
      expect(
        repo.alphabetUnitById('letter.a')?.imageAsset,
        'assets/images/alphabet/apple.png',
      );
      expect(
        repo.alphabet.every(
          (AlphabetUnit unit) =>
              unit.imageAsset != null && unit.imageAsset!.isNotEmpty,
        ),
        isTrue,
      );
      expect(
        repo.alphabet.every((AlphabetUnit unit) {
          final String? spoken = PronunciationClip.fromAlphabet(
            unit,
          ).speechText;
          if (spoken == null) {
            return false;
          }
          final String label = spoken.toLowerCase();
          return spoken == unit.glyph &&
              spoken == unit.speechText &&
              !label.contains('capital') &&
              !label.contains('uppercase') &&
              !label.contains('lowercase');
        }),
        isTrue,
      );
    });

    test('keeps German targets when the learner language is Turkish', () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      final AlphabetUnit letter = repo.alphabet.firstWhere(
        (AlphabetUnit unit) => unit.id == 'letter.a',
      );
      expect(letter.example, 'Apfel');
      expect(repo.translation('letter.a', languageCode: 'en'), 'apple');
      expect(repo.translation('letter.a', languageCode: 'tr'), 'elma');
      expect(letter.speechText, 'A');
      expect(PronunciationClip.fromAlphabet(letter).speechText, 'A');
      expect(PronunciationClip.fromAlphabet(letter).speechText, isNot('apple'));
      final AlphabetUnit letterB = repo.alphabet.firstWhere(
        (AlphabetUnit unit) => unit.id == 'letter.b',
      );
      final AlphabetUnit letterZ = repo.alphabet.firstWhere(
        (AlphabetUnit unit) => unit.id == 'letter.z',
      );
      expect(PronunciationClip.fromAlphabet(letterB).speechText, 'B');
      expect(PronunciationClip.fromAlphabet(letterZ).speechText, 'Z');
      for (final AlphabetUnit unit in <AlphabetUnit>[
        letter,
        letterB,
        letterZ,
      ]) {
        final String spoken = PronunciationClip.fromAlphabet(unit).speechText!;
        expect(spoken.toLowerCase(), isNot(contains('capital')));
        expect(spoken.toLowerCase(), isNot(contains('uppercase')));
        expect(spoken.toLowerCase(), isNot(contains('lowercase')));
      }
      expect(repo.translation('letter.a', languageCode: 'en'), 'apple');
      expect(repo.translation('letter.a', languageCode: 'tr'), 'elma');

      final WordEntry? cat = repo.wordById('word.animals.cat');
      expect(cat?.text, 'die Katze');
      expect(repo.translation('word.animals.cat', languageCode: 'en'), 'Cat');
      expect(repo.translation('word.animals.cat', languageCode: 'tr'), 'Kedi');
      final WordEntry? apple = repo.wordById('word.food.apple');
      expect(apple?.text, 'der Apfel');
      expect(repo.translation('word.food.apple', languageCode: 'en'), 'Apple');
      expect(repo.translation('word.food.apple', languageCode: 'tr'), 'Elma');

      final PhraseEntry? hello = repo.phraseById('phrase.greetings.hello');
      expect(hello?.text, 'Hallo.');
      expect(
        repo.translation('phrase.greetings.hello', languageCode: 'en'),
        'Hello.',
      );
      expect(
        repo.translation('phrase.greetings.hello', languageCode: 'tr'),
        'Merhaba.',
      );
    });
  });

  group('alphabet loading', () {
    test('keeps sort order and pronunciation', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(_validAssets()),
      );
      expect(repo.alphabet.map((AlphabetUnit unit) => unit.glyph), <String>[
        'A',
        'B',
      ]);
      expect(repo.alphabetUnitById('letter.b')?.pronunciation, 'beh');
    });

    test('stays empty when the writing system has no inventory', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(
          _validAssets(
            product: _productJson(writingSystem: 'other', alphabetFlag: false),
          ),
        ),
      );
      expect(repo.pack.hasAlphabet, isFalse);
      expect(repo.alphabet, isEmpty);
    });

    test('resolves pronunciation audio from language-pack data', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(
          _validAssets(
            product: _productJson(audioFlag: true),
            pack: _packJson(
              extraAssets: <String, String>{
                'letter.a.audio': 'assets/audio/alphabet/a.wav',
              },
            ),
            alphabet: jsonEncode(<String, Object?>{
              'units': <Object?>[
                <String, Object?>{
                  'id': 'letter.a',
                  'glyph': 'A',
                  'pronunciation': 'ah',
                  'pronunciationSpeechText': 'A',
                  'audioAssetId': 'letter.a.audio',
                  'sortOrder': 0,
                },
                <String, Object?>{
                  'id': 'letter.b',
                  'glyph': 'B',
                  'pronunciation': 'beh',
                  'sortOrder': 1,
                },
              ],
            }),
            words: jsonEncode(<String, Object?>{
              'items': <Object?>[
                <String, Object?>{
                  'id': 'word.cat',
                  'categoryId': 'word_category.animals',
                  'text': 'Cat',
                  'pronunciation': '/kæt/',
                  'audioAsset': 'assets/audio/words/cat.wav',
                  'sortOrder': 0,
                },
              ],
            }),
            phrases: jsonEncode(<String, Object?>{
              'items': <Object?>[
                <String, Object?>{
                  'id': 'phrase.hello',
                  'categoryId': 'phrase_category.greetings',
                  'text': 'Hello.',
                  'audioAsset': 'assets/audio/phrases/hello.wav',
                  'sortOrder': 0,
                },
              ],
            }),
          ),
        ),
      );

      expect(repo.pronunciationEnabled, isTrue);
      expect(
        repo.pronunciationAssetFor('letter.a'),
        'assets/audio/alphabet/a.wav',
      );
      expect(
        repo.pronunciationAssetFor('letter.b'),
        'assets/audio/und/alphabet/letter.b.wav',
      );
      expect(
        repo.pronunciationAssetFor('word.cat'),
        'assets/audio/words/cat.wav',
      );
      expect(
        repo.pronunciationAssetFor('phrase.hello'),
        'assets/audio/phrases/hello.wav',
      );
      expect(
        PronunciationClip.fromContent(repo, 'word.cat').assetPath,
        'assets/audio/words/cat.wav',
      );
      expect(
        PronunciationClip.fromAlphabet(
          repo.alphabetUnitById('letter.a')!,
        ).speechText,
        'A',
      );
      expect(
        PronunciationClip.fromWord(repo.wordById('word.cat')!).speechText,
        'Cat',
      );
      expect(
        PronunciationClip.fromPhrase(
          repo.phraseById('phrase.hello')!,
        ).speechText,
        'Hello.',
      );
    });
  });

  group('category relationships', () {
    test('groups words by category', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(_validAssets()),
      );
      expect(repo.wordsForCategory('word_category.animals').single.text, 'Cat');
      expect(repo.wordsForCategory('missing'), isEmpty);
    });

    test('groups phrases by category', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(_validAssets()),
      );
      expect(
        repo.phrasesForCategory('phrase_category.greetings').single.text,
        'Hello.',
      );
    });
  });

  group('translation fallback', () {
    test('falls back to the default translation language', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(_validAssets()),
      );
      expect(repo.translation('word.cat'), 'A small animal.');
      expect(
        repo.translation('word.cat', languageCode: 'tr'),
        'A small animal.',
      );
      expect(
        repo.labelFor('missing', 'Fallback', languageCode: 'ja'),
        'Fallback',
      );
    });
  });

  group('RTL configuration', () {
    test('reads RTL from product configuration', () {
      final ProductConfig product = parseProductConfig(
        jsonDecode(_productJson(direction: 'rtl', code: 'ar')),
      );
      expect(product.textDirection, ContentTextDirection.rtl);
      expect(product.targetLanguageCode, 'ar');

      final LanguagePack pack = parseLanguagePack(
        jsonDecode(_packJson()),
        product,
      );
      expect(pack.textDirection, ContentTextDirection.rtl);
    });
  });

  group('missing-data handling', () {
    test('loads when optional files and translations are missing', () async {
      final MemoryAssetBundle bundle = MemoryAssetBundle(<String, String>{
        ProductConfig.assetPath: _productJson(),
        'assets/content/language_pack.json': _packJson(),
        'assets/content/alphabet.json': _alphabetJson(),
        'assets/content/word_categories.json': _wordCategoriesJson(),
        'assets/content/words.json': _wordsJson(),
        'assets/content/phrase_categories.json': _phraseCategoriesJson(),
        'assets/content/phrases.json': _phrasesJson(),
      });
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: bundle,
      );
      expect(repo.wordsForCategory('word_category.animals'), isNotEmpty);
      expect(
        repo.validation.whereCode(ValidationCodes.missingTranslation),
        isNotEmpty,
      );
    });

    test('uses product fallback when product.json is absent', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(<String, String>{
          'assets/content/language_pack.json': _packJson(),
          'assets/content/alphabet.json': _alphabetJson(),
          'assets/content/word_categories.json': _wordCategoriesJson(),
          'assets/content/words.json': _wordsJson(),
          'assets/content/phrase_categories.json': _phraseCategoriesJson(),
          'assets/content/phrases.json': _phrasesJson(),
          'assets/content/translations/en.json': _enJson(),
        }),
      );
      expect(repo.product.id, ProductConfig.fallback.id);
      expect(
        repo.validation.whereCode(ValidationCodes.malformedEntry),
        isNotEmpty,
      );
    });
  });

  group('invalid language packs', () {
    test('detects duplicate IDs', () {
      final List<ValidationIssue> issues = <ValidationIssue>[];
      parseAlphabet(
        jsonDecode(
          '{"units":[{"id":"letter.a","glyph":"A"},{"id":"letter.a","glyph":"Á"}]}',
        ),
        _emptyPack(),
        issues,
      );
      expect(
        issues.where(
          (ValidationIssue issue) => issue.code == ValidationCodes.duplicateId,
        ),
        isNotEmpty,
      );
    });

    test('detects missing translations', () async {
      final LocalContentRepository repo = await LocalContentRepository.load(
        bundle: MemoryAssetBundle(
          _validAssets(
            en: '{"languageCode":"en","languageName":"English","strings":{}}',
          ),
        ),
      );
      expect(
        repo.validation.whereCode(ValidationCodes.missingTranslation),
        isNotEmpty,
      );
    });

    test('detects missing categories', () {
      final ValidationReport report = LanguagePackValidator.validate(
        product: ProductConfig.fallback,
        pack: _emptyPack(),
        alphabet: const <AlphabetUnit>[],
        wordCategories: const <ContentCategory>[],
        phraseCategories: const <ContentCategory>[],
        words: const <WordEntry>[],
        phrases: const <PhraseEntry>[],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{},
          ),
        ],
      );
      expect(report.whereCode(ValidationCodes.missingCategories), hasLength(2));
    });

    test('detects invalid category references', () {
      final List<ValidationIssue> issues = <ValidationIssue>[];
      parseWords(
        jsonDecode(
          '{"items":[{"id":"word.cat","categoryId":"missing","text":"Cat"}]}',
        ),
        _emptyPack(),
        <String>{'word_category.animals'},
        issues,
      );
      expect(
        issues.where(
          (ValidationIssue issue) =>
              issue.code == ValidationCodes.invalidCategoryReference,
        ),
        isNotEmpty,
      );
    });

    test('detects missing asset references', () {
      final List<ValidationIssue> issues = <ValidationIssue>[];
      parseCategories(
        jsonDecode(
          '{"items":[{"id":"word_category.animals","title":"Animals","imageAssetId":"missing.art"}]}',
        ),
        _emptyPack(),
        'word_categories',
        issues,
      );
      expect(
        issues.where(
          (ValidationIssue issue) =>
              issue.code == ValidationCodes.missingAssetReference,
        ),
        isNotEmpty,
      );
    });

    test('detects malformed entries', () {
      final List<ValidationIssue> issues = <ValidationIssue>[];
      parseWords(
        <String, Object?>{
          'items': <Object?>['not-an-object', 12],
        },
        _emptyPack(),
        <String>{'word_category.animals'},
        issues,
      );
      expect(
        issues.where(
          (ValidationIssue issue) =>
              issue.code == ValidationCodes.malformedEntry,
        ),
        isNotEmpty,
      );
    });

    test('detects empty required fields', () {
      final List<ValidationIssue> issues = <ValidationIssue>[];
      parsePhrases(
        jsonDecode(
          '{"items":[{"id":"","categoryId":"phrase_category.greetings","text":""}]}',
        ),
        _emptyPack(),
        <String>{'phrase_category.greetings'},
        issues,
      );
      expect(
        issues.where(
          (ValidationIssue issue) =>
              issue.code == ValidationCodes.emptyRequiredField,
        ),
        isNotEmpty,
      );
    });

    test('detects empty categories', () {
      final ValidationReport report = LanguagePackValidator.validate(
        product: ProductConfig.fallback,
        pack: _emptyPack(),
        alphabet: const <AlphabetUnit>[],
        wordCategories: const <ContentCategory>[
          ContentCategory(
            id: 'word_category.animals',
            title: 'Animals',
            sortOrder: 0,
          ),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(
            id: 'phrase_category.greetings',
            title: 'Greetings',
            sortOrder: 0,
          ),
        ],
        words: const <WordEntry>[],
        phrases: const <PhraseEntry>[],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{},
          ),
        ],
      );
      expect(report.whereCode(ValidationCodes.emptyCategory), hasLength(2));
    });

    test('detects invalid pronunciation', () {
      final ValidationReport report = LanguagePackValidator.validate(
        product: ProductConfig.fallback,
        pack: _emptyPack(),
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ],
        wordCategories: const <ContentCategory>[
          ContentCategory(
            id: 'word_category.animals',
            title: 'A',
            sortOrder: 0,
          ),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(
            id: 'phrase_category.greetings',
            title: 'P',
            sortOrder: 0,
          ),
        ],
        words: const <WordEntry>[
          WordEntry(
            id: 'word.cat',
            categoryId: 'word_category.animals',
            text: 'Cat',
            pronunciation: 'cat',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ],
        phrases: const <PhraseEntry>[
          PhraseEntry(
            id: 'phrase.hello',
            categoryId: 'phrase_category.greetings',
            text: 'Hello.',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{
              'word.cat': 'Cat',
              'phrase.hello': 'Hello.',
            },
          ),
        ],
      );
      expect(
        report.whereCode(ValidationCodes.invalidPronunciation),
        hasLength(3),
      );
    });

    test('detects quiz-unreadiness', () {
      final ValidationReport report = LanguagePackValidator.validate(
        product: ProductConfig.fallback,
        pack: _emptyPack(),
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: '',
            sortOrder: 0,
            quizEnabled: true,
            pronunciation: 'ay',
          ),
        ],
        wordCategories: const <ContentCategory>[
          ContentCategory(
            id: 'word_category.animals',
            title: 'A',
            sortOrder: 0,
          ),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(
            id: 'phrase_category.greetings',
            title: 'P',
            sortOrder: 0,
          ),
        ],
        words: const <WordEntry>[
          WordEntry(
            id: 'word.cat',
            categoryId: 'word_category.animals',
            text: 'Cat',
            pronunciation: '/kæt/',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ],
        phrases: const <PhraseEntry>[
          PhraseEntry(
            id: 'phrase.hello',
            categoryId: 'phrase_category.greetings',
            text: 'Hello.',
            pronunciation: '/həˈloʊ/',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{},
          ),
        ],
      );
      expect(report.whereCode(ValidationCodes.quizNotReady), isNotEmpty);
    });

    test('detects missing category illustration assets', () {
      final ValidationReport report = LanguagePackValidator.validate(
        product: ProductConfig.fallback,
        pack: _emptyPack(),
        alphabet: const <AlphabetUnit>[],
        wordCategories: const <ContentCategory>[
          ContentCategory(
            id: 'word_category.animals',
            title: 'Animals',
            sortOrder: 0,
          ),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(
            id: 'phrase_category.greetings',
            title: 'Greetings',
            sortOrder: 0,
            imageAsset: 'assets/images/categories/phrases/greetings.png',
          ),
        ],
        words: const <WordEntry>[
          WordEntry(
            id: 'word.cat',
            categoryId: 'word_category.animals',
            text: 'Cat',
            pronunciation: '/kæt/',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ],
        phrases: const <PhraseEntry>[
          PhraseEntry(
            id: 'phrase.hello',
            categoryId: 'phrase_category.greetings',
            text: 'Hello.',
            pronunciation: '/həˈloʊ/',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{
              'word.cat': 'Cat',
              'phrase.hello': 'Hello.',
            },
          ),
        ],
      );
      expect(
        report.whereCode(ValidationCodes.missingAssetReference),
        isNotEmpty,
      );
    });

    test('detects unsupported language codes', () {
      expect(isSupportedLanguageCode('en'), isTrue);
      expect(isSupportedLanguageCode('es'), isTrue);
      expect(isSupportedLanguageCode('ja'), isTrue);
      expect(isSupportedLanguageCode('es-MX'), isTrue);
      expect(isSupportedLanguageCode('not-a-language'), isFalse);
      final ProductConfig product = parseProductConfig(
        jsonDecode(
          _productJson(
            code: 'not-a-language',
            translations: <String>['not-a-language'],
          ),
        ),
        <ValidationIssue>[],
      );
      final ValidationReport report = LanguagePackValidator.validate(
        product: product,
        pack: _emptyPack(),
        alphabet: const <AlphabetUnit>[],
        wordCategories: const <ContentCategory>[
          ContentCategory(id: 'wc', title: 'W', sortOrder: 0),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(id: 'pc', title: 'P', sortOrder: 0),
        ],
        words: const <WordEntry>[],
        phrases: const <PhraseEntry>[],
        translations: const <TranslationBundle>[],
      );
      expect(
        report.whereCode(ValidationCodes.unsupportedLanguageCode),
        isNotEmpty,
      );
    });

    test('detects product and pack language mismatches', () {
      final ProductConfig product = ProductConfig(
        id: 'clone',
        displayName: 'Clone',
        targetLanguageName: 'English',
        targetLanguageCode: 'en',
        nativeLanguageName: 'English',
        textDirection: ContentTextDirection.ltr,
        writingSystem: WritingSystem.alphabet,
        primaryAccentColor: '#C46A3C',
        contentPackPath: 'assets/content',
        defaultTranslationLanguage: 'en',
        supportedTranslationLanguages: const <String>['en', 'tr'],
      );
      final ValidationReport report = LanguagePackValidator.validate(
        product: product,
        pack: _emptyPack(
          targetLanguageCode: 'es',
          translationLanguageCodes: const <String>['en'],
        ),
        alphabet: const <AlphabetUnit>[],
        wordCategories: const <ContentCategory>[
          ContentCategory(id: 'wc', title: 'W', sortOrder: 0),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(id: 'pc', title: 'P', sortOrder: 0),
        ],
        words: const <WordEntry>[],
        phrases: const <PhraseEntry>[],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{'wc': 'W', 'pc': 'P'},
          ),
        ],
      );
      expect(report.whereCode(ValidationCodes.languageMismatch), isNotEmpty);
    });

    test('detects missing alphabet example translations', () {
      final ValidationReport report = LanguagePackValidator.validate(
        product: ProductConfig.fallback,
        pack: _emptyPack(),
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: false,
            example: 'Apple',
          ),
        ],
        wordCategories: const <ContentCategory>[
          ContentCategory(id: 'wc', title: 'W', sortOrder: 0),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(id: 'pc', title: 'P', sortOrder: 0),
        ],
        words: const <WordEntry>[],
        phrases: const <PhraseEntry>[],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{'wc': 'W', 'pc': 'P'},
          ),
        ],
      );
      final List<ValidationIssue> missing = report.whereCode(
        ValidationCodes.missingTranslation,
      );
      expect(
        missing.any(
          (ValidationIssue issue) =>
              issue.id == 'letter.a' &&
              issue.message.contains('alphabet example'),
        ),
        isTrue,
      );
      expect(
        missing
            .where((ValidationIssue issue) => issue.id == 'letter.a')
            .every(
              (ValidationIssue issue) =>
                  issue.severity == ValidationSeverity.warning,
            ),
        isTrue,
      );
    });

    test('detects a missing UI localization bundle', () {
      final ProductConfig product = ProductConfig(
        id: 'clone',
        displayName: 'Clone',
        targetLanguageName: 'Sample',
        targetLanguageCode: 'und',
        nativeLanguageName: 'Sample',
        textDirection: ContentTextDirection.ltr,
        writingSystem: WritingSystem.alphabet,
        primaryAccentColor: '#C46A3C',
        contentPackPath: 'assets/content',
        defaultTranslationLanguage: 'en',
        supportedTranslationLanguages: const <String>['en', 'nl'],
      );
      final ValidationReport report = LanguagePackValidator.validate(
        product: product,
        pack: _emptyPack(translationLanguageCodes: const <String>['en', 'nl']),
        alphabet: const <AlphabetUnit>[],
        wordCategories: const <ContentCategory>[
          ContentCategory(id: 'wc', title: 'W', sortOrder: 0),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(id: 'pc', title: 'P', sortOrder: 0),
        ],
        words: const <WordEntry>[
          WordEntry(
            id: 'word.cat',
            categoryId: 'wc',
            text: 'Cat',
            sortOrder: 0,
            quizEnabled: false,
          ),
        ],
        phrases: const <PhraseEntry>[
          PhraseEntry(
            id: 'phrase.hello',
            categoryId: 'pc',
            text: 'Hello.',
            sortOrder: 0,
            quizEnabled: false,
          ),
        ],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{
              'wc': 'W',
              'pc': 'P',
              'word.cat': 'Cat',
              'phrase.hello': 'Hello.',
            },
          ),
          TranslationBundle(
            languageCode: 'nl',
            languageName: 'Nederlands',
            strings: <String, String>{
              'wc': 'W',
              'pc': 'P',
              'word.cat': 'Kat',
              'phrase.hello': 'Hallo',
            },
          ),
        ],
      );
      expect(
        report
            .whereCode(ValidationCodes.missingUiBundle)
            .any((ValidationIssue issue) => issue.id == 'nl'),
        isTrue,
      );
      expect(
        report
            .whereCode(ValidationCodes.missingUiBundle)
            .every(
              (ValidationIssue issue) =>
                  issue.severity == ValidationSeverity.warning,
            ),
        isTrue,
      );
    });

    test('detects a missing UI key, blank translation, and stale ID', () {
      UiCatalog.register('nl', <String, String>{UiKeys.navAlphabet: 'Alfabet'});
      addTearDown(UiCatalog.resetForTest);

      final ValidationReport report = LanguagePackValidator.validate(
        product: ProductConfig.fallback,
        pack: _emptyPack(translationLanguageCodes: const <String>['en', 'nl']),
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: false,
            example: 'Apple',
          ),
        ],
        wordCategories: const <ContentCategory>[
          ContentCategory(id: 'wc', title: 'W', sortOrder: 0),
        ],
        phraseCategories: const <ContentCategory>[
          ContentCategory(id: 'pc', title: 'P', sortOrder: 0),
        ],
        words: const <WordEntry>[
          WordEntry(
            id: 'word.cat',
            categoryId: 'wc',
            text: 'Cat',
            sortOrder: 0,
            quizEnabled: false,
          ),
        ],
        phrases: const <PhraseEntry>[
          PhraseEntry(
            id: 'phrase.hello',
            categoryId: 'pc',
            text: 'Hello.',
            sortOrder: 0,
            quizEnabled: false,
          ),
        ],
        translations: const <TranslationBundle>[
          TranslationBundle(
            languageCode: 'en',
            languageName: 'English',
            strings: <String, String>{
              'wc': 'W',
              'pc': 'P',
              'word.cat': 'Cat',
              'phrase.hello': 'Hello.',
              'letter.a': 'apple',
            },
          ),
          TranslationBundle(
            languageCode: 'nl',
            languageName: 'Nederlands',
            strings: <String, String>{
              'wc': ' ',
              'pc': 'P',
              'word.cat': 'Kat',
              'phrase.hello': 'Hallo.',
              'letter.a': 'appel',
              'word.gone': 'Weg',
            },
          ),
        ],
      );
      expect(report.whereCode(ValidationCodes.missingUiKey), isNotEmpty);
      expect(
        report
            .whereCode(ValidationCodes.blankTranslation)
            .any((ValidationIssue issue) => issue.id == 'wc'),
        isTrue,
      );
      expect(
        report
            .whereCode(ValidationCodes.staleTranslation)
            .any((ValidationIssue issue) => issue.id == 'word.gone'),
        isTrue,
      );
    });
  });
}

LanguagePack _emptyPack({
  String targetLanguageCode = 'und',
  String defaultTranslationLanguageCode = 'en',
  List<String> translationLanguageCodes = const <String>['en'],
}) {
  return LanguagePack(
    id: 'empty',
    name: 'Empty',
    version: '0',
    targetLanguageCode: targetLanguageCode,
    targetLanguageName: 'Sample',
    scriptFamily: ScriptFamily.latin,
    textDirection: ContentTextDirection.ltr,
    hasAlphabet: true,
    defaultTranslationLanguageCode: defaultTranslationLanguageCode,
    translationLanguageCodes: translationLanguageCodes,
    assetIndex: const <String, String>{},
  );
}

Map<String, String> _validAssets({
  String? product,
  String? pack,
  String? alphabet,
  String? words,
  String? phrases,
  String? en,
}) {
  return <String, String>{
    ProductConfig.assetPath: product ?? _productJson(),
    'assets/content/language_pack.json': pack ?? _packJson(),
    'assets/content/alphabet.json': alphabet ?? _alphabetJson(),
    'assets/content/word_categories.json': _wordCategoriesJson(),
    'assets/content/words.json': words ?? _wordsJson(),
    'assets/content/phrase_categories.json': _phraseCategoriesJson(),
    'assets/content/phrases.json': phrases ?? _phrasesJson(),
    'assets/content/translations/en.json': en ?? _enJson(),
  };
}

String _productJson({
  String direction = 'ltr',
  String code = 'und',
  String writingSystem = 'alphabet',
  bool alphabetFlag = true,
  bool audioFlag = false,
  List<String> translations = const <String>['en'],
}) {
  return jsonEncode(<String, Object?>{
    'id': 'lingo_core',
    'displayName': 'Lingo Core',
    'targetLanguageName': 'Sample',
    'targetLanguageCode': code,
    'nativeLanguageName': 'Sample',
    'textDirection': direction,
    'writingSystem': writingSystem,
    'primaryAccentColor': '#C46A3C',
    'contentPackPath': 'assets/content',
    'defaultTranslationLanguage': translations.first,
    'supportedTranslationLanguages': translations,
    'featureFlags': <String, Object?>{
      'alphabet': alphabetFlag,
      'audio': audioFlag,
    },
  });
}

String _packJson({Map<String, String> extraAssets = const <String, String>{}}) {
  return jsonEncode(<String, Object?>{
    'id': 'sample_core',
    'name': 'Sample Language Pack',
    'version': '0.1.0',
    'scriptFamily': 'latin',
    'assetIndex': <String, String>{
      'words.animals': 'assets/images/categories/words/animals.png',
      ...extraAssets,
    },
  });
}

String _alphabetJson() {
  return jsonEncode(<String, Object?>{
    'units': <Object?>[
      <String, Object?>{
        'id': 'letter.a',
        'glyph': 'A',
        'pronunciation': 'ah',
        'sortOrder': 0,
      },
      <String, Object?>{
        'id': 'letter.b',
        'glyph': 'B',
        'pronunciation': 'beh',
        'sortOrder': 1,
      },
    ],
  });
}

String _wordCategoriesJson() {
  return jsonEncode(<String, Object?>{
    'items': <Object?>[
      <String, Object?>{
        'id': 'word_category.animals',
        'title': 'Animals',
        'imageAssetId': 'words.animals',
        'artKind': 'animals',
        'sortOrder': 0,
      },
    ],
  });
}

String _wordsJson() {
  return jsonEncode(<String, Object?>{
    'items': <Object?>[
      <String, Object?>{
        'id': 'word.cat',
        'categoryId': 'word_category.animals',
        'text': 'Cat',
        'pronunciation': '/kæt/',
        'sortOrder': 0,
      },
    ],
  });
}

String _phraseCategoriesJson() {
  return jsonEncode(<String, Object?>{
    'items': <Object?>[
      <String, Object?>{
        'id': 'phrase_category.greetings',
        'title': 'Greetings',
        'sortOrder': 0,
      },
    ],
  });
}

String _phrasesJson() {
  return jsonEncode(<String, Object?>{
    'items': <Object?>[
      <String, Object?>{
        'id': 'phrase.hello',
        'categoryId': 'phrase_category.greetings',
        'text': 'Hello.',
        'sortOrder': 0,
      },
    ],
  });
}

String _enJson() {
  return jsonEncode(<String, Object?>{
    'languageCode': 'en',
    'languageName': 'English',
    'strings': <String, String>{
      'word.cat': 'A small animal.',
      'phrase.hello': 'A greeting.',
    },
  });
}
