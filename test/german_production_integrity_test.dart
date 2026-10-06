import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/audio/expected_audio.dart';
import 'package:lingo_core/core/audio/target_speech_locale.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/quiz_engine.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/domain/validation.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/domain/watch_learning_plan.dart';
import 'package:lingo_core/domain/wrong_answers.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalContentRepository repo;
  late ExpectedAudioInventory inventory;

  setUp(() async {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
    repo = await LocalContentRepository.load();
    inventory = ExpectedAudio.buildFrom(repo);
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
  });

  test('German product identity is consistent across pack and fallback', () {
    expect(repo.product.id, 'learn_german');
    expect(repo.product.displayName, 'Learn German for Beginners');
    expect(repo.product.targetLanguageName, 'German');
    expect(repo.product.targetLanguageCode, 'de');
    expect(repo.product.nativeLanguageName, 'Deutsch');
    expect(repo.product.speechLocale, 'de-DE');
    expect(repo.product.speechProfile.locale, 'de-DE');
    expect(repo.product.speechProfile.preferredVoiceName, 'Anna');
    expect(TargetSpeechLocale.resolve(product: repo.product), 'de-DE');
    expect(TargetSpeechLocale.languageCode('de-DE'), 'de');
    expect(repo.pack.id, 'learn_german');
    expect(repo.pack.targetLanguageCode, 'de');
    expect(repo.pack.targetLanguageName, 'German');
    expect(repo.pack.version, '2.1.0');
    expect(ProductConfig.fallback.id, 'learn_german');
    expect(ProductConfig.fallback.targetLanguageCode, 'de');
    expect(ProductConfig.fallback.nativeLanguageName, 'Deutsch');
  });

  test(
    'native identity files stay Learn German / de, not the old English core',
    () {
      expect(
        File('android/app/src/main/res/values/strings.xml').readAsStringSync(),
        contains('Learn German for Beginners'),
      );
      expect(
        File('android/app/build.gradle.kts').readAsStringSync(),
        contains('com.lingocore.learn_german'),
      );
      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        contains('Learn German for Beginners'),
      );
      expect(
        File('ios/LingoWatch/Info.plist').readAsStringSync(),
        allOf(
          contains('Learn German'),
          contains('com.lingocore.learnGerman'),
          isNot(contains('Learn English')),
          isNot(contains('Learn Italian')),
          isNot(contains('Learn French')),
          isNot(contains('Learn Spanish')),
        ),
      );
      expect(
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
        allOf(
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.lingocore.learnGerman;'),
          contains(
            'PRODUCT_BUNDLE_IDENTIFIER = com.lingocore.learnGerman.watchkitapp;',
          ),
        ),
      );
      expect(File('ios/Runner/PrivacyInfo.xcprivacy').existsSync(), isTrue);
      expect(File('ios/LingoWatch/PrivacyInfo.xcprivacy').existsSync(), isTrue);
      expect(
        File('docs/privacy.html').readAsStringSync(),
        allOf(
          contains('Learn German'),
          contains('com.lingocore.learnGerman'),
          isNot(contains('Learn Italian')),
          isNot(contains('Learn English')),
          isNot(contains('Learn French')),
          isNot(contains('Learn Spanish')),
        ),
      );
      expect(
        File('docs/support.html').readAsStringSync(),
        allOf(
          contains('Learn German'),
          contains(
            'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
          ),
          isNot(contains('Learn Italian')),
        ),
      );
      expect(
        File('assets/product.json').readAsStringSync(),
        allOf(contains('"de-DE"'), contains('"learn_german"')),
      );
      expect(
        File('lib/core/audio/target_speech_locale.dart').readAsStringSync(),
        contains("'de': 'de-DE'"),
      );
    },
  );

  test('curriculum counts reconcile exactly', () {
    expect(repo.wordCategories, hasLength(23));
    expect(repo.phraseCategories, hasLength(17));
    expect(repo.alphabet, hasLength(30));
    expect(repo.translationBundles, hasLength(15));

    int words = 0;
    for (final ContentCategory category in repo.wordCategories) {
      words += repo.wordsForCategory(category.id).length;
    }
    int phrases = 0;
    for (final ContentCategory category in repo.phraseCategories) {
      phrases += repo.phrasesForCategory(category.id).length;
    }
    expect(words, 1156);
    expect(phrases, 612);
    expect(repo.quizItems, hasLength(30 + 1156 + 612));
    expect(inventory.count, 1798);
    expect(inventory.locale, 'de-DE');
    expect(inventory.languageCode, 'de');
    expect(inventory.isStructurallyValid, isTrue);
  });

  test('committed audio manifest count equals live inventory', () {
    final Map<String, Object?> decoded =
        jsonDecode(File('docs/expected_audio_manifest.json').readAsStringSync())
            as Map<String, Object?>;
    expect(decoded['count'], 1798);
    expect(decoded['locale'], 'de-DE');
    expect(decoded['languageCode'], 'de');
    expect((decoded['items'] as List<Object?>).length, inventory.count);
    expect(decoded['count'], inventory.count);
  });

  test('full validation report stays clean', () {
    expect(repo.validation.issues, isEmpty);
    expect(repo.validation.hasErrors, isFalse);
    expect(repo.validation.whereCode(ValidationCodes.duplicateId), isEmpty);
    expect(
      repo.validation.whereCode(ValidationCodes.invalidCategoryReference),
      isEmpty,
    );
    expect(repo.validation.whereCode(ValidationCodes.emptyCategory), isEmpty);
  });

  test('German alphabet includes Ä Ö Ü ß with unique IDs and stills', () {
    expect(
      repo.alphabet.map((AlphabetUnit unit) => unit.glyph).toList(),
      <String>[
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
      ],
    );
    expect(
      repo.alphabet.map((AlphabetUnit unit) => unit.id).toSet(),
      hasLength(30),
    );
    expect(repo.alphabetUnitById('letter.auml')?.example, 'Äpfel');
    expect(repo.alphabetUnitById('letter.ouml')?.example, 'Öl');
    expect(repo.alphabetUnitById('letter.uuml')?.example, 'Übung');
    expect(repo.alphabetUnitById('letter.eszett')?.example, 'Straße');
    for (final AlphabetUnit unit in repo.alphabet) {
      expect(unit.imageAsset, isNotEmpty, reason: unit.id);
      expect(
        File(unit.imageAsset!).existsSync(),
        isTrue,
        reason: unit.imageAsset,
      );
      expect(unit.imageAsset, isNot(contains('dog.png')));
    }
  });

  test('German nouns keep articles, umlauts, and ß', () {
    int gendered = 0;
    int plurals = 0;
    int umlauts = 0;
    int eszett = 0;
    for (final ContentCategory category in repo.wordCategories) {
      for (final WordEntry word in repo.wordsForCategory(category.id)) {
        final String gender = word.grammaticalGender ?? '';
        if (gender == 'der' || gender == 'die' || gender == 'das') {
          gendered += 1;
          expect(
            word.text.startsWith('$gender ') ||
                word.text.startsWith('eine ') ||
                word.text.startsWith('ein '),
            isTrue,
            reason: '${word.id} ${word.text} ($gender)',
          );
        }
        if (word.plural != null && word.plural!.trim().isNotEmpty) {
          plurals += 1;
        }
        if (word.text.contains(RegExp('[ÄÖÜäöü]'))) {
          umlauts += 1;
        }
        if (word.text.contains('ß') || (word.plural ?? '').contains('ß')) {
          eszett += 1;
        }
        expect(word.text, isNot(contains('Ã')));
        expect(word.text, isNot(contains('�')));
      }
    }
    expect(gendered, 870);
    expect(plurals, 694);
    expect(umlauts, greaterThan(80));
    expect(eszett, greaterThan(10));
    expect(repo.wordById('word.number.one_million')?.text, 'eine Million');
    expect(repo.wordById('word.basics.hello')?.text, 'Hallo');
    expect(repo.phraseById('phrase.greetings.hello')?.text, 'Hallo.');
    expect(
      repo.phraseById('phrase.introductions.i_am_learning_english')?.text,
      'Ich lerne Deutsch.',
    );
    expect(
      repo.phraseById('phrase.introductions.let_me_introduce_myself')?.text,
      'Darf ich mich vorstellen?',
    );
    expect(
      repo.phraseById('phrase.introductions.let_me_introduce_my_friend')?.text,
      'Darf ich meinen Freund vorstellen?',
    );
  });

  test('runtime target rows are not leftover English source sentences', () {
    const Set<String> leftoverEnglish = <String>{
      'Hello',
      'Hello.',
      'Good morning.',
      'Thank you.',
      'Mother',
      'Father',
      'Apple',
      'Cat',
      'Dog',
      'How are you?',
      'My name is',
      'I am learning English.',
      'I speak a little English.',
    };
    for (final ContentCategory category in repo.wordCategories) {
      for (final WordEntry word in repo.wordsForCategory(category.id)) {
        expect(leftoverEnglish.contains(word.text), isFalse, reason: word.id);
      }
    }
    for (final ContentCategory category in repo.phraseCategories) {
      for (final PhraseEntry phrase in repo.phrasesForCategory(category.id)) {
        expect(
          leftoverEnglish.contains(phrase.text),
          isFalse,
          reason: phrase.id,
        );
        expect(phrase.text.contains('...'), isFalse, reason: phrase.id);
        expect(phrase.text.toLowerCase(), isNot(contains('todo')));
      }
    }
    expect(
      repo.phraseById('phrase.introductions.do_you_speak_english')?.text,
      'Sprichst du Englisch?',
    );
  });

  test('learner languages stay glosses; German is the spoken target', () {
    expect(
      LearnerLanguages.orderedCodes,
      containsAll(<String>['en', 'tr', 'de']),
    );
    expect(repo.translation('word.basics.hello', languageCode: 'en'), 'Hello');
    expect(
      repo.translation('word.basics.hello', languageCode: 'tr'),
      'Merhaba',
    );
    expect(repo.wordById('word.basics.hello')?.text, isNot('Hello'));
    final QuizEngine engine = QuizEngine(random: Random(3));
    final List<QuizReadyItem> words = repo.quizItems
        .where((QuizReadyItem item) => item.kind == QuizContentKind.word)
        .toList(growable: false);
    expect(
      engine
          .availableTypes(
            items: words,
            optionPool: words,
            translationLanguageCode: 'en',
          )
          .contains(QuizType.multipleChoice),
      isTrue,
    );
  });

  test('visual assets exist and leftover English alphabet stills are gone', () {
    for (final MapEntry<String, String> entry in repo.pack.assetIndex.entries) {
      expect(File(entry.value).existsSync(), isTrue, reason: entry.value);
    }
    const List<String> stale = <String>[
      'assets/images/alphabet/dog.png',
      'assets/images/alphabet/ice.png',
      'assets/images/alphabet/juice.png',
      'assets/images/alphabet/queen.png',
      'assets/images/alphabet/yellow.png',
      'assets/images/alphabet/umbrella.png',
      'assets/images/alphabet/key.png',
      'assets/images/alphabet/box.png',
    ];
    for (final String path in stale) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'ios/LingoWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'ios/LingoWatch/Assets.xcassets/PaperCrumpled.imageset/paper_crumpled_watch.jpg',
      ).existsSync(),
      isTrue,
    );
  });

  test('Watch shared payload uses German target text and de language code', () {
    final WatchPlanItem? hello = WatchCatalog.resolve(
      repo,
      'word.basics.hello',
      learnerLanguageCode: 'en',
    );
    expect(hello?.targetText, 'Hallo');
    expect(hello?.pronunciationId, 'word.basics.hello');
    final Map<String, Object> payload = WatchLearningPlan.payload(
      draft: WatchCompanionDraft.initial.toggled(hello!.id, hello.type).draft,
      items: <WatchPlanItem>[hello],
      targetLanguageCode: repo.product.targetLanguageCode,
      learnerLanguageCode: 'en',
      updatedAtEpochMs: 42,
    );
    expect(payload['targetLanguageCode'], 'de');
    expect(payload['targetLanguageCode'], isNot('en'));
    final List<Map<String, Object>> rows =
        payload['items']! as List<Map<String, Object>>;
    expect(rows.single['targetText'], 'Hallo');
  });

  test('persisted IDs resolve to current German text after reload', () async {
    final UserPreferences prefs = UserPreferences.instance;
    await prefs.addFavoriteWord('word.basics.hello');
    await prefs.addFavoritePhrase('phrase.greetings.hello');
    await prefs.recordWrongAnswer(
      contentId: 'word.family.mother',
      kind: QuizContentKind.word,
    );

    expect(prefs.getFavoriteWordIds(), contains('word.basics.hello'));
    expect(repo.wordById('word.basics.hello')?.text, 'Hallo');
    expect(repo.phraseById('phrase.greetings.hello')?.text, 'Hallo.');
    expect(repo.wordById('word.family.mother')?.text, 'die Mutter');

    final List<ResolvedWrongAnswer> resolved = resolveWrongAnswers(
      prefs.getWrongAnswers(),
      repo,
      languageCode: 'en',
    );
    expect(resolved, hasLength(1));
    expect(resolved.single.targetText, 'die Mutter');
    expect(resolved.single.learnerCue, isNot('die Mutter'));
    expect(UserPreferences.schemaVersion, 1);
  });
}
