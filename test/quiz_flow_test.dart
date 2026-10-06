import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_buttons.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_engine.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/features/quiz/quiz_request.dart';
import 'package:lingo_core/features/quiz/quiz_screen.dart';
import 'package:lingo_core/features/quiz/quiz_type_picker.dart';
import 'package:lingo_core/features/quiz/quiz_widgets.dart';

void main() {
  tearDown(FeedbackService.resetInstance);

  testWidgets('repeated option taps keep the first submitted answer', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word('word.cat', 'Cat', 'A small animal'),
      _word('word.dog', 'Dog', 'A loyal pet'),
      _word('word.sun', 'Sun', 'Daylight star'),
      _word('word.moon', 'Moon', 'Night light'),
    ];
    final QuizEngine engine = QuizEngine(random: Random(31));
    final QuizStartResult start = engine.start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      translationLanguageCode: 'en',
      allowedTypes: const <QuizType>[QuizType.multipleChoice],
      questionCount: 1,
      title: 'Animals',
    );
    final QuizSession? session = start.session;
    if (session == null) {
      fail('quiz should start, reason=${start.reason}');
    }
    final QuizQuestion question = session.questions.first;
    final QuizOption? correct = question.correctOption;
    QuizOption? wrong;
    for (final QuizOption option in question.options) {
      if (!option.isCorrect) {
        wrong = option;
        break;
      }
    }
    if (correct == null || wrong == null) {
      fail('multiple-choice question needs a correct option and a distractor');
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: QuizScreen(
          start: start,
          request: QuizLaunchRequest(
            title: 'Animals',
            items: items,
            optionPool: items,
            scriptFamily: ScriptFamily.latin,
            textDirection: ContentTextDirection.ltr,
            translationLanguageCode: 'en',
            allowedTypes: const <QuizType>[QuizType.multipleChoice],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(wrong.text));
    await tester.tap(find.text(correct.text));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Correct answer: ${question.expectedAnswer}'),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('wrong and correct answers play quiz SFX', (
    WidgetTester tester,
  ) async {
    final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
    final _RecordingHapticDriver haptics = _RecordingHapticDriver();
    FeedbackService.instance = FeedbackService(
      haptics: HapticService(driver: haptics),
      sound: SoundService(
        player: sounds,
        probe: const AlwaysPresentSoundAssetProbe(),
      ),
    );

    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word('word.cat', 'Cat', 'A small animal'),
      _word('word.dog', 'Dog', 'A loyal pet'),
      _word('word.sun', 'Sun', 'Daylight star'),
      _word('word.moon', 'Moon', 'Night light'),
    ];
    final QuizEngine engine = QuizEngine(random: Random(31));
    final QuizStartResult start = engine.start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      translationLanguageCode: 'en',
      allowedTypes: const <QuizType>[QuizType.multipleChoice],
      questionCount: 1,
      title: 'Animals',
    );
    final QuizSession? session = start.session;
    if (session == null) {
      fail('quiz should start, reason=${start.reason}');
    }
    final QuizQuestion question = session.questions.first;
    QuizOption? wrong;
    for (final QuizOption option in question.options) {
      if (!option.isCorrect) {
        wrong = option;
        break;
      }
    }
    if (wrong == null) {
      fail('multiple-choice question needs a distractor');
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: QuizScreen(
          start: start,
          request: QuizLaunchRequest(
            title: 'Animals',
            items: items,
            optionPool: items,
            scriptFamily: ScriptFamily.latin,
            textDirection: ContentTextDirection.ltr,
            translationLanguageCode: 'en',
            allowedTypes: const <QuizType>[QuizType.multipleChoice],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(wrong.text));
    await tester.pump();

    expect(sounds.cues, <SoundCue>[SoundCue.wrong]);
    expect(haptics.played, isNotEmpty);
  });

  testWidgets('correct option shows a correct state and plays success SFX', (
    WidgetTester tester,
  ) async {
    final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
    final _RecordingHapticDriver haptics = _RecordingHapticDriver();
    FeedbackService.instance = FeedbackService(
      haptics: HapticService(driver: haptics),
      sound: SoundService(
        player: sounds,
        probe: const AlwaysPresentSoundAssetProbe(),
      ),
    );

    final _PumpedQuiz pumped = await _pumpStartedQuiz(
      tester,
      type: QuizType.multipleChoice,
      questionCount: 1,
    );
    final QuizOption? correct = pumped.question.correctOption;
    if (correct == null) {
      fail('multiple-choice question needs a correct option');
    }

    await tester.tap(find.text(correct.text));
    await tester.pump();

    expect(find.byKey(const Key('quiz-outcome-correct')), findsOneWidget);
    expect(find.byKey(const Key('quiz-outcome-wrong')), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Quiz complete'), findsNothing);
    expect(sounds.cues, <SoundCue>[SoundCue.correct]);
    expect(haptics.played, isNotEmpty);

    await tester.tap(find.text(correct.text));
    await tester.pump();
    expect(sounds.cues, <SoundCue>[SoundCue.correct]);
  });

  testWidgets('Continue is required before the next question', (
    WidgetTester tester,
  ) async {
    final _PumpedQuiz pumped = await _pumpStartedQuiz(
      tester,
      type: QuizType.multipleChoice,
      questionCount: 2,
    );
    QuizOption? wrong;
    for (final QuizOption option in pumped.question.options) {
      if (!option.isCorrect) {
        wrong = option;
        break;
      }
    }
    if (wrong == null) {
      fail('multiple-choice question needs a distractor');
    }

    await tester.tap(find.text(wrong.text));
    await tester.pump();
    expect(find.byKey(const Key('quiz-outcome-wrong')), findsOneWidget);
    expect(find.byKey(const Key('quiz-option-wrong-selected')), findsOneWidget);
    expect(find.byKey(const Key('quiz-option-correct')), findsOneWidget);
    expect(find.text(pumped.question.prompt), findsWidgets);

    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Quiz complete'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byKey(const Key('quiz-outcome-wrong')), findsNothing);
  });

  testWidgets('type answer uses the learner cue and reveals the target', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = _englishTaught();
    final QuizEngine engine = QuizEngine(random: Random(41));
    final QuizStartResult start = engine.start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      translationLanguageCode: 'tr',
      allowedTypes: const <QuizType>[QuizType.typing],
      questionCount: 1,
      title: 'Words',
    );
    final QuizSession session = _sessionOf(start);
    final QuizQuestion question = session.questions.first;
    final QuizReadyItem item = items.firstWhere(
      (QuizReadyItem row) => row.id == question.contentId,
    );

    await tester.pumpWidget(
      _quizApp(
        start: start,
        items: items,
        type: QuizType.typing,
        language: 'tr',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(item.answersByLanguage['tr']!), findsOneWidget);
    expect(question.expectedAnswer, item.prompt);

    await tester.enterText(
      find.byType(TextField),
      item.answersByLanguage['tr']!,
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    if (find.byKey(const Key('quiz-outcome-wrong')).evaluate().isEmpty) {
      await tester.tap(find.byType(LingoPrimaryButton));
      await tester.pump();
    }

    expect(find.byKey(const Key('quiz-outcome-wrong')), findsOneWidget);
    expect(find.text('Doğru cevap: ${item.prompt}'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('build phrase checks tokens and keeps the first grade', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word(
        'phrase.hello',
        'Hello there',
        'A greeting',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.thanks',
        'Thank you',
        'Gratitude',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.bye',
        'Good night',
        'A farewell',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.please',
        'Please help',
        'A request',
        kind: QuizContentKind.phrase,
      ),
    ];
    final QuizEngine engine = QuizEngine(random: Random(42));
    final QuizStartResult start = engine.start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      translationLanguageCode: 'en',
      allowedTypes: const <QuizType>[QuizType.buildSequence],
      questionCount: 1,
      title: 'Phrases',
    );
    final QuizQuestion question = _sessionOf(start).questions.first;

    await tester.pumpWidget(
      _quizApp(start: start, items: items, type: QuizType.buildSequence),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (final String token in question.expectedTokens.reversed) {
      final Finder chip = find.text(token);
      expect(chip, findsWidgets);
      await tester.tap(chip.first);
      await tester.pump();
    }
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(find.byKey(const Key('quiz-outcome-wrong')), findsOneWidget);
    expect(
      find.text('Correct answer: ${question.expectedAnswer}'),
      findsOneWidget,
    );

    await tester.tap(find.text(question.expectedTokens.first));
    await tester.pump();
    expect(find.byKey(const Key('quiz-outcome-wrong')), findsOneWidget);
  });

  testWidgets('RTL typing keeps the target answer visible after a miss', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word('word.book', 'كتاب', 'book'),
      _word('word.house', 'بيت', 'house'),
      _word('word.water', 'ماء', 'water'),
      _word('word.sun', 'شمس', 'sun'),
    ];
    final QuizEngine engine = QuizEngine(random: Random(43));
    final QuizStartResult start = engine.start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.arabic,
      textDirection: ContentTextDirection.rtl,
      translationLanguageCode: 'en',
      allowedTypes: const <QuizType>[QuizType.typing],
      questionCount: 1,
      title: 'Arabic',
    );
    final QuizQuestion question = _sessionOf(start).questions.first;

    await tester.pumpWidget(
      _quizApp(
        start: start,
        items: items,
        type: QuizType.typing,
        scriptFamily: ScriptFamily.arabic,
        textDirection: ContentTextDirection.rtl,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(question.prompt), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    if (find.byKey(const Key('quiz-outcome-wrong')).evaluate().isEmpty) {
      await tester.tap(find.byType(LingoPrimaryButton));
      await tester.pump();
    }

    expect(find.byKey(const Key('quiz-outcome-wrong')), findsOneWidget);
    expect(
      find.text('Correct answer: ${question.expectedAnswer}'),
      findsOneWidget,
    );
  });

  testWidgets('quiz picker uses localized titles without extra headings', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = _animalWords();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: QuizTypePickerScreen(
          request: QuizLaunchRequest(
            title: 'Animals',
            items: items,
            optionPool: items,
            scriptFamily: ScriptFamily.latin,
            textDirection: ContentTextDirection.ltr,
            translationLanguageCode: 'en',
          ),
          types: QuizType.values,
          onStart: (BuildContext context, QuizLaunchRequest request) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Quiz'), findsNothing);
    expect(find.text('Choose quiz'), findsOneWidget);
    expect(find.byKey(QuizTopBar.backKey), findsOneWidget);
    expect(find.text('Mixed'), findsOneWidget);
    expect(find.text('Multiple choice'), findsOneWidget);
    expect(find.text('Reverse multiple choice'), findsOneWidget);
    expect(find.text('Build the word'), findsNothing);
    expect(find.text('Build the phrase'), findsNothing);
    expect(find.text('Type the answer'), findsOneWidget);
    expect(
      find.text('See a word or phrase and pick the meaning.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phrase picker includes build phrase and omits build word', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word(
        'phrase.hello',
        'Hello there',
        'A greeting',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.thanks',
        'Thank you',
        'Gratitude',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.bye',
        'Good night',
        'A farewell',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.please',
        'Please help',
        'A request',
        kind: QuizContentKind.phrase,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: QuizTypePickerScreen(
          request: QuizLaunchRequest(
            title: 'Phrases',
            items: items,
            optionPool: items,
            scriptFamily: ScriptFamily.latin,
            textDirection: ContentTextDirection.ltr,
            translationLanguageCode: 'en',
          ),
          types: QuizType.values,
          onStart: (BuildContext context, QuizLaunchRequest request) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mixed'), findsOneWidget);
    expect(find.text('Build the phrase'), findsOneWidget);
    expect(find.text('Build the word'), findsNothing);
    expect(find.text('Type the answer'), findsOneWidget);
    expect(find.byKey(QuizTypePickerScreen.mixedKey), findsOneWidget);
  });

  testWidgets('results screen keeps score and actions only', (
    WidgetTester tester,
  ) async {
    final _PumpedQuiz pumped = await _pumpStartedQuiz(
      tester,
      type: QuizType.multipleChoice,
      questionCount: 1,
    );
    final QuizOption? correct = pumped.question.correctOption;
    if (correct == null) {
      fail('multiple-choice question needs a correct option');
    }
    await tester.tap(find.text(correct.text));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Quiz complete'), findsOneWidget);
    expect(find.text('1 / 1 correct'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Incorrect'), findsOneWidget);
    expect(find.textContaining('→'), findsNothing);
  });

  testWidgets('build mode hides the Tokens heading', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word(
        'phrase.hello',
        'Hello there',
        'A greeting',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.thanks',
        'Thank you',
        'Gratitude',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.bye',
        'Good night',
        'A farewell',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.please',
        'Please help',
        'A request',
        kind: QuizContentKind.phrase,
      ),
    ];
    final QuizStartResult start = QuizEngine(random: Random(42)).start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      translationLanguageCode: 'en',
      allowedTypes: const <QuizType>[QuizType.buildSequence],
      questionCount: 1,
      title: 'Phrases',
    );
    await tester.pumpWidget(
      _quizApp(start: start, items: items, type: QuizType.buildSequence),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Tokens'), findsNothing);
    expect(find.text('Your answer'), findsOneWidget);
  });

  testWidgets('quiz layouts stay inside small and large iPhones', (
    WidgetTester tester,
  ) async {
    for (final Size size in <Size>[
      const Size(375, 667),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = Size(size.width * 2, size.height * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _PumpedQuiz pumped = await _pumpStartedQuiz(
        tester,
        type: QuizType.multipleChoice,
        questionCount: 1,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byKey(QuizTopBar.backKey), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Quiz')),
        findsNothing,
      );
      expect(find.text(pumped.question.prompt), findsWidgets);
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      final Rect continueRect = tester.getRect(find.text('Continue'));
      expect(continueRect.height, greaterThan(0));
      expect(continueRect.bottom, lessThanOrEqualTo(size.height + 1));
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('build token taps play selection SFX', (
    WidgetTester tester,
  ) async {
    final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
    final _RecordingHapticDriver haptics = _RecordingHapticDriver();
    FeedbackService.instance = FeedbackService(
      haptics: HapticService(driver: haptics),
      sound: SoundService(
        player: sounds,
        probe: const AlwaysPresentSoundAssetProbe(),
      ),
    );

    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word(
        'phrase.hello',
        'Hello there',
        'A greeting',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.thanks',
        'Thank you',
        'Gratitude',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.bye',
        'Good night',
        'A farewell',
        kind: QuizContentKind.phrase,
      ),
      _word(
        'phrase.please',
        'Please help',
        'A request',
        kind: QuizContentKind.phrase,
      ),
    ];
    final QuizStartResult start = QuizEngine(random: Random(42)).start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      translationLanguageCode: 'en',
      allowedTypes: const <QuizType>[QuizType.buildSequence],
      questionCount: 1,
      title: 'Phrases',
    );
    final QuizQuestion question = _sessionOf(start).questions.first;

    await tester.pumpWidget(
      _quizApp(start: start, items: items, type: QuizType.buildSequence),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(question.expectedTokens.first).first);
    await tester.pump();

    expect(sounds.cues, <SoundCue>[SoundCue.selection]);
    expect(haptics.played, isNotEmpty);
    expect(find.byKey(const Key('quiz-outcome-correct')), findsNothing);
  });

  testWidgets('wrong answers emit a structured hook without advancing', (
    WidgetTester tester,
  ) async {
    final List<QuizWrongAnswer> captured = <QuizWrongAnswer>[];
    final _PumpedQuiz pumped = await _pumpStartedQuiz(
      tester,
      type: QuizType.multipleChoice,
      questionCount: 2,
      onWrongAnswer: captured.add,
    );
    QuizOption? wrong;
    for (final QuizOption option in pumped.question.options) {
      if (!option.isCorrect) {
        wrong = option;
        break;
      }
    }
    if (wrong == null) {
      fail('multiple-choice question needs a distractor');
    }

    await tester.tap(find.text(wrong.text));
    await tester.pump();

    expect(captured, hasLength(1));
    expect(captured.single.contentId, pumped.question.contentId);
    expect(captured.single.kind, pumped.question.kind);
    expect(captured.single.quizType, QuizType.multipleChoice);
    expect(captured.single.targetAnswer, pumped.question.targetText);
    expect(captured.single.learnerCue, pumped.question.learnerCue);
    expect(find.byKey(const Key('quiz-outcome-wrong')), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Quiz complete'), findsNothing);
  });

  testWidgets('correct answers emit a structured hook without advancing', (
    WidgetTester tester,
  ) async {
    final List<QuizCorrectAnswer> captured = <QuizCorrectAnswer>[];
    final _PumpedQuiz pumped = await _pumpStartedQuiz(
      tester,
      type: QuizType.multipleChoice,
      questionCount: 2,
      onCorrectAnswer: captured.add,
    );
    final QuizOption? correct = pumped.question.correctOption;
    if (correct == null) {
      fail('multiple-choice question needs a correct option');
    }

    await tester.tap(find.text(correct.text));
    await tester.pump();

    expect(captured, hasLength(1));
    expect(captured.single.contentId, pumped.question.contentId);
    expect(captured.single.kind, pumped.question.kind);
    expect(captured.single.quizType, QuizType.multipleChoice);
    expect(find.byKey(const Key('quiz-outcome-correct')), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Quiz complete'), findsNothing);
  });

  testWidgets('correct answers show a success mark and stay until Continue', (
    WidgetTester tester,
  ) async {
    final _PumpedQuiz pumped = await _pumpStartedQuiz(
      tester,
      type: QuizType.multipleChoice,
      questionCount: 1,
    );
    final QuizOption? correct = pumped.question.correctOption;
    if (correct == null) {
      fail('multiple-choice question needs a correct option');
    }

    await tester.tap(find.text(correct.text));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const Key('quiz-outcome-correct')), findsOneWidget);
    expect(find.byKey(const Key('quiz-success-mark')), findsOneWidget);
    expect(find.byKey(const Key('quiz-success-burst')), findsOneWidget);
    expect(find.byKey(const Key('quiz-option-correct')), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Quiz complete'), findsNothing);
  });

  testWidgets('alphabet picker only lists recognition modes', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word('letter.a', 'A', 'apple', kind: QuizContentKind.alphabet),
      _word('letter.b', 'B', 'book', kind: QuizContentKind.alphabet),
      _word('letter.c', 'C', 'cat', kind: QuizContentKind.alphabet),
      _word('letter.d', 'D', 'dog', kind: QuizContentKind.alphabet),
    ];
    final List<QuizType> types = QuizEngine().availableTypes(
      items: items,
      optionPool: items,
      translationLanguageCode: 'en',
    );
    expect(types, isNot(contains(QuizType.buildSequence)));
    expect(types, isNot(contains(QuizType.typing)));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: QuizTypePickerScreen(
          request: QuizLaunchRequest(
            title: 'Alphabet',
            items: items,
            optionPool: items,
            scriptFamily: ScriptFamily.latin,
            textDirection: ContentTextDirection.ltr,
            translationLanguageCode: 'en',
          ),
          types: types,
          onStart: (BuildContext context, QuizLaunchRequest request) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mixed'), findsOneWidget);
    expect(find.text('Multiple choice'), findsOneWidget);
    expect(find.text('Reverse multiple choice'), findsOneWidget);
    expect(find.text('Build the word'), findsNothing);
    expect(find.text('Build the phrase'), findsNothing);
    expect(find.text('Type the answer'), findsNothing);
  });

  testWidgets('RTL picker keeps back control usable for Arabic and Persian', (
    WidgetTester tester,
  ) async {
    final List<QuizReadyItem> items = _animalWords();
    for (final TextDirection direction in <TextDirection>[
      TextDirection.rtl,
      TextDirection.ltr,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (BuildContext context, Widget? child) {
            return Directionality(
              textDirection: direction,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: QuizTypePickerScreen(
            request: QuizLaunchRequest(
              title: 'Animals',
              items: items,
              optionPool: items,
              scriptFamily: ScriptFamily.latin,
              textDirection: direction == TextDirection.rtl
                  ? ContentTextDirection.rtl
                  : ContentTextDirection.ltr,
              translationLanguageCode: direction == TextDirection.rtl
                  ? 'ar'
                  : 'en',
            ),
            types: const <QuizType>[
              QuizType.multipleChoice,
              QuizType.reverseMultipleChoice,
              QuizType.typing,
            ],
            onStart: (BuildContext context, QuizLaunchRequest request) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(QuizTopBar.backKey), findsOneWidget);
      expect(find.text('Build the word'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('long German and Russian options wrap without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<QuizReadyItem> items = <QuizReadyItem>[
      _word(
        'word.one',
        'Sehenswürdigkeit',
        'Ein besonders bemerkenswerter Ort zum Besichtigen',
      ),
      _word(
        'word.two',
        'Geschwindigkeitsbegrenzung',
        'Правило ограничения скорости на дороге',
      ),
      _word(
        'word.three',
        'Freundschaft',
        'A warm and lasting relationship between people',
      ),
      _word(
        'word.four',
        'Verantwortung',
        'Ответственность за собственные решения и поступки',
      ),
    ];
    final QuizStartResult start = QuizEngine(random: Random(51)).start(
      items: items,
      optionPool: items,
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      translationLanguageCode: 'en',
      allowedTypes: const <QuizType>[QuizType.multipleChoice],
      questionCount: 1,
      title: 'Words',
    );
    await tester.pumpWidget(
      _quizApp(start: start, items: items, type: QuizType.multipleChoice),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(QuizTopBar.backKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final QuizOption option in _sessionOf(start).questions.first.options) {
      expect(find.text(option.text), findsOneWidget);
    }
  });

  testWidgets('type-answer field stays above Check when the keyboard is open', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _PumpedQuiz pumped = await _pumpStartedQuiz(
      tester,
      type: QuizType.typing,
      questionCount: 1,
    );
    expect(pumped.question.type, QuizType.typing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Rect field = tester.getRect(find.byType(TextField));
    final Rect check = tester.getRect(find.text('Check'));
    expect(field.bottom, lessThanOrEqualTo(check.top + 1));
    expect(check.bottom, lessThanOrEqualTo(667 + 1));
    expect(find.byKey(QuizTopBar.backKey), findsOneWidget);
  });
}

QuizReadyItem _word(
  String id,
  String prompt,
  String translation, {
  QuizContentKind kind = QuizContentKind.word,
}) {
  return QuizReadyItem(
    id: id,
    kind: kind,
    prompt: prompt,
    answersByLanguage: <String, String>{'en': translation},
  );
}

List<QuizReadyItem> _englishTaught() {
  return <QuizReadyItem>[
    _bilingual('word.hello', 'Hello', 'Merhaba'),
    _bilingual('word.thanks', 'Thank you', 'Teşekkür ederim'),
    _bilingual('word.cat', 'Cat', 'Kedi'),
    _bilingual('word.dog', 'Dog', 'Köpek'),
  ];
}

QuizReadyItem _bilingual(String id, String target, String turkish) {
  return QuizReadyItem(
    id: id,
    kind: QuizContentKind.word,
    prompt: target,
    answersByLanguage: <String, String>{'en': target, 'tr': turkish},
  );
}

List<QuizReadyItem> _animalWords() {
  return <QuizReadyItem>[
    _word('word.cat', 'Cat', 'A small animal'),
    _word('word.dog', 'Dog', 'A loyal pet'),
    _word('word.sun', 'Sun', 'Daylight star'),
    _word('word.moon', 'Moon', 'Night light'),
  ];
}

QuizSession _sessionOf(QuizStartResult start) {
  final QuizSession? session = start.session;
  if (session == null) {
    fail('quiz should start, reason=${start.reason}');
  }
  return session;
}

Widget _quizApp({
  required QuizStartResult start,
  required List<QuizReadyItem> items,
  required QuizType type,
  String language = 'en',
  ScriptFamily scriptFamily = ScriptFamily.latin,
  ContentTextDirection textDirection = ContentTextDirection.ltr,
  String title = 'Quiz',
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: QuizScreen(
      start: start,
      request: QuizLaunchRequest(
        title: title,
        items: items,
        optionPool: items,
        scriptFamily: scriptFamily,
        textDirection: textDirection,
        translationLanguageCode: language,
        allowedTypes: <QuizType>[type],
      ),
    ),
  );
}

final class _PumpedQuiz {
  const _PumpedQuiz({required this.question});

  final QuizQuestion question;
}

Future<_PumpedQuiz> _pumpStartedQuiz(
  WidgetTester tester, {
  required QuizType type,
  int questionCount = 1,
  ValueChanged<QuizWrongAnswer>? onWrongAnswer,
  ValueChanged<QuizCorrectAnswer>? onCorrectAnswer,
}) async {
  final List<QuizReadyItem> items = _animalWords();
  final QuizStartResult start = QuizEngine(random: Random(31)).start(
    items: items,
    optionPool: items,
    scriptFamily: ScriptFamily.latin,
    textDirection: ContentTextDirection.ltr,
    translationLanguageCode: 'en',
    allowedTypes: <QuizType>[type],
    questionCount: questionCount,
    title: 'Animals',
  );
  final QuizQuestion question = _sessionOf(start).questions.first;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: QuizScreen(
        start: start,
        request: QuizLaunchRequest(
          title: 'Animals',
          items: items,
          optionPool: items,
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: <QuizType>[type],
        ),
        onWrongAnswer: onWrongAnswer,
        onCorrectAnswer: onCorrectAnswer,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return _PumpedQuiz(question: question);
}

final class _RecordingSoundPlayer implements SoundPlayer {
  final List<SoundCue> cues = <SoundCue>[];

  @override
  Future<void> play(SoundCue cue, String assetPath) async {
    cues.add(cue);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

final class _RecordingHapticDriver implements HapticDriver {
  final List<HapticLevel> played = <HapticLevel>[];

  @override
  Future<void> play(HapticLevel level) async {
    played.add(level);
  }
}
