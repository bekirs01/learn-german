import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(WatchCompanionService.resetForTest);

  test('missing plugin reports an unavailable Watch', () async {
    final WatchCompanionService service = WatchCompanionService();

    expect(await service.isSupported(), isFalse);
    final WatchCompanionStatus status = await service.getStatus();
    expect(status.supported, isFalse);
    expect(status.paired, isFalse);
    expect(status.watchAppInstalled, isFalse);
    expect(status.reachable, isFalse);
    expect(status.presence, WatchCompanionPresence.unsupported);
    expect(
      await service.sendTestPayload(<String, Object?>{'id': 'x'}),
      isFalse,
    );
    final WatchSyncResult sync = await service.syncLearningPlan(
      <String, Object>{'schemaVersion': 1},
    );
    expect(sync.ok, isFalse);
    expect(sync.outcome, WatchSyncOutcome.unavailable);
  });

  test('parses connected and app-not-installed states', () async {
    final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
    final WatchCompanionService service = WatchCompanionService(
      invoke: (String method, [dynamic arguments]) async {
        if (method == WatchCompanionService.isWatchSupportedMethod) {
          return true;
        }
        if (method == WatchCompanionService.getWatchStatusMethod) {
          return <String, Object?>{
            'supported': true,
            'paired': true,
            'watchAppInstalled': true,
            'reachable': true,
          };
        }
        if (method == WatchCompanionService.sendTestPayloadMethod) {
          sent.add(
            Map<String, Object?>.from(arguments as Map<Object?, Object?>),
          );
          return true;
        }
        if (method == WatchCompanionService.syncLearningPlanMethod) {
          sent.add(
            Map<String, Object?>.from(arguments as Map<Object?, Object?>),
          );
          return <String, Object?>{'ok': true, 'outcome': 'sent'};
        }
        return null;
      },
    );

    expect(await service.isSupported(), isTrue);
    expect(
      (await service.getStatus()).presence,
      WatchCompanionPresence.connected,
    );
    expect(
      await service.sendTestPayload(<String, Object?>{
        'id': 'word.basics.hello',
        'text': 'Hello',
      }),
      isTrue,
    );
    expect(sent, hasLength(1));
    expect(sent.first['id'], 'word.basics.hello');

    final WatchSyncResult synced = await service.syncLearningPlan(
      <String, Object>{
        'schemaVersion': 1,
        'targetLanguageCode': 'en',
        'learnerLanguageCode': 'tr',
      },
    );
    expect(synced.ok, isTrue);
    expect(synced.outcome, WatchSyncOutcome.sent);
    expect(sent, hasLength(2));
    expect(sent.last['targetLanguageCode'], 'en');
    expect(sent.last['learnerLanguageCode'], 'tr');

    final WatchCompanionService missingApp = WatchCompanionService(
      invoke: (String method, [dynamic arguments]) async {
        return <String, Object?>{
          'supported': true,
          'paired': true,
          'watchAppInstalled': false,
          'reachable': false,
        };
      },
    );
    expect(
      (await missingApp.getStatus()).presence,
      WatchCompanionPresence.appNotInstalled,
    );
    expect(
      (await missingApp.syncLearningPlan(<String, Object>{
        'schemaVersion': 1,
      })).outcome,
      WatchSyncOutcome.appNotInstalled,
    );
  });

  test('clearLearningPlan uses the native channel', () async {
    String? called;
    final WatchCompanionService service = WatchCompanionService(
      invoke: (String method, [dynamic arguments]) async {
        if (method == WatchCompanionService.getWatchStatusMethod) {
          return <String, Object?>{
            'supported': true,
            'paired': true,
            'watchAppInstalled': true,
            'reachable': false,
          };
        }
        called = method;
        return <String, Object?>{'ok': true, 'outcome': 'saved'};
      },
    );
    final WatchSyncResult result = await service.clearLearningPlan(
      payload: <String, Object>{'schemaVersion': 1},
    );
    expect(called, WatchCompanionService.clearLearningPlanMethod);
    expect(result.outcome, WatchSyncOutcome.saved);
    expect(result.ok, isTrue);
    expect((await service.getStatus()).presence, WatchCompanionPresence.ready);
  });

  test(
    'paired Watch that is not reachable still queues a saved plan',
    () async {
      Map<String, Object?>? sent;
      final WatchCompanionService service = WatchCompanionService(
        invoke: (String method, [dynamic arguments]) async {
          if (method == WatchCompanionService.getWatchStatusMethod) {
            return <String, Object?>{
              'supported': true,
              'paired': true,
              'watchAppInstalled': true,
              'reachable': false,
            };
          }
          if (method == WatchCompanionService.syncLearningPlanMethod) {
            sent = Map<String, Object?>.from(
              arguments as Map<Object?, Object?>,
            );
            return <String, Object?>{'ok': true, 'outcome': 'saved'};
          }
          return null;
        },
      );
      expect(
        (await service.getStatus()).presence,
        WatchCompanionPresence.ready,
      );
      final WatchSyncResult result = await service.syncLearningPlan(
        <String, Object>{
          'schemaVersion': 1,
          'targetLanguageCode': 'en',
          'learnerLanguageCode': 'tr',
        },
      );
      expect(result.outcome, WatchSyncOutcome.saved);
      expect(result.ok, isTrue);
      expect(sent?['targetLanguageCode'], 'en');
    },
  );

  test('unpaired Watch is distinct from an uninstalled Watch app', () async {
    final WatchCompanionService unpaired = WatchCompanionService(
      invoke: (String method, [dynamic arguments]) async {
        return <String, Object?>{
          'supported': true,
          'paired': false,
          'watchAppInstalled': false,
          'reachable': false,
        };
      },
    );
    final WatchCompanionStatus status = await unpaired.getStatus();
    expect(status.presence, WatchCompanionPresence.unpaired);
    expect(status.canDeliverPlan, isFalse);
    expect(
      (await unpaired.syncLearningPlan(<String, Object>{
        'schemaVersion': 1,
      })).outcome,
      WatchSyncOutcome.unavailable,
    );
  });
}
