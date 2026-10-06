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

class PhraseCategoriesScreen extends StatelessWidget {
  const PhraseCategoriesScreen({super.key});

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
          title: nested ? UiStrings.of(context, UiKeys.navPhrases) : null,
          body: LingoContent(
            storageKey: 'phrases',
            topSafeArea: !nested,
            children: <Widget>[
              if (content.phraseCategories.isEmpty)
                LingoEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: UiStrings.of(
                    context,
                    UiKeys.phrasesEmptyCategoriesTitle,
                  ),
                  message: UiStrings.of(
                    context,
                    UiKeys.phrasesEmptyCategoriesMessage,
                  ),
                )
              else
                LingoPairGrid(
                  spacing: metrics.categoryGridGap,
                  stack: metrics.stackCategoryGrid,
                  children: <Widget>[
                    for (final ContentCategory category
                        in content.phraseCategories)
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
                            PhraseCategoryScreen(category: category),
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

class PhraseCategoryScreen extends StatelessWidget {
  const PhraseCategoryScreen({super.key, required this.category});

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
          final List<PhraseEntry> items = content.phrasesForCategory(
            category.id,
          );
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
                    QuizContentKind.phrase,
                  );
                  openContentQuiz(
                    context: context,
                    title: title,
                    items: quizItemsWithIds(
                      content,
                      ids: items.map((PhraseEntry phrase) => phrase.id),
                      kind: QuizContentKind.phrase,
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
                icon: Icons.chat_bubble_outline_rounded,
                title: UiStrings.of(context, UiKeys.phrasesEmptyTitle),
                framed: false,
              ),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final PhraseEntry phrase = items[index];
                return LingoPhraseCard(
                  key: ValueKey<String>(phrase.id),
                  phrase: phrase.text,
                  pronunciation: phrase.pronunciation,
                  meaning: content.translation(
                    phrase.id,
                    languageCode: language,
                  ),
                  index: index + 1,
                  total: items.length,
                  titleDirection: titleDirection,
                  play: PronunciationControl(
                    key: ValueKey<String>('play-${phrase.id}'),
                    clip: PronunciationClip.fromPhrase(phrase),
                  ),
                  action: LingoFavoriteButton(
                    saved: content.isFavorite(phrase.id),
                    onPressed: () {
                      ContentScope.toggleFavorite(context, phrase.id);
                    },
                  ),
                  learned: content.isLearned(phrase.id),
                  learnedAction: LingoLearnedButton(
                    key: ValueKey<String>('learned-${phrase.id}'),
                    learned: content.isLearned(phrase.id),
                    onPressed: () {
                      ContentScope.toggleLearned(context, phrase.id);
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
