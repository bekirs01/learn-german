import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/quiz_text.dart';
import 'package:lingo_core/domain/validation.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';

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

  test('German product identity stays de / de-DE', () {
    expect(repo.product.id, 'learn_german');
    expect(repo.product.targetLanguageCode, 'de');
    expect(repo.product.nativeLanguageName, 'Deutsch');
    expect(repo.product.speechLocale, 'de-DE');
    expect(repo.pack.targetLanguageCode, 'de');
    expect(repo.pack.targetLanguageName, 'German');
    expect(repo.pack.scriptFamily, ScriptFamily.latin);
  });

  test('German alphabet has 30 unique units including umlauts and ß', () {
    expect(repo.alphabet, hasLength(30));
    expect(repo.validation.whereCode(ValidationCodes.duplicateId), isEmpty);

    const List<String> glyphs = <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      'Ä',
      'Ö',
      'Ü',
      'ß',
    ];
    expect(
      repo.alphabet.map((AlphabetUnit unit) => unit.glyph).toList(),
      glyphs,
    );
    expect(repo.alphabet.map((AlphabetUnit unit) => unit.id).toList(), <String>[
      'letter.a',
      'letter.b',
      'letter.c',
      'letter.d',
      'letter.e',
      'letter.f',
      'letter.g',
      'letter.h',
      'letter.i',
      'letter.j',
      'letter.k',
      'letter.l',
      'letter.m',
      'letter.n',
      'letter.o',
      'letter.p',
      'letter.q',
      'letter.r',
      'letter.s',
      'letter.t',
      'letter.u',
      'letter.v',
      'letter.w',
      'letter.x',
      'letter.y',
      'letter.z',
      'letter.auml',
      'letter.ouml',
      'letter.uuml',
      'letter.eszett',
    ]);

    expect(repo.alphabetUnitById('letter.auml')?.example, 'Äpfel');
    expect(repo.alphabetUnitById('letter.ouml')?.example, 'Öl');
    expect(repo.alphabetUnitById('letter.uuml')?.example, 'Übung');
    expect(repo.alphabetUnitById('letter.eszett')?.example, 'Straße');
    expect(repo.alphabetUnitById('letter.eszett')?.glyph, 'ß');
    expect(repo.alphabetUnitById('letter.a')?.example, 'Apfel');
    expect(repo.alphabetUnitById('letter.i')?.example, 'Igel');
    expect(repo.alphabetUnitById('letter.j')?.pronunciation, 'jot');
    expect(repo.alphabetUnitById('letter.v')?.pronunciation, 'fau');
    expect(repo.alphabetUnitById('letter.w')?.pronunciation, 'we');
    expect(repo.alphabetUnitById('letter.y')?.pronunciation, 'Ypsilon');
    expect(repo.alphabetUnitById('letter.z')?.pronunciation, 'zett');
  });

  test('umlauts and ß are preserved in stored German spelling', () {
    final AlphabetUnit eszett = repo.alphabetUnitById('letter.eszett')!;
    expect(eszett.example, contains('ß'));
    expect(eszett.example, isNot(contains('ss')));
    expect(eszett.speechText, 'ß');
    expect(repo.alphabetUnitById('letter.auml')?.glyph, 'Ä');
    expect(repo.alphabetUnitById('letter.ouml')?.glyph, 'Ö');
    expect(repo.alphabetUnitById('letter.uuml')?.glyph, 'Ü');
    expect(repo.translation('letter.eszett', languageCode: 'de'), 'Straße');
    expect(repo.translation('letter.auml', languageCode: 'de'), 'Äpfel');
  });

  test('alphabet examples stay German and match their teaching letter', () {
    const Set<String> leftoverEnglish = <String>{
      'apple',
      'book',
      'cat',
      'dog',
      'juice',
      'key',
      'queen',
      'umbrella',
      'yellow',
      'ice',
      'eis',
    };
    for (final AlphabetUnit unit in repo.alphabet) {
      final String example = unit.example!.trim();
      expect(leftoverEnglish.contains(example.toLowerCase()), isFalse);
      expect(example, isNot(matches(RegExp(r'^[a-z]'))));
      if (unit.id == 'letter.eszett') {
        expect(example, contains('ß'));
      } else {
        expect(example[0].toUpperCase(), unit.glyph, reason: unit.id);
      }
    }
  });

  test('learner glosses cover every alphabet unit in all 15 languages', () {
    for (final String code in LearnerLanguages.orderedCodes) {
      for (final AlphabetUnit unit in repo.alphabet) {
        final String? value = repo.translation(unit.id, languageCode: code);
        expect(value, isNotNull, reason: '$code ${unit.id}');
        expect(value!.trim(), isNotEmpty, reason: '$code ${unit.id}');
      }
    }
    expect(repo.translation('letter.a', languageCode: 'en'), 'apple');
    expect(repo.translation('letter.a', languageCode: 'tr'), 'elma');
  });

  test('alphabet audio files exist for every German letter', () {
    for (final AlphabetUnit unit in repo.alphabet) {
      expect(unit.audioAsset, isNull, reason: unit.id);
      final String prepared = 'assets/audio/de/alphabet/${unit.id}.wav';
      expect(repo.pronunciationAssetFor(unit.id), prepared, reason: unit.id);
      final File file = File(prepared);
      expect(file.existsSync(), isTrue, reason: unit.id);
      expect(file.lengthSync(), greaterThan(1500), reason: unit.id);
      expect(unit.speechText, unit.glyph, reason: unit.id);
      expect(
        PronunciationClip.fromAlphabet(unit).speechText,
        unit.glyph,
        reason: unit.id,
      );
      expect(prepared, contains('/de/alphabet/'));
      expect(prepared, contains(unit.id));
    }
    expect(Directory('assets/audio/de/alphabet').existsSync(), isTrue);
  });

  test('semantic stills exist for every German alphabet example', () {
    for (final AlphabetUnit unit in repo.alphabet) {
      final String path = unit.imageAsset!;
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(path, startsWith('assets/images/alphabet/'));
    }
    expect(File('assets/images/alphabet/dog.png').existsSync(), isFalse);
    expect(File('assets/images/alphabet/ice.png').existsSync(), isFalse);
    expect(File('assets/images/alphabet/juice.png').existsSync(), isFalse);
    expect(File('assets/images/alphabet/queen.png').existsSync(), isFalse);
    expect(File('assets/images/alphabet/yellow.png').existsSync(), isFalse);
  });

  test('search folds umlauts and ß without changing stored spelling', () {
    expect(QuizText.searchKey('Äpfel'), 'apfel');
    expect(QuizText.searchKey('Öl'), 'ol');
    expect(QuizText.searchKey('Übung'), 'ubung');
    expect(QuizText.searchKey('Straße'), 'strasse');
    expect(QuizText.matchesQuery('Äpfel', 'apfel'), isTrue);
    expect(QuizText.matchesQuery('Straße', 'strasse'), isTrue);
    expect(QuizText.matchesQuery('Straße', 'ß'), isTrue);
    expect(QuizText.equals('Äpfel', 'Apfel', caseSensitive: false), isFalse);
    expect(QuizText.equals('Straße', 'Strasse', caseSensitive: false), isFalse);
  });

  test('Watch picker search matches German umlauts and ß', () {
    final LocalContentRepository german = _germanWatchRepo();
    final List<WatchPickerRow> umlaut = WatchCatalog.pickerRows(
      content: german,
      learnerLanguageCode: 'en',
      filter: WatchContentFilter.words,
      query: 'apfel',
    );
    expect(
      umlaut.any((WatchPickerRow row) => row.item?.targetText == 'Äpfel'),
      isTrue,
    );

    final List<WatchPickerRow> eszett = WatchCatalog.pickerRows(
      content: german,
      learnerLanguageCode: 'en',
      filter: WatchContentFilter.words,
      query: 'strasse',
    );
    expect(
      eszett.any((WatchPickerRow row) => row.item?.targetText == 'Straße'),
      isTrue,
    );
  });
}

