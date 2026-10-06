import 'package:flutter/material.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/features/quiz/quiz_request.dart';
import 'package:lingo_core/features/quiz/quiz_widgets.dart';

/// Lets the learner pick a format, then starts the quiz immediately.
class QuizTypePickerScreen extends StatelessWidget {
  const QuizTypePickerScreen({
    super.key,
    required this.request,
    required this.types,
    required this.onStart,
  });

  static const ValueKey<String> mixedKey = ValueKey<String>('quiz-type-mixed');

  final QuizLaunchRequest request;
  final List<QuizType> types;
  final void Function(BuildContext context, QuizLaunchRequest request) onStart;

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final QuizContentKind? kind = sharedContentKind(request.items);
    final List<QuizType> visible = visibleQuizTypes(types: types, kind: kind);
    final double gap = metrics.isCompact ? LingoSpacing.sm : LingoSpacing.md;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return LingoPage(
      showAppBar: false,
      body: Column(
        children: <Widget>[
          const QuizTopBar(),
          Expanded(
            child: LingoContent(
              topInset: 0,
              children: <Widget>[
                Text(
                  UiStrings.of(context, UiKeys.quizChoose),
                  style: textTheme.titleLarge,
                ),
                SizedBox(height: gap),
                LingoLearningCard(
                  key: mixedKey,
                  title: UiStrings.of(context, UiKeys.quizMixed),
                  subtitle: UiStrings.of(context, UiKeys.quizMixedDescription),
                  trailing: const QuizPickerChevron(),
                  onPressed: () => onStart(context, request),
                ),
                for (final QuizType type in visible) ...<Widget>[
                  SizedBox(height: gap),
                  LingoLearningCard(
                    key: ValueKey<String>('quiz-type-${type.name}'),
                    title: quizTypeLabel(type, kind: kind, context: context),
                    subtitle: quizTypeSubtitle(type, context: context),
                    trailing: const QuizPickerChevron(),
                    onPressed: () {
                      onStart(
                        context,
                        request.copyWith(allowedTypes: <QuizType>[type]),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
