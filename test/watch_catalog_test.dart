import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(UserPreferences.resetForTest);

  test(
    'Watch catalog loads words and phrases from the local repository',
    () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      final List<WatchPlanItem> words = WatchCatalog.items(
        content: repo,
        learnerLanguageCode: 'tr',
        filter: WatchContentFilter.words,
      );
      final List<WatchPlanItem> phrases = WatchCatalog.items(
        content: repo,
        learnerLanguageCode: 'tr',
        filter: WatchContentFilter.phrases,
      );

      expect(words, isNotEmpty);
      expect(phrases, isNotEmpty);
      expect(
        words.every((WatchPlanItem item) => item.type == WatchItemType.word),
        isTrue,
      );
      expect(
        phrases.every(
          (WatchPlanItem item) => item.type == WatchItemType.phrase,
        ),
        isTrue,
      );
      expect(
        words.every(
          (WatchPlanItem item) =>
              item.id.isNotEmpty && item.targetText.isNotEmpty,
        ),
        isTrue,
      );
      expect(WatchCatalog.wordIds(repo), isNotEmpty);
      expect(WatchCatalog.phraseIds(repo), isNotEmpty);
      expect(
        WatchCatalog.wordIds(repo).intersection(WatchCatalog.phraseIds(repo)),
        isEmpty,
      );
    },
  );

  test('German target + Turkish learner shows Hallo → Merhaba', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final WatchPlanItem? hello = WatchCatalog.resolve(
      repo,
      'word.basics.hello',
      learnerLanguageCode: 'tr',
    );

    expect(hello, isNotNull);
    expect(hello?.type, WatchItemType.word);
    expect(hello?.targetText, 'Hallo');
    expect(hello?.translation, 'Merhaba');
    expect(hello?.translation, isNot(hello?.targetText));
    expect(hello?.translationMissing, isFalse);
  });

  test('German target + French learner shows warum → Pourquoi', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final WatchPlanItem? why = WatchCatalog.resolve(
      repo,
      'word.basics.why',
      learnerLanguageCode: 'fr',
    );

    expect(why?.targetText, 'warum');
    expect(why?.translation, 'Pourquoi');
    expect(why?.translation, isNot(why?.targetText));
    expect(why?.translationMissing, isFalse);
  });

  test('German target + German learner shows Hallo → Hallo', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final WatchPlanItem? hello = WatchCatalog.resolve(
      repo,
      'word.basics.hello',
      learnerLanguageCode: 'de',
    );

    expect(hello?.targetText, 'Hallo');
    expect(hello?.translation, 'Hallo');
    expect(hello?.translationMissing, isFalse);
  });

  test('Spanish target + English learner shows Hola → Hello', () {
    final LocalContentRepository repo = _spanishRepo();
    final WatchPlanItem? hello = WatchCatalog.resolve(
      repo,
      'word.basics.hello',
      learnerLanguageCode: 'en',
    );

    expect(repo.product.targetLanguageCode, 'es');
    expect(hello?.targetText, 'Hola');
    expect(hello?.translation, 'Hello');
    expect(hello?.translation, isNot(hello?.targetText));
    expect(hello?.translationMissing, isFalse);

    final WatchResolvedMeaning fromTargetLanguage = WatchCatalog.meaningFor(
      repo,
      'word.basics.hello',
      learnerLanguageCode: repo.product.targetLanguageCode,
    );
    expect(fromTargetLanguage.text, 'Hola');
    expect(
      hello?.translation,
      isNot(fromTargetLanguage.text),
      reason: 'Watch translation must not come from targetLanguageCode',
    );
  });

  test('phrase target text stays in the target language', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final WatchPlanItem? phrase = WatchCatalog.resolve(
      repo,
      'phrase.greetings.hello',
      learnerLanguageCode: 'tr',
    );

    expect(phrase?.type, WatchItemType.phrase);
    expect(phrase?.targetText, 'Hallo.');
    expect(phrase?.translation, 'Merhaba.');
    expect(phrase?.translation, isNot(phrase?.targetText));

    final WatchPlanItem? spanishPhrase = WatchCatalog.resolve(
      _spanishRepo(),
      'phrase.greetings.hello',
      learnerLanguageCode: 'en',
    );
    expect(spanishPhrase?.targetText, 'Buenos días.');
    expect(spanishPhrase?.translation, 'Good morning.');
  });

  test(
    'changing learner language keeps IDs and refreshes translations',
    () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      const String wordId = 'word.basics.hello';
      const String phraseId = 'phrase.greetings.hello';
      final WatchCompanionDraft draft = WatchCompanionDraft.initial
          .toggled(wordId, WatchItemType.word)
          .draft
          .toggled(phraseId, WatchItemType.phrase)
          .draft
          .copyWith(filter: WatchContentFilter.both);

      await UserPreferences.instance.setWatchDraft(draft);
      await UserPreferences.instance.setSelectedTranslationLanguage('de');

      expect(UserPreferences.instance.getWatchDraft().wordIds, <String>{
        wordId,
      });
      expect(UserPreferences.instance.getWatchDraft().phraseIds, <String>{
        phraseId,
      });

      final List<WatchPlanItem> turkish = WatchCatalog.selectedItems(
        content: repo,
        draft: UserPreferences.instance.getWatchDraft(),
        learnerLanguageCode: 'tr',
      );
      final List<WatchPlanItem> german = WatchCatalog.selectedItems(
        content: repo,
        draft: UserPreferences.instance.getWatchDraft(),
        learnerLanguageCode: 'de',
      );

      expect(turkish.map((WatchPlanItem item) => item.id), <String>[
        wordId,
        phraseId,
      ]);
      expect(german.map((WatchPlanItem item) => item.id), <String>[
        wordId,
        phraseId,
      ]);
      expect(turkish.first.targetText, 'Hallo');
      expect(german.first.targetText, turkish.first.targetText);
      expect(turkish.first.translation, 'Merhaba');
      expect(german.first.translation, 'Hallo');
      expect(turkish.last.targetText, german.last.targetText);
      expect(turkish.last.translation, 'Merhaba.');
      expect(german.last.translation, 'Hallo.');
    },
  );

  test(
    'Watch payload uses learner-language resources, not target text',
    () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      final WatchCompanionDraft draft = WatchCompanionDraft.initial
          .toggled('word.basics.hello', WatchItemType.word)
          .draft
          .toggled('phrase.greetings.hello', WatchItemType.phrase)
          .draft
          .copyWith(filter: WatchContentFilter.both);

      final Map<String, Object> payload = WatchCatalog.syncPayload(
        content: repo,
        draft: draft,
        learnerLanguageCode: 'tr',
        updatedAtEpochMs: 9,
      );

      expect(payload['targetLanguageCode'], repo.product.targetLanguageCode);
      expect(payload['learnerLanguageCode'], 'tr');
      expect(
        payload['targetLanguageCode'],
        isNot(payload['learnerLanguageCode']),
      );

      final Object? items = payload['items'];
      expect(items, isA<List<Map<String, Object>>>());
      final List<Map<String, Object>> rows = items as List<Map<String, Object>>;
      expect(rows, hasLength(2));
      expect(rows.first['id'], 'word.basics.hello');
      expect(rows.first['type'], 'word');
      expect(rows.first['targetText'], 'Hallo');
      expect(rows.first['translation'], 'Merhaba');
      expect(rows.first['translation'], isNot(rows.first['targetText']));
      expect(rows.last['id'], 'phrase.greetings.hello');
      expect(rows.last['type'], 'phrase');
      expect(rows.last['targetText'], 'Hallo.');
      expect(rows.last['translation'], 'Merhaba.');
      expect(rows.first['pronunciationId'], 'word.basics.hello');
      expect(rows.last['pronunciationId'], 'phrase.greetings.hello');
      expect(rows.last.keys, <String>{
        'id',
        'type',
        'targetText',
        'translation',
        'pronunciationId',
      });
    },
  );

  test('Both mode keeps word and phrase learner translations', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final WatchCompanionDraft draft = WatchCompanionDraft.initial
        .toggled('word.basics.hello', WatchItemType.word)
        .draft
        .toggled('phrase.greetings.good_morning', WatchItemType.phrase)
        .draft
        .copyWith(filter: WatchContentFilter.both);
    final List<WatchPlanItem> selected = WatchCatalog.selectedItems(
      content: repo,
      draft: draft,
      learnerLanguageCode: 'tr',
    );

    expect(selected, hasLength(2));
    expect(selected.map((WatchPlanItem item) => item.type), <WatchItemType>[
      WatchItemType.word,
      WatchItemType.phrase,
    ]);
    expect(selected.first.targetText, 'Hallo');
    expect(selected.first.translation, 'Merhaba');
    expect(selected.last.targetText, 'Guten Morgen.');
    expect(selected.last.translation, 'Günaydın.');
  });

  test(
    'missing learner translation uses the pack fallback and is reported',
    () {
      final LocalContentRepository repo = _missingTurkishRepo();
      final WatchPlanItem? item = WatchCatalog.resolve(
        repo,
        'word.basics.hello',
        learnerLanguageCode: 'tr',
      );

      expect(item?.targetText, 'Hello');
      expect(item?.translation, 'Hello');
      expect(item?.translationMissing, isTrue);
      expect(
        WatchCatalog.meaningFor(
          repo,
          'word.basics.hello',
          learnerLanguageCode: 'tr',
        ).missing,
        isTrue,
      );
    },
  );

  test('stable IDs keep the current learner translation', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final List<WatchPlanItem> english = WatchCatalog.items(
      content: repo,
      learnerLanguageCode: 'en',
      filter: WatchContentFilter.words,
    );
    expect(english, isNotEmpty);
    final WatchPlanItem first = english.first;
    final WatchPlanItem? turkish = WatchCatalog.resolve(
      repo,
      first.id,
      learnerLanguageCode: 'tr',
    );
    final WatchPlanItem? german = WatchCatalog.resolve(
      repo,
      first.id,
      learnerLanguageCode: 'de',
    );

    expect(turkish?.id, first.id);
    expect(german?.id, first.id);
    expect(turkish?.targetText, first.targetText);
    expect(german?.targetText, first.targetText);
    expect(turkish?.type, WatchItemType.word);
    expect(turkish?.translation, isNot(first.translation));
    expect(german?.translation, isNot(first.translation));

    final WatchCompanionDraft draft = WatchCompanionDraft.initial
        .toggled(first.id, WatchItemType.word)
        .draft
        .toggled(
          WatchCatalog.items(
            content: repo,
            learnerLanguageCode: 'tr',
            filter: WatchContentFilter.phrases,
          ).first.id,
          WatchItemType.phrase,
        )
        .draft;
    final List<WatchPlanItem> selected = WatchCatalog.selectedItems(
      content: repo,
      draft: draft.copyWith(filter: WatchContentFilter.words),
      learnerLanguageCode: 'tr',
    );
    expect(selected.map((WatchPlanItem item) => item.id), contains(first.id));
    expect(
      selected.any((WatchPlanItem item) => item.type == WatchItemType.phrase),
      isTrue,
    );
  });

  test('Both filter groups words and phrases by kind and category', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final List<WatchPickerRow> rows = WatchCatalog.pickerRows(
      content: repo,
      learnerLanguageCode: 'en',
      filter: WatchContentFilter.both,
    );
    expect(
      rows.any((WatchPickerRow row) => row.section == WatchItemType.word),
      isTrue,
    );
    expect(
      rows.any((WatchPickerRow row) => row.section == WatchItemType.phrase),
      isTrue,
    );
    expect(rows.any((WatchPickerRow row) => row.isHeader), isTrue);
    expect(
      rows.any(
        (WatchPickerRow row) =>
            row.item?.type == WatchItemType.word &&
            (row.item?.id.isNotEmpty ?? false),
      ),
      isTrue,
    );
  });
}

