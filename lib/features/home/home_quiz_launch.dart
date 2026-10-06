import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/app/lingo_navigation.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/features/quiz/quiz_launch.dart';
import 'package:lingo_core/features/quiz/quiz_widgets.dart';

/// Home adapter around the public Quiz launch API.
///
/// Asks Words vs Phrases first, then hands the chosen set to [QuizEntry.open].
void openHomeQuiz(BuildContext context) {
  LingoNavigation.push(context, const HomeQuizSourceScreen());
}

void openHomeQuizSource(BuildContext context, QuizContentKind kind) {
  final ContentRepository content = ContentScope.of(context);
  final List<QuizReadyItem> items = quizItemsOfKind(content, kind);
  QuizEntry.open(
    context: context,
    items: items,
    optionPool: items,
    title: UiStrings.of(context, UiKeys.quizTitle),
  );
}

/// Home-level source step. Does not reach into Quiz engine internals.
class HomeQuizSourceScreen extends StatelessWidget {
  const HomeQuizSourceScreen({super.key});

  static const ValueKey<String> screenKey = ValueKey<String>(
    'home-quiz-source',
  );
  static const ValueKey<String> wordsKey = ValueKey<String>(
    'home-quiz-source-words',
  );
  static const ValueKey<String> phrasesKey = ValueKey<String>(
    'home-quiz-source-phrases',
  );

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final double gap = metrics.isCompact
        ? LingoSpacing.md
        : metrics.cardSpacing;
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
                  UiStrings.of(context, UiKeys.quizPractice),
                  style: textTheme.titleLarge,
                ),
                SizedBox(height: gap),
                LingoLearningCard(
                  key: wordsKey,
                  title: UiStrings.of(context, UiKeys.navWords),
                  trailing: const QuizPickerChevron(),
                  onPressed: () {
                    openHomeQuizSource(context, QuizContentKind.word);
                  },
                ),
                SizedBox(height: gap),
                LingoLearningCard(
                  key: phrasesKey,
                  title: UiStrings.of(context, UiKeys.navPhrases),
                  trailing: const QuizPickerChevron(),
                  onPressed: () {
                    openHomeQuizSource(context, QuizContentKind.phrase);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
