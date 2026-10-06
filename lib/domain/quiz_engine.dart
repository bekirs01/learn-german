import 'dart:math';

import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/domain/quiz_text.dart';

/// Builds, scores, and advances language-agnostic quiz sessions.
///
/// Alias: [QuizService]. Session state stays in memory.
final class QuizEngine {
  QuizEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const int defaultQuestionCount = 10;
  static const int defaultOptionCount = 4;
  static const int minChoiceOptions = 2;
  static const int minBuildTokens = 2;
  static const int maxBuildTokens = 12;

  QuizStartResult start({
    required List<QuizReadyItem> items,
    required ScriptFamily scriptFamily,
    required ContentTextDirection textDirection,
    List<QuizReadyItem>? optionPool,
    String? translationLanguageCode,
    int questionCount = defaultQuestionCount,
    int optionCount = defaultOptionCount,
    String title = 'Quiz',
    Iterable<QuizType>? allowedTypes,
    String? sessionId,
  }) {
    if (items.isEmpty) {
      return const QuizStartResult.unavailable(
        QuizUnavailableReason.emptyContent,
      );
    }

    final Set<QuizType> types = allowedTypes == null
        ? QuizType.values.toSet()
        : allowedTypes.toSet();
    if (types.isEmpty) {
      return const QuizStartResult.unavailable(
        QuizUnavailableReason.insufficientContent,
      );
    }

    final List<QuizReadyItem> pool = optionPool == null
        ? List<QuizReadyItem>.from(items)
        : List<QuizReadyItem>.from(optionPool);
    final List<QuizReadyItem> shuffled = _shuffled(items);
    final Set<String> usedIds = <String>{};
    final List<QuizQuestion> questions = <QuizQuestion>[];
    final Map<QuizType, int> typeUses = <QuizType, int>{};
    final int target = questionCount < 1 ? 1 : questionCount;
    int sequence = 0;

    for (final QuizReadyItem item in shuffled) {
      if (questions.length >= target) {
        break;
      }
      if (usedIds.contains(item.id)) {
        continue;
      }
      final QuizQuestion? question = _buildQuestion(
        item: item,
        optionPool: pool,
        scriptFamily: scriptFamily,
        textDirection: textDirection,
        translationLanguageCode: translationLanguageCode,
        optionCount: optionCount,
        allowedTypes: types,
        typeUses: typeUses,
        sequence: sequence,
      );
      if (question == null) {
        continue;
      }
      usedIds.add(item.id);
      typeUses[question.type] = (typeUses[question.type] ?? 0) + 1;
      questions.add(question);
      sequence += 1;
    }

    if (questions.isEmpty) {
      return const QuizStartResult.unavailable(
        QuizUnavailableReason.insufficientContent,
      );
    }

    return QuizStartResult.session(
      QuizSession(
        id: sessionId ?? 'quiz-${_random.nextInt(1 << 30)}',
        title: title,
        questions: List<QuizQuestion>.unmodifiable(questions),
        answers: const <QuizAnswer>[],
        currentIndex: 0,
        isComplete: false,
      ),
    );
  }

  /// Types that can produce at least one question from [items].
  List<QuizType> availableTypes({
    required List<QuizReadyItem> items,
    List<QuizReadyItem>? optionPool,
    String? translationLanguageCode,
    Iterable<QuizType>? allowedTypes,
  }) {
    final Set<QuizType> wanted = allowedTypes == null
        ? QuizType.values.toSet()
        : allowedTypes.toSet();
    if (items.isEmpty || wanted.isEmpty) {
      return const <QuizType>[];
    }
    final List<QuizReadyItem> pool = optionPool ?? items;
    final Set<QuizType> found = <QuizType>{};
    for (final QuizReadyItem item in items) {
      final String prompt = item.prompt.trim();
      if (prompt.isEmpty) {
        continue;
      }
      found.addAll(
        _viableTypes(
          item: item,
          prompt: prompt,
          optionPool: pool,
          translationLanguageCode: translationLanguageCode,
          allowedTypes: wanted,
        ),
      );
      if (found.length == wanted.length) {
        break;
      }
    }
    return QuizType.values.where(found.contains).toList(growable: false);
  }

  bool isCorrect(QuizQuestion question, QuizAnswerInput input) {
    return grade(question, input).isCorrect;
  }

