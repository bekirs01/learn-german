import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/features/home/home_motivation.dart';
import 'package:lingo_core/features/home/home_motivation_card.dart';
import 'package:lingo_core/features/home/home_motivation_l10n.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
    WatchCompanionService.resetForTest();
    HomeMotivationQuotes.resetForTest();
  });

  test('Home keeps fifty attributed English quotes', () {
    expect(HomeMotivationQuotes.pool, hasLength(50));
    expect(HomeMotivationQuotes.pool.toSet(), hasLength(50));
    for (final HomeQuote quote in HomeMotivationQuotes.pool) {
      expect(quote.text.trim(), isNotEmpty);
      expect(quote.author.trim(), isNotEmpty);
      expect(quote.text.length, greaterThan(24));
      expect(quote.text.length, lessThan(110));
      expect(quote.text, isNot(contains('Özenle tekrarla')));
      expect(quote.text.toLowerCase(), isNot(contains('özenle')));
    }
    expect(
      HomeMotivationQuotes.pool.map((HomeQuote quote) => quote.text),
      contains('The journey of a thousand miles begins with a single step.'),
    );
    expect(
      HomeMotivationQuotes.pool.map((HomeQuote quote) => quote.author),
      contains('Lao Tzu'),
    );
  });

  test('every learner language ships fifty aligned quotes', () {
    expect(HomeMotivationL10n.poolSize, 50);
    for (final String code in LearnerLanguages.orderedCodes) {
      final List<HomeQuote> lines = HomeMotivationQuotes.poolFor(code);
      expect(lines, hasLength(50), reason: code);
      expect(
        lines.map((HomeQuote quote) => quote.text).toSet(),
        hasLength(50),
        reason: code,
      );
      for (final HomeQuote quote in lines) {
        expect(quote.text.trim(), isNotEmpty, reason: code);
        expect(quote.author.trim(), isNotEmpty, reason: '$code ${quote.text}');
        expect(quote.text.length, lessThan(160), reason: '$code ${quote.text}');
      }
    }
  });

  test(
    'quotes rotate by local calendar day and stay stable until midnight',
    () {
      final DateTime morning = DateTime(2026, 9, 19, 0, 5);
      final DateTime night = DateTime(2026, 9, 19, 23, 59, 59);
      final DateTime next = DateTime(2026, 9, 20);
      expect(
        HomeMotivationQuotes.forDate(morning),
        HomeMotivationQuotes.forDate(night),
      );
      expect(
        HomeMotivationQuotes.indexForDate(morning),
        HomeMotivationQuotes.indexForDate(night),
      );
      expect(
        HomeMotivationQuotes.forDate(next),
        isNot(HomeMotivationQuotes.forDate(night)),
      );
      expect(
        HomeMotivationQuotes.indexForDate(next),
        (HomeMotivationQuotes.indexForDate(night) + 1) %
            HomeMotivationQuotes.pool.length,
      );

      final Set<HomeQuote> cycle = <HomeQuote>{
        for (int i = 0; i < HomeMotivationQuotes.pool.length; i++)
          HomeMotivationQuotes.forDate(DateTime(2020, 1, 1 + i)),
      };
      expect(cycle, HomeMotivationQuotes.pool.toSet());
    },
  );

  testWidgets('Home shows the local-day quote and advances after midnight', (
    WidgetTester tester,
  ) async {
    HomeMotivationQuotes.now = () => DateTime(2026, 3, 8, 21, 10);
    await _pumpHome(tester);
    final HomeQuote first = HomeMotivationQuotes.todayFor('en');
    expect(find.byKey(HomeScreen.motivationKey), findsOneWidget);
    expect(find.byKey(HomeMotivationCard.quoteKey), findsOneWidget);
    expect(find.text(first.text), findsOneWidget);
    expect(find.textContaining(first.author), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    HomeMotivationQuotes.now = () => DateTime(2026, 3, 9, 0, 0);
    await _pumpHome(tester);
    final HomeQuote second = HomeMotivationQuotes.todayFor('en');
    expect(second, isNot(first));
    expect(find.text(second.text), findsOneWidget);
    expect(find.text(first.text), findsNothing);
  });

  testWidgets('Home quote follows the selected Translation Language', (
    WidgetTester tester,
  ) async {
    HomeMotivationQuotes.now = () => DateTime(2026, 4, 2);
    await _pumpHome(tester, languageCode: 'tr');
    expect(find.text('Alfabe'), findsWidgets);
    final HomeQuote turkish = HomeMotivationQuotes.todayFor('tr');
    final HomeQuote english = HomeMotivationQuotes.todayFor('en');
    expect(find.text(turkish.text), findsOneWidget);
    expect(find.textContaining(turkish.author), findsOneWidget);
    expect(turkish.text, isNot(english.text));
    expect(find.byType(HomeMotivationCard), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpHome(tester, languageCode: 'ar');
    expect(find.text(HomeMotivationQuotes.todayFor('ar').text), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(HomeMotivationCard.quoteKey)),
      ),
      TextDirection.rtl,
    );
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  String languageCode = 'en',
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  UserPreferences.resetForTest();
  await UserPreferences.instance.setSelectedTranslationLanguage(languageCode);
  FeedbackService.instance = FeedbackService(
    hapticsEnabled: false,
    soundEnabled: false,
  );
  WatchCompanionService.resetForTest();
  final LocalContentRepository? repo = await tester.runAsync(
    LocalContentRepository.load,
  );
  if (repo == null) {
    fail('content pack was not loaded');
  }
  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await tester.pump();
}
