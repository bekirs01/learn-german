import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_engine.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/domain/validation.dart';

/// Structure and quality checks for the master catalog.
/// Integrity assertions stay language-agnostic. Sample-specific checks
/// are retargeted to German (`de` / `de-DE`) for this product.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalContentRepository repo;

  setUp(() async {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    repo = await LocalContentRepository.load();
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
  });

  test('full content validation is clean', () {
    expect(repo.validation.issues, isEmpty);
    expect(repo.validation.hasErrors, isFalse);
    expect(repo.validation.whereCode(ValidationCodes.duplicateId), isEmpty);
    expect(
      repo.validation.whereCode(ValidationCodes.invalidCategoryReference),
      isEmpty,
    );
    expect(
      repo.validation.whereCode(ValidationCodes.missingTranslation),
      isEmpty,
    );
    expect(
      repo.validation.whereCode(ValidationCodes.missingAssetReference),
      isEmpty,
    );
    expect(repo.validation.whereCode(ValidationCodes.emptyCategory), isEmpty);
    expect(
      repo.validation.whereCode(ValidationCodes.invalidPronunciation),
      isEmpty,
    );
    expect(repo.validation.whereCode(ValidationCodes.quizNotReady), isEmpty);
  });

  test('language pack is complete for conversion', () {
    expect(repo.pack.id, isNotEmpty);
    expect(repo.pack.version, isNotEmpty);
    expect(repo.pack.hasAlphabet, isTrue);
    expect(repo.pack.defaultTranslationLanguageCode, 'en');
    expect(repo.pack.translationLanguageCodes, LearnerLanguages.orderedCodes);
    expect(
      repo.translationBundles.map((TranslationBundle b) => b.languageCode),
      containsAll(LearnerLanguages.orderedCodes),
    );
    expect(repo.product.supportedTranslationLanguages, contains('en'));
  });

  test('category integrity and illustration assets', () {
    expect(
      repo.wordCategories.map((ContentCategory c) => c.id),
      containsAll(<String>[
        'word_category.basics',
        'word_category.numbers',
        'word_category.colors',
        'word_category.family',
        'word_category.people',
        'word_category.body',
        'word_category.emotions',
        'word_category.food',
        'word_category.drinks',
        'word_category.home',
        'word_category.clothing',
        'word_category.animals',
        'word_category.nature',
        'word_category.weather',
        'word_category.school',
        'word_category.work',
        'word_category.sports',
        'word_category.shopping',
        'word_category.travel',
        'word_category.transportation',
        'word_category.health',
        'word_category.time',
        'word_category.places',
      ]),
    );
    expect(
      repo.phraseCategories.map((ContentCategory c) => c.id),
      containsAll(<String>[
        'phrase_category.greetings',
        'phrase_category.introductions',
        'phrase_category.daily_conversation',
        'phrase_category.questions',
        'phrase_category.restaurant',
        'phrase_category.cafe',
        'phrase_category.shopping',
        'phrase_category.hotel',
        'phrase_category.airport',
        'phrase_category.transportation',
        'phrase_category.directions',
        'phrase_category.doctor',
        'phrase_category.pharmacy',
        'phrase_category.emergency',
        'phrase_category.work',
        'phrase_category.school',
        'phrase_category.social_situations',
      ]),
    );

    for (final ContentCategory category in repo.wordCategories) {
      expect(category.imageAsset, isNotEmpty, reason: category.id);
      expect(
        repo.wordsForCategory(category.id).length,
        greaterThanOrEqualTo(40),
        reason: category.id,
      );
    }
    for (final ContentCategory category in repo.phraseCategories) {
      expect(category.imageAsset, isNotEmpty, reason: category.id);
      expect(
        repo.phrasesForCategory(category.id).length,
        greaterThanOrEqualTo(28),
        reason: category.id,
      );
    }

    expect(
      repo.phraseCategoryById('phrase_category.work')?.imageAsset,
      contains('work.png'),
    );
    expect(
      repo.phraseCategoryById('phrase_category.school')?.imageAsset,
      contains('school.png'),
    );
  });

  test('IDs are unique and pronunciations are quiz-ready', () {
    final Set<String> ids = <String>{};
    void take(String id) {
      expect(ids.add(id), isTrue, reason: 'Duplicate ID "$id".');
    }

    expect(repo.alphabet, hasLength(30));
    expect(repo.alphabetUnitById('letter.b')?.pronunciation, 'beh');
    expect(repo.alphabet.first.example, 'Apfel');
    expect(repo.alphabetUnitById('letter.auml')?.example, 'Äpfel');
    expect(repo.alphabetUnitById('letter.eszett')?.glyph, 'ß');

    for (final AlphabetUnit unit in repo.alphabet) {
      take(unit.id);
      expect(unit.glyph, isNotEmpty);
      expect(unit.pronunciation, isNotEmpty);
      expect(unit.quizEnabled, isTrue);
      expect(unit.example, isNotEmpty);
      expect(unit.imageAsset, isNotEmpty);
    }

    final Set<String> wordTexts = <String>{};
    final Set<String> wordTextsNormalized = <String>{};
    final Set<String> englishMeanings = <String>{};
    final Set<String> turkishMeanings = <String>{};
    final RegExp ipa = RegExp(r'^/.+/$');
    final RegExp ignorablePunct = RegExp(r'[.?!]+');
    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(ignorablePunct, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    int wordCount = 0;
    for (final ContentCategory category in repo.wordCategories) {
      take(category.id);
      int? previousWordOrder;
      for (final WordEntry word in repo.wordsForCategory(category.id)) {
        take(word.id);
        expect(word.id.startsWith('word.'), isTrue, reason: word.id);
        expect(word.categoryId, category.id);
        expect(word.text.trim(), isNotEmpty, reason: word.id);
        expect(ipa.hasMatch(word.pronunciation ?? ''), isTrue, reason: word.id);
        expect(word.quizEnabled, isTrue, reason: word.id);
        if (previousWordOrder != null) {
          expect(
            word.sortOrder,
            greaterThan(previousWordOrder),
            reason: word.id,
          );
        }
        previousWordOrder = word.sortOrder;
        expect(wordTexts.add(word.text.toLowerCase()), isTrue, reason: word.id);
        expect(
          wordTextsNormalized.add(normalize(word.text)),
          isTrue,
          reason: word.id,
        );
        final String english =
            repo.translation(word.id, languageCode: 'en') ?? '';
        final String turkish =
            repo.translation(word.id, languageCode: 'tr') ?? '';
        expect(english.trim(), isNotEmpty, reason: word.id);
        expect(turkish.trim(), isNotEmpty, reason: word.id);
        expect(
          englishMeanings.add(english.toLowerCase()),
          isTrue,
          reason: word.id,
        );
        expect(
          turkishMeanings.add(turkish.toLowerCase()),
          isTrue,
          reason: word.id,
        );
        wordCount += 1;
      }
    }
    expect(wordCount, greaterThanOrEqualTo(900));
    expect(wordCount / repo.wordCategories.length, greaterThanOrEqualTo(40));

    final Set<String> phraseTexts = <String>{};
    final Set<String> phraseTextsNormalized = <String>{};
    final Set<String> phraseEnglishMeanings = <String>{};
    final Set<String> phraseTurkishMeanings = <String>{};
    int phraseCount = 0;
    for (final ContentCategory category in repo.phraseCategories) {
      take(category.id);
      final String categorySlug = category.id.replaceFirst(
        'phrase_category.',
        '',
      );
      int? previousSortOrder;
      for (final PhraseEntry phrase in repo.phrasesForCategory(category.id)) {
        take(phrase.id);
        expect(phrase.categoryId, category.id, reason: phrase.id);
        expect(
          phrase.id.startsWith('phrase.$categorySlug.'),
          isTrue,
          reason: phrase.id,
        );
        expect(phrase.text.trim(), isNotEmpty, reason: phrase.id);
        expect(phrase.text.contains('...'), isFalse, reason: phrase.id);
        expect(
          ipa.hasMatch(phrase.pronunciation ?? ''),
          isTrue,
          reason: phrase.id,
        );
        expect(phrase.quizEnabled, isTrue, reason: phrase.id);
        if (previousSortOrder != null) {
          expect(
            phrase.sortOrder,
            greaterThan(previousSortOrder),
            reason: phrase.id,
          );
        }
        previousSortOrder = phrase.sortOrder;
        expect(
          phraseTexts.add(phrase.text.toLowerCase()),
          isTrue,
          reason: phrase.id,
        );
        expect(
          phraseTextsNormalized.add(normalize(phrase.text)),
          isTrue,
          reason: phrase.id,
        );
        final String english =
            repo.translation(phrase.id, languageCode: 'en') ?? '';
        final String turkish =
            repo.translation(phrase.id, languageCode: 'tr') ?? '';
        expect(english.trim(), isNotEmpty, reason: phrase.id);
        expect(turkish.trim(), isNotEmpty, reason: phrase.id);
        expect(
          phraseEnglishMeanings.add(english.toLowerCase()),
          isTrue,
          reason: phrase.id,
        );
        expect(
          phraseTurkishMeanings.add(turkish.toLowerCase()),
          isTrue,
          reason: phrase.id,
        );
        phraseCount += 1;
      }
    }
    expect(phraseCount, greaterThanOrEqualTo(400));
    expect(
      phraseCount / repo.phraseCategories.length,
      greaterThanOrEqualTo(28),
    );
  });

  test('phrase curriculum covers essential real-world situations', () {
    const List<String> requiredPhraseIds = <String>[
      'phrase.greetings.hello',
      'phrase.greetings.good_morning',
      'phrase.greetings.how_are_you',
      'phrase.restaurant.can_i_see_the_menu',
      'phrase.restaurant.what_do_you_recommend',
      'phrase.hotel.i_have_a_reservation',
      'phrase.directions.where_is_the_station',
      'phrase.directions.turn_left',
      'phrase.emergency.i_need_help',
      'phrase.emergency.call_the_police',
      'phrase.emergency.call_an_ambulance',
      'phrase.hotel.i_would_like_to_check_in',
      'phrase.airport.my_luggage_is_missing',
      'phrase.doctor.i_have_been_like_this_for_two_days',
    ];
    for (final String id in requiredPhraseIds) {
      final PhraseEntry? phrase = repo.phraseById(id);
      expect(phrase, isNotNull, reason: id);
      expect(phrase!.text.trim(), isNotEmpty, reason: id);
      expect(phrase.quizEnabled, isTrue, reason: id);
      expect(
        repo.translation(id, languageCode: 'en')?.trim(),
        isNotEmpty,
        reason: id,
      );
      expect(
        repo.translation(id, languageCode: 'tr')?.trim(),
        isNotEmpty,
        reason: id,
      );
    }
  });

  test('translation bundles cover every word and phrase', () {
    final List<String> contentIds = <String>[
      for (final ContentCategory category in repo.wordCategories) category.id,
      for (final ContentCategory category in repo.phraseCategories) category.id,
      for (final ContentCategory category in repo.wordCategories)
        for (final WordEntry word in repo.wordsForCategory(category.id))
          word.id,
      for (final ContentCategory category in repo.phraseCategories)
        for (final PhraseEntry phrase in repo.phrasesForCategory(category.id))
          phrase.id,
    ];
    expect(contentIds, isNotEmpty);
    for (final TranslationBundle bundle in repo.translationBundles) {
      expect(LearnerLanguages.codes, contains(bundle.languageCode));
      for (final String id in contentIds) {
        final String? value = bundle.strings[id];
        expect(value, isNotNull, reason: '${bundle.languageCode} $id');
        expect(value!.trim(), isNotEmpty, reason: '${bundle.languageCode} $id');
      }
    }
    expect(repo.translationBundles, hasLength(LearnerLanguages.codes.length));

    final Set<String> liveIds = contentIds.toSet()
      ..addAll(repo.alphabet.map((AlphabetUnit unit) => unit.id));
    const List<String> uiPrefixes = <String>[
      'nav.',
      'settings.',
      'quiz.',
      'favorites.',
      'common.',
      'app.',
      'audio.',
      'language.',
    ];
    for (final TranslationBundle bundle in repo.translationBundles) {
      for (final String key in bundle.strings.keys) {
        expect(
          liveIds.contains(key),
          isTrue,
          reason: 'Stale ${bundle.languageCode} key "$key".',
        );
        expect(
          uiPrefixes.any(key.startsWith),
          isFalse,
          reason: 'UI key "$key" must not live in content translations.',
        );
      }
    }
  });

  test('numbers curriculum covers essential numeric milestones', () {
    const List<String> requiredIds = <String>[
      'word.number.zero',
      'word.number.one',
      'word.number.two',
      'word.number.three',
      'word.number.four',
      'word.number.five',
      'word.number.six',
      'word.number.seven',
      'word.number.eight',
      'word.number.nine',
      'word.number.ten',
      'word.number.eleven',
      'word.number.twelve',
      'word.number.thirteen',
      'word.number.fourteen',
      'word.number.fifteen',
      'word.number.sixteen',
      'word.number.seventeen',
      'word.number.eighteen',
      'word.number.nineteen',
      'word.number.twenty',
      'word.number.thirty',
      'word.number.forty',
      'word.number.fifty',
      'word.number.sixty',
      'word.number.seventy',
      'word.number.eighty',
      'word.number.ninety',
      'word.number.hundred',
      'word.number.two_hundred',
      'word.number.five_hundred',
      'word.number.one_thousand',
      'word.number.ten_thousand',
      'word.number.one_hundred_thousand',
      'word.number.one_million',
      'word.number.first',
      'word.number.second',
      'word.number.third',
      'word.number.half',
      'word.number.quarter',
    ];
    for (final String id in requiredIds) {
      final WordEntry? word = repo.wordById(id);
      expect(word, isNotNull, reason: id);
      expect(word!.categoryId, 'word_category.numbers', reason: id);
      expect(word.text.trim(), isNotEmpty, reason: id);
      expect(word.quizEnabled, isTrue, reason: id);
    }
  });

  test('word curriculum covers practical everyday gaps', () {
    const List<(String, String)> requiredWords = <(String, String)>[
      ('word.time.seconds', 'word_category.time'),
      ('word.transportation.platform', 'word_category.transportation'),
      ('word.transportation.traffic_jam', 'word_category.transportation'),
      ('word.people.waiter', 'word_category.people'),
      ('word.people.police_officer', 'word_category.people'),
    ];
    for (final (String id, String categoryId) in requiredWords) {
      final WordEntry? word = repo.wordById(id);
      expect(word, isNotNull, reason: id);
      expect(word!.categoryId, categoryId, reason: id);
      expect(word.text.trim(), isNotEmpty, reason: id);
      expect(word.quizEnabled, isTrue, reason: id);
      expect(
        repo.translation(id, languageCode: 'en')?.trim(),
        isNotEmpty,
        reason: id,
      );
      expect(
        repo.translation(id, languageCode: 'tr')?.trim(),
        isNotEmpty,
        reason: id,
      );
    }
  });

  test('target rows stay separate from learner translations', () {
    final RegExp turkishSpecificLetters = RegExp(r'[ğşçıİĞŞÇ]');
    for (final ContentCategory category in repo.wordCategories) {
      for (final WordEntry word in repo.wordsForCategory(category.id)) {
        expect(
          turkishSpecificLetters.hasMatch(word.text),
          isFalse,
          reason: word.id,
        );
      }
    }
    for (final ContentCategory category in repo.phraseCategories) {
      for (final PhraseEntry phrase in repo.phrasesForCategory(category.id)) {
        expect(
          turkishSpecificLetters.hasMatch(phrase.text),
          isFalse,
          reason: phrase.id,
        );
      }
    }
  });

  test('target JSON rows do not embed learner-language fields', () async {
    const Set<String> allowed = <String>{
      'id',
      'categoryId',
      'text',
      'pronunciation',
      'romanization',
      'grammaticalGender',
      'plural',
      'imageAsset',
      'imageAssetId',
      'audioAsset',
      'audioAssetId',
      'sortOrder',
      'quizEnabled',
    };

    Future<void> checkFile(String assetPath) async {
      final Object? decoded = jsonDecode(
        await rootBundle.loadString(assetPath),
      );
      expect(decoded, isA<Map<dynamic, dynamic>>());
      final Object? itemsRaw = (decoded as Map<dynamic, dynamic>)['items'];
      expect(itemsRaw, isA<List<dynamic>>());
      for (final Object? raw in itemsRaw as List<dynamic>) {
        expect(raw, isA<Map<dynamic, dynamic>>(), reason: assetPath);
        final Map<dynamic, dynamic> item = raw! as Map<dynamic, dynamic>;
        expect(
          item.keys.map((dynamic key) => '$key').toSet().difference(allowed),
          isEmpty,
          reason: '${item['id']}',
        );
      }
    }

    await checkFile('assets/content/words.json');
    await checkFile('assets/content/phrases.json');
  });

  test('quiz eligibility covers every enabled item', () {
    final int expected =
        repo.alphabet.where((AlphabetUnit unit) => unit.quizEnabled).length +
        <WordEntry>[
          for (final ContentCategory category in repo.wordCategories)
            ...repo.wordsForCategory(category.id),
        ].where((WordEntry word) => word.quizEnabled).length +
        <PhraseEntry>[
          for (final ContentCategory category in repo.phraseCategories)
            ...repo.phrasesForCategory(category.id),
        ].where((PhraseEntry phrase) => phrase.quizEnabled).length;

    expect(repo.quizItems, hasLength(expected));
    expect(
      repo.quizItems.every((QuizReadyItem item) => item.prompt.isNotEmpty),
      isTrue,
    );
    expect(
      repo.quizItems
          .where((QuizReadyItem item) => item.kind != QuizContentKind.alphabet)
          .every(
            (QuizReadyItem item) =>
                item.answersByLanguage['en'] != null &&
                item.answersByLanguage['en']!.trim().isNotEmpty &&
                item.answersByLanguage['tr'] != null &&
                item.answersByLanguage['tr']!.trim().isNotEmpty,
          ),
      isTrue,
    );

    final List<QuizReadyItem> quizWords = repo.quizItems
        .where((QuizReadyItem item) => item.kind == QuizContentKind.word)
        .toList(growable: false);
    expect(quizWords.length, greaterThanOrEqualTo(900));
    expect(
      quizWords
          .map(
            (QuizReadyItem item) => item.answersByLanguage['en']!.toLowerCase(),
          )
          .toSet(),
      hasLength(quizWords.length),
    );
    expect(
      quizWords
          .map(
            (QuizReadyItem item) => item.answersByLanguage['tr']!.toLowerCase(),
          )
          .toSet(),
      hasLength(quizWords.length),
    );

    final List<QuizReadyItem> quizPhrases = repo.quizItems
        .where((QuizReadyItem item) => item.kind == QuizContentKind.phrase)
        .toList(growable: false);
    expect(quizPhrases.length, greaterThanOrEqualTo(400));
    expect(
      quizPhrases
          .map(
            (QuizReadyItem item) => item.answersByLanguage['en']!.toLowerCase(),
          )
          .toSet(),
      hasLength(quizPhrases.length),
    );
    expect(
      quizPhrases
          .map(
            (QuizReadyItem item) => item.answersByLanguage['tr']!.toLowerCase(),
          )
          .toSet(),
      hasLength(quizPhrases.length),
    );
  });

  test(
    'bundled pack quizzes stay available for English and Turkish learners',
    () {
      final QuizEngine engine = QuizEngine(random: Random(7));
      final List<QuizReadyItem> words = repo.quizItems
          .where((QuizReadyItem item) => item.kind == QuizContentKind.word)
          .toList(growable: false);
      final List<QuizReadyItem> phrases = repo.quizItems
          .where((QuizReadyItem item) => item.kind == QuizContentKind.phrase)
          .toList(growable: false);

      expect(
        engine.availableTypes(
          items: words,
          optionPool: words,
          translationLanguageCode: 'tr',
        ),
        <QuizType>[
          QuizType.multipleChoice,
          QuizType.reverseMultipleChoice,
          QuizType.typing,
        ],
      );
      expect(
        engine.availableTypes(
          items: phrases,
          optionPool: phrases,
          translationLanguageCode: 'tr',
        ),
        <QuizType>[
          QuizType.multipleChoice,
          QuizType.reverseMultipleChoice,
          QuizType.buildSequence,
          QuizType.typing,
        ],
      );
      expect(
        engine.availableTypes(
          items: words,
          optionPool: words,
          translationLanguageCode: 'en',
        ),
        <QuizType>[
          QuizType.multipleChoice,
          QuizType.reverseMultipleChoice,
          QuizType.typing,
        ],
      );
      expect(
        engine.availableTypes(
          items: phrases,
          optionPool: phrases,
          translationLanguageCode: 'en',
        ),
        containsAll(<QuizType>[
          QuizType.reverseMultipleChoice,
          QuizType.buildSequence,
          QuizType.typing,
        ]),
      );
      expect(
        engine
            .availableTypes(
              items: words,
              optionPool: words,
              translationLanguageCode: 'en',
            )
            .contains(QuizType.buildSequence),
        isFalse,
      );
    },
  );
}
