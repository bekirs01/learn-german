import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/app/lingo_navigation.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/wrong_answers.dart';
import 'package:lingo_core/features/home/home_artwork.dart';
import 'package:lingo_core/features/home/home_destination_card.dart';
import 'package:lingo_core/features/home/home_motivation_card.dart';
import 'package:lingo_core/features/home/home_quiz_launch.dart';
import 'package:lingo_core/features/home/wrong_answers_screen.dart';
import 'package:lingo_core/features/learn/alphabet_screen.dart';
import 'package:lingo_core/features/learn/phrase_categories_screen.dart';
import 'package:lingo_core/features/learn/word_categories_screen.dart';
import 'package:lingo_core/features/watch/watch_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const ValueKey<String> screenKey = ValueKey<String>('home-screen');
  static const ValueKey<String> alphabetKey = ValueKey<String>('home-alphabet');
  static const ValueKey<String> wordsKey = ValueKey<String>('home-words');
  static const ValueKey<String> phrasesKey = ValueKey<String>('home-phrases');
  static const ValueKey<String> quizKey = ValueKey<String>('home-quiz');
  static const ValueKey<String> wrongAnswersKey = ValueKey<String>(
    'home-wrong-answers',
  );
  static const ValueKey<String> appleWatchKey = ValueKey<String>(
    'home-apple-watch',
  );
  static const ValueKey<String> motivationKey = ValueKey<String>(
    'home-motivation',
  );

  @override
  Widget build(BuildContext context) {
    return LingoPage(
      showAppBar: false,
      body: ListenableBuilder(
        listenable: UserPreferences.instance,
        builder: (BuildContext context, Widget? _) {
          final ContentRepository content = ContentScope.of(context);
          final String language = ContentScope.translationLanguageOf(context);
          final int wrongCount = resolveWrongAnswers(
            UserPreferences.instance.getWrongAnswers(),
            content,
            languageCode: language,
          ).length;
          return _HomeDeck(
            wrongCount: wrongCount,
            onAlphabet: () {
              LingoNavigation.push(context, const AlphabetScreen());
            },
            onWords: () {
              LingoNavigation.push(context, const WordCategoriesScreen());
            },
            onPhrases: () {
              LingoNavigation.push(context, const PhraseCategoriesScreen());
            },
            onQuiz: () => openHomeQuiz(context),
            onWrongAnswers: () {
              LingoNavigation.push(
                context,
                const WrongAnswersScreen(key: WrongAnswersScreen.routeKey),
              );
            },
            onAppleWatch: () {
              LingoNavigation.push(
                context,
                const WatchScreen(key: WatchScreen.screenKey),
              );
            },
          );
        },
      ),
    );
  }
}

/// Compact 2×3 destinations above a daily quote.
class _HomeDeck extends StatelessWidget {
  const _HomeDeck({
    required this.wrongCount,
    required this.onAlphabet,
    required this.onWords,
    required this.onPhrases,
    required this.onQuiz,
    required this.onWrongAnswers,
    required this.onAppleWatch,
  });

  final int wrongCount;
  final VoidCallback onAlphabet;
  final VoidCallback onWords;
  final VoidCallback onPhrases;
  final VoidCallback onQuiz;
  final VoidCallback onWrongAnswers;
  final VoidCallback onAppleWatch;

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final double gap = metrics.categoryGridGap;
    final double topSafe = media.padding.top > media.viewPadding.top
        ? media.padding.top
        : media.viewPadding.top;
    final double top = topSafe + metrics.rootTopGap;
    // Keep every inset inside the scroller. Wrapping or shrinking the
    // viewport with SafeArea / outer padding clips the quote under the
    // floating tab bar (AppShell uses extendBody).
    final double navOverlay = media.padding.bottom > media.viewPadding.bottom
        ? media.padding.bottom
        : media.viewPadding.bottom;
    final double navClearance = navOverlay > metrics.floatingChromeClearance
        ? navOverlay
        : metrics.floatingChromeClearance;
    final double bottom = navClearance + LingoSpacing.lg;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        metrics.horizontalGutter,
        top,
        metrics.horizontalGutter,
        bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _grid(context, gap: gap),
          SizedBox(height: gap),
          KeyedSubtree(
            key: HomeScreen.motivationKey,
            child: const HomeMotivationQuote(),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, {required double gap}) {
    final List<List<Widget>> rows = <List<Widget>>[
      <Widget>[_alphabetCard(context), _wordsCard(context)],
      <Widget>[_phrasesCard(context), _quizCard(context)],
      <Widget>[_wrongCard(context), _watchCard(context)],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < rows.length; index++) ...<Widget>[
          if (index > 0) SizedBox(height: gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: rows[index][0]),
              SizedBox(width: gap),
              Expanded(child: rows[index][1]),
            ],
          ),
        ],
      ],
    );
  }

  Widget _alphabetCard(BuildContext context) {
    return HomeDestinationCard(
      key: HomeScreen.alphabetKey,
      label: UiStrings.of(context, UiKeys.navAlphabet),
      art: HomeDestinationArt.alphabet,
      onPressed: onAlphabet,
    );
  }

  Widget _wordsCard(BuildContext context) {
    return HomeDestinationCard(
      key: HomeScreen.wordsKey,
      label: UiStrings.of(context, UiKeys.navWords),
      art: HomeDestinationArt.words,
      onPressed: onWords,
    );
  }

  Widget _phrasesCard(BuildContext context) {
    return HomeDestinationCard(
      key: HomeScreen.phrasesKey,
      label: UiStrings.of(context, UiKeys.navPhrases),
      art: HomeDestinationArt.phrases,
      onPressed: onPhrases,
    );
  }

  Widget _quizCard(BuildContext context) {
    return HomeDestinationCard(
      key: HomeScreen.quizKey,
      label: UiStrings.of(context, UiKeys.quizTitle),
      art: HomeDestinationArt.quiz,
      onPressed: onQuiz,
    );
  }

  Widget _wrongCard(BuildContext context) {
    return HomeDestinationCard(
      key: HomeScreen.wrongAnswersKey,
      label: UiStrings.of(context, UiKeys.wrongAnswersTitle),
      art: HomeDestinationArt.wrongAnswers,
      detail: wrongCount > 0 ? '$wrongCount' : null,
      onPressed: onWrongAnswers,
    );
  }

  Widget _watchCard(BuildContext context) {
    return HomeDestinationCard(
      key: HomeScreen.appleWatchKey,
      label: UiStrings.of(context, UiKeys.watchTitle),
      art: HomeDestinationArt.appleWatch,
      onPressed: onAppleWatch,
    );
  }
}
