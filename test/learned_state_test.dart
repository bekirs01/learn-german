import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_cards.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/lingo_segmented_control.dart';
import 'package:lingo_core/core/widgets/pronunciation_control.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/features/favorites/favorites_screen.dart';
import 'package:lingo_core/features/learn/phrase_categories_screen.dart';
import 'package:lingo_core/features/learn/word_categories_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
    FeedbackService.instance = FeedbackService(
      hapticsEnabled: false,
      soundEnabled: false,
    );
    PronunciationService.instance = PronunciationService(
      audioEnabled: true,
      player: const SilentPronunciationPlayer(),
      probe: const AlwaysPresentSoundAssetProbe(),
      onStarted: () {},
    );
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
    FeedbackService.resetInstance();
    PronunciationService.resetInstance();
  });

  testWidgets('marking a word learned toggles the row and can be unmarked', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _repo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
    );

    expect(repo.isLearned('word.hello'), isFalse);
    expect(
      tester.widget<LingoWordCard>(find.byType(LingoWordCard).first).learned,
      isFalse,
    );
    expect(find.byIcon(Icons.check_box_outline_blank_rounded), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('learned-word.hello')));
    await tester.pump();

    expect(repo.isLearned('word.hello'), isTrue);
    expect(UserPreferences.instance.getLearnedWordIds(), <String>{
      'word.hello',
    });
    expect(
      tester.widget<LingoWordCard>(find.byType(LingoWordCard).first).learned,
      isTrue,
    );
    expect(
      tester
          .widget<LingoLearnedButton>(find.byType(LingoLearnedButton).first)
          .learned,
      isTrue,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    final Text word = tester.widget<Text>(find.text('Hello'));
    expect(word.style?.decoration, isNot(TextDecoration.lineThrough));
    expect(word.style?.color?.a ?? 1, greaterThan(0.9));

    await tester.tap(find.byKey(const ValueKey<String>('learned-word.hello')));
    await tester.pump();

    expect(repo.isLearned('word.hello'), isFalse);
    expect(UserPreferences.instance.getLearnedWordIds(), isEmpty);
    expect(
      tester.widget<LingoWordCard>(find.byType(LingoWordCard).first).learned,
      isFalse,
    );
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phrases keep an independent learned state', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _repo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: PhraseCategoryScreen(category: repo.phraseCategories.first),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('learned-phrase.hello')),
    );
    await tester.pump();

    expect(repo.isLearned('phrase.hello'), isTrue);
    expect(repo.isLearned('word.hello'), isFalse);
    expect(UserPreferences.instance.getLearnedPhraseIds(), <String>{
      'phrase.hello',
    });
    expect(
      tester.widget<LingoPhraseCard>(find.byType(LingoPhraseCard)).learned,
      isTrue,
    );
    expect(find.text('How are you?'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('learned-phrase.hello')),
    );
    await tester.pump();
    expect(repo.isLearned('phrase.hello'), isFalse);
    expect(tester.takeException(), isNull);
  });

  test('learned IDs survive a preference reload', () async {
    final MemoryPreferenceStore store = MemoryPreferenceStore();
    UserPreferences.resetForTest(store: store);
    final LocalContentRepository repo = _repo();
    repo.setLearned('word.hello', true);
    repo.setLearned('phrase.hello', true);
    repo.setLearned('word.hello', true);
    await UserPreferences.instance.flushWrites();

    expect(UserPreferences.instance.getLearnedWordIds(), <String>{
      'word.hello',
    });
    expect(UserPreferences.instance.getLearnedPhraseIds(), <String>{
      'phrase.hello',
    });

    UserPreferences.resetForTest(store: store);
    final LocalContentRepository reloaded = _repo();
    expect(reloaded.isLearned('word.hello'), isTrue);
    expect(reloaded.isLearned('phrase.hello'), isTrue);
    expect(UserPreferences.instance.getLearnedWordIds().length, 1);
    expect(UserPreferences.instance.getLearnedPhraseIds().length, 1);
  });

  testWidgets('favorites show and toggle the same learned state', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _repo();
    repo.setFavorite('word.hello', true);
    repo.setFavorite('phrase.hello', true);

    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('learned-word.hello')));
    await tester.pump();
    expect(repo.isLearned('word.hello'), isTrue);

    await _pumpScreen(
      tester,
      ContentScope(repository: repo, child: const FavoritesScreen()),
    );
    expect(find.byType(LingoWordCard), findsOneWidget);
    expect(
      tester.widget<LingoWordCard>(find.byType(LingoWordCard)).learned,
      isTrue,
    );
    expect(
      tester
          .widget<LingoLearnedButton>(find.byType(LingoLearnedButton))
          .learned,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey<String>('learned-word.hello')));
    await tester.pump();
    expect(repo.isLearned('word.hello'), isFalse);
    expect(
      tester.widget<LingoWordCard>(find.byType(LingoWordCard)).learned,
      isFalse,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Phrases'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('learned-phrase.hello')),
    );
    await tester.pump();
    expect(repo.isLearned('phrase.hello'), isTrue);

    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: PhraseCategoryScreen(category: repo.phraseCategories.first),
      ),
    );
    expect(
      tester.widget<LingoPhraseCard>(find.byType(LingoPhraseCard)).learned,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('language switching keeps learned IDs and target text', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _repo();
    repo.setLearned('word.hello', true);
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
    );

    for (final String code in <String>['tr', 'ar', 'fa', 'en']) {
      UserPreferences.instance.setSelectedTranslationLanguage(code);
      await tester.pump();
      expect(repo.isLearned('word.hello'), isTrue);
      expect(UserPreferences.instance.getLearnedWordIds(), <String>{
        'word.hello',
      });
      expect(find.text('Hello'), findsOneWidget);
      expect(
        tester.widget<LingoWordCard>(find.byType(LingoWordCard).first).learned,
        isTrue,
      );
    }
    expect(find.text('Merhaba'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('stale learned IDs are ignored and pruned safely', () async {
    final MemoryPreferenceStore store = MemoryPreferenceStore();
    UserPreferences.resetForTest(store: store);
    await UserPreferences.instance.addLearnedWord('word.hello');
    await UserPreferences.instance.addLearnedWord('word.retired');
    await UserPreferences.instance.addLearnedPhrase('phrase.gone');
    await UserPreferences.instance.flushWrites();

    final LocalContentRepository repo = _repo();
    expect(repo.isLearned('word.hello'), isTrue);
    expect(repo.isLearned('word.retired'), isFalse);
    expect(repo.isLearned('phrase.gone'), isFalse);

    await UserPreferences.instance.pruneUnknownLearned(
      wordIds: <String>{'word.hello', 'word.1'},
      phraseIds: <String>{'phrase.hello'},
    );
    expect(UserPreferences.instance.getLearnedWordIds(), <String>{
      'word.hello',
    });
    expect(UserPreferences.instance.getLearnedPhraseIds(), isEmpty);
    expect(() => repo.setLearned('missing.id', true), returnsNormally);
    expect(repo.isLearned('missing.id'), isFalse);
  });

  testWidgets('RTL Arabic and Persian keep three actions clear of long text', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _repo();
    const List<(String, Size)> cases = <(String, Size)>[
      ('ar', Size(320, 568)),
      ('fa', Size(390, 844)),
      ('ar', Size(430, 932)),
    ];

    for (final (String code, Size size) in cases) {
      UserPreferences.instance.setSelectedTranslationLanguage(code);
      await _pumpScreen(
        tester,
        ContentScope(
          repository: repo,
          child: WordCategoryScreen(category: repo.wordCategories.first),
        ),
        size: size,
        textDirection: TextDirection.rtl,
      );

      final Rect word = tester.getRect(find.text('Hello'));
      final Rect play = tester.getRect(find.byType(PronunciationControl).first);
      final Rect favorite = tester.getRect(
        find.byType(LingoFavoriteButton).first,
      );
      final Rect learned = tester.getRect(
        find.byType(LingoLearnedButton).first,
      );
      expect(word.overlaps(play), isFalse, reason: '$code ${size.width}');
      expect(word.overlaps(favorite), isFalse, reason: '$code ${size.width}');
      expect(word.overlaps(learned), isFalse, reason: '$code ${size.width}');
      expect(play.width, closeTo(favorite.width, 0.5));
      expect(play.width, closeTo(learned.width, 0.5));
      expect(play.center.dy, closeTo(learned.center.dy, 1));
      expect(tester.takeException(), isNull);
    }
  });
}

LocalContentRepository _repo({int wordCount = 2}) {
  return LocalContentRepository(
    product: ProductConfig.fallback,
    pack: const LanguagePack(
      id: 'learned-test',
      name: 'Learned Test',
      version: '1',
      targetLanguageCode: 'und',
      targetLanguageName: 'Sample',
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      hasAlphabet: false,
      defaultTranslationLanguageCode: 'en',
      translationLanguageCodes: <String>['en', 'tr', 'ar', 'fa'],
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
    words: <WordEntry>[
      for (int index = 0; index < wordCount; index++)
        WordEntry(
          id: index == 0 ? 'word.hello' : 'word.$index',
          categoryId: 'words.basics',
          text: index == 0 ? 'Hello' : 'Word $index',
          pronunciation: '/həˈloʊ/',
          sortOrder: index,
          quizEnabled: true,
        ),
    ],
    phrases: const <PhraseEntry>[
      PhraseEntry(
        id: 'phrase.hello',
        categoryId: 'phrases.greetings',
        text: 'How are you?',
        pronunciation: '/haʊ ɑːr juː/',
        sortOrder: 0,
        quizEnabled: true,
      ),
    ],
    translationBundles: const <TranslationBundle>[
      TranslationBundle(
        languageCode: 'en',
        languageName: 'English',
        strings: <String, String>{
          'word.hello': 'A greeting',
          'phrase.hello': 'How are you doing?',
          'words.basics': 'Basics',
          'phrases.greetings': 'Greetings',
        },
      ),
      TranslationBundle(
        languageCode: 'tr',
        languageName: 'Turkish',
        strings: <String, String>{
          'word.hello': 'Merhaba',
          'phrase.hello': 'Nasılsın?',
        },
      ),
      TranslationBundle(
        languageCode: 'ar',
        languageName: 'Arabic',
        strings: <String, String>{
          'word.hello': 'تحية طويلة تستخدم عند اللقاء',
          'phrase.hello': 'كيف حالك؟',
        },
      ),
      TranslationBundle(
        languageCode: 'fa',
        languageName: 'Persian',
        strings: <String, String>{
          'word.hello': 'یک سلام دوستانه',
          'phrase.hello': 'حال شما چطور است؟',
        },
      ),
    ],
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(390, 844),
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: home,
    ),
  );
  await tester.pump();
}
