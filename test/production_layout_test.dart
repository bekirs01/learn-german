import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/widgets/lingo_cards.dart';
import 'package:lingo_core/core/widgets/lingo_layout.dart';
import 'package:lingo_core/core/widgets/lingo_segmented_control.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/learn/alphabet_screen.dart';
import 'package:lingo_core/features/quiz/quiz_launch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
  });

  testWidgets('root tabs omit repeated headings and keep useful chrome', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    final LocalContentRepository pack = _pack();

    expect(find.byType(LingoLargeTitle), findsNothing);
    expect(find.byType(QuizLaunchButton), findsNothing);

    await tester.tap(_navItem(1));
    await tester.pump();
    expect(find.byType(LingoLargeTitle), findsNothing);
    expect(find.byType(QuizLaunchButton), findsNothing);
    if (pack.wordCategories.isNotEmpty) {
      expect(find.byType(LingoCategoryCard), findsWidgets);
    }

    await tester.tap(_navItem(2));
    await tester.pump();
    expect(find.byType(LingoLargeTitle), findsNothing);
    expect(find.byType(QuizLaunchButton), findsNothing);
    if (pack.phraseCategories.isNotEmpty) {
      expect(find.byType(LingoCategoryCard), findsWidgets);
    }

    await tester.tap(_navItem(3));
    await tester.pump();
    expect(find.byType(LingoLargeTitle), findsNothing);
    expect(find.byType(LingoSegmentedControl), findsOneWidget);
    expect(find.text('No saved words'), findsOneWidget);

    await tester.tap(_navItem(4));
    await tester.pump();
    expect(find.byType(LingoLargeTitle), findsNothing);
    expect(find.text('Translation language'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About'), findsNothing);
    expect(find.text('Rate App'), findsNothing);
    expect(find.text('Theme'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('word and phrase lists stay scannable on a standard iPhone', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    final LocalContentRepository pack = _pack();

    await tester.tap(_navItem(1));
    await tester.pump();
    if (pack.wordCategories.isNotEmpty) {
      final ContentCategory category = pack.wordCategories.first;
      final String label = _label(pack, category);
      await tester.scrollUntilVisible(find.text(label), 280);
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();
      expect(find.text(label), findsWidgets);
      expect(find.byType(QuizLaunchButton), findsOneWidget);
      expect(find.byType(LingoCategoryHero), findsOneWidget);
      final List<WordEntry> words = pack.wordsForCategory(category.id);
      if (words.isNotEmpty) {
        expect(find.text(words.first.text), findsWidgets);
        expect(find.byType(LingoWordCard), findsWidgets);
        expect(
          tester.getSize(find.byType(LingoWordCard).first).height,
          lessThan(180),
        );
      }
      await tester.pageBack();
      await tester.pump();
    }

    await tester.tap(_navItem(2));
    await tester.pump();
    if (pack.phraseCategories.isNotEmpty) {
      final ContentCategory category = pack.phraseCategories.first;
      final String label = _label(pack, category);
      await tester.tap(find.text(label));
      await tester.pump();
      expect(find.text(label), findsWidgets);
      expect(find.byType(QuizLaunchButton), findsOneWidget);
      final List<PhraseEntry> phrases = pack.phrasesForCategory(category.id);
      if (phrases.isNotEmpty) {
        expect(find.text(phrases.first.text), findsWidgets);
        expect(find.byType(LingoPhraseCard), findsWidgets);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('production roots do not overflow on small and large iPhones', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.byType(LingoLargeTitle), findsNothing);

    await tester.tap(_navItem(1));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(LingoCategoryCard), findsWidgets);

    await tester.tap(_navItem(3));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(_navItem(4));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await _pumpApp(tester, const Size(430, 932));
    expect(tester.takeException(), isNull);

    await tester.tap(_navItem(2));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(LingoCategoryCard), findsWidgets);

    await tester.tap(_navItem(4));
    await tester.pump();
    expect(find.text('Privacy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('German alphabet and iPad roots keep umlauts without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(320, 568));
    await tester.ensureVisible(find.byKey(HomeScreen.alphabetKey));
    await tester.tap(find.byKey(HomeScreen.alphabetKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlphabetScreen), findsOneWidget);
    expect(find.text('A'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('alphabet-tile-letter.eszett')),
    );
    expect(
      find.byKey(const ValueKey<String>('alphabet-tile-letter.eszett')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await _pumpApp(tester, const Size(768, 1024));
    expect(tester.takeException(), isNull);
    await tester.tap(_navItem(1));
    await tester.pump();
    expect(find.byType(LingoCategoryCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

LocalContentRepository _pack() {
  final LocalContentRepository? pack = LocalContentRepository.cached;
  if (pack == null) {
    fail('content pack was not loaded');
  }
  return pack;
}

Finder _navItem(int index) {
  return find.byKey(ValueKey<String>('nav-item-$index'));
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
