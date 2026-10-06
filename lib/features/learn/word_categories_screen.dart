import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/app/lingo_navigation.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/features/quiz/quiz_launch.dart';

class WordCategoriesScreen extends StatelessWidget {
  const WordCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserPreferences.instance,
      builder: (BuildContext context, Widget? _) {
        final LingoMetrics metrics = LingoMetrics.of(context);
        final ContentRepository content = ContentScope.of(context);
        final String language = ContentScope.translationLanguageOf(context);

        final bool nested = ModalRoute.of(context)?.canPop ?? false;
        return LingoPage(
          showAppBar: nested,
          title: nested ? UiStrings.of(context, UiKeys.navWords) : null,
          body: LingoContent(
            storageKey: 'words',
            topSafeArea: !nested,
            children: <Widget>[
              if (content.wordCategories.isEmpty)
                LingoEmptyState(
                  icon: Icons.auto_stories_rounded,
                  title: UiStrings.of(
                    context,
                    UiKeys.wordsEmptyCategoriesTitle,
                  ),
                  message: UiStrings.of(
                    context,
                    UiKeys.wordsEmptyCategoriesMessage,
                  ),
                )
              else
                LingoPairGrid(
                  spacing: metrics.categoryGridGap,
                  stack: metrics.stackCategoryGrid,
                  children: <Widget>[
                    for (final ContentCategory category
                        in content.wordCategories)
                      LingoCategoryCard(
                        label: content.labelFor(
                          category.id,
                          category.title,
                          languageCode: language,
                        ),
                        art: lingoArtKindFromName(category.artKind),
                        imageAsset: category.imageAsset,
                        onPressed: () {
                          LingoNavigation.push(
                            context,
                            WordCategoryScreen(category: category),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class WordCategoryScreen extends StatelessWidget {
  const WordCategoryScreen({super.key, required this.category});

  final ContentCategory category;

  @override
  Widget build(BuildContext context) {
    return PronunciationSession(
      child: ListenableBuilder(
        listenable: UserPreferences.instance,
        builder: (BuildContext context, Widget? _) {
          final LingoMetrics metrics = LingoMetrics.of(context);
          final ContentRepository content = ContentScope.of(context);
          final String language = ContentScope.translationLanguageOf(context);
          final List<WordEntry> items = content.wordsForCategory(category.id);
          final String title = content.labelFor(
            category.id,
            category.title,
            languageCode: language,
          );
          final TextDirection titleDirection = _packTextDirection(content.pack);

          return LingoPage(
            title: title,
            titleSpacing: LingoSpacing.sm,
            actions: <Widget>[
              QuizLaunchButton(
                onPressed: () {
                  final List<QuizReadyItem> pool = quizItemsOfKind(
                    content,
                    QuizContentKind.word,
                  );
                  openContentQuiz(
                    context: context,
                    title: title,
                    items: quizItemsWithIds(
                      content,
                      ids: items.map((WordEntry word) => word.id),
                      kind: QuizContentKind.word,
                    ),
                    optionPool: pool,
                  );
                },
              ),
            ],
            body: LingoContent(
              topInset: LingoSpacing.xs,
              itemGap: metrics.listRowGap,
              showScrollProgress: items.length > 8,
              header: LingoCategoryHero(
                art: lingoArtKindFromName(category.artKind),
                imageAsset: category.imageAsset,
              ),
              empty: LingoEmptyState(
                icon: Icons.auto_stories_rounded,
                title: UiStrings.of(context, UiKeys.wordsEmptyTitle),
                framed: false,
              ),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final WordEntry word = items[index];
                return LingoWordCard(
                  key: ValueKey<String>(word.id),
                  word: word.text,
                  pronunciation: word.pronunciation,
                  meaning: content.translation(word.id, languageCode: language),
                  detail: word.plural,
                  index: index + 1,
                  total: items.length,
                  titleDirection: titleDirection,
                  play: PronunciationControl(
                    key: ValueKey<String>('play-${word.id}'),
                    clip: PronunciationClip.fromWord(word),
                  ),
                  action: LingoFavoriteButton(
                    saved: content.isFavorite(word.id),
                    onPressed: () {
                      ContentScope.toggleFavorite(context, word.id);
                    },
                  ),
                  learned: content.isLearned(word.id),
                  learnedAction: LingoLearnedButton(
                    key: ValueKey<String>('learned-${word.id}'),
                    learned: content.isLearned(word.id),
                    onPressed: () {
                      ContentScope.toggleLearned(context, word.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

TextDirection _packTextDirection(LanguagePack pack) {
  return pack.textDirection == ContentTextDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
}
