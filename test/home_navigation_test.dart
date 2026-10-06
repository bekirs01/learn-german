import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/app/shell_tab.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/widgets/lingo_bottom_nav.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/features/home/home_artwork.dart';
import 'package:lingo_core/features/home/home_motivation.dart';
import 'package:lingo_core/features/home/home_quiz_launch.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/home/wrong_answers_screen.dart';
import 'package:lingo_core/features/learn/alphabet_screen.dart';
import 'package:lingo_core/features/learn/phrase_categories_screen.dart';
import 'package:lingo_core/features/learn/word_categories_screen.dart';
import 'package:lingo_core/features/quiz/quiz_screen.dart';
import 'package:lingo_core/features/quiz/quiz_type_picker.dart';
import 'package:lingo_core/features/quiz/quiz_widgets.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';
import 'package:lingo_core/features/watch/watch_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
    WatchCompanionService.resetForTest();
    HomeMotivationQuotes.resetForTest();
  });

  testWidgets('five main tabs start on Home and omit Alphabet', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));

    expect(ShellTab.values, hasLength(5));
    expect(ShellTab.values.first, ShellTab.home);
    expect(ShellTab.values.contains(ShellTab.home), isTrue);
    expect(ShellTab.values.map((ShellTab tab) => tab.name).toList(), <String>[
      'home',
      'words',
      'phrases',
      'favorites',
      'settings',
    ]);

    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(HomeScreen.alphabetKey), findsOneWidget);
    expect(find.byKey(HomeScreen.wordsKey), findsOneWidget);
    expect(find.byKey(HomeScreen.phrasesKey), findsOneWidget);
    expect(find.byKey(HomeScreen.quizKey), findsOneWidget);
    expect(find.byKey(HomeScreen.wrongAnswersKey), findsOneWidget);
    expect(find.byKey(HomeScreen.appleWatchKey), findsOneWidget);

    final List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items, hasLength(5));
    expect(items[0].selected, isTrue);
    expect(items[0].label, 'Home');
    expect(items.map((LingoBottomNavItem item) => item.label), <String>[
      'Home',
      'Words',
      'Phrases',
      'Favorites',
      'Settings',
    ]);
    expect(items[0].glyph, LingoNavGlyph.home);
    expect(
      items.any((LingoBottomNavItem item) => item.glyph == LingoNavGlyph.words),
      isTrue,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Alphabet')),
      findsNothing,
    );
    expect(find.byType(AlphabetScreen), findsNothing);
    expect(find.byType(LingoNavGlyphIcon), findsNWidgets(5));
  });

  testWidgets('Home opens all six destinations', (WidgetTester tester) async {
    await _pumpApp(tester, const Size(390, 844));

    await tester.tap(find.byKey(HomeScreen.alphabetKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlphabetScreen), findsOneWidget);
    expect(find.text('Alphabet'), findsWidgets);
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AlphabetScreen), findsNothing);

    await tester.tap(find.byKey(HomeScreen.wordsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WordCategoriesScreen), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WordCategoriesScreen), findsNothing);

    await tester.tap(find.byKey(HomeScreen.phrasesKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PhraseCategoriesScreen), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(PhraseCategoriesScreen), findsNothing);

    await tester.tap(find.byKey(HomeScreen.quizKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HomeQuizSourceScreen), findsOneWidget);
    expect(find.text('What do you want to practice?'), findsOneWidget);
    expect(find.byKey(HomeQuizSourceScreen.wordsKey), findsOneWidget);
    expect(find.byKey(HomeQuizSourceScreen.phrasesKey), findsOneWidget);
    expect(find.byType(QuizTypePickerScreen), findsNothing);
    expect(find.byKey(QuizTopBar.backKey), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Quiz')),
      findsNothing,
    );
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(HomeQuizSourceScreen), findsNothing);
    expect(find.byType(QuizTypePickerScreen), findsNothing);
    expect(find.byType(QuizScreen), findsNothing);

    await tester.ensureVisible(find.byKey(HomeScreen.wrongAnswersKey));
    await tester.tap(find.byKey(HomeScreen.wrongAnswersKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WrongAnswersScreen), findsOneWidget);
    expect(find.text('Wrong Answers'), findsWidgets);
    expect(find.text('No mistakes to review'), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WrongAnswersScreen), findsNothing);

    await tester.ensureVisible(find.byKey(HomeScreen.appleWatchKey));
    await tester.tap(find.byKey(HomeScreen.appleWatchKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WatchScreen), findsOneWidget);
    expect(find.text('Apple Watch'), findsWidgets);
    expect(find.text('Set up Apple Watch from your iPhone.'), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WatchScreen), findsNothing);
  });

  testWidgets('selected nav state, semantics, and glass stay interactive', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));

    List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items[0].selected, isTrue);

    await tester.tap(_navTab('Settings'));
    await tester.pump();
    items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items[4].selected, isTrue);
    expect(
      items.where((LingoBottomNavItem item) => item.selected),
      hasLength(1),
    );
    expect(find.text('Privacy'), findsOneWidget);

    await tester.tap(_navTab('Home'));
    await tester.pump();
    items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items[0].selected, isTrue);
    expect(find.byKey(HomeScreen.alphabetKey), findsOneWidget);

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('nav-item-0')))
          .label,
      'Home',
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('nav-item-1')))
          .label,
      'Words',
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('nav-item-0')))
          .flagsCollection
          .isSelected
          .toString()
          .toLowerCase(),
      contains('istrue'),
    );

    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);
    final Rect bar = tester.getRect(nav);
    expect(bar.bottom, closeTo(844, 0.5));
    final Rect first = tester.getRect(find.byType(LingoBottomNavItem).first);
    final Rect last = tester.getRect(find.byType(LingoBottomNavItem).last);
    expect(first.left, greaterThan(8));
    expect(last.right, lessThan(390 - 8));
    expect(first.height, greaterThanOrEqualTo(44));
  });

  testWidgets('RTL Home cards and nav remain usable', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844), languageCode: 'ar');

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(HomeScreen))),
      TextDirection.rtl,
    );
    expect(find.text('الأبجدية'), findsWidgets);
    expect(find.text('الكلمات'), findsWidgets);
    expect(find.text('العبارات'), findsWidgets);
    expect(find.text('اختبار'), findsWidgets);
    expect(find.text('الإجابات الخاطئة'), findsOneWidget);
    expect(find.text('Apple Watch'), findsWidgets);

    final List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items.map((LingoBottomNavItem item) => item.label), <String>[
      'الرئيسية',
      'الكلمات',
      'العبارات',
      'المفضلة',
      'الإعدادات',
    ]);

    await tester.tap(find.byKey(HomeScreen.alphabetKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlphabetScreen), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('nav hides after idle and returns on Home interaction', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);

    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isFalse);

    await tester.tap(find.byKey(HomeScreen.quizKey));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);

    await tester.tap(_navTab('Words'));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);
    final List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items[1].selected, isTrue);
  });

  testWidgets('Home Quiz Words and Phrases open the existing picker', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));

    await tester.tap(find.byKey(HomeScreen.quizKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('What do you want to practice?'), findsOneWidget);
    expect(find.byKey(HomeQuizSourceScreen.wordsKey), findsOneWidget);
    expect(find.byKey(HomeQuizSourceScreen.phrasesKey), findsOneWidget);

    await tester.tap(find.byKey(HomeQuizSourceScreen.wordsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _expectQuizLaunch(tester, QuizContentKind.word);
    expect(find.text('Quiz unavailable'), findsNothing);
    expect(find.byKey(QuizTypePickerScreen.mixedKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('quiz-type-reverseMultipleChoice')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz-type-typing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz-type-buildSequence')),
      findsNothing,
    );
    expect(find.text('Build the word'), findsNothing);
    await _popRoute(tester);
    expect(find.byType(HomeQuizSourceScreen), findsOneWidget);

    await tester.tap(find.byKey(HomeQuizSourceScreen.phrasesKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _expectQuizLaunch(tester, QuizContentKind.phrase);
    expect(find.text('Quiz unavailable'), findsNothing);
    expect(find.byKey(QuizTypePickerScreen.mixedKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('quiz-type-buildSequence')),
      findsOneWidget,
    );
    expect(find.text('Build the word'), findsNothing);
    expect(find.text('Build the phrase'), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(HomeQuizSourceScreen), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Home labels localize for TR DE RU AR FA JA', (
    WidgetTester tester,
  ) async {
    const Map<String, List<String>> expected = <String, List<String>>{
      'tr': <String>[
        'Alfabe',
        'Kelimeler',
        'İfadeler',
        'Quiz',
        'Yanlış cevaplar',
        'Apple Watch',
        'Ana sayfa',
        'Ne çalışmak istiyorsun?',
      ],
      'de': <String>[
        'Alphabet',
        'Wörter',
        'Sätze',
        'Quiz',
        'Falsche Antworten',
        'Apple Watch',
        'Start',
        'Was möchtest du üben?',
      ],
      'ru': <String>[
        'Алфавит',
        'Слова',
        'Фразы',
        'Викторина',
        'Неверные ответы',
        'Apple Watch',
        'Главная',
        'Что вы хотите практиковать?',
      ],
      'ar': <String>[
        'الأبجدية',
        'الكلمات',
        'العبارات',
        'اختبار',
        'الإجابات الخاطئة',
        'Apple Watch',
        'الرئيسية',
        'ماذا تريد أن تتدرب؟',
      ],
      'fa': <String>[
        'الفبا',
        'واژه‌ها',
        'عبارت‌ها',
        'آزمون',
        'پاسخ‌های نادرست',
        'Apple Watch',
        'خانه',
        'می‌خواهید چه چیزی تمرین کنید؟',
      ],
      'ja': <String>[
        'アルファベット',
        '単語',
        'フレーズ',
        'クイズ',
        '間違えた問題',
        'Apple Watch',
        'ホーム',
        '何を練習しますか？',
      ],
    };

    for (final MapEntry<String, List<String>> entry in expected.entries) {
      await _pumpApp(tester, const Size(390, 844), languageCode: entry.key);
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.alphabetKey),
          matching: find.text(entry.value[0]),
        ),
        findsOneWidget,
        reason: entry.key,
      );
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.wordsKey),
          matching: find.text(entry.value[1]),
        ),
        findsOneWidget,
        reason: entry.key,
      );
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.phrasesKey),
          matching: find.text(entry.value[2]),
        ),
        findsOneWidget,
        reason: entry.key,
      );
      expect(find.text(entry.value[3]), findsWidgets, reason: entry.key);
      expect(find.text(entry.value[4]), findsOneWidget, reason: entry.key);
      expect(find.text(entry.value[5]), findsWidgets, reason: entry.key);
      expect(
        tester
            .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
            .first
            .label,
        entry.value[6],
        reason: entry.key,
      );
      if (entry.key == 'ar' || entry.key == 'fa') {
        expect(
          Directionality.of(tester.element(find.byType(HomeScreen))),
          TextDirection.rtl,
          reason: entry.key,
        );
      }
      await tester.tap(find.byKey(HomeScreen.quizKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(entry.value[7]), findsOneWidget, reason: entry.key);
      await _popRoute(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Home cards stay inside small, standard, and Pro Max frames', (
    WidgetTester tester,
  ) async {
    for (final Size size in <Size>[
      const Size(375, 667),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await _pumpApp(tester, size);
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.byKey(HomeScreen.alphabetKey), findsOneWidget);
      expect(find.byKey(HomeScreen.wordsKey), findsOneWidget);
      expect(find.byKey(HomeScreen.phrasesKey), findsOneWidget);
      expect(find.byKey(HomeScreen.quizKey), findsOneWidget);
      expect(find.byKey(HomeScreen.wrongAnswersKey), findsOneWidget);
      expect(find.byKey(HomeScreen.appleWatchKey), findsOneWidget);
      expect(find.byKey(HomeScreen.motivationKey), findsOneWidget);
      expect(
        find.text(HomeMotivationQuotes.todayFor('en').text),
        findsOneWidget,
      );
      expect(find.text('Lingo'), findsNothing);
      expect(find.text('Daily goal'), findsNothing);
      expect(find.text('Streak'), findsNothing);
      expect(find.text('XP'), findsNothing);
      final Rect alphabet = tester.getRect(find.byKey(HomeScreen.alphabetKey));
      final Rect words = tester.getRect(find.byKey(HomeScreen.wordsKey));
      final Rect phrases = tester.getRect(find.byKey(HomeScreen.phrasesKey));
      final Rect quiz = tester.getRect(find.byKey(HomeScreen.quizKey));
      final Rect wrong = tester.getRect(find.byKey(HomeScreen.wrongAnswersKey));
      final Rect watch = tester.getRect(find.byKey(HomeScreen.appleWatchKey));
      final Rect quote = tester.getRect(find.byKey(HomeScreen.motivationKey));
      expect(alphabet.left, greaterThanOrEqualTo(12));
      expect(alphabet.right, lessThanOrEqualTo(size.width - 12));
      expect(words.right, lessThanOrEqualTo(size.width - 12));
      expect(phrases.left, greaterThanOrEqualTo(12));
      expect(quiz.right, lessThanOrEqualTo(size.width - 12));
      expect(wrong.left, greaterThanOrEqualTo(12));
      expect(watch.right, lessThanOrEqualTo(size.width - 12));
      expect(quote.left, greaterThanOrEqualTo(12), reason: '$size');
      expect(quote.right, lessThanOrEqualTo(size.width - 12), reason: '$size');
      expect(quote.height, greaterThan(64), reason: '$size');
      expect(quote.height, lessThan(140), reason: '$size');
      expect(quote.top - watch.bottom, lessThan(28), reason: '$size');
      expect(
        quote.top,
        greaterThanOrEqualTo(watch.bottom - 1),
        reason: '$size',
      );
      if (size.height >= 844) {
        expect(watch.bottom, lessThan(size.height - 24), reason: '$size');
        expect(quote.bottom, lessThan(size.height - 24), reason: '$size');
      }
      await tester.ensureVisible(find.byKey(HomeScreen.motivationKey));
      await tester.pump();
      final Rect visibleQuote = tester.getRect(
        find.byKey(HomeScreen.motivationKey),
      );
      final Rect nav = tester.getRect(find.byType(LingoFloatingBottomNav));
      expect(visibleQuote.top, greaterThanOrEqualTo(0), reason: '$size');
      expect(
        visibleQuote.bottom,
        lessThanOrEqualTo(size.height),
        reason: '$size',
      );
      expect(visibleQuote.bottom, lessThan(nav.top), reason: '$size');
      expect(
        nav.top - visibleQuote.bottom,
        greaterThanOrEqualTo(12),
        reason: '$size',
      );
      for (final Rect card in <Rect>[
        alphabet,
        words,
        phrases,
        quiz,
        wrong,
        watch,
      ]) {
        final double aspect = card.width / card.height;
        expect(aspect, greaterThan(0.82), reason: '$size $aspect');
        expect(aspect, lessThan(1.18), reason: '$size $aspect');
        expect(card.width, closeTo(alphabet.width, 1), reason: '$size');
        expect(card.height, closeTo(alphabet.height, 1), reason: '$size');
      }
      expect(alphabet.top, closeTo(words.top, 1), reason: '$size');
      expect(phrases.top, closeTo(quiz.top, 1), reason: '$size');
      expect(wrong.top, closeTo(watch.top, 1), reason: '$size');
      expect(phrases.top, greaterThan(alphabet.bottom), reason: '$size');
      expect(wrong.top, greaterThan(phrases.bottom), reason: '$size');
      final Rect alphabetArt = tester.getRect(
        find.descendant(
          of: find.byKey(HomeScreen.alphabetKey),
          matching: find.byType(HomeArtwork),
        ),
      );
      final Rect alphabetLabel = tester.getRect(
        find.descendant(
          of: find.byKey(HomeScreen.alphabetKey),
          matching: find.text('Alphabet'),
        ),
      );
      expect(
        alphabetArt.height,
        greaterThan(alphabet.height * 0.72),
        reason: '$size',
      );
      expect(
        alphabetLabel.bottom,
        lessThanOrEqualTo(alphabet.bottom + 1),
        reason: '$size',
      );
      expect(alphabetLabel.top, greaterThan(alphabet.top), reason: '$size');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Home titles follow every learner language', (
    WidgetTester tester,
  ) async {
    HomeMotivationQuotes.now = () => DateTime(2026, 4, 2);
    for (final String code in LearnerLanguages.orderedCodes) {
      await _pumpApp(tester, const Size(390, 844), languageCode: code);
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.alphabetKey),
          matching: find.text(
            UiStrings.resolve(UiKeys.navAlphabet, languageCode: code),
          ),
        ),
        findsOneWidget,
        reason: code,
      );
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.wordsKey),
          matching: find.text(
            UiStrings.resolve(UiKeys.navWords, languageCode: code),
          ),
        ),
        findsOneWidget,
        reason: code,
      );
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.phrasesKey),
          matching: find.text(
            UiStrings.resolve(UiKeys.navPhrases, languageCode: code),
          ),
        ),
        findsOneWidget,
        reason: code,
      );
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.quizKey),
          matching: find.text(
            UiStrings.resolve(UiKeys.quizTitle, languageCode: code),
          ),
        ),
        findsOneWidget,
        reason: code,
      );
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.wrongAnswersKey),
          matching: find.text(
            UiStrings.resolve(UiKeys.wrongAnswersTitle, languageCode: code),
          ),
        ),
        findsOneWidget,
        reason: code,
      );
      expect(
        find.descendant(
          of: find.byKey(HomeScreen.appleWatchKey),
          matching: find.text(
            UiStrings.resolve(UiKeys.watchTitle, languageCode: code),
          ),
        ),
        findsOneWidget,
        reason: code,
      );
      expect(
        find.text(HomeMotivationQuotes.todayFor(code).text),
        findsOneWidget,
        reason: code,
      );
      if (LearnerLanguages.isRtl(code)) {
        expect(
          Directionality.of(tester.element(find.byType(HomeScreen))),
          TextDirection.rtl,
          reason: code,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Home Quiz Words lists meaning modes for Turkish learners', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844), languageCode: 'tr');

    await tester.tap(find.byKey(HomeScreen.quizKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(HomeQuizSourceScreen.wordsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await _expectQuizLaunch(tester, QuizContentKind.word);
    expect(find.byKey(QuizTypePickerScreen.mixedKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('quiz-type-multipleChoice')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz-type-reverseMultipleChoice')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz-type-typing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('quiz-type-buildSequence')),
      findsNothing,
    );
    expect(find.text('Kelimeyi oluştur'), findsNothing);
  });
}

Future<void> _expectQuizLaunch(
  WidgetTester tester,
  QuizContentKind kind,
) async {
  expect(find.text('Quiz unavailable'), findsNothing);
  expect(find.byType(QuizTypePickerScreen), findsOneWidget);
  final QuizTypePickerScreen picker = tester.widget<QuizTypePickerScreen>(
    find.byType(QuizTypePickerScreen),
  );
  expect(picker.request.items, isNotEmpty);
  expect(
    picker.request.items.every((QuizReadyItem item) => item.kind == kind),
    isTrue,
  );
  expect(
    picker.request.items.any(
      (QuizReadyItem item) => item.kind == QuizContentKind.alphabet,
    ),
    isFalse,
  );
}

Finder _navTab(String label) {
  return find.byWidgetPredicate(
    (Widget widget) => widget is LingoBottomNavItem && widget.label == label,
  );
}

Future<void> _popRoute(WidgetTester tester) async {
  final Iterable<NavigatorState> navigators = tester.stateList<NavigatorState>(
    find.byType(Navigator),
  );
  for (final NavigatorState navigator in navigators) {
    if (navigator.canPop()) {
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  fail('expected a nested route to pop');
}

Future<void> _pumpApp(
  WidgetTester tester,
  Size size, {
  String languageCode = 'en',
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
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
