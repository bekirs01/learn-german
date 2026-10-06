import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/widgets/lingo_segmented_control.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/quiz/quiz_request.dart';

import 'support/shell_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UiCatalog.resetForTest();
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
  });

  group('catalog', () {
    test('all 15 learner languages ship the same chrome keys', () {
      expect(LearnerLanguages.orderedCodes, hasLength(15));
      final Set<String> englishKeys = UiCatalog.stringsFor('en').keys.toSet();
      expect(englishKeys, unorderedEquals(UiKeys.chrome));
      for (final String code in LearnerLanguages.orderedCodes) {
        expect(UiCatalog.hasTable(code), isTrue, reason: code);
        expect(UiCatalog.missingChromeKeys(code), isEmpty, reason: code);
        expect(
          UiCatalog.stringsFor(code).keys,
          unorderedEquals(englishKeys),
          reason: code,
        );
      }
    });

    test('English UI strings stay English', () {
      expect(UiStrings.resolve(UiKeys.navAlphabet), 'Alphabet');
      expect(UiStrings.resolve(UiKeys.navWords, languageCode: 'en'), 'Words');
      expect(
        UiStrings.resolve(UiKeys.settingsTitle, languageCode: 'en'),
        'Settings',
      );
      expect(
        UiStrings.resolve(UiKeys.favoritesEmptyWords, languageCode: 'en'),
        'No saved words',
      );
      expect(
        UiStrings.resolve(UiKeys.quizContinue, languageCode: 'en'),
        'Continue',
      );
    });

    test('Turkish UI strings are complete for production chrome', () {
      expect(
        UiStrings.resolve(UiKeys.navAlphabet, languageCode: 'tr'),
        'Alfabe',
      );
      expect(
        UiStrings.resolve(UiKeys.navWords, languageCode: 'tr'),
        'Kelimeler',
      );
      expect(
        UiStrings.resolve(UiKeys.navPhrases, languageCode: 'tr'),
        'İfadeler',
      );
      expect(
        UiStrings.resolve(UiKeys.navFavorites, languageCode: 'tr'),
        'Favoriler',
      );
      expect(
        UiStrings.resolve(UiKeys.navSettings, languageCode: 'tr'),
        'Ayarlar',
      );
      expect(
        UiStrings.resolve(
          UiKeys.settingsTranslationLanguage,
          languageCode: 'tr',
        ),
        'Çeviri dili',
      );
      expect(
        UiStrings.resolve(UiKeys.settingsSoundEffects, languageCode: 'tr'),
        'Ses efektleri',
      );
      expect(
        UiStrings.resolve(UiKeys.favoritesWords, languageCode: 'tr'),
        'Kelimeler',
      );
      expect(
        UiStrings.resolve(UiKeys.quizChoose, languageCode: 'tr'),
        'Quiz seç',
      );
      expect(
        UiStrings.resolve(UiKeys.quizMixed, languageCode: 'tr'),
        'Karışık',
      );
      expect(
        UiStrings.resolve(UiKeys.alphabetExample, languageCode: 'en'),
        'Example',
      );
      expect(
        UiStrings.resolve(UiKeys.alphabetMeaning, languageCode: 'en'),
        'Meaning',
      );
      expect(
        UiStrings.resolve(UiKeys.alphabetExample, languageCode: 'tr'),
        'Örnek',
      );
      expect(
        UiStrings.resolve(UiKeys.alphabetMeaning, languageCode: 'tr'),
        'Anlam',
      );
      expect(
        UiStrings.resolve(UiKeys.audioPlayPronunciation, languageCode: 'tr'),
        'Telaffuzu dinle',
      );
    });

    test('missing keys fall back to English then a readable label', () {
      expect(UiStrings.resolve(UiKeys.navWords, languageCode: 'xx'), 'Words');
      expect(
        UiStrings.resolve('does.not_exist', languageCode: 'tr'),
        'Not exist',
      );
      UiCatalog.register('xx', <String, String>{
        UiKeys.navAlphabet: 'XX-Alpha',
        UiKeys.navWords: '  ',
      });
      expect(
        UiStrings.resolve(UiKeys.navAlphabet, languageCode: 'xx'),
        'XX-Alpha',
      );
      expect(UiStrings.resolve(UiKeys.navWords, languageCode: 'xx'), 'Words');
    });

    test('quiz labels resolve through localization', () {
      expect(
        quizTypeLabel(QuizType.multipleChoice, languageCode: 'en'),
        'Multiple choice',
      );
      expect(
        quizTypeLabel(QuizType.multipleChoice, languageCode: 'tr'),
        'Çoktan seçmeli',
      );
      expect(
        quizTypeLabel(
          QuizType.buildSequence,
          kind: QuizContentKind.word,
          languageCode: 'tr',
        ),
        'Kelimeyi oluştur',
      );
      expect(
        quizTypeSubtitle(QuizType.typing, languageCode: 'tr'),
        'Cevabı kendin yaz.',
      );
    });

    test('clone overlay supplies UI chrome without rewriting screens', () {
      expect(
        UiCatalog.resolve(
          UiKeys.navAlphabet,
          languageCode: 'nl',
          overlay: <String, String>{UiKeys.navAlphabet: 'Alfabet'},
        ),
        'Alfabet',
      );
      expect(
        UiCatalog.resolve(
          UiKeys.navWords,
          languageCode: 'nl',
          overlay: <String, String>{UiKeys.navAlphabet: 'Alfabet'},
        ),
        'Words',
      );
    });
  });

  testWidgets('English UI shell, settings, and favorites copy', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Alphabet'), findsWidgets);
    expect(shellTabLabels(tester), <String>[
      'Home',
      'Words',
      'Phrases',
      'Favorites',
      'Settings',
    ]);

    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    expect(find.text('Translation language'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(shellTab(ShellTabIndex.favorites));
    await _pumpUi(tester);
    expect(find.text('No saved words'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Phrases'),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('No saved phrases'), findsOneWidget);
  });

  testWidgets('changing translation language updates visible shell copy', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _selectTurkish(tester);

    expect(shellTabLabels(tester), <String>[
      'Ana sayfa',
      'Kelimeler',
      'İfadeler',
      'Favoriler',
      'Ayarlar',
    ]);
    expect(find.text('Çeviri dili'), findsOneWidget);
    expect(find.text('Ses efektleri'), findsOneWidget);
    expect(find.text('Dokunsal geri bildirim'), findsOneWidget);
    expect(find.text('Gizlilik'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('Sound effects'), findsNothing);

    await tester.tap(shellTab(ShellTabIndex.home));
    await _pumpUi(tester);
    expect(find.text('Alfabe'), findsWidgets);

    await tester.tap(shellTab(ShellTabIndex.favorites));
    await _pumpUi(tester);
    expect(find.text('Kayıtlı kelime yok'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('İfadeler'),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('Kayıtlı ifade yok'), findsOneWidget);
  });

  testWidgets('learner-language selection persists across restart', (
    WidgetTester tester,
  ) async {
    final MemoryPreferenceStore store = MemoryPreferenceStore();
    await _pumpApp(tester, store: store);
    await _selectTurkish(tester);
    expect(UserPreferences.instance.getSelectedTranslationLanguage(), 'tr');
    expect(shellTabLabels(tester), contains('Ayarlar'));

    await UserPreferences.instance.flushWrites();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    FeedbackService.instance = FeedbackService(
      hapticsEnabled: false,
      soundEnabled: false,
    );
    UserPreferences.resetForTest(store: store);
    final LocalContentRepository repo = await _loadRepo(tester);
    await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
    await _pumpUi(tester);

    expect(UserPreferences.instance.getSelectedTranslationLanguage(), 'tr');
    expect(find.text('Alfabe'), findsWidgets);
    expect(shellTabLabels(tester), contains('Ayarlar'));
    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    expect(find.text('Türkçe'), findsOneWidget);
  });

  testWidgets('Turkish UI keeps English target-language learning content', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final LocalContentRepository pack = _pack();
    if (pack.wordCategories.isEmpty) {
      return;
    }
    final ContentCategory category = pack.wordCategories.first;
    final List<WordEntry> words = pack.wordsForCategory(category.id);
    if (words.isEmpty) {
      return;
    }
    final WordEntry word = words.first;
    final String turkishCategory = pack.labelFor(
      category.id,
      category.title,
      languageCode: 'tr',
    );
    final String? turkishMeaning = pack.translation(
      word.id,
      languageCode: 'tr',
    );

    await _selectTurkish(tester);
    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    expect(find.text(turkishCategory), findsWidgets);
    expect(find.text('Basics'), findsNothing);

    await tester.tap(find.text(turkishCategory).first);
    await _pumpUi(tester);
    expect(find.text(word.text), findsWidgets);
    if (turkishMeaning != null &&
        turkishMeaning.toLowerCase() != word.text.toLowerCase()) {
      expect(find.text(turkishMeaning), findsWidgets);
    }

    if (pack.alphabet.isNotEmpty) {
      final AlphabetUnit letter = pack.alphabet.first;
      await tester.tap(shellTab(ShellTabIndex.home));
      await _pumpUi(tester);
      await tester.tap(find.byKey(HomeScreen.alphabetKey));
      await _pumpUi(tester);
      expect(find.text(letter.glyph), findsWidgets);
      final String? example = letter.example?.trim();
      if (example != null && example.isNotEmpty) {
        expect(find.text(example), findsWidgets);
      }
      final String? meaning = pack.translation(letter.id, languageCode: 'tr');
      if (meaning != null &&
          meaning.trim().isNotEmpty &&
          meaning.toLowerCase() != (example ?? '').toLowerCase()) {
        expect(find.text(meaning), findsWidgets);
      }
    }
  });

  testWidgets('quiz setup chrome follows the selected learner language', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _selectTurkish(tester);
    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    final LocalContentRepository pack = _pack();
    final String turkishCategory = pack.labelFor(
      pack.wordCategories.first.id,
      pack.wordCategories.first.title,
      languageCode: 'tr',
    );
    await tester.tap(find.text(turkishCategory).first);
    await _pumpUi(tester);
    await tester.tap(find.byTooltip('Quiz'));
    await _pumpUi(tester);
    expect(find.text('Quiz seç'), findsOneWidget);
    expect(find.text('Karışık'), findsOneWidget);
    expect(find.text('Çoktan seçmeli'), findsOneWidget);
    expect(find.text('Choose quiz'), findsNothing);
    expect(find.text('Mixed'), findsNothing);
  });

  testWidgets(
    'Alphabet keeps the German example and shows the learner meaning',
    (WidgetTester tester) async {
      await _pumpApp(tester);
      final LocalContentRepository pack = _pack();
      final AlphabetUnit letter = pack.alphabet.firstWhere(
        (AlphabetUnit unit) => unit.id == 'letter.a',
      );
      expect(letter.example, 'Apfel');
      await tester.tap(find.byKey(HomeScreen.alphabetKey));
      await _pumpUi(tester);
      expect(find.text('Apfel'), findsWidgets);

      await tester.pageBack();
      await _pumpUi(tester);
      await _selectTurkish(tester);
      await tester.tap(shellTab(ShellTabIndex.home));
      await _pumpUi(tester);
      await tester.tap(find.byKey(HomeScreen.alphabetKey));
      await _pumpUi(tester);
      expect(find.text('A'), findsWidgets);
      expect(find.text('Apfel'), findsWidgets);
      expect(find.text('elma'), findsWidgets);
      expect(
        UiStrings.resolve(UiKeys.alphabetExample, languageCode: 'tr'),
        'Örnek',
      );
      expect(
        UiStrings.resolve(UiKeys.alphabetMeaning, languageCode: 'tr'),
        'Anlam',
      );
    },
  );

  testWidgets('Phrases keep English targets and swap learner meanings', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final LocalContentRepository pack = _pack();
    if (pack.phraseCategories.isEmpty) {
      return;
    }
    final ContentCategory category = pack.phraseCategories.first;
    final List<PhraseEntry> phrases = pack.phrasesForCategory(category.id);
    if (phrases.isEmpty) {
      return;
    }
    final PhraseEntry phrase = phrases.first;
    final String turkishCategory = pack.labelFor(
      category.id,
      category.title,
      languageCode: 'tr',
    );
    final String? turkishMeaning = pack.translation(
      phrase.id,
      languageCode: 'tr',
    );
    final String? englishMeaning = pack.translation(
      phrase.id,
      languageCode: 'en',
    );

    await tester.tap(shellTab(ShellTabIndex.phrases));
    await _pumpUi(tester);
    await tester.tap(
      find.text(pack.labelFor(category.id, category.title)).first,
    );
    await _pumpUi(tester);
    expect(find.text(phrase.text), findsWidgets);
    if (englishMeaning != null) {
      expect(find.text(englishMeaning), findsWidgets);
    }

    await _selectTurkish(tester);
    await tester.tap(shellTab(ShellTabIndex.phrases));
    await _pumpUi(tester);
    expect(find.text(turkishCategory), findsWidgets);
    expect(find.text(phrase.text), findsWidgets);
    if (turkishMeaning != null) {
      expect(find.text(turkishMeaning), findsWidgets);
    }
  });

  testWidgets('Favorites keep IDs and swap only the learner meaning', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final LocalContentRepository pack = _pack();
    if (pack.wordCategories.isEmpty) {
      return;
    }
    final ContentCategory category = pack.wordCategories.first;
    final List<WordEntry> words = pack.wordsForCategory(category.id);
    if (words.isEmpty) {
      return;
    }
    final WordEntry word = words.first;
    final String? englishMeaning = pack.translation(
      word.id,
      languageCode: 'en',
    );
    final String? turkishMeaning = pack.translation(
      word.id,
      languageCode: 'tr',
    );

    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    await tester.tap(
      find.text(pack.labelFor(category.id, category.title)).first,
    );
    await _pumpUi(tester);
    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pump();
    expect(UserPreferences.instance.getFavoriteWordIds(), <String>{word.id});

    await tester.tap(shellTab(ShellTabIndex.favorites));
    await _pumpUi(tester);
    expect(find.text(word.text), findsWidgets);
    if (englishMeaning != null) {
      expect(find.text(englishMeaning), findsWidgets);
    }

    await _selectTurkish(tester);
    await tester.tap(shellTab(ShellTabIndex.favorites));
    await _pumpUi(tester);
    expect(UserPreferences.instance.getFavoriteWordIds(), <String>{word.id});
    expect(find.text(word.text), findsWidgets);
    if (turkishMeaning != null && turkishMeaning != englishMeaning) {
      expect(find.text(turkishMeaning), findsWidgets);
    }
    expect(find.byTooltip('Favorilerden çıkar'), findsOneWidget);
  });

  testWidgets('switching back to English restores English learner UI', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _selectTurkish(tester);
    expect(shellTabLabels(tester), contains('Ayarlar'));
    expect(shellTabLabels(tester), isNot(contains('Settings')));

    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    await tester.tap(find.text('Çeviri dili'));
    await _pumpUi(tester);
    final Finder english = find.text('English');
    await tester.ensureVisible(english);
    await tester.tap(english);
    await _pumpUi(tester);

    expect(shellTabLabels(tester), contains('Settings'));
    expect(find.text('Translation language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(shellTabLabels(tester), isNot(contains('Ayarlar')));

    await tester.tap(shellTab(ShellTabIndex.home));
    await _pumpUi(tester);
    expect(find.text('Alphabet'), findsWidgets);
    expect(UserPreferences.instance.getSelectedTranslationLanguage(), 'en');
  });
}

