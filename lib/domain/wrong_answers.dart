import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/quiz_models.dart';

/// Compact on-device miss record. Identity is [contentId], never display text.
final class WrongAnswerRecord {
  const WrongAnswerRecord({
    required this.contentId,
    required this.kind,
    required this.wrongCount,
    this.lastWrongAtMillis,
    this.lastQuizType,
  });

  final String contentId;
  final QuizContentKind kind;
  final int wrongCount;
  final int? lastWrongAtMillis;
  final QuizType? lastQuizType;

  WrongAnswerRecord incremented({QuizType? quizType, int? atMillis}) {
    final int nextCount = wrongCount < 1 ? 2 : wrongCount + 1;
    return WrongAnswerRecord(
      contentId: contentId,
      kind: kind,
      wrongCount: nextCount,
      lastWrongAtMillis: atMillis ?? lastWrongAtMillis,
      lastQuizType: quizType ?? lastQuizType,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': contentId,
      'kind': kind.name,
      'count': wrongCount,
      if (lastWrongAtMillis != null) 'at': lastWrongAtMillis,
      if (lastQuizType != null) 'type': lastQuizType!.name,
    };
  }

  static WrongAnswerRecord? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final Object? idRaw = raw['id'] ?? raw['contentId'];
    if (idRaw is! String) {
      return null;
    }
    final String contentId = idRaw.trim();
    if (contentId.isEmpty) {
      return null;
    }
    final QuizContentKind? kind = _kindOf(raw['kind']);
    if (kind == null) {
      return null;
    }
    final int count = _countOf(raw['count'] ?? raw['wrongCount']);
    return WrongAnswerRecord(
      contentId: contentId,
      kind: kind,
      wrongCount: count,
      lastWrongAtMillis: _intOf(raw['at'] ?? raw['lastWrongAtMillis']),
      lastQuizType: _quizTypeOf(raw['type'] ?? raw['lastQuizType']),
    );
  }

  static QuizContentKind? _kindOf(Object? raw) {
    if (raw is! String) {
      return null;
    }
    for (final QuizContentKind kind in QuizContentKind.values) {
      if (kind.name == raw) {
        return kind;
      }
    }
    return null;
  }

  static QuizType? _quizTypeOf(Object? raw) {
    if (raw is! String) {
      return null;
    }
    for (final QuizType type in QuizType.values) {
      if (type.name == raw) {
        return type;
      }
    }
    return null;
  }

  static int _countOf(Object? raw) {
    final int? parsed = _intOf(raw);
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  static int? _intOf(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return null;
  }
}

/// Catalog view of a stored miss. Learner copy is resolved live.
final class ResolvedWrongAnswer {
  const ResolvedWrongAnswer({
    required this.record,
    required this.kind,
    required this.targetText,
    this.learnerCue,
    this.pronunciation,
    this.quizItem,
  });

  final WrongAnswerRecord record;
  final QuizContentKind kind;
  final String targetText;
  final String? learnerCue;
  final String? pronunciation;
  final QuizReadyItem? quizItem;

  String get contentId => record.contentId;

  bool get canReview => quizItem != null;
}

/// Maps stored IDs onto current pack content. Stale IDs are skipped.
List<ResolvedWrongAnswer> resolveWrongAnswers(
  Iterable<WrongAnswerRecord> records,
  ContentRepository content, {
  String? languageCode,
}) {
  final List<ResolvedWrongAnswer> resolved = <ResolvedWrongAnswer>[];
  for (final WrongAnswerRecord record in records) {
    final ResolvedWrongAnswer? item = _resolveOne(
      record,
      content,
      languageCode,
    );
    if (item != null) {
      resolved.add(item);
    }
  }
  return resolved;
}

Set<String> knownWrongAnswerIds(ContentRepository content) {
  return <String>{
    for (final AlphabetUnit unit in content.alphabet) unit.id,
    for (final ContentCategory category in content.wordCategories)
      for (final WordEntry word in content.wordsForCategory(category.id))
        word.id,
    for (final ContentCategory category in content.phraseCategories)
      for (final PhraseEntry phrase in content.phrasesForCategory(category.id))
        phrase.id,
  };
}

ResolvedWrongAnswer? _resolveOne(
  WrongAnswerRecord record,
  ContentRepository content,
  String? languageCode,
) {
  final WordEntry? word = content.wordById(record.contentId);
  if (word != null) {
    return ResolvedWrongAnswer(
      record: record,
      kind: QuizContentKind.word,
      targetText: word.text,
      learnerCue: content.translation(word.id, languageCode: languageCode),
      pronunciation: word.pronunciation,
      quizItem: word.quizEnabled
          ? _quizItem(
              content,
              id: word.id,
              kind: QuizContentKind.word,
              prompt: word.text,
              pronunciation: word.pronunciation,
              romanization: word.romanization,
              imageAsset: word.imageAsset,
              audioAsset: word.audioAsset,
            )
          : null,
    );
  }

  final PhraseEntry? phrase = content.phraseById(record.contentId);
  if (phrase != null) {
    return ResolvedWrongAnswer(
      record: record,
      kind: QuizContentKind.phrase,
      targetText: phrase.text,
      learnerCue: content.translation(phrase.id, languageCode: languageCode),
      pronunciation: phrase.pronunciation,
      quizItem: phrase.quizEnabled
          ? _quizItem(
              content,
              id: phrase.id,
              kind: QuizContentKind.phrase,
              prompt: phrase.text,
              pronunciation: phrase.pronunciation,
              romanization: phrase.romanization,
              imageAsset: phrase.imageAsset,
              audioAsset: phrase.audioAsset,
            )
          : null,
    );
  }

  final AlphabetUnit? unit = content.alphabetUnitById(record.contentId);
  if (unit != null) {
    return ResolvedWrongAnswer(
      record: record,
      kind: QuizContentKind.alphabet,
      targetText: unit.glyph,
      learnerCue:
          content.translation(unit.id, languageCode: languageCode) ??
          unit.pronunciation,
      pronunciation: unit.pronunciation,
      quizItem: unit.quizEnabled
          ? _quizItem(
              content,
              id: unit.id,
              kind: QuizContentKind.alphabet,
              prompt: unit.glyph,
              pronunciation: unit.pronunciation,
              romanization: unit.romanization,
              imageAsset: unit.imageAsset,
              audioAsset: unit.audioAsset,
              extra: unit.pronunciation,
            )
          : null,
    );
  }

  return null;
}

QuizReadyItem _quizItem(
  ContentRepository content, {
  required String id,
  required QuizContentKind kind,
  required String prompt,
  String? pronunciation,
  String? romanization,
  String? imageAsset,
  String? audioAsset,
  String? extra,
}) {
  return QuizReadyItem(
    id: id,
    kind: kind,
    prompt: prompt,
    pronunciation: pronunciation,
    romanization: romanization,
    imageAsset: imageAsset,
    audioAsset: audioAsset,
    answersByLanguage: _answersFor(content, id, extra: extra),
  );
}

Map<String, String> _answersFor(
  ContentRepository content,
  String id, {
  String? extra,
}) {
  final Map<String, String> answers = <String, String>{};
  for (final TranslationBundle bundle in content.translationBundles) {
    final String? value = bundle.strings[id];
    if (value != null) {
      answers[bundle.languageCode] = value;
    }
  }
  if (extra != null && extra.isNotEmpty) {
    answers.putIfAbsent('pronunciation', () => extra);
  }
  return Map<String, String>.unmodifiable(answers);
}
