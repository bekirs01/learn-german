import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/widgets/lingo_cards.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/lingo_segmented_control.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';

import 'support/shell_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
  });

  testWidgets('default preferences appear on first launch', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final LocalContentRepository pack = _pack();

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

    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    if (pack.translationBundles.isNotEmpty) {
      expect(find.text(_defaultBundle(pack).languageName), findsOneWidget);
    }
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About'), findsNothing);

    final List<LingoToggle> toggles = tester
        .widgetList<LingoToggle>(find.byType(LingoToggle))
        .toList();
    expect(toggles, hasLength(2));
    expect(toggles[0].value, isTrue);
    expect(toggles[1].value, isTrue);
    expect(FeedbackService.instance.soundEnabled, isTrue);
    expect(FeedbackService.instance.hapticsEnabled, isTrue);
  });

  testWidgets('translation language changes persist across restart', (
    WidgetTester tester,
  ) async {
    final MemoryPreferenceStore store = MemoryPreferenceStore();
    await _pumpApp(tester, store: store);
    final LocalContentRepository pack = _pack();
    if (pack.translationBundles.length < 2 || pack.wordCategories.isEmpty) {
      return;
    }
    final TranslationBundle other = pack.translationBundles.firstWhere(
      (TranslationBundle bundle) =>
          bundle.languageCode != pack.pack.defaultTranslationLanguageCode,
    );
    final ContentCategory category = pack.wordCategories.first;
    final String translated = pack.labelFor(
      category.id,
      category.title,
      languageCode: other.languageCode,
    );

    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    await tester.tap(find.text('Translation language'));
    await _pumpUi(tester);
    final Finder languageOption = find.text(
      UiStrings.languageNameFor(
        other.languageCode,
        languageCode: 'en',
        fallback: other.languageName,
      ),
    );
    await tester.ensureVisible(languageOption);
    await _pumpUi(tester);
    await tester.tap(languageOption);
    await _pumpUi(tester);
    expect(
      find.text(
        UiStrings.languageNameFor(
          other.languageCode,
          languageCode: other.languageCode,
          fallback: other.languageName,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    expect(find.text(translated), findsOneWidget);

    await _restart(tester, store);

    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    expect(
      find.text(
        UiStrings.languageNameFor(
          other.languageCode,
          languageCode: other.languageCode,
          fallback: other.languageName,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    expect(find.text(translated), findsOneWidget);
  });

  testWidgets('favorites add and remove immediately and survive restart', (
    WidgetTester tester,
  ) async {
    final MemoryPreferenceStore store = MemoryPreferenceStore();
    await _pumpApp(tester, store: store);
    final LocalContentRepository pack = _pack();
    if (pack.wordCategories.isEmpty || pack.phraseCategories.isEmpty) {
      return;
    }
    final ContentCategory wordCategory = pack.wordCategories.first;
    final ContentCategory phraseCategory = pack.phraseCategories.first;
    final List<WordEntry> words = pack.wordsForCategory(wordCategory.id);
    final List<PhraseEntry> phrases = pack.phrasesForCategory(
      phraseCategory.id,
    );
    if (words.isEmpty || phrases.isEmpty) {
      return;
    }
    final WordEntry word = words.first;
    PhraseEntry phrase = phrases.first;
    for (final PhraseEntry item in phrases) {
      if (item.text != word.text) {
        phrase = item;
        break;
      }
    }

    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    await tester.tap(find.text(_label(pack, wordCategory)));
    await _pumpUi(tester);
    expect(find.text(word.text), findsWidgets);

    await tester.ensureVisible(find.byTooltip('Add to favorites').first);
    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pump();
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await tester.pageBack();
    await _pumpUi(tester);
    await tester.tap(shellTab(ShellTabIndex.phrases));
    await _pumpUi(tester);
    await tester.tap(find.text(_label(pack, phraseCategory)));
    await _pumpUi(tester);
    await tester.ensureVisible(find.byTooltip('Add to favorites').first);
    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pump();

    await tester.tap(shellTab(ShellTabIndex.favorites));
    await _pumpUi(tester);
    expect(find.byType(LingoWordCard), findsOneWidget);
    expect(find.text(word.text), findsWidgets);
    expect(find.text(phrase.text), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Phrases'),
      ),
    );
    await _pumpUi(tester);
    expect(find.byType(LingoPhraseCard), findsOneWidget);
    expect(find.text(phrase.text), findsWidgets);
    expect(find.byType(LingoWordCard), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Words'),
      ),
    );
    await _pumpUi(tester);
    expect(find.byType(LingoWordCard), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(find.text('No saved words'), findsOneWidget);

    await _restart(tester, store);

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
    expect(find.byType(LingoPhraseCard), findsOneWidget);
    expect(find.text(phrase.text), findsWidgets);
  });

  testWidgets('settings toggles persist and sync feedback', (
    WidgetTester tester,
  ) async {
    final MemoryPreferenceStore store = MemoryPreferenceStore();
    await _pumpApp(tester, store: store);

    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    await tester.tap(find.byType(LingoToggle).at(0));
    await tester.pump();
    await tester.tap(find.byType(LingoToggle).at(1));
    await tester.pump();

    List<LingoToggle> toggles = tester
        .widgetList<LingoToggle>(find.byType(LingoToggle))
        .toList();
    expect(toggles[0].value, isFalse);
    expect(toggles[1].value, isFalse);
    expect(FeedbackService.instance.soundEnabled, isFalse);
    expect(FeedbackService.instance.hapticsEnabled, isFalse);

    await _restart(tester, store);

    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    toggles = tester.widgetList<LingoToggle>(find.byType(LingoToggle)).toList();
    expect(toggles[0].value, isFalse);
    expect(toggles[1].value, isFalse);
    expect(FeedbackService.instance.soundEnabled, isFalse);
    expect(FeedbackService.instance.hapticsEnabled, isFalse);
  });

  testWidgets('invalid favorite IDs are ignored', (WidgetTester tester) async {
    final MemoryPreferenceStore store = MemoryPreferenceStore();
    UserPreferences.resetForTest(store: store);
    await _loadRepo(tester);
    final LocalContentRepository pack = _pack();
    if (pack.wordCategories.isEmpty) {
      return;
    }
    final List<WordEntry> words = pack.wordsForCategory(
      pack.wordCategories.first.id,
    );
    if (words.isEmpty) {
      return;
    }
    final WordEntry word = words.first;
    await UserPreferences.instance.addFavoriteWord('missing.word');
    await UserPreferences.instance.addFavoritePhrase('missing.phrase');
    await UserPreferences.instance.addFavoriteWord(word.id);
    await UserPreferences.instance.addFavoriteWord(word.id);

    await _pumpApp(tester, store: store, resetPreferences: false);

    await tester.tap(shellTab(ShellTabIndex.favorites));
    await _pumpUi(tester);
    expect(find.text(word.text), findsWidgets);
    expect(find.byType(LingoWordCard), findsOneWidget);
    expect(find.text('missing.word'), findsNothing);
    expect(UserPreferences.instance.getFavoriteWordIds(), <String>{word.id});
    expect(UserPreferences.instance.getFavoritePhraseIds(), isEmpty);
  });
}

LocalContentRepository _pack() {
  final LocalContentRepository? pack = LocalContentRepository.cached;
  if (pack == null) {
    fail('content pack was not loaded');
  }
  return pack;
}

TranslationBundle _defaultBundle(LocalContentRepository pack) {
  for (final TranslationBundle bundle in pack.translationBundles) {
    if (bundle.languageCode == pack.pack.defaultTranslationLanguageCode) {
      return bundle;
    }
  }
  return pack.translationBundles.first;
}

String _label(LocalContentRepository pack, ContentCategory category) {
  return pack.labelFor(
    category.id,
    category.title,
    languageCode: pack.pack.defaultTranslationLanguageCode,
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  MemoryPreferenceStore? store,
  bool resetPreferences = true,
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
  if (resetPreferences) {
    UserPreferences.resetForTest(store: store);
  }
  final LocalContentRepository repo = await _loadRepo(tester);

  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await _pumpUi(tester);
}

Future<void> _restart(WidgetTester tester, MemoryPreferenceStore store) async {
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
