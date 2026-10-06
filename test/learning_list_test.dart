import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_cards.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/lingo_progress.dart';
import 'package:lingo_core/core/widgets/lingo_segmented_control.dart';
import 'package:lingo_core/core/widgets/pronunciation_control.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/features/favorites/favorites_screen.dart';
import 'package:lingo_core/features/learn/phrase_categories_screen.dart';
import 'package:lingo_core/features/learn/word_categories_screen.dart';
import 'package:lingo_core/features/quiz/quiz_launch.dart';

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
      probe: const _MissingSoundAssetProbe(),
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

  testWidgets('word cards stay compact and hide technical pronunciation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: LingoWordCard(
              word: 'Hello',
              pronunciation: '/həˈloʊ/',
              meaning: 'Merhaba',
              index: 1,
              total: 12,
              play: PronunciationControl(
                clip: PronunciationClip(
                  id: 'word.hello',
                  assetPath: 'assets/audio/words/hello.wav',
                ),
              ),
              action: LingoFavoriteButton(saved: false, onPressed: _noop),
              learnedAction: LingoLearnedButton(
                learned: false,
                onPressed: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Merhaba'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('/həˈloʊ/'), findsNothing);
    expect(find.byType(PronunciationControl), findsOneWidget);
    expect(find.byType(LingoFavoriteButton), findsOneWidget);
    expect(find.byType(LingoLearnedButton), findsOneWidget);
    expect(
      tester.getRect(find.text('Merhaba')).bottom -
          tester.getRect(find.text('Hello')).top,
      lessThan(72),
    );
    expect(tester.getSize(find.byType(LingoWordCard)).height, lessThan(180));

    final Rect number = tester.getRect(find.text('01'));
    final Rect word = tester.getRect(find.text('Hello'));
    final Rect meaning = tester.getRect(find.text('Merhaba'));
    final Rect play = tester.getRect(find.byType(PronunciationControl));
    final Rect favorite = tester.getRect(find.byType(LingoFavoriteButton));
    final Rect learned = tester.getRect(find.byType(LingoLearnedButton));
    expect(number.center.dy, closeTo(word.center.dy, 3));
    expect(play.center.dy, closeTo(favorite.center.dy, 1));
    expect(play.center.dy, closeTo(learned.center.dy, 1));
    expect(play.center.dy, closeTo(number.center.dy, 3));
    expect(word.left, greaterThan(number.right + 8));
    expect(meaning.left, closeTo(word.left, 1));
    expect(word.right, lessThanOrEqualTo(play.left + 1));
    expect(play.width, closeTo(favorite.width, 0.5));
    expect(play.height, closeTo(favorite.height, 0.5));
    expect(play.width, closeTo(learned.width, 0.5));
    expect(play.height, closeTo(learned.height, 0.5));
    expect(play.width, greaterThanOrEqualTo(44));
    expect(favorite.width, greaterThanOrEqualTo(44));
    expect(learned.width, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.byType(LingoWordCard)).height, greaterThan(60));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phrase cards wrap and keep play plus favorite actions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: LingoPhraseCard(
              phrase: 'Could you please tell me how to get to the station?',
              pronunciation: '/kʊd ju pliːz/',
              meaning:
                  'İstasyona nasıl gideceğimi lütfen söyler misiniz, çok teşekkür ederim.',
              index: 4,
              total: 20,
              play: PronunciationControl(
                clip: PronunciationClip(id: 'phrase.ask'),
              ),
              action: LingoFavoriteButton(saved: true, onPressed: _noop),
              learnedAction: LingoLearnedButton(
                learned: true,
                onPressed: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Could you please tell me how to get to the station?'),
      findsOneWidget,
    );
    expect(find.text('04'), findsOneWidget);
    expect(find.text('/kʊd ju pliːz/'), findsNothing);
    expect(find.byType(PronunciationControl), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final Rect phrase = tester.getRect(
      find.text('Could you please tell me how to get to the station?'),
    );
    final Rect play = tester.getRect(find.byType(PronunciationControl));
    final Rect favorite = tester.getRect(find.byType(LingoFavoriteButton));
    final Rect learned = tester.getRect(find.byType(LingoLearnedButton));
    expect(phrase.overlaps(play), isFalse);
    expect(phrase.overlaps(favorite), isFalse);
    expect(phrase.overlaps(learned), isFalse);
    expect(play.center.dy, closeTo(favorite.center.dy, 1));
    expect(play.center.dy, closeTo(learned.center.dy, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('category cards keep compact labels and a square art well', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 168,
              child: LingoCategoryCard(
                label: 'Sehenswürdigkeiten und Reiseziele',
                art: LingoArtKind.travel,
              ),
            ),
          ),
        ),
      ),
    );

    final Size card = tester.getSize(find.byType(LingoCategoryCard));
    expect(find.text('Sehenswürdigkeiten und Reiseziele'), findsOneWidget);
    expect(card.width, closeTo(168, 0.5));
    expect(card.height - card.width, lessThan(52));
    expect(card.height - card.width, greaterThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('root Words and Phrases omit global quiz actions', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _learningRepo();
    await _pumpScreen(
      tester,
      ContentScope(repository: repo, child: const WordCategoriesScreen()),
    );
    expect(find.byType(QuizLaunchButton), findsNothing);
    expect(find.byType(LingoCategoryCard), findsOneWidget);

    await _pumpScreen(
      tester,
      ContentScope(repository: repo, child: const PhraseCategoriesScreen()),
    );
    expect(find.byType(QuizLaunchButton), findsNothing);
    expect(find.byType(LingoCategoryCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a specific word category keeps its quiz action and hero', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _learningRepo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
      size: const Size(390, 844),
    );

    expect(find.byType(QuizLaunchButton), findsOneWidget);
    expect(find.byType(LingoCategoryHero), findsOneWidget);
    final Size hero = tester.getSize(find.byType(LingoCategoryHero));
    expect(
      hero.width / hero.height,
      closeTo(LingoCategoryHero.frameAspectRatio, 0.08),
    );
    expect(hero.height, greaterThan(160));
    expect(hero.height, lessThan(280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a specific phrase category keeps its quiz action', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _learningRepo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: PhraseCategoryScreen(category: repo.phraseCategories.first),
      ),
    );

    expect(find.byType(QuizLaunchButton), findsOneWidget);
    expect(find.byType(LingoCategoryHero), findsOneWidget);
    expect(find.text('How are you?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('word category lists index items and update translations', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _learningRepo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('A greeting'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('/həˈloʊ/'), findsNothing);
    expect(find.byType(PronunciationControl), findsWidgets);
    expect(find.byType(LingoEdgeScrollProgress), findsOneWidget);

    UserPreferences.instance.setSelectedTranslationLanguage('tr');
    await tester.pump();
    expect(find.text('Merhaba'), findsOneWidget);
    expect(find.text('A greeting'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long word list hosts the edge progress rail', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _learningRepo(wordCount: 24);
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
      size: const Size(390, 844),
    );

    expect(find.byType(LingoWordCard), findsWidgets);
    expect(find.byType(LingoEdgeScrollProgress), findsOneWidget);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('list-scroll-progress')),
      findsOneWidget,
    );
    final Rect rail = tester.getRect(
      find.byKey(const ValueKey<String>('list-scroll-progress')),
    );
    final Rect card = tester.getRect(find.byType(LingoWordCard).first);
    expect(rail.width, lessThan(4));
    expect(rail.left, greaterThanOrEqualTo(card.right - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('short lists keep the progress rail hidden', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _learningRepo(wordCount: 2);
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
      size: const Size(430, 932),
    );

    expect(find.byType(LingoWordCard), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('list-scroll-progress')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phrase lists speak the target phrase, not the translation', (
    WidgetTester tester,
  ) async {
    final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
    PronunciationService.instance = PronunciationService(
      audioEnabled: true,
      player: const SilentPronunciationPlayer(),
      speech: speech,
      probe: const _MissingSoundAssetProbe(),
      speechLocale: 'en',
      onStarted: () {},
    );
    UserPreferences.instance.setSelectedTranslationLanguage('tr');
    final LocalContentRepository repo = _learningRepo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: PhraseCategoryScreen(category: repo.phraseCategories.first),
      ),
    );

    expect(find.text('How are you?'), findsOneWidget);
    expect(find.text('Nasılsın?'), findsOneWidget);
    expect(find.text('/haʊ ɑːr juː/'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('play-phrase.hello')));
    await tester.pump();
    expect(speech.utterances, <(String, String)>[('How are you?', 'en-US')]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('word pronunciation stays on the target word across languages', (
    WidgetTester tester,
  ) async {
    final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
    PronunciationService.instance = PronunciationService(
      audioEnabled: true,
      player: const SilentPronunciationPlayer(),
      speech: speech,
      probe: const _MissingSoundAssetProbe(),
      speechLocale: 'en',
      onStarted: () {},
    );
    final LocalContentRepository repo = _learningRepo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
    );

    const Map<String, String> meanings = <String, String>{
      'en': 'A greeting',
      'tr': 'Merhaba',
      'de': 'Eine sehr höfliche Begrüßung unter Freunden',
      'ru': 'Приветствие',
      'ar': 'تحية طويلة تستخدم عند اللقاء',
      'fa': 'یک سلام دوستانه',
      'ja': 'あいさつ',
      'zh': '问候',
    };

    for (final MapEntry<String, String> entry in meanings.entries) {
      UserPreferences.instance.setSelectedTranslationLanguage(entry.key);
      await tester.pump();
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('/həˈloʊ/'), findsNothing);
    }

    await tester.tap(find.byKey(const ValueKey<String>('play-word.hello')));
    await tester.pump();
    expect(speech.utterances, <(String, String)>[('Hello', 'en-US')]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL Arabic layout keeps actions reachable on a small iPhone', (
    WidgetTester tester,
  ) async {
    UserPreferences.instance.setSelectedTranslationLanguage('ar');
    final LocalContentRepository repo = _learningRepo();
    await _pumpScreen(
      tester,
      ContentScope(
        repository: repo,
        child: WordCategoryScreen(category: repo.wordCategories.first),
      ),
      size: const Size(320, 568),
      textDirection: TextDirection.rtl,
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('تحية طويلة تستخدم عند اللقاء'), findsOneWidget);
    expect(find.byType(PronunciationControl), findsWidgets);
    expect(find.byType(LingoFavoriteButton), findsWidgets);
    expect(find.byType(LingoLearnedButton), findsWidgets);
    expect(find.byType(QuizLaunchButton), findsOneWidget);
    final Rect word = tester.getRect(find.text('Hello'));
    final Rect meaning = tester.getRect(
      find.text('تحية طويلة تستخدم عند اللقاء'),
    );
    final Rect play = tester.getRect(find.byType(PronunciationControl).first);
    final Rect favorite = tester.getRect(
      find.byType(LingoFavoriteButton).first,
    );
    final Rect learned = tester.getRect(find.byType(LingoLearnedButton).first);
    expect(word.overlaps(play), isFalse);
    expect(word.overlaps(favorite), isFalse);
    expect(word.overlaps(learned), isFalse);
    expect(meaning.overlaps(play), isFalse);
    expect(meaning.overlaps(favorite), isFalse);
    expect(meaning.overlaps(learned), isFalse);
    expect(play.center.dy, closeTo(favorite.center.dy, 1));
    expect(play.center.dy, closeTo(learned.center.dy, 1));
    final Size hero = tester.getSize(find.byType(LingoCategoryHero));
    expect(
      hero.width / hero.height,
      closeTo(LingoCategoryHero.frameAspectRatio, 0.08),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('favorites match the learning cards and can remove items', (
    WidgetTester tester,
  ) async {
    final LocalContentRepository repo = _learningRepo();
    repo.setFavorite('word.hello', true);
    repo.setFavorite('phrase.hello', true);
    await _pumpScreen(
      tester,
      ContentScope(repository: repo, child: const FavoritesScreen()),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('A greeting'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(LingoWordCard), findsOneWidget);
    expect(find.byType(PronunciationControl), findsOneWidget);
    expect(find.byType(LingoSegmentedControl), findsOneWidget);
    expect(
      tester.getSize(find.byType(LingoSegmentedControl)).height,
      greaterThanOrEqualTo(52),
    );

    UserPreferences.instance.setSelectedTranslationLanguage('tr');
    await tester.pump();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Merhaba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long German phrases wrap on Pro Max without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 430,
            child: LingoPhraseCard(
              phrase:
                  'Could you please tell me how to get to the railway station?',
              pronunciation: '/kʊd ju/',
              meaning:
                  'Könnten Sie mir bitte sagen, wie ich zum Bahnhof komme, ich wäre Ihnen sehr dankbar.',
              index: 12,
              total: 24,
              play: PronunciationControl(
                clip: PronunciationClip(id: 'phrase.station'),
              ),
              action: LingoFavoriteButton(saved: false, onPressed: _noop),
              learnedAction: LingoLearnedButton(
                learned: false,
                onPressed: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('/kʊd ju/'), findsNothing);
    expect(find.byType(PronunciationControl), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

LocalContentRepository _learningRepo({int wordCount = 2}) {
  return LocalContentRepository(
    product: ProductConfig.fallback,
    pack: const LanguagePack(
      id: 'learning-test',
      name: 'Learning Test',
      version: '1',
      targetLanguageCode: 'und',
      targetLanguageName: 'Sample',
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      hasAlphabet: false,
      defaultTranslationLanguageCode: 'en',
      translationLanguageCodes: <String>[
        'en',
        'tr',
        'de',
        'ru',
        'ar',
        'fa',
        'ja',
        'zh',
      ],
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
          audioAsset: index == 0 ? 'assets/audio/words/hello.wav' : null,
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
    translationBundles: <TranslationBundle>[
      TranslationBundle(
        languageCode: 'tr',
        languageName: 'Turkish',
        strings: <String, String>{
          'word.hello': 'Merhaba',
          for (int index = 1; index < wordCount; index++)
            'word.$index': 'Kelime $index',
          'phrase.hello': 'Nasılsın?',
          'words.basics': 'Temel',
          'phrases.greetings': 'Selamlaşma',
        },
      ),
      TranslationBundle(
        languageCode: 'en',
        languageName: 'English',
        strings: <String, String>{
          'word.hello': 'A greeting',
          for (int index = 1; index < wordCount; index++)
            'word.$index': 'Word meaning $index',
          'phrase.hello': 'How are you doing?',
          'words.basics': 'Basics',
          'phrases.greetings': 'Greetings',
        },
      ),
      TranslationBundle(
        languageCode: 'de',
        languageName: 'German',
        strings: <String, String>{
          'word.hello': 'Eine sehr höfliche Begrüßung unter Freunden',
          'phrase.hello': 'Wie geht es Ihnen?',
          'words.basics': 'Grundlagen',
          'phrases.greetings': 'Begrüßungen',
        },
      ),
      TranslationBundle(
        languageCode: 'ru',
        languageName: 'Russian',
        strings: <String, String>{
          'word.hello': 'Приветствие',
          'phrase.hello': 'Как дела?',
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
      TranslationBundle(
        languageCode: 'ja',
        languageName: 'Japanese',
        strings: <String, String>{
          'word.hello': 'あいさつ',
          'phrase.hello': '元気ですか？',
        },
      ),
      TranslationBundle(
        languageCode: 'zh',
        languageName: 'Chinese',
        strings: <String, String>{'word.hello': '问候', 'phrase.hello': '你好吗？'},
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

final class _RecordingSpeechEngine implements SpeechEngine {
  final List<(String, String)> utterances = <(String, String)>[];

  @override
  Future<void> speak({
    required String text,
    required String locale,
    TargetSpeechProfile? profile,
  }) async {
    utterances.add((text, locale));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

final class _MissingSoundAssetProbe implements SoundAssetProbe {
  const _MissingSoundAssetProbe();

  @override
  Future<bool> exists(String path) async => false;
}
