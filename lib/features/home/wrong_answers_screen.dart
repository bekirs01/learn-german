import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/wrong_answers.dart';
import 'package:lingo_core/features/quiz/quiz_launch.dart';

/// Review list for locally stored quiz misses.
class WrongAnswersScreen extends StatelessWidget {
  const WrongAnswersScreen({super.key});

  static const ValueKey<String> routeKey = ValueKey<String>(
    'wrong-answers-screen',
  );
  static const ValueKey<String> practiceKey = ValueKey<String>(
    'wrong-answers-practice',
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserPreferences.instance,
      builder: (BuildContext context, Widget? _) {
        final ContentRepository content = ContentScope.of(context);
        final String language = ContentScope.translationLanguageOf(context);
        final List<ResolvedWrongAnswer> items = resolveWrongAnswers(
          UserPreferences.instance.getWrongAnswers(),
          content,
          languageCode: language,
        );
        final List<QuizReadyItem> reviewItems = <QuizReadyItem>[
          for (final ResolvedWrongAnswer item in items)
            if (item.quizItem != null) item.quizItem!,
        ];
        final bool canPractice = reviewItems.isNotEmpty;

        return LingoPage(
          title: UiStrings.of(context, UiKeys.wrongAnswersTitle),
          body: LingoContent(
            storageKey: 'wrong-answers',
            children: <Widget>[
              if (items.isEmpty)
                LingoEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: UiStrings.of(context, UiKeys.wrongAnswersEmptyTitle),
                  message: UiStrings.of(
                    context,
                    UiKeys.wrongAnswersEmptyMessage,
                  ),
                )
              else ...<Widget>[
                if (canPractice) ...<Widget>[
                  LingoPrimaryButton(
                    key: practiceKey,
                    label: UiStrings.of(context, UiKeys.wrongAnswersPractice),
                    onPressed: () {
                      QuizEntry.open(
                        context: context,
                        items: reviewItems,
                        optionPool: content.quizItems,
                        title: UiStrings.of(
                          context,
                          UiKeys.wrongAnswersPractice,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: LingoSpacing.lg),
                ],
                ..._groupedChildren(context, items),
              ],
            ],
          ),
        );
      },
    );
  }
}

List<Widget> _groupedChildren(
  BuildContext context,
  List<ResolvedWrongAnswer> items,
) {
  final List<Widget> children = <Widget>[];
  const List<QuizContentKind> order = <QuizContentKind>[
    QuizContentKind.word,
    QuizContentKind.phrase,
    QuizContentKind.alphabet,
  ];
  for (final QuizContentKind kind in order) {
    final List<ResolvedWrongAnswer> group = items
        .where((ResolvedWrongAnswer item) => item.kind == kind)
        .toList(growable: false);
    if (group.isEmpty) {
      continue;
    }
    if (children.isNotEmpty) {
      children.add(const SizedBox(height: LingoSpacing.lg));
    }
    children.add(_GroupHeading(label: _groupLabel(context, kind)));
    children.add(const SizedBox(height: LingoSpacing.sm));
    for (int index = 0; index < group.length; index += 1) {
      if (index > 0) {
        children.add(const SizedBox(height: LingoSpacing.sm));
      }
      children.add(_WrongAnswerTile(item: group[index]));
    }
  }
  return children;
}

String _groupLabel(BuildContext context, QuizContentKind kind) {
  switch (kind) {
    case QuizContentKind.word:
      return UiStrings.of(context, UiKeys.navWords);
    case QuizContentKind.phrase:
      return UiStrings.of(context, UiKeys.navPhrases);
    case QuizContentKind.alphabet:
      return UiStrings.of(context, UiKeys.wrongAnswersCharacters);
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: theme.colors.onSurfaceMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.08,
      ),
    );
  }
}

class _WrongAnswerTile extends StatelessWidget {
  const _WrongAnswerTile({required this.item});

  final ResolvedWrongAnswer item;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final int count = item.record.wrongCount;
    final Widget? trailing = count > 1
        ? Text(
            UiStrings.of(
              context,
              UiKeys.wrongAnswersMissCount,
              params: <String, String>{'count': '$count'},
            ),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: theme.colors.onSurfaceFaint,
              fontWeight: FontWeight.w600,
            ),
          )
        : null;
    return LingoLearningCard(
      key: ValueKey<String>('wrong-answer-${item.contentId}'),
      title: item.targetText,
      subtitle: item.learnerCue,
      trailing: trailing,
    );
  }
}
