import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/quiz_models.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/domain/wrong_answers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(UserPreferences.resetForTest);

  group('first launch', () {
    test('uses defaults when nothing is stored', () {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      expect(prefs.getSelectedTranslationLanguage(), 'en');
      expect(prefs.getFavoriteWordIds(), isEmpty);
      expect(prefs.getFavoritePhraseIds(), isEmpty);
      expect(prefs.getLearnedWordIds(), isEmpty);
      expect(prefs.getLearnedPhraseIds(), isEmpty);
      expect(prefs.getWrongAnswers(), isEmpty);
      expect(prefs.getSoundEnabled(), isTrue);
      expect(prefs.getHapticsEnabled(), isTrue);
      expect(prefs.getWatchDraft().selectedIds, isEmpty);
      expect(prefs.getWatchDraft().kind, QuizContentKind.word);
      expect(prefs.getWatchDraft().deliveriesPerDay, 5);
      expect(prefs.getWatchDraft().windowStartMinutes, 9 * 60);
      expect(prefs.getWatchDraft().windowEndMinutes, 21 * 60);
    });
  });

  group('translation language', () {
    test('saves and loads the selected language', () async {
      final MemoryPreferenceStore store = MemoryPreferenceStore();
      final UserPreferences prefs = UserPreferences(store: store);

      await prefs.setSelectedTranslationLanguage('tr');
      expect(prefs.getSelectedTranslationLanguage(), 'tr');

      final UserPreferences reloaded = UserPreferences(store: store);
      expect(reloaded.getSelectedTranslationLanguage(), 'tr');
    });

    test('ignores an unsupported language instead of persisting it', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.setSelectedTranslationLanguage('not-a-language');
      expect(prefs.getSelectedTranslationLanguage(), 'en');
    });
  });

  group('favorites', () {
    test('adds and removes word and phrase IDs', () async {
      final MemoryPreferenceStore store = MemoryPreferenceStore();
      final UserPreferences prefs = UserPreferences(store: store);

      await prefs.addFavoriteWord('word.hello');
      await prefs.addFavoritePhrase('phrase.how_are_you');
      expect(prefs.getFavoriteWordIds(), <String>{'word.hello'});
      expect(prefs.getFavoritePhraseIds(), <String>{'phrase.how_are_you'});

      await prefs.removeFavoriteWord('word.hello');
      await prefs.removeFavoritePhrase('phrase.how_are_you');
      expect(prefs.getFavoriteWordIds(), isEmpty);
      expect(prefs.getFavoritePhraseIds(), isEmpty);

      final UserPreferences reloaded = UserPreferences(store: store);
      expect(reloaded.getFavoriteWordIds(), isEmpty);
      expect(reloaded.getFavoritePhraseIds(), isEmpty);
    });

    test('does not store duplicate favorite IDs', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.addFavoriteWord('word.hello');
      await prefs.addFavoriteWord(' word.hello ');
      await prefs.addFavoritePhrase('phrase.hello');
      await prefs.addFavoritePhrase('phrase.hello');

      expect(prefs.getFavoriteWordIds(), <String>{'word.hello'});
      expect(prefs.getFavoritePhraseIds(), <String>{'phrase.hello'});
    });

    test('drops removed content IDs', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.addFavoriteWord('word.hello');
      await prefs.addFavoriteWord('word.retired');
      await prefs.addFavoritePhrase('phrase.hello');
      await prefs.addFavoritePhrase('phrase.retired');

      await prefs.pruneUnknownFavorites(
        wordIds: <String>{'word.hello'},
        phraseIds: <String>{'phrase.hello'},
      );

      expect(prefs.getFavoriteWordIds(), <String>{'word.hello'});
      expect(prefs.getFavoritePhraseIds(), <String>{'phrase.hello'});
    });
  });

  group('learned', () {
    test('adds and removes word and phrase IDs', () async {
      final MemoryPreferenceStore store = MemoryPreferenceStore();
      final UserPreferences prefs = UserPreferences(store: store);

      await prefs.addLearnedWord('word.hello');
      await prefs.addLearnedPhrase('phrase.how_are_you');
      expect(prefs.getLearnedWordIds(), <String>{'word.hello'});
      expect(prefs.getLearnedPhraseIds(), <String>{'phrase.how_are_you'});

      await prefs.removeLearnedWord('word.hello');
      await prefs.removeLearnedPhrase('phrase.how_are_you');
      expect(prefs.getLearnedWordIds(), isEmpty);
      expect(prefs.getLearnedPhraseIds(), isEmpty);

      final UserPreferences reloaded = UserPreferences(store: store);
      expect(reloaded.getLearnedWordIds(), isEmpty);
      expect(reloaded.getLearnedPhraseIds(), isEmpty);
    });

    test('does not store duplicate learned IDs', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.addLearnedWord('word.hello');
      await prefs.addLearnedWord(' word.hello ');
      await prefs.addLearnedPhrase('phrase.hello');
      await prefs.addLearnedPhrase('phrase.hello');

      expect(prefs.getLearnedWordIds(), <String>{'word.hello'});
      expect(prefs.getLearnedPhraseIds(), <String>{'phrase.hello'});
    });

    test('keeps IDs when the translation language changes', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.addLearnedWord('word.hello');
      await prefs.addLearnedPhrase('phrase.hello');
      await prefs.setSelectedTranslationLanguage('tr');
      await prefs.setSelectedTranslationLanguage('ar');

      expect(prefs.getSelectedTranslationLanguage(), 'ar');
      expect(prefs.getLearnedWordIds(), <String>{'word.hello'});
      expect(prefs.getLearnedPhraseIds(), <String>{'phrase.hello'});
    });

    test('drops removed content IDs without crashing', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.addLearnedWord('word.hello');
      await prefs.addLearnedWord('word.retired');
      await prefs.addLearnedPhrase('phrase.hello');
      await prefs.addLearnedPhrase('phrase.retired');

      await prefs.pruneUnknownLearned(
        wordIds: <String>{'word.hello'},
        phraseIds: <String>{'phrase.hello'},
      );

      expect(prefs.getLearnedWordIds(), <String>{'word.hello'});
      expect(prefs.getLearnedPhraseIds(), <String>{'phrase.hello'});
    });
  });

  group('wrong answers', () {
    test('stores a miss, increments count, and never duplicates', () async {
      final MemoryPreferenceStore store = MemoryPreferenceStore();
      final UserPreferences prefs = UserPreferences(store: store);

      await prefs.recordWrongAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
        quizType: QuizType.multipleChoice,
        atMillis: 10,
      );
      await prefs.recordWrongAnswer(
        contentId: ' word.basics.hello ',
        kind: QuizContentKind.word,
        quizType: QuizType.typing,
        atMillis: 20,
      );

      expect(prefs.getWrongAnswers(), hasLength(1));
      final WrongAnswerRecord stored = prefs.getWrongAnswers().single;
      expect(stored.contentId, 'word.basics.hello');
      expect(stored.kind, QuizContentKind.word);
      expect(stored.wrongCount, 2);
      expect(stored.lastWrongAtMillis, 20);
      expect(stored.lastQuizType, QuizType.typing);

      final UserPreferences reloaded = UserPreferences(store: store);
      expect(reloaded.getWrongAnswers(), hasLength(1));
      expect(reloaded.getWrongAnswers().single.wrongCount, 2);
    });

    test('removes only the item answered correctly', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.recordWrongAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
      );
      await prefs.recordWrongAnswer(
        contentId: 'phrase.greetings.hello',
        kind: QuizContentKind.phrase,
      );
      await prefs.recordCorrectAnswer('word.basics.yes');
      expect(prefs.getWrongAnswerCount(), 2);

      await prefs.recordCorrectAnswer('word.basics.hello');
      expect(
        prefs.getWrongAnswers().map((WrongAnswerRecord item) => item.contentId),
        <String>['phrase.greetings.hello'],
      );
    });

    test('keeps IDs when the translation language changes', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.recordWrongAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
      );
      await prefs.setSelectedTranslationLanguage('tr');

      expect(prefs.getSelectedTranslationLanguage(), 'tr');
      expect(prefs.getWrongAnswers().single.contentId, 'word.basics.hello');
    });

    test('prunes stale IDs without crashing', () async {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(),
      );

      await prefs.recordWrongAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
      );
      await prefs.recordWrongAnswer(
        contentId: 'word.retired',
        kind: QuizContentKind.word,
      );
      await prefs.recordWrongAnswer(
        contentId: 'letter.gone',
        kind: QuizContentKind.alphabet,
      );

      await prefs.pruneUnknownWrongAnswers(<String>{'word.basics.hello'});
      expect(prefs.getWrongAnswers().single.contentId, 'word.basics.hello');
    });

    test('recovers a JSON-encoded list and skips junk', () {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(<String, Object?>{
          'lingo.user.wrongAnswers':
              '[{"id":"word.basics.hello","kind":"word","count":3},'
              '{"id":"word.basics.hello","kind":"word","count":9},'
              '{"kind":"word"},{"id":"broken","kind":"nope"}]',
        }),
      );

      expect(prefs.getWrongAnswers(), hasLength(1));
      expect(prefs.getWrongAnswers().single.contentId, 'word.basics.hello');
      expect(prefs.getWrongAnswers().single.wrongCount, 3);
    });
  });

  group('toggles', () {
    test('saves and loads the sound toggle', () async {
      final MemoryPreferenceStore store = MemoryPreferenceStore();
      final UserPreferences prefs = UserPreferences(store: store);

      await prefs.setSoundEnabled(false);
      expect(prefs.getSoundEnabled(), isFalse);

      final UserPreferences reloaded = UserPreferences(store: store);
      expect(reloaded.getSoundEnabled(), isFalse);

      await reloaded.setSoundEnabled(true);
      expect(reloaded.getSoundEnabled(), isTrue);
    });

    test('saves and loads the haptics toggle', () async {
      final MemoryPreferenceStore store = MemoryPreferenceStore();
      final UserPreferences prefs = UserPreferences(store: store);

      await prefs.setHapticsEnabled(false);
      expect(prefs.getHapticsEnabled(), isFalse);

      final UserPreferences reloaded = UserPreferences(store: store);
      expect(reloaded.getHapticsEnabled(), isFalse);

      await reloaded.setHapticsEnabled(true);
      expect(reloaded.getHapticsEnabled(), isTrue);
    });
  });

  group('corrupted or missing values', () {
    test('falls back to defaults for missing and invalid payloads', () {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(<String, Object?>{
          'lingo.user.translationLanguage': 12,
          'lingo.user.favoriteWordIds': 'not-json',
          'lingo.user.favoritePhraseIds': <Object>[42, '', '  ', 'phrase.ok'],
          'lingo.user.learnedWordIds': 'not-json',
          'lingo.user.learnedPhraseIds': <Object>[42, '', '  ', 'phrase.ok'],
          'lingo.user.soundEnabled': 'yes',
          'lingo.user.hapticsEnabled': <String>['true'],
        }),
      );

      expect(prefs.getSelectedTranslationLanguage(), 'en');
      expect(prefs.getFavoriteWordIds(), isEmpty);
      expect(prefs.getFavoritePhraseIds(), <String>{'phrase.ok'});
      expect(prefs.getLearnedWordIds(), isEmpty);
      expect(prefs.getLearnedPhraseIds(), <String>{'phrase.ok'});
      expect(prefs.getWrongAnswers(), isEmpty);
      expect(prefs.getSoundEnabled(), isTrue);
      expect(prefs.getHapticsEnabled(), isTrue);
    });

    test('recovers a JSON-encoded favorite list', () {
      final UserPreferences prefs = UserPreferences(
        store: MemoryPreferenceStore(<String, Object?>{
          'lingo.user.favoriteWordIds': '["word.hello","word.hello",""]',
          'lingo.user.learnedWordIds': '["word.hello","word.hello",""]',
          'lingo.user.translationLanguage': ' TR ',
        }),
      );

      expect(prefs.getFavoriteWordIds(), <String>{'word.hello'});
      expect(prefs.getLearnedWordIds(), <String>{'word.hello'});
      expect(prefs.getSelectedTranslationLanguage(), 'tr');
    });
  });

  group('device store', () {
    test('bootstraps shared preferences and reloads saved values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final UserPreferences prefs = await UserPreferences.bootstrap();

      await prefs.setSelectedTranslationLanguage('tr');
      await prefs.addFavoriteWord('word.hello');
      await prefs.addLearnedWord('word.hello');
      await prefs.recordWrongAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
      );
      await prefs.setSoundEnabled(false);
      await prefs.setHapticsEnabled(false);

      final UserPreferences reloaded = await UserPreferences.bootstrap();
      expect(reloaded.getSelectedTranslationLanguage(), 'tr');
      expect(reloaded.getFavoriteWordIds(), <String>{'word.hello'});
      expect(reloaded.getLearnedWordIds(), <String>{'word.hello'});
      expect(reloaded.getWrongAnswers().single.contentId, 'word.basics.hello');
      expect(reloaded.getSoundEnabled(), isFalse);
      expect(reloaded.getHapticsEnabled(), isFalse);
    });
  });

  group('content IDs', () {
    setUp(() {
      LocalContentRepository.clearCache();
      UserPreferences.resetForTest();
    });

    tearDown(LocalContentRepository.clearCache);

    test(
      'persists catalog word and phrase IDs and drops removed ones',
      () async {
        final LocalContentRepository repo = await LocalContentRepository.load();
        final WordEntry word = repo
            .wordsForCategory(repo.wordCategories.first.id)
            .first;
        final PhraseEntry phrase = repo
            .phrasesForCategory(repo.phraseCategories.first.id)
            .first;

        repo.setFavorite(word.id, true);
        repo.setFavorite(phrase.id, true);
        repo.setFavorite('missing.id', true);
        repo.setLearned(word.id, true);
        repo.setLearned(phrase.id, true);
        repo.setLearned('missing.id', true);
        await UserPreferences.instance.flushWrites();

        expect(repo.isFavorite(word.id), isTrue);
        expect(repo.isFavorite(phrase.id), isTrue);
        expect(repo.isFavorite('missing.id'), isFalse);
        expect(repo.isLearned(word.id), isTrue);
        expect(repo.isLearned(phrase.id), isTrue);
        expect(repo.isLearned('missing.id'), isFalse);
        expect(UserPreferences.instance.getFavoriteWordIds(), <String>{
          word.id,
        });
        expect(UserPreferences.instance.getFavoritePhraseIds(), <String>{
          phrase.id,
        });
        expect(UserPreferences.instance.getLearnedWordIds(), <String>{word.id});
        expect(UserPreferences.instance.getLearnedPhraseIds(), <String>{
          phrase.id,
        });

        await UserPreferences.instance.addFavoriteWord('word.removed');
        await UserPreferences.instance.addLearnedWord('word.removed');
        LocalContentRepository.clearCache();
        final LocalContentRepository reloaded =
            await LocalContentRepository.load();

        expect(reloaded.isFavorite(word.id), isTrue);
        expect(reloaded.isFavorite('word.removed'), isFalse);
        expect(reloaded.isLearned(word.id), isTrue);
        expect(reloaded.isLearned('word.removed'), isFalse);
        expect(
          UserPreferences.instance.getFavoriteWordIds(),
          isNot(contains('word.removed')),
        );
        expect(
          UserPreferences.instance.getLearnedWordIds(),
          isNot(contains('word.removed')),
        );
      },
    );

    test('prunes stale wrong-answer IDs on catalog load', () async {
      await UserPreferences.instance.recordWrongAnswer(
        contentId: 'word.basics.hello',
        kind: QuizContentKind.word,
      );
      await UserPreferences.instance.recordWrongAnswer(
        contentId: 'word.removed',
        kind: QuizContentKind.word,
      );
      await UserPreferences.instance.recordWrongAnswer(
        contentId: 'letter.a',
        kind: QuizContentKind.alphabet,
      );
      await UserPreferences.instance.flushWrites();

      final LocalContentRepository repo = await LocalContentRepository.load();
      expect(
        UserPreferences.instance.getWrongAnswers().map(
          (WrongAnswerRecord item) => item.contentId,
        ),
        unorderedEquals(<String>['word.basics.hello', 'letter.a']),
      );
      expect(
        resolveWrongAnswers(
          UserPreferences.instance.getWrongAnswers(),
          repo,
        ).map((ResolvedWrongAnswer item) => item.contentId),
        unorderedEquals(<String>['word.basics.hello', 'letter.a']),
      );
    });
  });

  group('watch draft', () {
    test('persists selected IDs, kind, and schedule', () async {
      final MemoryPreferenceStore store = MemoryPreferenceStore();
      final UserPreferences prefs = UserPreferences(store: store);

      await prefs.setWatchDraft(
        WatchCompanionDraft.initial.copyWith(
          filter: WatchContentFilter.phrases,
          wordIds: <String>{'word.basics.hello'},
          phraseIds: <String>{'phrase.greetings.good_morning'},
          scheduleEnabled: false,
          windowStartMinutes: 10 * 60,
          windowEndMinutes: 20 * 60,
          deliveriesPerDay: 3,
          lastSyncOutcome: WatchSyncOutcome.saved,
          lastSyncAtEpochMs: 123,
        ),
      );
      expect(prefs.getWatchDraft().kind, QuizContentKind.phrase);
      expect(prefs.getWatchDraft().filter, WatchContentFilter.phrases);
      expect(prefs.getWatchDraft().wordIds, <String>{'word.basics.hello'});
      expect(prefs.getWatchDraft().selectedIds, <String>{
        'phrase.greetings.good_morning',
      });
      expect(prefs.getWatchDraft().deliveriesPerDay, 3);
      expect(prefs.getWatchDraft().scheduleEnabled, isFalse);
      expect(prefs.getWatchDraft().lastSyncOutcome, WatchSyncOutcome.saved);

      final UserPreferences reloaded = UserPreferences(store: store);
      expect(reloaded.getWatchDraft().kind, QuizContentKind.phrase);
      expect(reloaded.getWatchDraft().filter, WatchContentFilter.phrases);
      expect(reloaded.getWatchDraft().wordIds, <String>{'word.basics.hello'});
      expect(reloaded.getWatchDraft().phraseIds, <String>{
        'phrase.greetings.good_morning',
      });
      expect(reloaded.getWatchDraft().windowStartMinutes, 10 * 60);
      expect(reloaded.getWatchDraft().windowEndMinutes, 20 * 60);
      expect(reloaded.getWatchDraft().deliveriesPerDay, 3);
      expect(reloaded.getWatchDraft().scheduleEnabled, isFalse);
      expect(reloaded.getWatchDraft().lastSyncAtEpochMs, 123);
      expect(reloaded.getWatchDraft().selectedCount, 2);
      expect(reloaded.getWatchDraft().lastSyncOutcome, WatchSyncOutcome.saved);
    });
  });
}
