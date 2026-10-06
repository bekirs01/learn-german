import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_buttons.dart';
import 'package:lingo_core/core/widgets/lingo_segmented_control.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';
import 'package:lingo_core/features/watch/watch_picker_screen.dart';
import 'package:lingo_core/features/watch/watch_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
    WatchCompanionService.resetForTest();
  });

  testWidgets('Apple Watch Home entry opens the management screen', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(HomeScreen.appleWatchKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WatchScreen), findsOneWidget);
    expect(find.byKey(WatchScreen.statusKey), findsOneWidget);
    expect(find.byKey(WatchScreen.previewKey), findsOneWidget);
    expect(find.text('Set up Apple Watch from your iPhone.'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('Send to Watch', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Next reminders'), findsOneWidget);
    await _reveal(tester, find.text('Active hours', skipOffstage: false));
    expect(find.text('Active hours'), findsOneWidget);
    expect(find.text('5 times per day'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);
  });

  testWidgets('Watch status stays safe when the Watch is unavailable', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);

    expect(find.text('Apple Watch connected'), findsNothing);
    expect(find.text('Set up Apple Watch from your iPhone.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connected Watch status is human-readable', (
    WidgetTester tester,
  ) async {
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': true,
        'reachable': true,
      },
    );
    await _pumpApp(tester);
    await _openWatch(tester);
    expect(find.text('Apple Watch connected'), findsOneWidget);
  });

  testWidgets('Words, Phrases, and Both switch the draft filter', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);

    expect(find.byKey(WatchScreen.wordsKey), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Phrases'),
      ),
    );
    await tester.pump();
    expect(find.byKey(WatchScreen.phrasesKey), findsOneWidget);
    expect(
      UserPreferences.instance.getWatchDraft().filter,
      WatchContentFilter.phrases,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Both'),
      ),
    );
    await tester.pump();
    expect(find.byKey(WatchScreen.bothKey), findsOneWidget);
    expect(
      UserPreferences.instance.getWatchDraft().filter,
      WatchContentFilter.both,
    );
  });

  testWidgets('draft item selection persists after leaving the screen', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );

    await _openPicker(tester);
    await _tapPickerItem(tester, word);
    await tester.pump();
    expect(UserPreferences.instance.getWatchDraft().wordIds, <String>{word.id});

    await _popRoute(tester);
    expect(find.byType(WatchScreen), findsOneWidget);
    await _popRoute(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await _openWatch(tester);
    expect(UserPreferences.instance.getWatchDraft().wordIds, <String>{word.id});
    expect(find.byKey(WatchScreen.summaryKey), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byKey(WatchScreen.itemKey(word.id)), findsNothing);
    expect(find.text('Change selection'), findsOneWidget);
  });

  testWidgets('Clear sits beside the Watch selection summary', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));
    await _openWatch(tester);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );
    await _openPicker(tester);
    await _tapPickerItem(tester, word);
    await tester.pump();
    await _popRoute(tester);

    final Rect summary = tester.getRect(find.byKey(WatchScreen.summaryKey));
    final Rect clear = tester.getRect(find.byKey(WatchScreen.clearKey));
    final Rect choose = tester.getRect(find.byKey(WatchScreen.chooseKey));
    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;

    expect(find.text('Clear'), findsOneWidget);
    expect(clear.left, greaterThan(summary.right - 4));
    expect((clear.center.dy - summary.center.dy).abs(), lessThan(24));
    expect(choose.top, greaterThan(clear.bottom - 2));
    expect(clear.right, lessThanOrEqualTo(size.width - 12));
    expect(summary.left, greaterThanOrEqualTo(12));

    await tester.tap(find.byKey(WatchScreen.clearKey));
    await tester.pump();
    expect(UserPreferences.instance.getWatchDraft().selectedCount, 0);
    expect(find.byKey(WatchScreen.clearKey), findsNothing);
    expect(find.text('Choose content'), findsOneWidget);
  });

  testWidgets('phrases can be selected from the curriculum picker', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem phrase = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.phrase,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Phrases'),
      ),
    );
    await tester.pump();
    await _openPicker(tester);
    await _tapPickerItem(tester, phrase);
    await tester.pump();
    expect(UserPreferences.instance.getWatchDraft().phraseIds, <String>{
      phrase.id,
    });
  });

  testWidgets('schedule steppers update the local draft', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);

    await _reveal(
      tester,
      find.byKey(WatchScreen.frequencyIncreaseKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(WatchScreen.frequencyIncreaseKey));
    await tester.pump();
    expect(find.text('6 times per day'), findsOneWidget);
    expect(UserPreferences.instance.getWatchDraft().deliveriesPerDay, 6);

    await tester.tap(find.byKey(WatchScreen.windowStartIncreaseKey));
    await tester.pump();
    expect(find.text('09:30'), findsOneWidget);
    expect(
      UserPreferences.instance.getWatchDraft().windowStartMinutes,
      9 * 60 + 30,
    );
  });

  testWidgets('localized Watch chrome and RTL stay usable', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, languageCode: 'tr');
    await _openWatch(tester);
    expect(find.text('Apple Watch’u iPhone’unuzdan kurun.'), findsOneWidget);
    expect(find.text('İçerik'), findsOneWidget);
    await _reveal(tester, find.text('Günde 5 kez', skipOffstage: false));
    expect(find.text('Günde 5 kez'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, languageCode: 'ar');
    await _openWatch(tester);
    expect(
      Directionality.of(tester.element(find.byType(WatchScreen))),
      TextDirection.rtl,
    );
    expect(find.text('أعدّ Apple Watch من جهاز iPhone.'), findsOneWidget);
    expect(find.text('المحتوى'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, languageCode: 'zh');
    await _openWatch(tester);
    expect(find.text('请在 iPhone 上设置 Apple Watch。'), findsOneWidget);
    expect(find.text('内容'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, languageCode: 'de');
    await _openWatch(tester);
    expect(
      find.text('Richte Apple Watch über dein iPhone ein.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, languageCode: 'ru');
    await _openWatch(tester);
    expect(find.text('Настройте Apple Watch на iPhone.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, languageCode: 'fa');
    await _openWatch(tester);
    expect(
      Directionality.of(tester.element(find.byType(WatchScreen))),
      TextDirection.rtl,
    );
    expect(
      find.text('Apple Watch را از iPhone خود راه‌اندازی کنید.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, languageCode: 'ja');
    await _openWatch(tester);
    expect(find.text('iPhoneからApple Watchを設定してください。'), findsOneWidget);
  });

  testWidgets('Send to Watch calls syncLearningPlan with the frozen payload', (
    WidgetTester tester,
  ) async {
    final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': true,
        'reachable': true,
      },
      onSync: sent.add,
    );
    await _pumpApp(tester, languageCode: 'tr');
    await _openWatch(tester);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );

    await _openPicker(tester);
    await _tapPickerItem(tester, word);
    await tester.pump();
    await _popRoute(tester);
    await _tapSend(tester);
    await tester.pump(const Duration(milliseconds: 50));

    expect(sent, hasLength(1));
    expect(sent.first['schemaVersion'], 1);
    expect(sent.first['targetLanguageCode'], repo.product.targetLanguageCode);
    expect(sent.first['learnerLanguageCode'], 'tr');
    expect(sent.first['targetLanguageCode'], isNot('tr'));
    final Object? items = sent.first['items'];
    expect(items, isA<List<Object?>>());
    final Map<Object?, Object?> row =
        (items! as List<Object?>).first as Map<Object?, Object?>;
    expect(row['id'], word.id);
    expect(row['type'], 'word');
    expect(row['targetText'], word.prompt);
    expect(row['translation'], repo.translation(word.id, languageCode: 'tr'));
    expect(row['translation'], isNot(row['targetText']));
    expect(find.text('Gönderildi'), findsOneWidget);
  });

  testWidgets('empty send shows localized validation instead of crashing', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);
    await _tapSend(tester);
    expect(find.text('Choose a few words or phrases'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable Watch stays human-readable after send', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );
    await _openPicker(tester);
    await _tapPickerItem(tester, word);
    await tester.pump();
    await _popRoute(tester);
    await _tapSend(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text('Set up Apple Watch from your iPhone.', skipOffstage: false),
      findsWidgets,
    );
    expect(find.textContaining('WCSession'), findsNothing);
  });

  testWidgets('Watch management stays usable on small and large iPhones', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, size: const Size(375, 667));
    await _openWatch(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(WatchScreen.previewKey), findsOneWidget);
    expect(
      find.byKey(WatchScreen.chooseKey, skipOffstage: false),
      findsOneWidget,
    );
    await _assertSendSitsBelowSchedule(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, size: const Size(390, 844));
    await _openWatch(tester);
    expect(tester.takeException(), isNull);
    await _assertSendSitsBelowSchedule(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, size: const Size(430, 932));
    await _openWatch(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(WatchScreen.previewKey), findsOneWidget);
    await _assertSendSitsBelowSchedule(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpApp(tester, size: const Size(375, 667));
    await _openWatch(tester);
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(WatchScreen), findsOneWidget);
    expect(find.byKey(WatchScreen.previewKey), findsOneWidget);
    await _assertSendSitsBelowSchedule(tester);
    expect(
      find.byKey(WatchScreen.chooseKey, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('unreachable Watch still reports Saved for Apple Watch', (
    WidgetTester tester,
  ) async {
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': true,
        'reachable': false,
      },
    );
    await _pumpApp(tester);
    await _openWatch(tester);
    expect(find.text('Apple Watch ready'), findsOneWidget);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );
    await _openPicker(tester);
    await _tapPickerItem(tester, word);
    await tester.pump();
    await _popRoute(tester);
    await _tapSend(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Saved for Apple Watch'), findsOneWidget);
    expect(find.textContaining('WCSession'), findsNothing);
  });

  testWidgets('selection limit is explained and does not drop items', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final LocalContentRepository repo = _pack();
    final List<QuizReadyItem> words = repo.quizItems
        .where((QuizReadyItem item) => item.kind == QuizContentKind.word)
        .toList();
    expect(words.length, greaterThan(WatchCompanionDraft.maxSelectedItems));
    final List<QuizReadyItem> filled = words
        .take(WatchCompanionDraft.maxSelectedItems)
        .toList();
    final QuizReadyItem extra = words[WatchCompanionDraft.maxSelectedItems];
    await UserPreferences.instance.setWatchDraft(
      WatchCompanionDraft.initial.copyWith(
        wordIds: <String>{for (final QuizReadyItem item in filled) item.id},
      ),
    );
    await _openWatch(tester);
    expect(
      UserPreferences.instance.getWatchDraft().selectedCount,
      WatchCompanionDraft.maxSelectedItems,
    );
    await _openPicker(tester);
    await _tapPickerItem(tester, extra);
    await tester.pump();
    expect(find.byKey(WatchPickerScreen.limitKey), findsOneWidget);
    expect(
      UserPreferences.instance.getWatchDraft().wordIds.contains(extra.id),
      isFalse,
    );
    expect(
      UserPreferences.instance.getWatchDraft().selectedCount,
      WatchCompanionDraft.maxSelectedItems,
    );
  });

  testWidgets('Watch presence covers unpaired, missing app, ready, connected', (
    WidgetTester tester,
  ) async {
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': false,
        'watchAppInstalled': false,
        'reachable': false,
      },
    );
    await _pumpApp(tester);
    await _openWatch(tester);
    expect(find.text('Set up Apple Watch from your iPhone.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('watch-presence-unpaired')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': false,
        'reachable': false,
      },
    );
    await _pumpApp(tester);
    await _openWatch(tester);
    expect(find.text('Watch app not installed'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': true,
        'reachable': false,
      },
    );
    await _pumpApp(tester);
    await _openWatch(tester);
    expect(find.text('Apple Watch ready'), findsOneWidget);
    expect(find.text('Set up Apple Watch from your iPhone.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': true,
        'reachable': true,
      },
    );
    await _pumpApp(tester);
    await _openWatch(tester);
    expect(find.text('Apple Watch connected'), findsOneWidget);
  });

  testWidgets('Both keeps a compact summary instead of a selected list', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(LingoSegmentedControl),
        matching: find.text('Both'),
      ),
    );
    await tester.pump();
    expect(find.byKey(WatchScreen.bothKey), findsOneWidget);
    expect(find.text('Words + Phrases'), findsOneWidget);
    expect(find.text('0 selected'), findsOneWidget);

    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );
    final QuizReadyItem phrase = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.phrase,
    );
    await _openPicker(tester);
    expect(find.text('Words'), findsWidgets);
    expect(find.text('Phrases'), findsWidgets);
    expect(find.text('Basics'), findsWidgets);
    await _tapPickerItem(tester, word);
    await tester.enterText(find.byKey(WatchPickerScreen.searchKey), '');
    await tester.pump();
    await _tapPickerItem(tester, phrase);
    await tester.pump();
    await _popRoute(tester);

    expect(find.byType(WatchScreen), findsOneWidget);
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Change selection'), findsOneWidget);
    expect(find.byKey(WatchScreen.itemKey(word.id)), findsNothing);
    expect(find.byKey(WatchScreen.itemKey(phrase.id)), findsNothing);
  });

  testWidgets('Send to Watch stays a primary action after failure', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _openWatch(tester);
    await _tapSend(tester);
    final LingoPrimaryButton button = tester.widget<LingoPrimaryButton>(
      find.byKey(WatchScreen.sendKey),
    );
    expect(button.status, LingoStatus.idle);
    expect(find.text('Choose a few words or phrases'), findsWidgets);
  });

  testWidgets('invalid reminder window is explained without sending', (
    WidgetTester tester,
  ) async {
    final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': true,
        'reachable': true,
      },
      onSync: sent.add,
    );
    await _pumpApp(tester);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );
    await UserPreferences.instance.setWatchDraft(
      WatchCompanionDraft.initial.copyWith(
        wordIds: <String>{word.id},
        windowStartMinutes: 12 * 60,
        windowEndMinutes: 12 * 60,
      ),
    );
    await _openWatch(tester);
    await _tapSend(tester);
    expect(sent, isEmpty);
    expect(find.text('End time must be after start time'), findsOneWidget);
    final LingoPrimaryButton button = tester.widget<LingoPrimaryButton>(
      find.byKey(WatchScreen.sendKey),
    );
    expect(button.status, LingoStatus.idle);
  });

  testWidgets('dense reminder windows send without a frequency error', (
    WidgetTester tester,
  ) async {
    final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
    _installBridge(
      status: <String, Object?>{
        'supported': true,
        'paired': true,
        'watchAppInstalled': true,
        'reachable': true,
      },
      onSync: sent.add,
    );
    await _pumpApp(tester);
    final LocalContentRepository repo = _pack();
    final QuizReadyItem word = repo.quizItems.firstWhere(
      (QuizReadyItem item) => item.kind == QuizContentKind.word,
    );
    await UserPreferences.instance.setWatchDraft(
      WatchCompanionDraft.initial.copyWith(
        wordIds: <String>{word.id},
        windowStartMinutes: 12 * 60,
        windowEndMinutes: 12 * 60 + 30,
        deliveriesPerDay: 10,
      ),
    );
    await _openWatch(tester);
    await _tapSend(tester);
    await tester.pump(const Duration(milliseconds: 50));
    expect(sent, hasLength(1));
    final Object? schedule = sent.single['schedule'];
    expect(schedule, isA<Map<Object?, Object?>>());
    expect((schedule! as Map<Object?, Object?>)['timesPerDay'], 10);
    expect(find.text('Too many reminders for these hours'), findsNothing);
    expect(find.text('Too many reminders for this hour'), findsNothing);
    expect(find.textContaining('Too many reminders'), findsNothing);
  });
}