  QuizAnswer grade(QuizQuestion question, QuizAnswerInput input) {
    final bool correct = _matches(question, input);
    return QuizAnswer(
      questionId: question.id,
      contentId: question.contentId,
      kind: question.kind,
      type: question.type,
      submittedText: _submittedText(question, input),
      targetAnswer: question.targetText,
      learnerCue: question.learnerCue,
      isCorrect: correct,
    );
  }

  QuizSession submit(QuizSession session, QuizAnswerInput input) {
    if (session.isComplete) {
      return session;
    }
    final QuizQuestion? question = session.currentQuestion;
    if (question == null || session.hasAnsweredCurrent) {
      return session;
    }
    final QuizAnswer answer = grade(question, input);
    return session.copyWith(
      answers: List<QuizAnswer>.unmodifiable(<QuizAnswer>[
        ...session.answers,
        answer,
      ]),
    );
  }

  QuizSession next(QuizSession session) {
    if (session.isComplete || !session.hasAnsweredCurrent) {
      return session;
    }
    final int upcoming = session.currentIndex + 1;
    if (upcoming >= session.questions.length) {
      return complete(session);
    }
    return session.copyWith(currentIndex: upcoming);
  }

  QuizSession complete(QuizSession session) {
    if (session.isComplete) {
      return session;
    }
    return session.copyWith(
      isComplete: true,
      currentIndex: session.questions.length,
    );
  }

  QuizResult resultOf(QuizSession session) => session.result;

  QuizQuestion? _buildQuestion({
    required QuizReadyItem item,
    required List<QuizReadyItem> optionPool,
    required ScriptFamily scriptFamily,
    required ContentTextDirection textDirection,
    required String? translationLanguageCode,
    required int optionCount,
    required Set<QuizType> allowedTypes,
    required Map<QuizType, int> typeUses,
    required int sequence,
  }) {
    final String prompt = item.prompt.trim();
    if (prompt.isEmpty) {
      return null;
    }
    final List<QuizType> viable = _viableTypes(
      item: item,
      prompt: prompt,
      optionPool: optionPool,
      translationLanguageCode: translationLanguageCode,
      allowedTypes: allowedTypes,
    );
    if (viable.isEmpty) {
      return null;
    }
    final QuizType type = _pickType(viable, typeUses);
    final _ResolvedCue? cue = _cueForType(
      item: item,
      prompt: prompt,
      type: type,
      translationLanguageCode: translationLanguageCode,
    );
    if (cue == null) {
      return null;
    }
    final bool caseSensitive = QuizText.usesCaseSensitiveAnswers(
      kind: item.kind,
      scriptFamily: scriptFamily,
    );
    final ContentTextDirection cueDirection = cue.directionFor(
      translationLanguageCode,
    );

    switch (type) {
      case QuizType.multipleChoice:
        final List<QuizOption>? options = _choiceOptions(
          item: item,
          optionPool: optionPool,
          optionCount: optionCount,
          translationLanguageCode: translationLanguageCode,
          reverse: false,
        );
        if (options == null) {
          return null;
        }
        return QuizQuestion(
          id: '${item.id}:${type.name}:$sequence',
          contentId: item.id,
          type: type,
          kind: item.kind,
          prompt: prompt,
          expectedAnswer: cue.text,
          promptDirection: textDirection,
          answerDirection: cueDirection,
          caseSensitive: caseSensitive,
          targetText: prompt,
          learnerCue: cue.text,
          options: options,
        );
      case QuizType.reverseMultipleChoice:
        final List<QuizOption>? options = _choiceOptions(
          item: item,
          optionPool: optionPool,
          optionCount: optionCount,
          translationLanguageCode: translationLanguageCode,
          reverse: true,
        );
        if (options == null) {
          return null;
        }
        return QuizQuestion(
          id: '${item.id}:${type.name}:$sequence',
          contentId: item.id,
          type: type,
          kind: item.kind,
          prompt: cue.text,
          expectedAnswer: prompt,
          promptDirection: cueDirection,
          answerDirection: textDirection,
          caseSensitive: caseSensitive,
          targetText: prompt,
          learnerCue: cue.text,
          options: options,
        );
      case QuizType.buildSequence:
        final List<String> expectedTokens = QuizText.tokensFor(prompt);
        if (!_canBuild(item.kind, expectedTokens)) {
          return null;
        }
        final String separator = _tokenSeparator(prompt);
        return QuizQuestion(
          id: '${item.id}:${type.name}:$sequence',
          contentId: item.id,
          type: type,
          kind: item.kind,
          prompt: cue.text,
          expectedAnswer: prompt,
          promptDirection: cueDirection,
          answerDirection: textDirection,
          caseSensitive: caseSensitive,
          targetText: prompt,
          learnerCue: cue.text,
          tokens: _shuffledTokens(expectedTokens),
          expectedTokens: List<String>.unmodifiable(expectedTokens),
          tokenSeparator: separator,
        );
      case QuizType.typing:
        return QuizQuestion(
          id: '${item.id}:${type.name}:$sequence',
          contentId: item.id,
          type: type,
          kind: item.kind,
          prompt: cue.text,
          expectedAnswer: prompt,
          promptDirection: cueDirection,
          answerDirection: textDirection,
          caseSensitive: caseSensitive,
          targetText: prompt,
          learnerCue: cue.text,
        );
    }
  }