LocalContentRepository _pack() {
  final LocalContentRepository? pack = LocalContentRepository.cached;
  if (pack == null) {
    fail('content pack was not loaded');
  }
  return pack;
}

Future<void> _selectTurkish(WidgetTester tester) async {
  await tester.tap(shellTab(ShellTabIndex.settings));
  await _pumpUi(tester);
  await tester.tap(find.text('Translation language'));
  await _pumpUi(tester);
  final Finder turkish = find.text('Türkçe');
  await tester.ensureVisible(turkish);
  await tester.tap(turkish);
  await _pumpUi(tester);
}

Future<void> _pumpApp(
  WidgetTester tester, {
  MemoryPreferenceStore? store,
}) async {
  tester.view.physicalSize = const Size(1290, 3600);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  FeedbackService.instance = FeedbackService(
    hapticsEnabled: false,
    soundEnabled: false,
  );
  UserPreferences.resetForTest(store: store);
  final LocalContentRepository repo = await _loadRepo(tester);
  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await _pumpUi(tester);
}

Future<LocalContentRepository> _loadRepo(WidgetTester tester) async {
  final LocalContentRepository? repo = await tester.runAsync(
    LocalContentRepository.load,
  );
  if (repo == null) {
    fail('content pack was not loaded');
  }
  return repo;
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