void _installBridge({
  required Map<String, Object?> status,
  void Function(Map<String, Object?> payload)? onSend,
  void Function(Map<String, Object?> payload)? onSync,
}) {
  WatchCompanionService.resetForTest(
    service: WatchCompanionService(
      invoke: (String method, [dynamic arguments]) async {
        if (method == WatchCompanionService.isWatchSupportedMethod) {
          return status['supported'] == true;
        }
        if (method == WatchCompanionService.getWatchStatusMethod) {
          return status;
        }
        if (method == WatchCompanionService.sendTestPayloadMethod) {
          onSend?.call(
            Map<String, Object?>.from(arguments as Map<Object?, Object?>),
          );
          return true;
        }
        if (method == WatchCompanionService.syncLearningPlanMethod ||
            method == WatchCompanionService.clearLearningPlanMethod) {
          onSync?.call(
            Map<String, Object?>.from(arguments as Map<Object?, Object?>),
          );
          return <String, Object?>{
            'ok': true,
            'outcome': status['reachable'] == true ? 'sent' : 'saved',
          };
        }
        return null;
      },
    ),
  );
}

LocalContentRepository _pack() {
  final LocalContentRepository? repo = LocalContentRepository.cached;
  if (repo == null) {
    fail('content pack was not loaded');
  }
  return repo;
}