LocalContentRepository _spanishRepo() {
  return LocalContentRepository(
    product: ProductConfig.fallback.copyWith(targetLanguageCode: 'es'),
    pack: const LanguagePack(
      id: 'es-watch-test',
      name: 'Spanish Watch Test',
      version: '1',
      targetLanguageCode: 'es',
      targetLanguageName: 'Spanish',
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      hasAlphabet: false,
      defaultTranslationLanguageCode: 'en',
      translationLanguageCodes: <String>['en', 'es'],
      assetIndex: <String, String>{},
    ),
    alphabet: const <AlphabetUnit>[],
    wordCategories: const <ContentCategory>[
      ContentCategory(id: 'words.basics', title: 'Basics', sortOrder: 0),
    ],
    phraseCategories: const <ContentCategory>[
      ContentCategory(
        id: 'phrases.greetings',
        title: 'Greetings',
        sortOrder: 0,
      ),
    ],
    words: const <WordEntry>[
      WordEntry(
        id: 'word.basics.hello',
        categoryId: 'words.basics',
        text: 'Hola',
        sortOrder: 0,
        quizEnabled: true,
      ),
    ],
    phrases: const <PhraseEntry>[
      PhraseEntry(
        id: 'phrase.greetings.hello',
        categoryId: 'phrases.greetings',
        text: 'Buenos días.',
        sortOrder: 0,
        quizEnabled: true,
      ),
    ],
    translationBundles: const <TranslationBundle>[
      TranslationBundle(
        languageCode: 'en',
        languageName: 'English',
        strings: <String, String>{
          'word.basics.hello': 'Hello',
          'phrase.greetings.hello': 'Good morning.',
          'words.basics': 'Basics',
          'phrases.greetings': 'Greetings',
        },
      ),
      TranslationBundle(
        languageCode: 'es',
        languageName: 'Spanish',
        strings: <String, String>{
          'word.basics.hello': 'Hola',
          'phrase.greetings.hello': 'Buenos días.',
          'words.basics': 'Básicos',
          'phrases.greetings': 'Saludos',
        },
      ),
    ],
  );
}

