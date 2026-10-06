import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_engine.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/domain/quiz_text.dart';

void main() {
  group('question generation', () {
    test('builds unique-content questions from mixed sources', () {
      final QuizEngine engine = QuizEngine(random: Random(4));
      final QuizStartResult start = engine.start(
        items: _mixedPool(),
        optionPool: _mixedPool(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        questionCount: 20,
        sessionId: 'mixed',
      );

      final QuizSession session = _ready(start);
      expect(session.questions, isNotEmpty);
      expect(session.questions.length, lessThanOrEqualTo(_mixedPool().length));
      final Set<String> ids = session.questions
          .map((QuizQuestion question) => question.contentId)
          .toSet();
      expect(ids.length, session.questions.length);
      expect(
        session.questions.map((QuizQuestion question) => question.kind).toSet(),
        containsAll(<QuizContentKind>[
          QuizContentKind.alphabet,
          QuizContentKind.word,
          QuizContentKind.phrase,
        ]),
      );
    });

    test('can force each supported quiz type', () {
      for (final QuizType type in quizTypesForKind(QuizContentKind.word)) {
        final QuizEngine engine = QuizEngine(random: Random(11));
        final QuizStartResult start = engine.start(
          items: _latinWords(),
          optionPool: _latinWords(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: <QuizType>[type],
          questionCount: 4,
        );
        final QuizSession session = _ready(start);
        expect(
          session.questions.every(
            (QuizQuestion question) => question.type == type,
          ),
          isTrue,
          reason: 'expected only $type',
        );
      }
    });

    test('does not build word-letter puzzles for Words', () {
      final QuizEngine engine = QuizEngine(random: Random(14));
      expect(
        engine.availableTypes(
          items: _latinWords(),
          optionPool: _latinWords(),
          translationLanguageCode: 'en',
        ),
        <QuizType>[
          QuizType.multipleChoice,
          QuizType.reverseMultipleChoice,
          QuizType.typing,
        ],
      );
      expect(
        quizTypesForKind(QuizContentKind.word).contains(QuizType.buildSequence),
        isFalse,
      );
      final QuizStartResult start = engine.start(
        items: _latinWords(),
        optionPool: _latinWords(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.buildSequence],
      );
      expect(start.isReady, isFalse);
    });

    test('can force build sequence for phrases', () {
      final QuizEngine engine = QuizEngine(random: Random(15));
      final QuizStartResult start = engine.start(
        items: _latinPhrases(),
        optionPool: _latinPhrases(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.buildSequence],
        questionCount: 4,
      );
      final QuizSession session = _ready(start);
      expect(session.questions, isNotEmpty);
      expect(
        session.questions.every(
          (QuizQuestion question) => question.type == QuizType.buildSequence,
        ),
        isTrue,
      );
    });
  });

  group('learner vs target language direction', () {
    test(
      'multiple choice shows the target and asks for the learner meaning',
      () {
        final List<QuizReadyItem> items = _englishTaughtWords();
        final QuizQuestion question = _singleQuestion(
          QuizEngine(random: Random(5)),
          items: items,
          type: QuizType.multipleChoice,
          translationLanguageCode: 'tr',
        );
        final QuizReadyItem item = _byId(items, question.contentId);
        expect(question.prompt, item.prompt);
        expect(question.expectedAnswer, item.answersByLanguage['tr']);
        expect(
          question.options
              .where((QuizOption option) => option.isCorrect)
              .single
              .text,
          item.answersByLanguage['tr'],
        );
        expect(
          question.options.any(
            (QuizOption option) => option.text == item.prompt,
          ),
          isFalse,
        );
      },
    );

    test(
      'reverse multiple choice shows the meaning and asks for the target',
      () {
        final List<QuizReadyItem> items = _englishTaughtWords();
        final QuizQuestion question = _singleQuestion(
          QuizEngine(random: Random(6)),
          items: items,
          type: QuizType.reverseMultipleChoice,
          translationLanguageCode: 'tr',
        );
        final QuizReadyItem item = _byId(items, question.contentId);
        expect(question.prompt, item.answersByLanguage['tr']);
        expect(question.expectedAnswer, item.prompt);
        expect(
          question.options
              .where((QuizOption option) => option.isCorrect)
              .single
              .text,
          item.prompt,
        );
      },
    );

    test('build uses the learner cue and the target-language tokens', () {
      final List<QuizReadyItem> items = _englishTaughtPhrases();
      final QuizQuestion question = _singleQuestion(
        QuizEngine(random: Random(7)),
        items: items,
        type: QuizType.buildSequence,
        translationLanguageCode: 'tr',
      );
      final QuizReadyItem item = _byId(items, question.contentId);
      expect(question.prompt, item.answersByLanguage['tr']);
      expect(question.expectedAnswer, item.prompt);
      expect(question.expectedTokens, QuizText.tokensFor(item.prompt));
    });

    test('type answer uses the learner cue and a target-language response', () {
      final QuizEngine engine = QuizEngine(random: Random(8));
      final List<QuizReadyItem> items = _englishTaughtWords();
      final QuizQuestion question = _singleQuestion(
        engine,
        items: items,
        type: QuizType.typing,
        translationLanguageCode: 'tr',
      );
      final QuizReadyItem item = _byId(items, question.contentId);
      expect(question.prompt, item.answersByLanguage['tr']);
      expect(question.expectedAnswer, item.prompt);
      expect(
        engine.isCorrect(question, QuizAnswerInput.text(item.prompt)),
        isTrue,
      );
      expect(
        engine.isCorrect(
          question,
          QuizAnswerInput.text(item.answersByLanguage['tr']!),
        ),
        isFalse,
      );
    });

    test('English learner direction still keeps the English target', () {
      final List<QuizReadyItem> items = _latinWords();
      final QuizQuestion multipleChoice = _singleQuestion(
        QuizEngine(random: Random(9)),
        items: items,
        type: QuizType.multipleChoice,
        translationLanguageCode: 'en',
      );
      final QuizReadyItem mcItem = _byId(items, multipleChoice.contentId);
      expect(multipleChoice.prompt, mcItem.prompt);
      expect(multipleChoice.expectedAnswer, mcItem.answersByLanguage['en']);
      expect(multipleChoice.targetText, mcItem.prompt);
      expect(multipleChoice.learnerCue, mcItem.answersByLanguage['en']);

      final QuizQuestion reverse = _singleQuestion(
        QuizEngine(random: Random(10)),
        items: items,
        type: QuizType.reverseMultipleChoice,
        translationLanguageCode: 'en',
      );
      final QuizReadyItem reverseItem = _byId(items, reverse.contentId);
      expect(reverse.prompt, reverseItem.answersByLanguage['en']);
      expect(reverse.expectedAnswer, reverseItem.prompt);

      final QuizQuestion typing = _singleQuestion(
        QuizEngine(random: Random(12)),
        items: items,
        type: QuizType.typing,
        translationLanguageCode: 'en',
      );
      final QuizReadyItem typingItem = _byId(items, typing.contentId);
      expect(typing.prompt, typingItem.answersByLanguage['en']);
      expect(typing.expectedAnswer, typingItem.prompt);
    });

    test('mixed questions keep target answers and learner cues', () {
      final List<QuizReadyItem> items = _englishTaughtWords();
      final QuizSession session = _ready(
        QuizEngine(random: Random(13)).start(
          items: items,
          optionPool: items,
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'tr',
          questionCount: 10,
        ),
      );
      expect(session.questions, isNotEmpty);
      for (final QuizQuestion question in session.questions) {
        final QuizReadyItem item = _byId(items, question.contentId);
        final String turkish = item.answersByLanguage['tr']!;
        switch (question.type) {
          case QuizType.multipleChoice:
            expect(question.prompt, item.prompt);
            expect(question.expectedAnswer, turkish);
          case QuizType.reverseMultipleChoice:
          case QuizType.typing:
            expect(question.prompt, turkish);
            expect(question.expectedAnswer, item.prompt);
          case QuizType.buildSequence:
            expect(question.prompt, turkish);
            expect(question.expectedTokens, QuizText.tokensFor(item.prompt));
        }
      }
    });
  });

  group('option uniqueness', () {
    test('keeps four unique multiple-choice labels', () {
      final QuizEngine engine = QuizEngine(random: Random(2));
      final QuizStartResult start = engine.start(
        items: _latinWords(),
        optionPool: _latinWords(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.multipleChoice],
        optionCount: 4,
      );
      final QuizSession session = _ready(start);
      expect(session.questions, isNotEmpty);
      for (final QuizQuestion question in session.questions) {
        expect(question.options.length, 4);
        final Set<String> keys = question.options
            .map((QuizOption option) => QuizText.uniquenessKey(option.text))
            .toSet();
        expect(keys.length, question.options.length);
        expect(
          question.options.where((QuizOption option) => option.isCorrect),
          hasLength(1),
        );
      }
    });

    test('skips duplicate translation strings as distractors', () {
      final QuizEngine engine = QuizEngine(random: Random(3));
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item('word.one', 'Uno', 'One'),
        _item('word.two', 'Dos', 'Two'),
        _item('word.twin', 'Dos-alt', 'Two'),
        _item('word.four', 'Cuatro', 'Four'),
        _item('word.five', 'Cinco', 'Five'),
      ];
      final QuizStartResult start = engine.start(
        items: items,
        optionPool: items,
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.multipleChoice],
      );
      final QuizQuestion question = _ready(start).questions.first;
      final Set<String> keys = question.options
          .map((QuizOption option) => QuizText.uniquenessKey(option.text))
          .toSet();
      expect(keys.length, question.options.length);
      expect(keys.contains('two'), isTrue);
    });

    test('treats punctuation-only differences as the same visible option', () {
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item('word.one', 'Uno', 'Hello!'),
        _item('word.two', 'Dos', 'Hello'),
        _item('word.three', 'Tres', 'Three'),
        _item('word.four', 'Cuatro', 'Four'),
      ];
      final QuizQuestion question = _singleQuestion(
        QuizEngine(random: Random(34)),
        items: items,
        type: QuizType.multipleChoice,
      );
      final Set<String> keys = question.options
          .map((QuizOption option) => QuizText.uniquenessKey(option.text))
          .toSet();
      expect(keys.length, question.options.length);
      expect(keys.contains('hello'), isTrue);
    });
  });

  group('answer validation', () {
    test(
      'accepts the correct multiple-choice option and rejects a wrong one',
      () {
        final QuizEngine engine = QuizEngine(random: Random(5));
        final QuizQuestion question = _singleQuestion(
          engine,
          items: _latinWords(),
          type: QuizType.multipleChoice,
        );
        final QuizOption? correct = question.correctOption;
        if (correct == null) {
          fail('multiple-choice question is missing a correct option');
        }
        expect(
          engine.isCorrect(question, QuizAnswerInput.option(correct.id)),
          isTrue,
        );

        QuizOption? wrong;
        for (final QuizOption option in question.options) {
          if (!option.isCorrect) {
            wrong = option;
            break;
          }
        }
        if (wrong == null) {
          fail('multiple-choice question is missing a distractor');
        }
        expect(
          engine.isCorrect(question, QuizAnswerInput.option(wrong.id)),
          isFalse,
        );
      },
    );

    test('accepts case-insensitive Latin typing and rejects a misspelling', () {
      final QuizEngine engine = QuizEngine(random: Random(6));
      final QuizQuestion question = _singleQuestion(
        engine,
        items: _latinWords(),
        type: QuizType.typing,
      );
      expect(
        engine.isCorrect(
          question,
          QuizAnswerInput.text('  ${question.expectedAnswer.toUpperCase()}  '),
        ),
        isTrue,
      );
      expect(
        engine.isCorrect(
          question,
          QuizAnswerInput.text('${question.expectedAnswer}!'),
        ),
        isTrue,
      );
      expect(
        engine.isCorrect(question, QuizAnswerInput.text('not-the-answer')),
        isFalse,
      );
    });

    test('does not offer typing or build for isolated alphabet glyphs', () {
      final QuizEngine engine = QuizEngine(random: Random(7));
      expect(
        engine.availableTypes(
          items: _alphabetItems(),
          optionPool: _alphabetItems(),
          translationLanguageCode: 'en',
        ),
        <QuizType>[QuizType.multipleChoice, QuizType.reverseMultipleChoice],
      );
      expect(
        QuizText.usesCaseSensitiveAnswers(
          kind: QuizContentKind.alphabet,
          scriptFamily: ScriptFamily.latin,
        ),
        isTrue,
      );
      final QuizStartResult typing = engine.start(
        items: _alphabetItems(),
        optionPool: _alphabetItems(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.typing],
      );
      expect(typing.isReady, isFalse);
      final QuizStartResult build = engine.start(
        items: _alphabetItems(),
        optionPool: _alphabetItems(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.buildSequence],
      );
      expect(build.isReady, isFalse);
    });

    test('checks build-sequence tokens in order', () {
      final QuizEngine engine = QuizEngine(random: Random(8));
      final QuizQuestion question = _singleQuestion(
        engine,
        items: _latinPhrases(),
        type: QuizType.buildSequence,
      );
      expect(question.expectedTokens, isNotEmpty);
      expect(
        engine.isCorrect(
          question,
          QuizAnswerInput.tokens(question.expectedTokens),
        ),
        isTrue,
      );
      expect(
        engine.isCorrect(
          question,
          QuizAnswerInput.tokens(question.expectedTokens.reversed.toList()),
        ),
        isFalse,
      );
    });
  });

  group('session completion', () {
    test('scores answered questions and completes the session', () {
      final QuizEngine engine = QuizEngine(random: Random(9));
      final QuizStartResult start = engine.start(
        items: _latinWords(),
        optionPool: _latinWords(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.typing],
        questionCount: 3,
        sessionId: 'session-complete',
      );
      QuizSession session = _ready(start);
      expect(session.questions, hasLength(3));

      final QuizQuestion first = session.questions[0];
      session = engine.submit(
        session,
        QuizAnswerInput.text(first.expectedAnswer),
      );
      session = engine.next(session);

      session = engine.submit(session, QuizAnswerInput.text('wrong'));
      session = engine.next(session);

      final QuizQuestion third = session.questions[2];
      session = engine.submit(
        session,
        QuizAnswerInput.text(third.expectedAnswer),
      );
      session = engine.next(session);

      expect(session.isComplete, isTrue);
      expect(session.result.totalCount, 3);
      expect(session.result.correctCount, 2);
      expect(session.result.score, closeTo(2 / 3, 0.001));
      expect(engine.resultOf(session).correctCount, 2);
    });
  });

  group('mixed-language characters', () {
    test('matches Japanese, Korean, and accented answers', () {
      final QuizEngine engine = QuizEngine(random: Random(10));
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item('word.cat', '猫', 'cat', kind: QuizContentKind.word),
        _item('word.water', '물', 'water', kind: QuizContentKind.word),
        _item('word.coffee', 'café', 'coffee', kind: QuizContentKind.word),
        _item('word.tea', 'お茶', 'tea', kind: QuizContentKind.word),
      ];
      final QuizStartResult start = engine.start(
        items: items,
        optionPool: items,
        scriptFamily: ScriptFamily.japanese,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.typing],
      );
      final QuizSession session = _ready(start);
      for (final QuizQuestion question in session.questions) {
        expect(
          engine.isCorrect(
            question,
            QuizAnswerInput.text(question.expectedAnswer),
          ),
          isTrue,
        );
      }

      final QuizQuestion coffee = session.questions.firstWhere(
        (QuizQuestion question) => question.contentId == 'word.coffee',
      );
      expect(engine.isCorrect(coffee, QuizAnswerInput.text('cafe')), isFalse);
      expect(engine.isCorrect(coffee, QuizAnswerInput.text('café')), isTrue);

      expect(QuizText.graphemes('猫').length, 1);
      expect(QuizText.graphemes('こんにちは').length, 5);
      expect(QuizText.graphemes('물').length, 1);
      expect(QuizText.graphemes('café'), <String>['c', 'a', 'f', 'é']);
    });
  });

  group('RTL-compatible data', () {
    test('preserves RTL direction and ignores bidi marks', () {
      final QuizEngine engine = QuizEngine(random: Random(12));
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item('word.book', 'كتاب', 'book'),
        _item('word.house', 'بيت', 'house'),
        _item('word.water', 'ماء', 'water'),
        _item('word.sun', 'شمس', 'sun'),
      ];
      final QuizStartResult start = engine.start(
        items: items,
        optionPool: items,
        scriptFamily: ScriptFamily.arabic,
        textDirection: ContentTextDirection.rtl,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.typing],
      );
      final QuizSession session = _ready(start);
      expect(session.questions, isNotEmpty);
      for (final QuizQuestion question in session.questions) {
        expect(question.answerDirection, ContentTextDirection.rtl);
        expect(question.promptDirection, ContentTextDirection.ltr);
        expect(
          engine.isCorrect(
            question,
            QuizAnswerInput.text('\u200F${question.expectedAnswer}\u200E'),
          ),
          isTrue,
        );
      }

      final QuizStartResult reverse = engine.start(
        items: items,
        optionPool: items,
        scriptFamily: ScriptFamily.arabic,
        textDirection: ContentTextDirection.rtl,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.reverseMultipleChoice],
      );
      final QuizQuestion reverseQuestion = _ready(reverse).questions.first;
      expect(reverseQuestion.promptDirection, ContentTextDirection.ltr);
      expect(reverseQuestion.answerDirection, ContentTextDirection.rtl);
    });
  });

  group('empty and insufficient content', () {
    test('flags an empty pool', () {
      final QuizStartResult start = QuizEngine(random: Random(1)).start(
        items: const <QuizReadyItem>[],
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
      );
      expect(start.isReady, isFalse);
      expect(start.reason, QuizUnavailableReason.emptyContent);
    });

    test('flags content that cannot form the requested type', () {
      final QuizStartResult start = QuizEngine(random: Random(1)).start(
        items: <QuizReadyItem>[_item('word.only', 'Hi', 'Hello')],
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.multipleChoice],
      );
      expect(start.isReady, isFalse);
      expect(start.reason, QuizUnavailableReason.insufficientContent);
    });

    test('still starts a typing session from a single item', () {
      final QuizStartResult start = QuizEngine(random: Random(1)).start(
        items: <QuizReadyItem>[_item('word.only', 'Hi', 'Hello')],
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.typing],
      );
      expect(start.isReady, isTrue);
      expect(_ready(start).questions, hasLength(1));
    });

    test('skips blank prompts', () {
      final QuizStartResult start = QuizEngine(random: Random(1)).start(
        items: <QuizReadyItem>[
          _item('word.blank', '   ', 'Blank'),
          _item('word.empty-cue', 'Hola', ''),
        ],
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
      );
      expect(start.isReady, isFalse);
      expect(start.reason, QuizUnavailableReason.insufficientContent);
    });
  });

  group('repeated taps', () {
    test('ignores a second submit on the same question', () {
      final QuizEngine engine = QuizEngine(random: Random(21));
      QuizSession session = _ready(
        engine.start(
          items: _latinWords(),
          optionPool: _latinWords(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: const <QuizType>[QuizType.typing],
          questionCount: 1,
        ),
      );
      final String expected = session.questions.first.expectedAnswer;
      session = engine.submit(session, QuizAnswerInput.text(expected));
      final QuizSession blocked = engine.submit(
        session,
        QuizAnswerInput.text('wrong'),
      );
      expect(identical(blocked, session), isTrue);
      expect(blocked.answers, hasLength(1));
      expect(blocked.answers.single.isCorrect, isTrue);
    });

    test('does not skip ahead until the current question is answered', () {
      final QuizEngine engine = QuizEngine(random: Random(22));
      final QuizSession session = _ready(
        engine.start(
          items: _latinWords(),
          optionPool: _latinWords(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: const <QuizType>[QuizType.typing],
          questionCount: 3,
        ),
      );
      expect(engine.next(session).currentIndex, 0);
      expect(engine.next(session).isComplete, isFalse);
    });
  });

  group('long content', () {
    test('keeps a long phrase for typing and skips build-the-phrase', () {
      final String longPhrase =
          'Please would you kindly tell me the way to the station this evening';
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item(
          'phrase.long',
          longPhrase,
          'A polite request for directions',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.short',
          'Hello there friend',
          'A greeting',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.thanks',
          'Thank you so much',
          'Gratitude',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.bye',
          'See you tomorrow',
          'A farewell',
          kind: QuizContentKind.phrase,
        ),
      ];
      final QuizEngine engine = QuizEngine(random: Random(23));
      expect(QuizText.tokensFor(longPhrase).length, greaterThan(12));
      expect(
        engine.availableTypes(
          items: <QuizReadyItem>[items.first],
          optionPool: items,
          translationLanguageCode: 'en',
        ),
        isNot(contains(QuizType.buildSequence)),
      );

      final QuizSession typed = _ready(
        engine.start(
          items: <QuizReadyItem>[items.first],
          optionPool: items,
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: const <QuizType>[QuizType.typing],
          questionCount: 1,
        ),
      );
      expect(typed.questions.first.expectedAnswer, longPhrase);
      expect(typed.questions.first.prompt.length, greaterThan(20));
      expect(
        engine.isCorrect(
          typed.questions.first,
          QuizAnswerInput.text('  $longPhrase  '),
        ),
        isTrue,
      );
    });
  });

  group('answer normalization', () {
    test('treats extra spaces and capitalization as the same Latin answer', () {
      expect(
        QuizText.equals(
          '  Hello   there ',
          'hello there',
          caseSensitive: false,
        ),
        isTrue,
      );
      expect(QuizText.equals('Café', 'café', caseSensitive: false), isTrue);
      expect(QuizText.equals('Café', 'cafe', caseSensitive: false), isFalse);
    });

    test('matches Unicode-decomposed Latin and Hangul to composed forms', () {
      expect(
        QuizText.equals('café', 'cafe\u0301', caseSensitive: false),
        isTrue,
      );
      expect(
        QuizText.equals('\uAC00', '\u1100\u1161', caseSensitive: true),
        isTrue,
      );
    });

    test('ignores wrapping punctuation without accepting a different word', () {
      expect(QuizText.equals('Hello!', 'hello', caseSensitive: false), isTrue);
      expect(QuizText.equals('Hello?', 'hello.', caseSensitive: false), isTrue);
      expect(
        QuizText.equals('Hello there.', 'hello   there', caseSensitive: false),
        isTrue,
      );
      expect(QuizText.equals('«Hello»', 'hello', caseSensitive: false), isTrue);
      expect(QuizText.equals('Hello', 'Halló', caseSensitive: false), isFalse);
      expect(QuizText.equals('!', '?', caseSensitive: true), isFalse);
    });
  });

  group('insufficient options', () {
    test('builds a shorter multiple-choice set when only two labels exist', () {
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item('word.one', 'Uno', 'One'),
        _item('word.two', 'Dos', 'Two'),
      ];
      final QuizEngine engine = QuizEngine(random: Random(24));
      expect(
        engine.availableTypes(items: items, translationLanguageCode: 'en'),
        contains(QuizType.multipleChoice),
      );
      final QuizQuestion question = _singleQuestion(
        engine,
        items: items,
        type: QuizType.multipleChoice,
      );
      expect(question.options.length, 2);
      final Set<String> keys = question.options
          .map((QuizOption option) => QuizText.uniquenessKey(option.text))
          .toSet();
      expect(keys.length, 2);
    });
  });

  group('result calculation', () {
    test('counts correct and incorrect answers on completion', () {
      final QuizEngine engine = QuizEngine(random: Random(25));
      QuizSession session = _ready(
        engine.start(
          items: _latinWords(),
          optionPool: _latinWords(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: const <QuizType>[QuizType.typing],
          questionCount: 3,
        ),
      );
      session = engine.submit(
        session,
        QuizAnswerInput.text(session.questions[0].expectedAnswer),
      );
      session = engine.next(session);
      session = engine.submit(session, QuizAnswerInput.text('nope'));
      session = engine.next(session);
      session = engine.submit(session, QuizAnswerInput.text('also wrong'));
      session = engine.next(session);

      final QuizResult result = session.result;
      expect(session.isComplete, isTrue);
      expect(result.correctCount, 1);
      expect(result.incorrectCount, 2);
      expect(result.correctAnswers, hasLength(1));
      expect(result.incorrectAnswers, hasLength(2));
      expect(result.score, closeTo(1 / 3, 0.001));
    });
  });

  group('mixed type variety', () {
    test('spreads viable types instead of repeating one mode', () {
      final QuizSession session = _ready(
        QuizEngine(random: Random(27)).start(
          items: _latinWords(),
          optionPool: _latinWords(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          questionCount: 6,
        ),
      );
      expect(session.questions, hasLength(6));
      expect(
        session.questions.map((QuizQuestion question) => question.type).toSet(),
        quizTypesForKind(QuizContentKind.word),
      );
    });

    test('phrase mixed sessions can include build phrase', () {
      final QuizSession session = _ready(
        QuizEngine(random: Random(48)).start(
          items: _latinPhrases(),
          optionPool: _latinPhrases(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          questionCount: 8,
        ),
      );
      expect(session.questions, isNotEmpty);
      expect(
        session.questions.map((QuizQuestion question) => question.type).toSet(),
        quizTypesForKind(QuizContentKind.phrase),
      );
      expect(
        session.questions.any(
          (QuizQuestion question) => question.type == QuizType.buildSequence,
        ),
        isTrue,
      );
    });

    test('does not pick a type the item cannot support', () {
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item('word.i', 'I', 'First person'),
        ..._latinWords(),
      ];
      final QuizSession session = _ready(
        QuizEngine(random: Random(28)).start(
          items: items,
          optionPool: items,
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          questionCount: 20,
        ),
      );
      for (final QuizQuestion question in session.questions) {
        if (question.contentId == 'word.i') {
          expect(question.type, isNot(QuizType.buildSequence));
        }
        if (question.type == QuizType.buildSequence) {
          expect(question.expectedTokens.length, greaterThanOrEqualTo(2));
        }
      }
    });
  });

  group('translation language safety', () {
    test('skips items that lack the selected learner language', () {
      final QuizStartResult start = QuizEngine(random: Random(29)).start(
        items: _latinWords(),
        optionPool: _latinWords(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'tr',
        allowedTypes: const <QuizType>[QuizType.typing],
      );
      expect(start.isReady, isFalse);
      expect(start.reason, QuizUnavailableReason.insufficientContent);
    });

    test('uses English meaning when the target is another language', () {
      final List<QuizReadyItem> items = _turkishTaughtWords();
      final QuizEngine engine = QuizEngine(random: Random(30));
      final QuizQuestion typing = _singleQuestion(
        engine,
        items: items,
        type: QuizType.typing,
        translationLanguageCode: 'en',
      );
      final QuizReadyItem item = _byId(items, typing.contentId);
      expect(typing.prompt, item.answersByLanguage['en']);
      expect(typing.expectedAnswer, item.prompt);
      expect(
        engine.isCorrect(
          typing,
          QuizAnswerInput.text(item.answersByLanguage['en']!),
        ),
        isFalse,
      );
      expect(
        engine.isCorrect(typing, QuizAnswerInput.text(item.prompt)),
        isTrue,
      );

      final QuizQuestion multipleChoice = _singleQuestion(
        QuizEngine(random: Random(31)),
        items: items,
        type: QuizType.multipleChoice,
        translationLanguageCode: 'en',
      );
      final QuizReadyItem mcItem = _byId(items, multipleChoice.contentId);
      expect(multipleChoice.prompt, mcItem.prompt);
      expect(multipleChoice.expectedAnswer, mcItem.answersByLanguage['en']);
    });
  });

  group('build tokenization', () {
    test('keeps phrase words without a standalone punctuation chip', () {
      expect(QuizText.tokensFor('Thank you!'), <String>['Thank', 'you']);
      expect(QuizText.tokensFor('Hello there.'), <String>['Hello', 'there']);
      expect(QuizText.tokensFor('¿Qué tal?'), <String>['Qué', 'tal']);
      expect(
        QuizText.joinTokens(<String>['Thank', 'you', '!'], ' '),
        'Thank you!',
      );
      expect(QuizText.tokensFor("don't go"), <String>["don't", 'go']);
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item(
          'phrase.thanks',
          'Thank you!',
          'A polite phrase',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.hello',
          'Hello there.',
          'A greeting',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.please',
          'Please help',
          'A request',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.bye',
          'Good night',
          'A farewell',
          kind: QuizContentKind.phrase,
        ),
      ];
      final QuizQuestion question = _singleQuestion(
        QuizEngine(random: Random(32)),
        items: items,
        type: QuizType.buildSequence,
      );
      expect(question.expectedAnswer, _byId(items, question.contentId).prompt);
      expect(question.expectedTokens, isNotEmpty);
    });

    test('uses graphemes for scripts without spaces, including Arabic', () {
      expect(QuizText.tokensFor('كتاب'), <String>['ك', 'ت', 'ا', 'ب']);
      expect(QuizText.tokensFor('こんにちは'), hasLength(5));
      expect(QuizText.tokensFor('물'), <String>['물']);
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item(
          'phrase.book',
          'هذا كتاب',
          'this is a book',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.house',
          'بيت كبير',
          'a large house',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.water',
          'ماء بارد',
          'cold water',
          kind: QuizContentKind.phrase,
        ),
        _item(
          'phrase.sun',
          'شمس مشرقة',
          'a shining sun',
          kind: QuizContentKind.phrase,
        ),
      ];
      final QuizQuestion question = _singleQuestion(
        QuizEngine(random: Random(33)),
        items: items,
        type: QuizType.buildSequence,
        scriptFamily: ScriptFamily.arabic,
        textDirection: ContentTextDirection.rtl,
      );
      expect(question.expectedTokens.length, greaterThanOrEqualTo(2));
      expect(question.answerDirection, ContentTextDirection.rtl);
      expect(question.promptDirection, ContentTextDirection.ltr);
      expect(question.kind, QuizContentKind.phrase);
    });
  });

  group('restarting a session', () {
    test('starts a fresh unanswered run from the same content', () {
      final QuizEngine engine = QuizEngine(random: Random(26));
      QuizSession first = _ready(
        engine.start(
          items: _latinWords(),
          optionPool: _latinWords(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: const <QuizType>[QuizType.typing],
          questionCount: 2,
          sessionId: 'first',
        ),
      );
      first = engine.submit(
        first,
        QuizAnswerInput.text(first.questions.first.expectedAnswer),
      );
      first = engine.next(first);
      first = engine.submit(first, QuizAnswerInput.text('wrong'));
      first = engine.next(first);
      expect(first.isComplete, isTrue);

      final QuizSession second = _ready(
        engine.start(
          items: _latinWords(),
          optionPool: _latinWords(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          allowedTypes: const <QuizType>[QuizType.typing],
          questionCount: 2,
          sessionId: 'second',
        ),
      );
      expect(second.isComplete, isFalse);
      expect(second.answers, isEmpty);
      expect(second.currentIndex, 0);
      expect(second.questions, isNotEmpty);
    });
  });
  group('alphabet mode restrictions', () {
    test('mixed alphabet sessions stay on recognition modes', () {
      final QuizSession session = _ready(
        QuizEngine(random: Random(44)).start(
          items: _alphabetItems(),
          optionPool: _alphabetItems(),
          scriptFamily: ScriptFamily.latin,
          textDirection: ContentTextDirection.ltr,
          translationLanguageCode: 'en',
          questionCount: 4,
        ),
      );
      expect(session.questions, isNotEmpty);
      for (final QuizQuestion question in session.questions) {
        expect(question.kind, QuizContentKind.alphabet);
        expect(question.type, isNot(QuizType.buildSequence));
        expect(question.type, isNot(QuizType.typing));
        expect(
          <QuizType>{
            QuizType.multipleChoice,
            QuizType.reverseMultipleChoice,
          }.contains(question.type),
          isTrue,
        );
        expect(
          QuizText.isTrivialPair(question.targetText, question.learnerCue),
          isFalse,
        );
      }
    });

    test('skips a single-character build even if typing is requested', () {
      final List<QuizReadyItem> items = <QuizReadyItem>[
        _item('letter.x', 'X', 'example', kind: QuizContentKind.alphabet),
        _item('letter.y', 'Y', 'yellow', kind: QuizContentKind.alphabet),
      ];
      expect(QuizText.tokensFor('X'), <String>['X']);
      expect(
        QuizEngine(random: Random(45)).availableTypes(
          items: items,
          optionPool: items,
          translationLanguageCode: 'en',
        ),
        isNot(contains(QuizType.buildSequence)),
      );
    });
  });

  group('question quality', () {
    test('skips items whose prompt and cue are effectively identical', () {
      final QuizStartResult start = QuizEngine(random: Random(46)).start(
        items: _englishTaughtWords(),
        optionPool: _englishTaughtWords(),
        scriptFamily: ScriptFamily.latin,
        textDirection: ContentTextDirection.ltr,
        translationLanguageCode: 'en',
        allowedTypes: const <QuizType>[QuizType.typing],
      );
      expect(start.isReady, isFalse);
      expect(start.reason, QuizUnavailableReason.insufficientContent);
    });

    test('uses pronunciation when the learner meaning matches the target', () {
      final List<QuizReadyItem> items = _englishTaughtWordsWithIpa();
      final QuizEngine engine = QuizEngine(random: Random(48));
      expect(
        engine.availableTypes(
          items: items,
          optionPool: items,
          translationLanguageCode: 'en',
        ),
        <QuizType>[QuizType.reverseMultipleChoice, QuizType.typing],
      );
      expect(
        engine.availableTypes(
          items: items,
          optionPool: items,
          translationLanguageCode: 'en',
          allowedTypes: const <QuizType>[QuizType.multipleChoice],
        ),
        isEmpty,
      );

      final QuizQuestion reverse = _singleQuestion(
        engine,
        items: items,
        type: QuizType.reverseMultipleChoice,
        translationLanguageCode: 'en',
      );
      final QuizReadyItem reverseItem = _byId(items, reverse.contentId);
      expect(reverse.prompt, reverseItem.pronunciation);
      expect(reverse.expectedAnswer, reverseItem.prompt);
      expect(reverse.targetText, reverseItem.prompt);

      final QuizQuestion typing = _singleQuestion(
        QuizEngine(random: Random(49)),
        items: items,
        type: QuizType.typing,
        translationLanguageCode: 'en',
      );
      final QuizReadyItem typingItem = _byId(items, typing.contentId);
      expect(typing.prompt, typingItem.pronunciation);
      expect(typing.expectedAnswer, typingItem.prompt);
      expect(
        engine.isCorrect(typing, QuizAnswerInput.text(typingItem.prompt)),
        isTrue,
      );
    });
  });

  group('wrong-answer integration hook', () {
    test('exposes stable content, kind, type, target, and learner cue', () {
      final QuizEngine engine = QuizEngine(random: Random(47));
      final QuizQuestion question = _singleQuestion(
        engine,
        items: _englishTaughtWords(),
        type: QuizType.typing,
        translationLanguageCode: 'tr',
      );
      final QuizAnswer wrong = engine.grade(
        question,
        QuizAnswerInput.text('nope'),
      );
      expect(wrong.isCorrect, isFalse);
      expect(wrong.contentId, question.contentId);
      expect(wrong.kind, question.kind);
      expect(wrong.type, QuizType.typing);
      expect(wrong.targetAnswer, question.targetText);
      expect(wrong.learnerCue, question.learnerCue);
      expect(wrong.targetAnswer, isNot(equals(wrong.learnerCue)));

      final QuizWrongAnswer? event = wrong.asWrongAnswer;
      expect(event, isNotNull);
      expect(event?.contentId, question.contentId);
      expect(event?.kind, QuizContentKind.word);
      expect(event?.quizType, QuizType.typing);
      expect(event?.targetAnswer, question.expectedAnswer);
      expect(event?.learnerCue, question.prompt);

      final QuizAnswer right = engine.grade(
        question,
        QuizAnswerInput.text(question.expectedAnswer),
      );
      expect(right.asWrongAnswer, isNull);
      final QuizCorrectAnswer? hit = right.asCorrectAnswer;
      expect(hit, isNotNull);
      expect(hit?.contentId, question.contentId);
      expect(hit?.kind, QuizContentKind.word);
      expect(hit?.quizType, QuizType.typing);
      expect(wrong.asCorrectAnswer, isNull);
    });
  });
}

QuizSession _ready(QuizStartResult start) {
  final QuizSession? session = start.session;
  if (session == null) {
    fail('quiz should start, reason=${start.reason}');
  }
  return session;
}

QuizQuestion _singleQuestion(
  QuizEngine engine, {
  required List<QuizReadyItem> items,
  required QuizType type,
  String translationLanguageCode = 'en',
  ScriptFamily scriptFamily = ScriptFamily.latin,
  ContentTextDirection textDirection = ContentTextDirection.ltr,
}) {
  final QuizStartResult start = engine.start(
    items: items,
    optionPool: items,
    scriptFamily: scriptFamily,
    textDirection: textDirection,
    translationLanguageCode: translationLanguageCode,
    allowedTypes: <QuizType>[type],
    questionCount: 1,
  );
  final QuizSession session = _ready(start);
  expect(session.questions, isNotEmpty);
  return session.questions.first;
}

QuizReadyItem _item(
  String id,
  String prompt,
  String translation, {
  QuizContentKind kind = QuizContentKind.word,
  String? pronunciation,
}) {
  return QuizReadyItem(
    id: id,
    kind: kind,
    prompt: prompt,
    pronunciation: pronunciation,
    answersByLanguage: <String, String>{
      if (translation.isNotEmpty) 'en': translation,
    },
  );
}

List<QuizReadyItem> _latinPhrases() {
  return <QuizReadyItem>[
    _item(
      'phrase.hello',
      'Hello there',
      'A greeting',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.thanks',
      'Thank you',
      'Gratitude',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.bye',
      'Good night',
      'An evening farewell',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.please',
      'Please help',
      'A polite request',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.see',
      'See you tomorrow',
      'A later farewell',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.come',
      'Come here now',
      'A request to approach',
      kind: QuizContentKind.phrase,
    ),
  ];
}

List<QuizReadyItem> _latinWords() {
  return <QuizReadyItem>[
    _item('word.cat', 'Cat', 'A small animal'),
    _item('word.dog', 'Dog', 'A loyal pet'),
    _item('word.sun', 'Sun', 'Daylight star'),
    _item('word.moon', 'Moon', 'Night light'),
    _item('word.bread', 'Bread', 'Baked food'),
    _item('word.water', 'Water', 'Clear drink'),
  ];
}

List<QuizReadyItem> _englishTaughtWords() {
  return <QuizReadyItem>[
    _bilingual('word.hello', 'Hello', 'Hello', 'Merhaba'),
    _bilingual('word.thanks', 'Thank you', 'Thank you', 'Teşekkür ederim'),
    _bilingual('word.cat', 'Cat', 'Cat', 'Kedi'),
    _bilingual('word.dog', 'Dog', 'Dog', 'Köpek'),
  ];
}

List<QuizReadyItem> _englishTaughtWordsWithIpa() {
  return <QuizReadyItem>[
    _bilingual(
      'word.hello',
      'Hello',
      'Hello',
      'Merhaba',
      pronunciation: '/həˈloʊ/',
    ),
    _bilingual(
      'word.thanks',
      'Thank you',
      'Thank you',
      'Teşekkür ederim',
      pronunciation: '/θæŋk juː/',
    ),
    _bilingual('word.cat', 'Cat', 'Cat', 'Kedi', pronunciation: '/kæt/'),
    _bilingual('word.dog', 'Dog', 'Dog', 'Köpek', pronunciation: '/dɔːɡ/'),
  ];
}

List<QuizReadyItem> _turkishTaughtWords() {
  return <QuizReadyItem>[
    _bilingual('word.hello', 'Merhaba', 'Hello', 'Merhaba'),
    _bilingual(
      'word.thanks',
      'Teşekkür ederim',
      'Thank you',
      'Teşekkür ederim',
    ),
    _bilingual('word.cat', 'Kedi', 'Cat', 'Kedi'),
    _bilingual('word.dog', 'Köpek', 'Dog', 'Köpek'),
  ];
}

List<QuizReadyItem> _englishTaughtPhrases() {
  return <QuizReadyItem>[
    _bilingual(
      'phrase.hello',
      'Hello there',
      'Hello there',
      'Merhaba dostum',
      kind: QuizContentKind.phrase,
    ),
    _bilingual(
      'phrase.thanks',
      'Thank you',
      'Thank you',
      'Teşekkür ederim',
      kind: QuizContentKind.phrase,
    ),
    _bilingual(
      'phrase.bye',
      'Good night',
      'Good night',
      'İyi geceler',
      kind: QuizContentKind.phrase,
    ),
    _bilingual(
      'phrase.please',
      'Please help',
      'Please help',
      'Lütfen yardım et',
      kind: QuizContentKind.phrase,
    ),
  ];
}

QuizReadyItem _bilingual(
  String id,
  String target,
  String english,
  String turkish, {
  QuizContentKind kind = QuizContentKind.word,
  String? pronunciation,
}) {
  return QuizReadyItem(
    id: id,
    kind: kind,
    prompt: target,
    pronunciation: pronunciation,
    answersByLanguage: <String, String>{'en': english, 'tr': turkish},
  );
}

QuizReadyItem _byId(List<QuizReadyItem> items, String id) {
  return items.firstWhere((QuizReadyItem item) => item.id == id);
}

List<QuizReadyItem> _alphabetItems() {
  return <QuizReadyItem>[
    _item(
      'letter.a',
      'A',
      'apple',
      kind: QuizContentKind.alphabet,
      pronunciation: 'ay',
    ),
    _item(
      'letter.b',
      'B',
      'book',
      kind: QuizContentKind.alphabet,
      pronunciation: 'bee',
    ),
    _item(
      'letter.c',
      'C',
      'cat',
      kind: QuizContentKind.alphabet,
      pronunciation: 'see',
    ),
    _item(
      'letter.d',
      'D',
      'dog',
      kind: QuizContentKind.alphabet,
      pronunciation: 'dee',
    ),
  ];
}

List<QuizReadyItem> _mixedPool() {
  return <QuizReadyItem>[
    ..._alphabetItems(),
    ..._latinWords(),
    _item(
      'phrase.hello',
      'Hello there',
      'A greeting',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.thanks',
      'Thank you',
      'Gratitude',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.bye',
      'Good night',
      'An evening farewell',
      kind: QuizContentKind.phrase,
    ),
    _item(
      'phrase.please',
      'Please help',
      'A polite request',
      kind: QuizContentKind.phrase,
    ),
  ];
}
