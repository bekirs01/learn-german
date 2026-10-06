import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/widgets/lingo_bottom_nav.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/learn/alphabet_screen.dart';

import 'support/shell_nav.dart';

void main() {
  testWidgets('primary tabs and learning pushes stay shallow', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    final LocalContentRepository pack = _pack();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Alphabet'), findsWidgets);
    await tester.tap(find.byKey(HomeScreen.alphabetKey));
    await tester.pump();
    if (pack.alphabet.isNotEmpty) {
      final AlphabetUnit first = pack.alphabet.first;
      expect(find.byType(AlphabetScreen), findsOneWidget);
      expect(find.text(first.glyph), findsWidgets);
      if (pack.alphabet.length > 1) {
        final AlphabetUnit second = pack.alphabet[1];
        await tester.tap(find.text(second.glyph).first);
        await tester.pump();
        final String? cue = second.pronunciation ?? second.romanization;
        if (cue != null && cue.isNotEmpty) {
          expect(find.text(cue), findsOneWidget);
        }
      }
      await tester.pageBack();
      await tester.pump();
    }

    await tester.tap(shellTab(ShellTabIndex.words));
    await tester.pump();
    if (pack.wordCategories.isNotEmpty) {
      final ContentCategory category = pack.wordCategories.first;
      final String label = _label(pack, category);
      expect(find.text(label), findsWidgets);
      await _scrollTo(tester, find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
      final List<WordEntry> words = pack.wordsForCategory(category.id);
      if (words.isNotEmpty) {
        expect(find.text(words.first.text), findsWidgets);
      }
      await tester.pageBack();
      await tester.pump();
    }

    await tester.tap(shellTab(ShellTabIndex.phrases));
    await tester.pump();
    if (pack.phraseCategories.isNotEmpty) {
      final ContentCategory category = pack.phraseCategories.first;
      final String label = _label(pack, category);
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pump();
      final List<PhraseEntry> phrases = pack.phrasesForCategory(category.id);
      if (phrases.isNotEmpty) {
        expect(find.text(phrases.first.text), findsWidgets);
      }
      await tester.pageBack();
      await tester.pump();
    }

    await tester.tap(shellTab(ShellTabIndex.favorites));
    await tester.pump();
    expect(find.text('No saved words'), findsOneWidget);

    await tester.tap(shellTab(ShellTabIndex.settings));
    await tester.pump();
    expect(find.text('Privacy'), findsOneWidget);
    await tester.tap(find.text('Privacy'));
    await tester.pump();
    expect(find.textContaining('no account'), findsOneWidget);
  });

  testWidgets('small iPhone, large iPhone, text scale, and scroll', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(375, 667));
    final LocalContentRepository pack = _pack();
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Alphabet'), findsWidgets);

    await _pumpApp(tester, const Size(430, 932));
    expect(tester.takeException(), isNull);
    await tester.tap(shellTab(ShellTabIndex.words));
    await tester.pump();
    if (pack.wordCategories.isNotEmpty) {
      expect(find.text(_label(pack, pack.wordCategories.first)), findsWidgets);
    }

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(top: 47, bottom: 34),
          textScaler: TextScaler.linear(1.6),
        ),
        child: LingoCoreApp(contentRepository: pack),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(shellTab(ShellTabIndex.words));
    await tester.pump();
    if (pack.wordCategories.isNotEmpty) {
      expect(find.text(_label(pack, pack.wordCategories.first)), findsWidgets);
    }
  });

  testWidgets('category cards compress on press', (WidgetTester tester) async {
    await _pumpApp(tester, const Size(390, 844));
    final LocalContentRepository pack = _pack();
    await tester.tap(shellTab(ShellTabIndex.words));
    await tester.pump();
    if (pack.wordCategories.isEmpty) {
      return;
    }
    final ContentCategory category = pack.wordCategories.first;
    final String label = _label(pack, category);
    await _scrollTo(tester, find.text(label));
    final TestGesture gesture = await tester.press(find.text(label));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pump();
    final List<WordEntry> words = pack.wordsForCategory(category.id);
    if (words.isNotEmpty) {
      expect(find.text(words.first.text), findsWidgets);
    }
  });

  testWidgets('floating nav hides after idle and returns on tap', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    final LocalContentRepository pack = _pack();

    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);

    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isFalse);

    await tester.tap(find.byKey(HomeScreen.alphabetKey));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);

    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(shellTab(ShellTabIndex.words));
    await tester.pump();
    if (pack.wordCategories.isNotEmpty) {
      expect(
        find.text(_label(pack, pack.wordCategories.first)),
        findsOneWidget,
      );
    }
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);
  });

  testWidgets('keyboard hides the floating nav without overflowing', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    addTearDown(tester.view.resetViewInsets);

    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isFalse);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);
  });
}

LocalContentRepository _pack() {
  final LocalContentRepository? pack = LocalContentRepository.cached;
  if (pack == null) {
    fail('content pack was not loaded');
  }
  return pack;
}

String _label(LocalContentRepository pack, ContentCategory category) {
  return pack.labelFor(
    category.id,
    category.title,
    languageCode: pack.pack.defaultTranslationLanguageCode,
  );
}

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  UserPreferences.resetForTest();
  FeedbackService.instance = FeedbackService(
    hapticsEnabled: false,
    soundEnabled: false,
  );
  final LocalContentRepository repo = await _loadRepo(tester);

  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await tester.pump();
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

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 360);
  await tester.pump();
}