LocalContentRepository _missingTurkishRepo() {
  return LocalContentRepository(
    product: ProductConfig.fallback.copyWith(targetLanguageCode: 'en'),
    pack: const LanguagePack(
      id: 'missing-tr-watch-test',
      name: 'Missing Turkish Watch Test',
      version: '1',
      targetLanguageCode: 'en',
      targetLanguageName: 'English',
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      hasAlphabet: false,
      defaultTranslationLanguageCode: 'en',
      translationLanguageCodes: <String>['en', 'tr'],
      assetIndex: <String, String>{},
    ),
    alphabet: const <AlphabetUnit>[],
    wordCategories: const <ContentCategory>[
      ContentCategory(id: 'words.basics', title: 'Basics', sortOrder: 0),
    ],
    phraseCategories: const <ContentCategory>[],
    words: const <WordEntry>[
      WordEntry(
        id: 'word.basics.hello',
        categoryId: 'words.basics',
        text: 'Hello',
        sortOrder: 0,
        quizEnabled: true,
      ),
    ],
    phrases: const <PhraseEntry>[],
    translationBundles: const <TranslationBundle>[
      TranslationBundle(
        languageCode: 'en',
        languageName: 'English',
        strings: <String, String>{'word.basics.hello': 'Hello'},
      ),
      TranslationBundle(
        languageCode: 'tr',
        languageName: 'Turkish',
        strings: <String, String>{},
      ),
    ],
  );
}
