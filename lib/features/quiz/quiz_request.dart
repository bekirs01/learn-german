import 'package:flutter/material.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/quiz_models.dart';

/// In-memory launch parameters. Wrong-answer persistence is applied by
/// launch wiring, not this object.
final class QuizLaunchRequest {
  const QuizLaunchRequest({
    required this.title,
    required this.items,
    required this.optionPool,
    required this.scriptFamily,
    required this.textDirection,
    this.translationLanguageCode,
    this.allowedTypes,
  });

  final String title;
  final List<QuizReadyItem> items;
  final List<QuizReadyItem> optionPool;
  final ScriptFamily scriptFamily;
  final ContentTextDirection textDirection;
  final String? translationLanguageCode;
  final List<QuizType>? allowedTypes;

  QuizLaunchRequest copyWith({List<QuizType>? allowedTypes}) {
    return QuizLaunchRequest(
      title: title,
      items: items,
      optionPool: optionPool,
      scriptFamily: scriptFamily,
      textDirection: textDirection,
      translationLanguageCode: translationLanguageCode,
      allowedTypes: allowedTypes ?? this.allowedTypes,
    );
  }
}

List<QuizReadyItem> quizItemsOfKind(
  ContentRepository content,
  QuizContentKind kind,
) {
  return content.quizItems
      .where((QuizReadyItem item) => item.kind == kind)
      .toList(growable: false);
}

List<QuizReadyItem> quizItemsWithIds(
  ContentRepository content, {
  required Iterable<String> ids,
  QuizContentKind? kind,
}) {
  final Set<String> wanted = ids.toSet();
  return content.quizItems
      .where((QuizReadyItem item) {
        if (!wanted.contains(item.id)) {
          return false;
        }
        if (kind != null && item.kind != kind) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

String quizTypeLabel(
  QuizType type, {
  QuizContentKind? kind,
  BuildContext? context,
  String? languageCode,
}) {
  final String Function(String key) t = _quizCopy(
    context,
    languageCode: languageCode,
  );
  switch (type) {
    case QuizType.multipleChoice:
      return t(UiKeys.quizMultipleChoice);
    case QuizType.reverseMultipleChoice:
      return t(UiKeys.quizReverseMultipleChoice);
    case QuizType.buildSequence:
      if (kind == QuizContentKind.phrase) {
        return t(UiKeys.quizBuildPhrase);
      }
      if (kind == QuizContentKind.word) {
        return t(UiKeys.quizBuildWord);
      }
      return t(UiKeys.quizBuildAnswer);
    case QuizType.typing:
      return t(UiKeys.quizTypeAnswer);
  }
}

String quizTypeSubtitle(
  QuizType type, {
  BuildContext? context,
  String? languageCode,
}) {
  final String Function(String key) t = _quizCopy(
    context,
    languageCode: languageCode,
  );
  switch (type) {
    case QuizType.multipleChoice:
      return t(UiKeys.quizMultipleChoiceDescription);
    case QuizType.reverseMultipleChoice:
      return t(UiKeys.quizReverseMultipleChoiceDescription);
    case QuizType.buildSequence:
      return t(UiKeys.quizBuildDescription);
    case QuizType.typing:
      return t(UiKeys.quizTypeDescription);
  }
}

String Function(String key) _quizCopy(
  BuildContext? context, {
  String? languageCode,
}) {
  if (context != null) {
    return (String key) => UiStrings.of(context, key);
  }
  return (String key) => UiStrings.resolve(key, languageCode: languageCode);
}

QuizContentKind? sharedContentKind(List<QuizReadyItem> items) {
  if (items.isEmpty) {
    return null;
  }
  final QuizContentKind kind = items.first.kind;
  for (final QuizReadyItem item in items) {
    if (item.kind != kind) {
      return null;
    }
  }
  return kind;
}

List<QuizType> visibleQuizTypes({
  required Iterable<QuizType> types,
  QuizContentKind? kind,
}) {
  if (kind == null) {
    return List<QuizType>.from(types);
  }
  final Set<QuizType> allowed = quizTypesForKind(kind);
  return types.where(allowed.contains).toList(growable: false);
}