Future<void> _tapSend(WidgetTester tester) async {
  final Finder send = find.byKey(WatchScreen.sendKey, skipOffstage: false);
  await _reveal(tester, send);
  await tester.tap(find.byKey(WatchScreen.sendKey));
  await tester.pump();
}

Future<void> _assertSendSitsBelowSchedule(WidgetTester tester) async {
  await _reveal(
    tester,
    find.byKey(WatchScreen.frequencyIncreaseKey, skipOffstage: false),
  );
  await _reveal(tester, find.byKey(WatchScreen.sendKey, skipOffstage: false));
  final Rect send = tester.getRect(find.byKey(WatchScreen.sendKey));
  final Rect schedule = tester.getRect(
    find.byKey(WatchScreen.frequencyIncreaseKey),
  );
  final MediaQueryData media = MediaQuery.of(
    tester.element(find.byType(WatchScreen)),
  );
  expect(send.top, greaterThan(schedule.bottom + LingoSpacing.md));
  expect(
    send.top - schedule.bottom,
    lessThan(LingoSpacing.massive + LingoSpacing.lg),
  );
  expect(
    send.bottom,
    lessThanOrEqualTo(media.size.height - media.padding.bottom),
  );
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find
        .descendant(
          of: find.byType(WatchScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
}

Future<void> _openWatch(WidgetTester tester) async {
  final Finder entry = find.byKey(
    HomeScreen.appleWatchKey,
    skipOffstage: false,
  );
  expect(entry, findsOneWidget);
  await tester.ensureVisible(entry);
  await tester.tap(find.byKey(HomeScreen.appleWatchKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(WatchScreen), findsOneWidget);
}

Future<void> _tapPickerItem(WidgetTester tester, QuizReadyItem item) async {
  await tester.enterText(find.byKey(WatchPickerScreen.searchKey), item.prompt);
  await tester.pump();
  final Finder row = find.byKey(WatchScreen.itemKey(item.id));
  expect(row, findsOneWidget);
  await tester.tap(row);
  await tester.pump();
}

Future<void> _openPicker(WidgetTester tester) async {
  final Finder choose = find.byKey(WatchScreen.chooseKey, skipOffstage: false);
  final Finder scrollable = find
      .descendant(
        of: find.byType(WatchScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(choose, 240, scrollable: scrollable);
  await tester.drag(scrollable, const Offset(0, -160));
  await tester.pump();
  await tester.tap(find.byKey(WatchScreen.chooseKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(WatchPickerScreen), findsOneWidget);
}

Future<void> _popRoute(WidgetTester tester) async {
  final Iterable<NavigatorState> navigators = tester.stateList<NavigatorState>(
    find.byType(Navigator),
  );
  for (final NavigatorState navigator in navigators) {
    if (navigator.canPop()) {
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  fail('expected a nested route to pop');
}

Future<void> _pumpApp(
  WidgetTester tester, {
  String languageCode = 'en',
  Size size = const Size(390, 844),
}) async {
  const double dpr = 3;
  tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  UserPreferences.resetForTest();
  await UserPreferences.instance.setSelectedTranslationLanguage(languageCode);
  FeedbackService.instance = FeedbackService(
    hapticsEnabled: false,
    soundEnabled: false,
  );
  final LocalContentRepository? repo = await tester.runAsync(
    LocalContentRepository.load,
  );
  if (repo == null) {
    fail('content pack was not loaded');
  }
  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await tester.pump();
}
