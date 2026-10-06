import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';
import 'package:lingo_core/features/watch/watch_learner_copy.dart';
import 'package:lingo_core/features/watch/watch_learner_language_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserPreferences.resetForTest();
    WatchCompanionService.resetForTest();
  });

  test('learnerLanguageCode is sent on every language refresh', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
    _installBridge(sent.add);
    await _seedDeliveredPlan();

    final WatchSyncResult? result = await WatchLearnerLanguageSync.refresh(
      content: repo,
      learnerLanguageCode: 'fr',
      updatedAtEpochMs: 21,
    );

    expect(result?.succeeded, isTrue);
    expect(sent, hasLength(1));
    expect(sent.single['learnerLanguageCode'], 'fr');
    expect(sent.single['targetLanguageCode'], repo.product.targetLanguageCode);
    expect(
      UserPreferences.instance.getWatchDraft().lastSyncedLearnerLanguage,
      'fr',
    );
  });

  test('Watch UI strings follow the learner language', () {
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.today, 'fr'),
      'Aujourd’hui',
    );
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.word, 'fr'), 'Mot');
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.phrase, 'fr'), 'Phrase');
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.words, 'fr'), 'Mots');
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.phrases, 'fr'), 'Phrases');
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.setUpOnIPhone, 'fr'),
      'Configurer sur iPhone',
    );
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.chooseLearningContent, 'fr'),
      'Choisis ton contenu d’apprentissage...',
    );

    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.today, 'tr'), 'Bugün');
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.word, 'tr'), 'Kelime');
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.phrase, 'tr'), 'İfade');
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.setUpOnIPhone, 'tr'),
      'iPhone’da kur',
    );

    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.today, 'de'), 'Heute');
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.word, 'de'), 'Wort');
    expect(WatchLearnerCopy.resolve(WatchLearnerCopy.phrase, 'de'), 'Satz');
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.setUpOnIPhone, 'de'),
      'Auf iPhone einrichten',
    );

    for (final String code in LearnerLanguages.orderedCodes) {
      for (final String key in WatchLearnerCopy.keys) {
        final String value = WatchLearnerCopy.resolve(key, code);
        expect(value, isNotEmpty, reason: '$key missing for $code');
        expect(value, isNot(key), reason: '$key fell back to the key in $code');
      }
    }
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.today, 'fr'),
      isNot('Today'),
    );
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.today, 'tr'),
      isNot('Today'),
    );
    expect(
      WatchLearnerCopy.resolve(WatchLearnerCopy.today, 'de'),
      isNot('Today'),
    );
  });

  test('word translations follow the learner language', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    const String id = 'word.basics.why';

    final WatchPlanItem? french = WatchCatalog.resolve(
      repo,
      id,
      learnerLanguageCode: 'fr',
    );
    final WatchPlanItem? turkish = WatchCatalog.resolve(
      repo,
      id,
      learnerLanguageCode: 'tr',
    );
    final WatchPlanItem? german = WatchCatalog.resolve(
      repo,
      id,
      learnerLanguageCode: 'de',
    );

    expect(french?.id, id);
    expect(turkish?.id, id);
    expect(german?.id, id);
    expect(french?.targetText, 'warum');
    expect(turkish?.targetText, 'warum');
    expect(german?.targetText, 'warum');
    expect(french?.translation, 'Pourquoi');
    expect(turkish?.translation, 'Neden');
    expect(german?.translation, 'warum');
    expect(french?.translation, isNot(french?.targetText));
  });

  test('phrase translations follow the learner language', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    const String id = 'phrase.greetings.hello';

    final WatchPlanItem? french = WatchCatalog.resolve(
      repo,
      id,
      learnerLanguageCode: 'fr',
    );
    final WatchPlanItem? turkish = WatchCatalog.resolve(
      repo,
      id,
      learnerLanguageCode: 'tr',
    );
    final WatchPlanItem? german = WatchCatalog.resolve(
      repo,
      id,
      learnerLanguageCode: 'de',
    );

    expect(french?.type, WatchItemType.phrase);
    expect(french?.targetText, 'Hallo.');
    expect(turkish?.targetText, french?.targetText);
    expect(german?.targetText, french?.targetText);
    expect(french?.translation, 'Bonjour.');
    expect(turkish?.translation, 'Merhaba.');
    expect(german?.translation, 'Hallo.');
    expect(french?.id, id);
    expect(turkish?.id, id);
    expect(german?.id, id);
  });

  test('language change refreshes meanings and keeps stable IDs', () async {
    final LocalContentRepository repo = await LocalContentRepository.load();
    final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
    _installBridge(sent.add);
    await _seedDeliveredPlan(learnerLanguageCode: 'en');

    for (final (String code, String wordMeaning, String phraseMeaning)
        in <(String, String, String)>[
          ('fr', 'Pourquoi', 'Bonjour.'),
          ('tr', 'Neden', 'Merhaba.'),
          ('de', 'warum', 'Hallo.'),
        ]) {
      await UserPreferences.instance.setSelectedTranslationLanguage(code);
      final WatchSyncResult? result = await WatchLearnerLanguageSync.refresh(
        content: repo,
        learnerLanguageCode: code,
        updatedAtEpochMs: 40 + sent.length,
      );
      expect(result?.succeeded, isTrue, reason: 'refresh failed for $code');

      final Map<String, Object?> payload = sent.last;
      expect(payload['learnerLanguageCode'], code);
      expect(payload['targetLanguageCode'], repo.product.targetLanguageCode);
      if (code != repo.product.targetLanguageCode) {
        expect(payload['targetLanguageCode'], isNot(code));
      }

      final List<Map<String, Object?>> items = _items(payload);
      expect(items.map((Map<String, Object?> item) => item['id']), <String>[
        'word.basics.why',
        'phrase.greetings.hello',
      ]);
      expect(items.first['type'], 'word');
      expect(items.first['targetText'], 'warum');
      expect(items.first['translation'], wordMeaning);
      if (code != repo.product.targetLanguageCode) {
        expect(items.first['translation'], isNot(items.first['targetText']));
      }
      expect(items.last['type'], 'phrase');
      expect(items.last['targetText'], 'Hallo.');
      expect(items.last['translation'], phraseMeaning);
      expect(UserPreferences.instance.getWatchDraft().wordIds, <String>{
        'word.basics.why',
      });
      expect(UserPreferences.instance.getWatchDraft().phraseIds, <String>{
        'phrase.greetings.hello',
      });
      expect(
        UserPreferences.instance.getWatchDraft().lastSyncedLearnerLanguage,
        code,
      );
    }
    expect(sent, hasLength(3));
  });

  test(
    'stable IDs survive a translation-language change without reselection',
    () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      _installBridge((Map<String, Object?> _) {});
      await _seedDeliveredPlan(learnerLanguageCode: 'en');

      final Set<String> wordIds = UserPreferences.instance
          .getWatchDraft()
          .wordIds;
      final Set<String> phraseIds = UserPreferences.instance
          .getWatchDraft()
          .phraseIds;

      await UserPreferences.instance.setSelectedTranslationLanguage('fr');
      await WatchLearnerLanguageSync.refresh(
        content: repo,
        learnerLanguageCode: 'fr',
      );

      expect(UserPreferences.instance.getWatchDraft().wordIds, wordIds);
      expect(UserPreferences.instance.getWatchDraft().phraseIds, phraseIds);
      expect(wordIds, <String>{'word.basics.why'});
      expect(phraseIds, <String>{'phrase.greetings.hello'});
    },
  );
}