  List<QuizType> _viableTypes({
    required QuizReadyItem item,
    required String prompt,
    required List<QuizReadyItem> optionPool,
    required String? translationLanguageCode,
    required Set<QuizType> allowedTypes,
  }) {
    final Set<QuizType> kindAllowed = _typesForKind(item.kind);
    final List<QuizType> types = <QuizType>[];
    if (allowedTypes.contains(QuizType.multipleChoice) &&
        kindAllowed.contains(QuizType.multipleChoice) &&
        _cueForType(
              item: item,
              prompt: prompt,
              type: QuizType.multipleChoice,
              translationLanguageCode: translationLanguageCode,
            ) !=
            null &&
        _uniqueOptionCount(
              item: item,
              optionPool: optionPool,
              translationLanguageCode: translationLanguageCode,
              reverse: false,
            ) >=
            minChoiceOptions) {
      types.add(QuizType.multipleChoice);
    }
    if (allowedTypes.contains(QuizType.reverseMultipleChoice) &&
        kindAllowed.contains(QuizType.reverseMultipleChoice) &&
        _cueForType(
              item: item,
              prompt: prompt,
              type: QuizType.reverseMultipleChoice,
              translationLanguageCode: translationLanguageCode,
            ) !=
            null &&
        _uniqueOptionCount(
              item: item,
              optionPool: optionPool,
              translationLanguageCode: translationLanguageCode,
              reverse: true,
            ) >=
            minChoiceOptions) {
      types.add(QuizType.reverseMultipleChoice);
    }
    if (allowedTypes.contains(QuizType.buildSequence) &&
        kindAllowed.contains(QuizType.buildSequence) &&
        _cueForType(
              item: item,
              prompt: prompt,
              type: QuizType.buildSequence,
              translationLanguageCode: translationLanguageCode,
            ) !=
            null &&
        _canBuild(item.kind, QuizText.tokensFor(prompt))) {
      types.add(QuizType.buildSequence);
    }
    if (allowedTypes.contains(QuizType.typing) &&
        kindAllowed.contains(QuizType.typing) &&
        _cueForType(
              item: item,
              prompt: prompt,
              type: QuizType.typing,
              translationLanguageCode: translationLanguageCode,
            ) !=
            null) {
      types.add(QuizType.typing);
    }
    return types;
  }

  Set<QuizType> _typesForKind(QuizContentKind kind) {
    return quizTypesForKind(kind);
  }

  QuizType _pickType(List<QuizType> viable, Map<QuizType, int> typeUses) {
    if (viable.length == 1) {
      return viable.first;
    }
    int lowest = 1 << 30;
    final List<QuizType> preferred = <QuizType>[];
    for (final QuizType type in viable) {
      final int used = typeUses[type] ?? 0;
      if (used < lowest) {
        lowest = used;
        preferred
          ..clear()
          ..add(type);
      } else if (used == lowest) {
        preferred.add(type);
      }
    }
    return preferred[_random.nextInt(preferred.length)];
  }

