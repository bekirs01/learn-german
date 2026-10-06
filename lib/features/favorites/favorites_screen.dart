import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';

enum _FavoritesSegment { words, phrases }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  _FavoritesSegment _segment = _FavoritesSegment.words;

  @override
  void dispose() {
    unawaited(PronunciationService.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserPreferences.instance,
      builder: (BuildContext context, Widget? _) {
        final ContentRepository content = ContentScope.of(context);
        final String language = ContentScope.translationLanguageOf(context);
        final bool showingWords = _segment == _FavoritesSegment.words;
        final List<WordEntry> words = UserPreferences.instance
            .getFavoriteWordIds()
            .map(content.wordById)
            .whereType<WordEntry>()
            .toList(growable: false);
        final List<PhraseEntry> phrases = UserPreferences.instance
            .getFavoritePhraseIds()
            .map(content.phraseById)
            .whereType<PhraseEntry>()
            .toList(growable: false);
        final int count = showingWords ? words.length : phrases.length;
        final TextDirection titleDirection = _packTextDirection(content.pack);
        final LingoMetrics metrics = LingoMetrics.of(context);

        return LingoPage(
          showAppBar: false,
          body: LingoContent(
            storageKey: 'favorites',
            topSafeArea: true,
            showScrollProgress: count > 8,
            itemGap: metrics.listRowGap,
            header: LingoSegmentedControl(
              labels: <String>[
                UiStrings.of(context, UiKeys.favoritesWords),
                UiStrings.of(context, UiKeys.favoritesPhrases),
              ],
              selectedIndex: _segment.index,
              onChanged: (int index) {
                unawaited(PronunciationService.instance.stop());
                setState(() => _segment = _FavoritesSegment.values[index]);
              },
            ),
            empty: LingoEmptyState(
              icon: showingWords
                  ? Icons.auto_stories_rounded
                  : Icons.chat_bubble_outline_rounded,
              title: showingWords
                  ? UiStrings.of(context, UiKeys.favoritesEmptyWords)
                  : UiStrings.of(context, UiKeys.favoritesEmptyPhrases),
            ),
            itemCount: count,
            itemBuilder: (BuildContext context, int index) {
              if (showingWords) {
                final WordEntry word = words[index];
                return LingoWordCard(
                  key: ValueKey<String>(word.id),
                  word: word.text,
                  pronunciation: word.pronunciation,
                  meaning: content.translation(word.id, languageCode: language),
                  detail: word.plural,
                  index: index + 1,
                  total: words.length,
                  titleDirection: titleDirection,
                  play: PronunciationControl(
                    key: ValueKey<String>('play-${word.id}'),
                    clip: PronunciationClip.fromWord(word),
                  ),
                  action: LingoFavoriteButton(
                    saved: true,
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
              }

              final PhraseEntry phrase = phrases[index];
              return LingoPhraseCard(
                key: ValueKey<String>(phrase.id),
                phrase: phrase.text,
                pronunciation: phrase.pronunciation,
                meaning: content.translation(phrase.id, languageCode: language),
                index: index + 1,
                total: phrases.length,
                titleDirection: titleDirection,
                play: PronunciationControl(
                  key: ValueKey<String>('play-${phrase.id}'),
                  clip: PronunciationClip.fromPhrase(phrase),
                ),
                action: LingoFavoriteButton(
                  saved: true,
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
    );
  }
}

TextDirection _packTextDirection(LanguagePack pack) {
  return pack.textDirection == ContentTextDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
}
