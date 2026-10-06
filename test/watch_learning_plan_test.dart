import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/domain/watch_learning_plan.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';
import 'package:lingo_core/features/watch/watch_screen.dart';
import 'package:lingo_core/features/watch/watch_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const WatchPlanItem hello = WatchPlanItem(
    id: 'word.basics.hello',
    type: WatchItemType.word,
    targetText: 'Hello',
    translation: 'Merhaba',
  );
  const WatchPlanItem morning = WatchPlanItem(
    id: 'phrase.greetings.good_morning',
    type: WatchItemType.phrase,
    targetText: 'Good morning.',
    translation: 'Günaydın',
  );

  test('payload uses the frozen Watch contract and product language', () {
    final WatchCompanionDraft draft = WatchCompanionDraft.initial
        .toggled(hello.id, hello.type)
        .draft
        .toggled(morning.id, morning.type)
        .draft
        .copyWith(filter: WatchContentFilter.both);
    final Map<String, Object> payload = WatchLearningPlan.payload(
      draft: draft,
      items: <WatchPlanItem>[hello, morning],
      targetLanguageCode: ProductConfig.fallback.targetLanguageCode,
      learnerLanguageCode: 'tr',
      updatedAtEpochMs: 0,
    );

    expect(payload['schemaVersion'], 1);
    expect(
      payload['targetLanguageCode'],
      ProductConfig.fallback.targetLanguageCode,
    );
    expect(payload['targetLanguageCode'], isNot('tr'));
    expect(payload['learnerLanguageCode'], 'tr');
    expect(payload['updatedAtEpochMs'], 0);
    final Object? items = payload['items'];
    expect(items, isA<List<Map<String, Object>>>());
    final List<Map<String, Object>> rows = items as List<Map<String, Object>>;
    expect(rows, hasLength(2));
    expect(rows.first.keys, <String>{
      'id',
      'type',
      'targetText',
      'translation',
      'pronunciationId',
    });
    expect(rows.first['id'], 'word.basics.hello');
    expect(rows.first['type'], 'word');
    expect(rows.first['targetText'], 'Hello');
    expect(rows.first['translation'], 'Merhaba');
    expect(rows.first['pronunciationId'], 'word.basics.hello');
    expect(rows.first['translation'], isNot(rows.first['targetText']));
    final Object? schedule = payload['schedule'];
    expect(schedule, isA<Map<String, Object>>());
    final Map<String, Object> window = schedule as Map<String, Object>;
    expect(window['enabled'], isTrue);
    expect(window['mode'], 'window_frequency');
    expect(window['startMinutes'], 540);
    expect(window['endMinutes'], 1260);
    expect(window['timesPerDay'], 5);
    expect(payload.keys, <String>{
      'schemaVersion',
      'targetLanguageCode',
      'learnerLanguageCode',
      'items',
      'schedule',
      'updatedAtEpochMs',
    });
  });

  test('live German catalog payload stays de with Hallo target text', () async {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    addTearDown(() {
      LocalContentRepository.clearCache();
      UserPreferences.resetForTest();
    });
    final LocalContentRepository repo = await LocalContentRepository.load();
    final WatchPlanItem? hello = WatchCatalog.resolve(
      repo,
      'word.basics.hello',
      learnerLanguageCode: 'en',
    );
    expect(hello, isNotNull);
    expect(hello!.targetText, 'Hallo');
    expect(repo.product.targetLanguageCode, 'de');

    final Map<String, Object> payload = WatchLearningPlan.payload(
      draft: WatchCompanionDraft.initial.toggled(hello.id, hello.type).draft,
      items: <WatchPlanItem>[hello],
      targetLanguageCode: repo.product.targetLanguageCode,
      learnerLanguageCode: 'en',
      updatedAtEpochMs: 1,
    );
    expect(payload['targetLanguageCode'], 'de');
    final List<Map<String, Object>> rows =
        payload['items']! as List<Map<String, Object>>;
    expect(rows.single['targetText'], 'Hallo');
    expect(rows.single['pronunciationId'], 'word.basics.hello');
    expect(rows.single['targetText'], isNot('Hello'));
  });

  test('stable IDs keep selection when the translation string changes', () {
    final WatchCompanionDraft selected = WatchCompanionDraft.initial
        .toggled(hello.id, WatchItemType.word)
        .draft;
    expect(selected.wordIds, <String>{hello.id});
    final WatchPlanItem german = WatchPlanItem(
      id: hello.id,
      type: WatchItemType.word,
      targetText: hello.targetText,
      translation: 'Hallo',
    );
    final Map<String, Object> payload = WatchLearningPlan.payload(
      draft: selected,
      items: <WatchPlanItem>[german],
      targetLanguageCode: 'en',
      learnerLanguageCode: 'de',
      updatedAtEpochMs: 1,
    );
    final Object? translated = payload['items'];
    expect(translated, isA<List<Map<String, Object>>>());
    final List<Map<String, Object>> rows =
        translated as List<Map<String, Object>>;
    expect(rows.single['id'], hello.id);
    expect(rows.single['targetText'], hello.targetText);
    expect(rows.single['translation'], 'Hallo');
    expect(rows.single['translation'], isNot(rows.single['targetText']));
    expect(
      payload['targetLanguageCode'],
      isNot(payload['learnerLanguageCode']),
    );
  });

  test('validation covers empty, window, frequency, and limit', () {
    expect(
      WatchLearningPlan.validate(WatchCompanionDraft.initial),
      WatchPlanIssue.noContent,
    );
    final WatchCompanionDraft filled = WatchCompanionDraft.initial
        .toggled(hello.id, hello.type)
        .draft;
    expect(WatchLearningPlan.validate(filled), isNull);
    expect(
      WatchLearningPlan.validate(filled.copyWith(deliveriesPerDay: 0)),
      WatchPlanIssue.zeroDeliveries,
    );
    expect(
      WatchLearningPlan.validate(
        filled.copyWith(windowStartMinutes: 600, windowEndMinutes: 600),
      ),
      WatchPlanIssue.invalidWindow,
    );
    expect(
      WatchLearningPlan.validate(
        filled.copyWith(
          windowStartMinutes: 9 * 60,
          windowEndMinutes: 9 * 60 + 15,
          deliveriesPerDay: 8,
        ),
      ),
      isNull,
    );
    WatchCompanionDraft many = WatchCompanionDraft.initial;
    for (int index = 0; index < WatchCompanionDraft.maxSelectedItems; index++) {
      many = many.toggled('word.item.$index', WatchItemType.word).draft;
    }
    expect(many.selectedCount, WatchCompanionDraft.maxSelectedItems);
    final WatchToggleResult blocked = many.toggled(
      'word.item.overflow',
      WatchItemType.word,
    );
    expect(blocked.atLimit, isTrue);
    expect(blocked.draft.selectedCount, WatchCompanionDraft.maxSelectedItems);
    expect(blocked.draft.wordIds.contains('word.item.overflow'), isFalse);

    WatchCompanionDraft mixed = WatchCompanionDraft.initial;
    for (int index = 0; index < 20; index++) {
      mixed = mixed.toggled('word.item.$index', WatchItemType.word).draft;
    }
    mixed = mixed.copyWith(filter: WatchContentFilter.phrases);
    for (int index = 0; index < 4; index++) {
      mixed = mixed.toggled('phrase.item.$index', WatchItemType.phrase).draft;
    }
    expect(mixed.selectedCount, WatchCompanionDraft.maxSelectedItems);
    final WatchToggleResult blockedPhrase = mixed.toggled(
      'phrase.item.overflow',
      WatchItemType.phrase,
    );
    expect(blockedPhrase.atLimit, isTrue);
    expect(
      blockedPhrase.draft.phraseIds.contains('phrase.item.overflow'),
      isFalse,
    );
  });

  test('payload keeps every selected item and both content types', () {
    final WatchCompanionDraft draft = WatchCompanionDraft.initial
        .toggled(hello.id, hello.type)
        .draft
        .toggled(morning.id, morning.type)
        .draft
        .copyWith(filter: WatchContentFilter.words);
    final Map<String, Object> payload = WatchLearningPlan.payload(
      draft: draft,
      items: <WatchPlanItem>[hello, morning],
      targetLanguageCode: 'en',
      learnerLanguageCode: 'tr',
      updatedAtEpochMs: 0,
    );
    final Object? items = payload['items'];
    expect(items, isA<List<Map<String, Object>>>());
    final List<Map<String, Object>> rows = items as List<Map<String, Object>>;
    expect(rows, hasLength(2));
    expect(rows.map((Map<String, Object> row) => row['type']), <String>[
      'word',
      'phrase',
    ]);
  });

  test('changing learner language is not used as the target language', () {
    final WatchCompanionDraft draft = WatchCompanionDraft.initial
        .toggled(hello.id, hello.type)
        .draft;
    final Map<String, Object> payload = WatchLearningPlan.payload(
      draft: draft,
      items: <WatchPlanItem>[hello],
      targetLanguageCode: 'en',
      learnerLanguageCode: 'ja',
      updatedAtEpochMs: 9,
    );
    expect(payload['targetLanguageCode'], 'en');
    expect(payload['learnerLanguageCode'], 'ja');
  });

  test('next reminder stays inside the daily window', () {
    final WatchCompanionDraft draft = WatchCompanionDraft.initial.copyWith(
      windowStartMinutes: 9 * 60,
      windowEndMinutes: 21 * 60,
      deliveriesPerDay: 5,
    );
    final int? next = WatchLearningPlan.nextReminderMinutes(
      draft: draft,
      now: DateTime(2026, 9, 19, 10, 0),
    );
    expect(next, isNotNull);
    final int reminder = next ?? -1;
    expect(reminder >= 9 * 60, isTrue);
    expect(reminder <= 21 * 60, isTrue);
    expect(
      WatchLearningPlan.nextReminderMinutes(
        draft: draft.copyWith(scheduleEnabled: false),
        now: DateTime(2026, 9, 19, 10, 0),
      ),
      isNull,
    );
  });

  test('reminder maximum is 10 per 30-minute window', () {
    expect(
      WatchCompanionDraft.maxDeliveriesForWindow(12 * 60, 12 * 60 + 30),
      10,
    );
    expect(WatchCompanionDraft.maxDeliveriesForWindow(12 * 60, 13 * 60), 20);
    expect(
      WatchCompanionDraft.maxDeliveriesForWindow(12 * 60, 12 * 60 + 90),
      30,
    );
    expect(WatchCompanionDraft.maxDeliveriesForWindow(12 * 60, 14 * 60), 40);
    expect(
      WatchCompanionDraft.initial
          .copyWith(
            windowStartMinutes: 12 * 60,
            windowEndMinutes: 12 * 60,
            deliveriesPerDay: 20,
          )
          .clampedToWindow()
          .deliveriesPerDay,
      WatchCompanionDraft.minDeliveriesPerDay,
    );
  });

  test('shrinking the window clamps the reminder count', () {
    final WatchCompanionDraft hour = WatchCompanionDraft.initial
        .toggled(hello.id, hello.type)
        .draft
        .copyWith(
          windowStartMinutes: 12 * 60,
          windowEndMinutes: 13 * 60,
          deliveriesPerDay: 20,
        );
    expect(hour.clampedToWindow().deliveriesPerDay, 20);
    expect(
      hour
          .copyWith(windowEndMinutes: 12 * 60 + 30)
          .clampedToWindow()
          .deliveriesPerDay,
      10,
    );
    expect(
      WatchCompanionDraft.tryParse(<String, Object?>{
        'windowStartMinutes': 12 * 60,
        'windowEndMinutes': 12 * 60 + 30,
        'deliveriesPerDay': 20,
      }).deliveriesPerDay,
      10,
    );
    expect(WatchLearningPlan.validate(hour), isNull);
    expect(
      WatchLearningPlan.validate(
        hour.copyWith(windowEndMinutes: 12 * 60 + 30, deliveriesPerDay: 20),
      ),
      isNull,
    );
    final Object? schedule = WatchLearningPlan.payload(
      draft: hour.copyWith(
        windowEndMinutes: 12 * 60 + 30,
        deliveriesPerDay: 20,
      ),
      items: <WatchPlanItem>[hello],
      targetLanguageCode: 'en',
      learnerLanguageCode: 'tr',
      updatedAtEpochMs: 0,
    )['schedule'];
    expect(schedule, isA<Map<String, Object>>());
    expect(schedule as Map<String, Object>, containsPair('timesPerDay', 10));
  });

  test('schedule slots stay even, unique, and under density', () {
    final WatchCompanionDraft hour = WatchCompanionDraft.initial.copyWith(
      windowStartMinutes: 12 * 60,
      windowEndMinutes: 13 * 60,
      deliveriesPerDay: 20,
    );
    final List<int> slots = WatchLearningPlan.reminderSlots(hour);
    expect(slots, hasLength(20));
    expect(slots.toSet(), hasLength(20));
    expect(slots.first, 12 * 60);
    expect(slots.last, 13 * 60);
    _expectEvenUniqueAndUnderDensity(slots);

    final List<int> halfHour = WatchLearningPlan.reminderSlots(
      hour.copyWith(windowEndMinutes: 12 * 60 + 30, deliveriesPerDay: 20),
    );
    expect(halfHour, hasLength(10));
    _expectEvenUniqueAndUnderDensity(halfHour);

    expect(
      WatchLearningPlan.reminderSlots(
        hour.copyWith(deliveriesPerDay: 1),
      ).single,
      12 * 60 + 30,
    );
    expect(
      WatchLearningPlan.reminderSlots(hour.copyWith(windowEndMinutes: 12 * 60)),
      isEmpty,
    );
    expect(
      WatchLearningPlan.reminderSlots(hour.copyWith(deliveriesPerDay: 0)),
      isEmpty,
    );
    expect(
      WatchLearningPlan.nextReminderMinutes(
        draft: hour.copyWith(scheduleEnabled: false),
        now: DateTime(2026, 9, 19, 12, 5),
      ),
      isNull,
    );
  });

  testWidgets('frequency + button disables at the dynamic maximum', (
    WidgetTester tester,
  ) async {
    await _pumpSchedule(
      tester,
      WatchCompanionDraft.initial.copyWith(
        windowStartMinutes: 12 * 60,
        windowEndMinutes: 12 * 60 + 30,
        deliveriesPerDay: 10,
      ),
    );
    final WatchStepButton plus = tester.widget(
      find.byKey(WatchScreen.frequencyIncreaseKey),
    );
    expect(plus.enabled, isFalse);
    expect(find.text('Too many reminders for these hours'), findsNothing);
    expect(find.text('Too many reminders for this hour'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpSchedule(
      tester,
      WatchCompanionDraft.initial.copyWith(
        windowStartMinutes: 12 * 60,
        windowEndMinutes: 13 * 60,
        deliveriesPerDay: 19,
      ),
    );
    expect(
      tester
          .widget<WatchStepButton>(find.byKey(WatchScreen.frequencyIncreaseKey))
          .enabled,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpSchedule(
      tester,
      WatchCompanionDraft.initial.copyWith(
        windowStartMinutes: 12 * 60,
        windowEndMinutes: 13 * 60,
        deliveriesPerDay: 20,
      ),
    );
    expect(
      tester
          .widget<WatchStepButton>(find.byKey(WatchScreen.frequencyIncreaseKey))
          .enabled,
      isFalse,
    );
  });

  testWidgets('changing to a shorter window clamps the stepper count', (
    WidgetTester tester,
  ) async {
    WatchCompanionDraft draft = WatchCompanionDraft.initial.copyWith(
      windowStartMinutes: 12 * 60,
      windowEndMinutes: 13 * 60,
      deliveriesPerDay: 20,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return WatchScheduleCard(
                draft: draft,
                onChanged: (WatchCompanionDraft next) {
                  setState(() => draft = next);
                },
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('20 times per day'), findsOneWidget);
    await tester.tap(find.byKey(WatchScreen.windowEndDecreaseKey));
    await tester.pump();
    expect(draft.deliveriesPerDay, 10);
    expect(find.text('10 times per day'), findsOneWidget);
    expect(
      tester
          .widget<WatchStepButton>(find.byKey(WatchScreen.frequencyIncreaseKey))
          .enabled,
      isFalse,
    );
    expect(find.text('Too many reminders for these hours'), findsNothing);
  });
}

Future<void> _pumpSchedule(
  WidgetTester tester,
  WatchCompanionDraft draft,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: WatchScheduleCard(draft: draft, onChanged: (_) {}),
      ),
    ),
  );
}

void _expectEvenUniqueAndUnderDensity(List<int> slots) {
  expect(slots, isNotEmpty);
  expect(slots.toSet(), hasLength(slots.length));
  const int window = WatchCompanionDraft.reminderDensityWindowMinutes;
  const int cap = WatchCompanionDraft.maxRemindersPerDensityWindow;
  for (int index = 0; index + cap < slots.length; index++) {
    expect(slots[index + cap] - slots[index], greaterThan(window));
  }
  if (slots.length < 2) {
    return;
  }
  final List<int> gaps = <int>[
    for (int index = 1; index < slots.length; index++)
      slots[index] - slots[index - 1],
  ];
  gaps.sort();
  expect(gaps.last - gaps.first, lessThanOrEqualTo(2));
}
