import 'package:lingo_core/domain/content_models.dart';

/// Reusable quiz formats. None of these are tied to a target language.
enum QuizType { multipleChoice, reverseMultipleChoice, buildSequence, typing }

/// Formats a content kind is allowed to expose in pickers and sessions.
Set<QuizType> quizTypesForKind(QuizContentKind kind) {
  switch (kind) {
    case QuizContentKind.alphabet:
      return const <QuizType>{
        QuizType.multipleChoice,
        QuizType.reverseMultipleChoice,
      };
    case QuizContentKind.word:
      return const <QuizType>{
        QuizType.multipleChoice,
        QuizType.reverseMultipleChoice,
        QuizType.typing,
      };
    case QuizContentKind.phrase:
      return const <QuizType>{
        QuizType.multipleChoice,
        QuizType.reverseMultipleChoice,
        QuizType.buildSequence,
        QuizType.typing,
      };
  }
}

enum QuizUnavailableReason { emptyContent, insufficientContent }

/// One selectable choice for a multiple-choice question.
final class QuizOption {
  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  /// Stable content ID when the option maps to a pack item.
  final String id;
  final String text;
  final bool isCorrect;
}

/// A single in-memory quiz prompt. Identified by [contentId], not by language.
final class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.contentId,
    required this.type,
    required this.kind,
    required this.prompt,
    required this.expectedAnswer,
    required this.promptDirection,
    required this.answerDirection,
    required this.caseSensitive,
    required this.targetText,
    required this.learnerCue,
    this.options = const <QuizOption>[],
    this.tokens = const <String>[],
    this.expectedTokens = const <String>[],
    this.tokenSeparator = '',
  });

  final String id;
  final String contentId;
  final QuizType type;
  final QuizContentKind kind;
  final String prompt;
  final String expectedAnswer;
  final ContentTextDirection promptDirection;
  final ContentTextDirection answerDirection;
  final bool caseSensitive;

  /// Target-language form the learner is studying.
  final String targetText;

  /// Learner-language cue shown or asked for this item.
  final String learnerCue;
  final List<QuizOption> options;
  final List<String> tokens;
  final List<String> expectedTokens;
  final String tokenSeparator;

  QuizOption? get correctOption {
    for (final QuizOption option in options) {
      if (option.isCorrect) {
        return option;
      }
    }
    return null;
  }
}

/// Learner response captured for one question.
final class QuizAnswer {
  const QuizAnswer({
    required this.questionId,
    required this.contentId,
    required this.kind,
    required this.type,
    required this.submittedText,
    required this.targetAnswer,
    required this.learnerCue,
    required this.isCorrect,
  });

  final String questionId;
  final String contentId;
  final QuizContentKind kind;
  final QuizType type;
  final String submittedText;

  /// Target-language answer for this item.
  final String targetAnswer;

  /// Learner-language cue for this item.
  final String learnerCue;
  final bool isCorrect;

  /// Structured miss for the Wrong Answers store. Not persisted here.
  QuizWrongAnswer? get asWrongAnswer {
    if (isCorrect) {
      return null;
    }
    return QuizWrongAnswer(
      contentId: contentId,
      kind: kind,
      quizType: type,
      targetAnswer: targetAnswer,
      learnerCue: learnerCue,
      submittedText: submittedText,
    );
  }

  /// Structured hit used to drop a stored Wrong Answers item.
  QuizCorrectAnswer? get asCorrectAnswer {
    if (!isCorrect) {
      return null;
    }
    return QuizCorrectAnswer(contentId: contentId, kind: kind, quizType: type);
  }
}

/// In-memory miss payload. Persistence lives in user preferences.
final class QuizWrongAnswer {
  const QuizWrongAnswer({
    required this.contentId,
    required this.kind,
    required this.quizType,
    required this.targetAnswer,
    required this.learnerCue,
    required this.submittedText,
  });

  final String contentId;
  final QuizContentKind kind;
  final QuizType quizType;
  final String targetAnswer;
  final String learnerCue;
  final String submittedText;
}