  int _uniqueOptionCount({
    required QuizReadyItem item,
    required List<QuizReadyItem> optionPool,
    required String? translationLanguageCode,
    required bool reverse,
  }) {
    final Set<String> keys = <String>{};
    final String? correctText = reverse
        ? item.prompt.trim()
        : _meaningCue(item, translationLanguageCode);
    if (correctText == null || correctText.isEmpty) {
      return 0;
    }
    final String correctKey = QuizText.uniquenessKey(correctText);
    if (correctKey.isEmpty) {
      return 0;
    }
    keys.add(correctKey);
    final Set<String> blocked = _blockedOptionKeys(
      item: item,
      translationLanguageCode: translationLanguageCode,
    );
    for (final QuizReadyItem candidate in optionPool) {
      if (candidate.kind != item.kind || candidate.id == item.id) {
        continue;
      }
      final String? text = reverse
          ? candidate.prompt.trim()
          : _meaningCue(candidate, translationLanguageCode);
      if (text == null || text.isEmpty) {
        continue;
      }
      final String key = QuizText.uniquenessKey(text);
      if (key.isEmpty || blocked.contains(key)) {
        continue;
      }
      keys.add(key);
    }
    return keys.length;
  }

  List<QuizOption>? _choiceOptions({
    required QuizReadyItem item,
    required List<QuizReadyItem> optionPool,
    required int optionCount,
    required String? translationLanguageCode,
    required bool reverse,
  }) {
    final String? correctText = reverse
        ? item.prompt.trim()
        : _meaningCue(item, translationLanguageCode);
    if (correctText == null || correctText.isEmpty) {
      return null;
    }
    final String correctKey = QuizText.uniquenessKey(correctText);
    if (correctKey.isEmpty) {
      return null;
    }
    final List<QuizOption> options = <QuizOption>[
      QuizOption(id: item.id, text: correctText, isCorrect: true),
    ];
    final Set<String> usedKeys = <String>{correctKey};
    final Set<String> blocked = _blockedOptionKeys(
      item: item,
      translationLanguageCode: translationLanguageCode,
    );
    final List<QuizReadyItem> candidates = _shuffled(
      optionPool
          .where((QuizReadyItem other) {
            return other.kind == item.kind && other.id != item.id;
          })
          .toList(growable: false),
    );

    for (final QuizReadyItem candidate in candidates) {
      if (options.length >= optionCount) {
        break;
      }
      final String? text = reverse
          ? candidate.prompt.trim()
          : _meaningCue(candidate, translationLanguageCode);
      if (text == null || text.isEmpty) {
        continue;
      }
      final String key = QuizText.uniquenessKey(text);
      if (key.isEmpty || blocked.contains(key) || !usedKeys.add(key)) {
        continue;
      }
      options.add(QuizOption(id: candidate.id, text: text, isCorrect: false));
    }

    if (options.length < minChoiceOptions) {
      return null;
    }
    return List<QuizOption>.unmodifiable(_shuffled(options));
  }

  bool _canBuild(QuizContentKind kind, List<String> tokens) {
    if (kind != QuizContentKind.phrase) {
      return false;
    }
    return tokens.length >= minBuildTokens && tokens.length <= maxBuildTokens;
  }

  Set<String> _blockedOptionKeys({
    required QuizReadyItem item,
    required String? translationLanguageCode,
  }) {
    final Set<String> blocked = <String>{};
    final String promptKey = QuizText.uniquenessKey(item.prompt);
    if (promptKey.isNotEmpty) {
      blocked.add(promptKey);
    }
    final String? cue = _meaningCue(item, translationLanguageCode);
    if (cue != null) {
      final String cueKey = QuizText.uniquenessKey(cue);
      if (cueKey.isNotEmpty) {
        blocked.add(cueKey);
      }
    }
    final String? pronunciation = item.pronunciation?.trim();
    if (pronunciation != null && pronunciation.isNotEmpty) {
      final String spokenKey = QuizText.uniquenessKey(pronunciation);
      if (spokenKey.isNotEmpty) {
        blocked.add(spokenKey);
      }
    }
    return blocked;
  }

  String _tokenSeparator(String prompt) {
    return RegExp(r'\s').hasMatch(prompt.trim()) ? ' ' : '';
  }