LocalContentRepository _germanWatchRepo() {
  return LocalContentRepository(
    product: ProductConfig.fallback.copyWith(
      targetLanguageCode: 'de',
      speechLocale: 'de-DE',
    ),
    pack: const LanguagePack(
      id: 'de-watch-search-test',
      name: 'German Watch Search Test',
      version: '1',
      targetLanguageCode: 'de',
      targetLanguageName: 'German',
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      hasAlphabet: false,
      defaultTranslationLanguageCode: 'en',
      translationLanguageCodes: <String>['en'],
      assetIndex: <String, String>{},
    ),
    alphabet: const <AlphabetUnit>[],
    wordCategories: const <ContentCategory>[
      ContentCategory(id: 'words.food', title: 'Food', sortOrder: 0),
    ],
    phraseCategories: const <ContentCategory>[],
    words: const <WordEntry>[
      WordEntry(
        id: 'word.food.apples',
        categoryId: 'words.food',
        text: 'Äpfel',
        sortOrder: 0,
        quizEnabled: true,
      ),
      WordEntry(
        id: 'word.places.street',
        categoryId: 'words.food',
        text: 'Straße',
        sortOrder: 1,
        quizEnabled: true,
      ),
    ],
    phrases: const <PhraseEntry>[],
    translationBundles: const <TranslationBundle>[
      TranslationBundle(
        languageCode: 'en',
        languageName: 'English',
        strings: <String, String>{
          'word.food.apples': 'apples',
          'word.places.street': 'street',
          'words.food': 'Food',
        },
      ),
    ],
  );
}
