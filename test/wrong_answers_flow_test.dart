import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/home/wrong_answers_screen.dart';
import 'package:lingo_core/features/quiz/quiz_request.dart';
import 'package:lingo_core/features/quiz/quiz_screen.dart';
import 'package:lingo_core/features/quiz/quiz_type_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UserPreferences.resetForTest();
    FeedbackService.instance = FeedbackService(
      hapticsEnabled: false,
      soundEnabled: false,
    );
  });

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
  });

  testWidgets('Home count updates from stored Wrong Answers', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    expect(
      find.byKey(const ValueKey<String>('home-wrong-answers-count')),
      findsNothing,
    );

    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'word.basics.hello',
      kind: QuizContentKind.word,
    );
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'phrase.greetings.hello',
      kind: QuizContentKind.phrase,
    );
    await tester.pump();

    expect(find.byKey(HomeScreen.wrongAnswersKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home-wrong-answers-count')),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);

    await UserPreferences.instance.recordCorrectAnswer('word.basics.hello');
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Wrong Answers screen groups items and launches review Quiz', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'word.basics.hello',
      kind: QuizContentKind.word,
    );
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'word.basics.hello',
      kind: QuizContentKind.word,
    );
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'phrase.greetings.hello',
      kind: QuizContentKind.phrase,
    );
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'letter.a',
      kind: QuizContentKind.alphabet,
    );

    await tester.tap(find.byKey(HomeScreen.wrongAnswersKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WrongAnswersScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('wrong-answer-word.basics.hello')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('wrong-answer-phrase.greetings.hello')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('wrong-answer-letter.a')),
      findsOneWidget,
    );
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Practice mistakes'), findsOneWidget);

    await tester.ensureVisible(find.byKey(WrongAnswersScreen.practiceKey));
    await tester.tap(find.byKey(WrongAnswersScreen.practiceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final QuizLaunchRequest request = _reviewRequest(tester);
    expect(request.items.map((QuizReadyItem item) => item.id), <String>[
      'word.basics.hello',
      'phrase.greetings.hello',
      'letter.a',
    ]);
  });

  testWidgets('empty Wrong Answers stays positive', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(HomeScreen.wrongAnswersKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('No mistakes to review'), findsOneWidget);
    expect(find.text('Practice mistakes'), findsNothing);
  });

  testWidgets('switching translation language keeps IDs and updates cues', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'word.basics.hello',
      kind: QuizContentKind.word,
    );
    await tester.tap(find.byKey(HomeScreen.wrongAnswersKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await UserPreferences.instance.setSelectedTranslationLanguage('tr');
    await tester.pump();
    expect(find.text('Merhaba'), findsOneWidget);
    expect(
      UserPreferences.instance.getWrongAnswers().single.contentId,
      'word.basics.hello',
    );
  });
}

QuizLaunchRequest _reviewRequest(WidgetTester tester) {
  final Finder picker = find.byType(QuizTypePickerScreen);
  if (picker.evaluate().isNotEmpty) {
    return tester.widget<QuizTypePickerScreen>(picker).request;
  }
  final Finder quiz = find.byType(QuizScreen);
  if (quiz.evaluate().isNotEmpty) {
    return tester.widget<QuizScreen>(quiz).request;
  }
  fail('expected a Quiz type picker or Quiz screen');
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  UserPreferences.resetForTest();
  await UserPreferences.instance.setSelectedTranslationLanguage('en');
  FeedbackService.instance = FeedbackService(
    hapticsEnabled: false,
    soundEnabled: false,
  );
  final LocalContentRepository? repo = await tester.runAsync(
    LocalContentRepository.load,
  );
  if (repo == null) {
    fail('content pack was not loaded');
  }
  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await tester.pump();
}