/// In-memory hit payload. Persistence lives in user preferences.
final class QuizCorrectAnswer {
  const QuizCorrectAnswer({
    required this.contentId,
    required this.kind,
    required this.quizType,
  });

  final String contentId;
  final QuizContentKind kind;
  final QuizType quizType;
}

/// Score for a finished (or early-completed) session. Not persisted.
final class QuizResult {
  const QuizResult({
    required this.correctCount,
    required this.totalCount,
    required this.answers,
  });

  final int correctCount;
  final int totalCount;
  final List<QuizAnswer> answers;

  double get score {
    if (totalCount <= 0) {
      return 0;
    }
    return correctCount / totalCount;
  }

  int get incorrectCount {
    final int wrong = totalCount - correctCount;
    return wrong < 0 ? 0 : wrong;
  }

  List<QuizAnswer> get correctAnswers {
    return answers
        .where((QuizAnswer answer) => answer.isCorrect)
        .toList(growable: false);
  }

  List<QuizAnswer> get incorrectAnswers {
    return answers
        .where((QuizAnswer answer) => !answer.isCorrect)
        .toList(growable: false);
  }

  /// Stable miss records for the Wrong Answers store.
  List<QuizWrongAnswer> get wrongAnswers {
    return incorrectAnswers
        .map((QuizAnswer answer) => answer.asWrongAnswer)
        .whereType<QuizWrongAnswer>()
        .toList(growable: false);
  }
}

/// In-memory quiz run. Persistence is intentionally out of scope.
final class QuizSession {
  const QuizSession({
    required this.id,
    required this.title,
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.isComplete,
  });

  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final List<QuizAnswer> answers;
  final int currentIndex;
  final bool isComplete;

  QuizQuestion? get currentQuestion {
    if (isComplete || currentIndex < 0 || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  bool get hasAnsweredCurrent {
    final QuizQuestion? question = currentQuestion;
    if (question == null) {
      return false;
    }
    return _answerFor(question.id) != null;
  }

  QuizAnswer? answerForCurrent() {
    final QuizQuestion? question = currentQuestion;
    if (question == null) {
      return null;
    }
    return _answerFor(question.id);
  }

  QuizQuestion? questionById(String questionId) {
    for (final QuizQuestion question in questions) {
      if (question.id == questionId) {
        return question;
      }
    }
    return null;
  }

  int get questionNumber {
    if (questions.isEmpty) {
      return 0;
    }
    final int bounded = currentIndex.clamp(0, questions.length - 1) + 1;
    return isComplete ? questions.length : bounded;
  }

  QuizResult get result {
    final int correct = answers
        .where((QuizAnswer answer) => answer.isCorrect)
        .length;
    return QuizResult(
      correctCount: correct,
      totalCount: questions.length,
      answers: answers,
    );
  }

  QuizSession copyWith({
    List<QuizAnswer>? answers,
    int? currentIndex,
    bool? isComplete,
  }) {
    return QuizSession(
      id: id,
      title: title,
      questions: questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  QuizAnswer? _answerFor(String questionId) {
    for (final QuizAnswer answer in answers) {
      if (answer.questionId == questionId) {
        return answer;
      }
    }
    return null;
  }
}

/// Outcome of trying to build a session from a content pool.
final class QuizStartResult {
  const QuizStartResult.session(this.session) : reason = null;

  const QuizStartResult.unavailable(this.reason) : session = null;

  final QuizSession? session;
  final QuizUnavailableReason? reason;

  bool get isReady {
    final QuizSession? session = this.session;
    return session != null && session.questions.isNotEmpty;
  }
}

/// Learner input for [QuizEngine.grade].
final class QuizAnswerInput {
  const QuizAnswerInput.option(this.optionId) : text = null, tokens = null;

  const QuizAnswerInput.text(this.text) : optionId = null, tokens = null;

  const QuizAnswerInput.tokens(this.tokens) : optionId = null, text = null;

  final String? optionId;
  final String? text;
  final List<String>? tokens;
}
