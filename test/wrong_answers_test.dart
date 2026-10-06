import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/domain/wrong_answers.dart';
import 'package:lingo_core/features/quiz/wrong_answers_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
  });

  test(
    'quiz sync stores words, phrases, and alphabet without duplicates',
    () async {
      await WrongAnswersSync.recordWrong(
        const QuizWrongAnswer(
          contentId: 'word.basics.hello',
          kind: QuizContentKind.word,
          quizType: QuizType.multipleChoice,
          targetAnswer: 'Hello',
          learnerCue: 'Merhaba',
          submittedText: 'nope',
        ),
      );
      await WrongAnswersSync.recordWrong(
        const QuizWrongAnswer(
          contentId: 'word.basics.hello',
          kind: QuizContentKind.word,
          quizType: QuizType.typing,
          targetAnswer: 'Hello',
          learnerCue: 'Merhaba',
          submittedText: 'still nope',
        ),
      );
      await WrongAnswersSync.recordWrong(
        const QuizWrongAnswer(
          contentId: 'phrase.greetings.hello',
          kind: QuizContentKind.phrase,
          quizType: QuizType.multipleChoice,
          targetAnswer: 'Hello.',
          learnerCue: 'Merhaba.',
          submittedText: 'nope',
        ),
      );
      await WrongAnswersSync.recordWrong(
        const QuizWrongAnswer(
          contentId: 'letter.a',
          kind: QuizContentKind.alphabet,
          quizType: QuizType.reverseMultipleChoice,
          targetAnswer: 'A',
          learnerCue: 'apple',
          submittedText: 'B',
        ),
      );

      final List<WrongAnswerRecord> stored = UserPreferences.instance
          .getWrongAnswers();
      expect(stored.map((WrongAnswerRecord item) => item.contentId), <String>[
        'word.basics.hello',
        'phrase.greetings.hello',
        'letter.a',
      ]);
      expect(stored.first.wrongCount, 2);
    },
  );

  test('a later correct answer removes only that stored miss', () async {
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'word.basics.hello',
      kind: QuizContentKind.word,
    );
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'word.basics.goodbye',
      kind: QuizContentKind.word,
    );
    await WrongAnswersSync.recordCorrect(
      const QuizCorrectAnswer(
        contentId: 'word.basics.yes',
        kind: QuizContentKind.word,
        quizType: QuizType.multipleChoice,
      ),
    );
    expect(UserPreferences.instance.getWrongAnswerCount(), 2);

    await WrongAnswersSync.recordCorrect(
      const QuizCorrectAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
        quizType: QuizType.multipleChoice,
      ),
    );
    expect(
      UserPreferences.instance.getWrongAnswers().single.contentId,
      'word.basics.goodbye',
    );
  });

  test(
    'resolved copy follows translation language without duplicating IDs',
    () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      await UserPreferences.instance.recordWrongAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
      );

      final List<ResolvedWrongAnswer> english = resolveWrongAnswers(
        UserPreferences.instance.getWrongAnswers(),
        repo,
        languageCode: 'en',
      );
      final List<ResolvedWrongAnswer> turkish = resolveWrongAnswers(
        UserPreferences.instance.getWrongAnswers(),
        repo,
        languageCode: 'tr',
      );

      expect(english, hasLength(1));
      expect(turkish, hasLength(1));
      expect(english.single.contentId, 'word.basics.hello');
      expect(turkish.single.contentId, 'word.basics.hello');
      expect(english.single.targetText, turkish.single.targetText);
      expect(
        english.single.learnerCue,
        isNot(equals(turkish.single.learnerCue)),
      );
      expect(turkish.single.learnerCue, 'Merhaba');
    },
  );

  test('stale IDs are ignored and pruned without throwing', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'word.basics.hello',
      kind: QuizContentKind.word,
    );
    await UserPreferences.instance.recordWrongAnswer(
      contentId: 'missing.retired',
      kind: QuizContentKind.word,
    );

    final List<ResolvedWrongAnswer> resolved = resolveWrongAnswers(
      UserPreferences.instance.getWrongAnswers(),
      repo,
    );
    expect(resolved.single.contentId, 'word.basics.hello');

    await UserPreferences.instance.pruneUnknownWrongAnswers(
      knownWrongAnswerIds(repo),
    );
    expect(
      UserPreferences.instance.getWrongAnswers().single.contentId,
      'word.basics.hello',
    );
  });

  test('review items only include currently saved quiz IDs', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
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

    final List<QuizReadyItem> review = <QuizReadyItem>[
      for (final ResolvedWrongAnswer item in resolveWrongAnswers(
        UserPreferences.instance.getWrongAnswers(),
        repo,
      ))
        if (item.quizItem != null) item.quizItem!,
    ];
    expect(review.map((QuizReadyItem item) => item.id), <String>[
      'word.basics.hello',
      'phrase.greetings.hello',
      'letter.a',
    ]);
    expect(review[0].kind, QuizContentKind.word);
    expect(review[1].kind, QuizContentKind.phrase);
    expect(review[2].kind, QuizContentKind.alphabet);
  });
}