  List<String> _shuffledTokens(List<String> tokens) {
    List<String> shuffled = _shuffled(tokens);
    if (tokens.length > 1) {
      int attempt = 0;
      while (_sameSequence(shuffled, tokens) && attempt < 8) {
        shuffled = _shuffled(tokens);
        attempt += 1;
      }
    }
    return List<String>.unmodifiable(shuffled);
  }

  bool _sameSequence(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (int index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  _ResolvedCue? _cueForType({
    required QuizReadyItem item,
    required String prompt,
    required QuizType type,
    required String? translationLanguageCode,
  }) {
    final String? meaning = _meaningCue(item, translationLanguageCode);
    if (meaning != null && _usableCue(prompt, meaning)) {
      return _ResolvedCue(text: meaning, fromPronunciation: false);
    }
    if (type == QuizType.multipleChoice) {
      return null;
    }
    final String? pronunciation = item.pronunciation?.trim();
    if (pronunciation != null && _usableCue(prompt, pronunciation)) {
      return _ResolvedCue(text: pronunciation, fromPronunciation: true);
    }
    return null;
  }

  bool _usableCue(String prompt, String? cue) {
    return cue != null &&
        cue.isNotEmpty &&
        !QuizText.isTrivialPair(prompt, cue);
  }

  /// Learner-language meaning. Never IPA, never a pronunciation fallback.
  String? _meaningCue(QuizReadyItem item, String? languageCode) {
    if (languageCode != null &&
        languageCode.isNotEmpty &&
        languageCode != 'pronunciation') {
      final String? direct = item.answersByLanguage[languageCode];
      if (direct != null && !QuizText.isBlank(direct)) {
        return direct.trim();
      }
      return null;
    }
    for (final MapEntry<String, String> entry
        in item.answersByLanguage.entries) {
      if (entry.key == 'pronunciation') {
        continue;
      }
      if (!QuizText.isBlank(entry.value)) {
        return entry.value.trim();
      }
    }
    return null;
  }

  bool _matches(QuizQuestion question, QuizAnswerInput input) {
    final String? optionId = input.optionId;
    if (optionId != null) {
      for (final QuizOption option in question.options) {
        if (option.id == optionId) {
          return option.isCorrect;
        }
      }
      return false;
    }

    final List<String>? tokens = input.tokens;
    if (tokens != null) {
      if (question.expectedTokens.isEmpty) {
        return false;
      }
      final String joined = QuizText.joinTokens(
        tokens,
        question.tokenSeparator,
      );
      if (QuizText.equals(
        joined,
        question.expectedAnswer,
        caseSensitive: question.caseSensitive,
      )) {
        return true;
      }
      if (tokens.length != question.expectedTokens.length) {
        return false;
      }
      for (int index = 0; index < tokens.length; index += 1) {
        if (!QuizText.equals(
          tokens[index],
          question.expectedTokens[index],
          caseSensitive: question.caseSensitive,
        )) {
          return false;
        }
      }
      return true;
    }

    final String? text = input.text;
    if (text == null) {
      return false;
    }
    return QuizText.equals(
      text,
      question.expectedAnswer,
      caseSensitive: question.caseSensitive,
    );
  }

  String _submittedText(QuizQuestion question, QuizAnswerInput input) {
    final String? optionId = input.optionId;
    if (optionId != null) {
      for (final QuizOption option in question.options) {
        if (option.id == optionId) {
          return option.text;
        }
      }
      return optionId;
    }
    final List<String>? tokens = input.tokens;
    if (tokens != null) {
      return QuizText.joinTokens(tokens, question.tokenSeparator);
    }
    return input.text ?? '';
  }

  List<T> _shuffled<T>(List<T> input) {
    final List<T> copy = List<T>.from(input);
    copy.shuffle(_random);
    return copy;
  }
}

final class _ResolvedCue {
  const _ResolvedCue({required this.text, required this.fromPronunciation});

  final String text;
  final bool fromPronunciation;

  ContentTextDirection directionFor(String? translationLanguageCode) {
    if (fromPronunciation) {
      return ContentTextDirection.ltr;
    }
    return QuizText.directionForLanguage(
      translationLanguageCode,
      fallback: ContentTextDirection.ltr,
    );
  }
}

/// Public service name for the reusable quiz engine.
typedef QuizService = QuizEngine;