Future<void> _seedDeliveredPlan({String learnerLanguageCode = 'en'}) {
  return UserPreferences.instance.setWatchDraft(
    WatchCompanionDraft.initial
        .toggled('word.basics.why', WatchItemType.word)
        .draft
        .toggled('phrase.greetings.hello', WatchItemType.phrase)
        .draft
        .copyWith(filter: WatchContentFilter.both)
        .withSync(
          WatchSyncOutcome.sent,
          10,
          learnerLanguageCode: learnerLanguageCode,
        ),
  );
}

void _installBridge(void Function(Map<String, Object?> payload) onSync) {
  WatchCompanionService.resetForTest(
    service: WatchCompanionService(
      invoke: (String method, [dynamic arguments]) async {
        if (method == WatchCompanionService.getWatchStatusMethod ||
            method == WatchCompanionService.isWatchSupportedMethod) {
          return <String, Object?>{
            'supported': true,
            'paired': true,
            'watchAppInstalled': true,
            'reachable': true,
          };
        }
        if (method == WatchCompanionService.syncLearningPlanMethod) {
          onSync(Map<String, Object?>.from(arguments as Map<Object?, Object?>));
          return <String, Object?>{'ok': true, 'outcome': 'sent'};
        }
        return null;
      },
    ),
  );
}

List<Map<String, Object?>> _items(Map<String, Object?> payload) {
  final Object? raw = payload['items'];
  expect(raw, isA<List<Object?>>());
  return <Map<String, Object?>>[
    for (final Object? row in raw! as List<Object?>)
      Map<String, Object?>.from(row! as Map<Object?, Object?>),
  ];
}
