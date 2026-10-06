import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/app/lingo_navigation.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_motion.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/quiz_engine.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/features/quiz/quiz_request.dart';
import 'package:lingo_core/features/quiz/quiz_screen.dart';
import 'package:lingo_core/features/quiz/quiz_type_picker.dart';
import 'package:lingo_core/features/quiz/wrong_answers_sync.dart';

export 'package:lingo_core/domain/quiz_models.dart'
    show QuizCorrectAnswer, QuizWrongAnswer;
export 'package:lingo_core/features/quiz/quiz_request.dart';

/// Public Quiz entry used by Home and learning lists.
///
/// Session language behavior:
/// - A new quiz captures the Translation Language at launch (questions and
///   chrome).
/// - Changing Translation Language while a quiz is already on screen does not
///   rebuild that session.
/// - The next launched quiz uses the newly selected learner language.
abstract final class QuizEntry {
  /// Opens a type picker when more than one format is viable, otherwise starts.
  static void open({
    required BuildContext context,
    required List<QuizReadyItem> items,
    List<QuizReadyItem>? optionPool,
    String? title,
    Iterable<QuizType>? allowedTypes,
    ValueChanged<QuizWrongAnswer>? onWrongAnswer,
    ValueChanged<QuizCorrectAnswer>? onCorrectAnswer,
  }) {
    final ContentRepository content = ContentScope.of(context);
    final QuizLaunchRequest request = QuizLaunchRequest(
      title: title ?? UiStrings.of(context, UiKeys.quizTitle),
      items: items,
      optionPool: optionPool ?? items,
      scriptFamily: content.pack.scriptFamily,
      textDirection: content.pack.textDirection,
      translationLanguageCode: ContentScope.translationLanguageOf(context),
      allowedTypes: allowedTypes?.toList(growable: false),
    );
    openQuizRequest(
      context,
      request,
      onWrongAnswer: onWrongAnswer,
      onCorrectAnswer: onCorrectAnswer,
    );
  }

  /// Formats that can actually produce a question from [items].
  static List<QuizType> viableTypes({
    required List<QuizReadyItem> items,
    List<QuizReadyItem>? optionPool,
    String? translationLanguageCode,
    Iterable<QuizType>? allowedTypes,
  }) {
    return QuizEngine().availableTypes(
      items: items,
      optionPool: optionPool,
      translationLanguageCode: translationLanguageCode,
      allowedTypes: allowedTypes,
    );
  }
}

/// Pushes a type picker when more than one format works, otherwise starts now.
void openContentQuiz({
  required BuildContext context,
  required String title,
  required List<QuizReadyItem> items,
  List<QuizReadyItem>? optionPool,
  ValueChanged<QuizWrongAnswer>? onWrongAnswer,
  ValueChanged<QuizCorrectAnswer>? onCorrectAnswer,
}) {
  QuizEntry.open(
    context: context,
    items: items,
    optionPool: optionPool,
    title: title,
    onWrongAnswer: onWrongAnswer,
    onCorrectAnswer: onCorrectAnswer,
  );
}

void openQuizRequest(
  BuildContext context,
  QuizLaunchRequest request, {
  ValueChanged<QuizWrongAnswer>? onWrongAnswer,
  ValueChanged<QuizCorrectAnswer>? onCorrectAnswer,
}) {
  final List<QuizType> types = QuizEngine().availableTypes(
    items: request.items,
    optionPool: request.optionPool,
    translationLanguageCode: request.translationLanguageCode,
    allowedTypes: request.allowedTypes,
  );
  if (types.length > 1 && request.allowedTypes == null) {
    LingoNavigation.push(
      context,
      QuizTypePickerScreen(
        request: request,
        types: types,
        onStart: (BuildContext pickerContext, QuizLaunchRequest next) {
          startQuizSession(
            pickerContext,
            next,
            replace: true,
            onWrongAnswer: onWrongAnswer,
            onCorrectAnswer: onCorrectAnswer,
          );
        },
      ),
    );
    return;
  }
  startQuizSession(
    context,
    request,
    onWrongAnswer: onWrongAnswer,
    onCorrectAnswer: onCorrectAnswer,
  );
}

void startQuizSession(
  BuildContext context,
  QuizLaunchRequest request, {
  bool replace = false,
  ValueChanged<QuizWrongAnswer>? onWrongAnswer,
  ValueChanged<QuizCorrectAnswer>? onCorrectAnswer,
}) {
  final String? language = _launchLanguage(context, request);
  final QuizStartResult start = QuizEngine().start(
    items: request.items,
    optionPool: request.optionPool,
    scriptFamily: request.scriptFamily,
    textDirection: request.textDirection,
    translationLanguageCode: language,
    title: request.title,
    allowedTypes: request.allowedTypes,
  );
  final QuizScreen page = QuizScreen(
    start: start,
    request: QuizLaunchRequest(
      title: request.title,
      items: request.items,
      optionPool: request.optionPool,
      scriptFamily: request.scriptFamily,
      textDirection: request.textDirection,
      translationLanguageCode: language,
      allowedTypes: request.allowedTypes,
    ),
    onWrongAnswer: (QuizWrongAnswer wrong) {
      unawaited(WrongAnswersSync.recordWrong(wrong));
      onWrongAnswer?.call(wrong);
    },
    onCorrectAnswer: (QuizCorrectAnswer correct) {
      unawaited(WrongAnswersSync.recordCorrect(correct));
      onCorrectAnswer?.call(correct);
    },
  );
  if (replace) {
    Navigator.of(
      context,
    ).pushReplacement<void, void>(LingoNavigation.route(context, page));
    return;
  }
  LingoNavigation.push(context, page);
}

class QuizLaunchButton extends StatelessWidget {
  const QuizLaunchButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String label = UiStrings.of(context, UiKeys.quizTitle);
    return Semantics(
      button: true,
      label: label,
      tooltip: label,
      child: Tooltip(
        message: label,
        child: LingoTapScale(
          onPressed: onPressed,
          child: SizedBox(
            width: LingoSpacing.minTapTarget,
            height: LingoSpacing.minTapTarget,
            child: Icon(
              Icons.quiz_outlined,
              color: LingoTheme.of(context).colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

String? _launchLanguage(BuildContext context, QuizLaunchRequest request) {
  try {
    return ContentScope.translationLanguageOf(context);
  } on StateError {
    return request.translationLanguageCode;
  }
}
