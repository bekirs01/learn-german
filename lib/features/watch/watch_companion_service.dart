import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';

/// Human Watch presence. Raw booleans stay inside [WatchCompanionStatus].
enum WatchCompanionPresence {
  unsupported,
  unpaired,
  appNotInstalled,
  ready,
  connected,
}

/// Snapshot from the iPhone WatchConnectivity bridge.
final class WatchCompanionStatus {
  const WatchCompanionStatus({
    required this.supported,
    required this.paired,
    required this.watchAppInstalled,
    required this.reachable,
  });

  static const WatchCompanionStatus unavailable = WatchCompanionStatus(
    supported: false,
    paired: false,
    watchAppInstalled: false,
    reachable: false,
  );

  final bool supported;
  final bool paired;
  final bool watchAppInstalled;
  final bool reachable;

  WatchCompanionPresence get presence {
    if (!supported) {
      return WatchCompanionPresence.unsupported;
    }
    if (!paired) {
      return WatchCompanionPresence.unpaired;
    }
    if (!watchAppInstalled) {
      return WatchCompanionPresence.appNotInstalled;
    }
    // Reachability only affects sent vs saved. Application context still works
    // when the Watch is paired but not currently reachable.
    if (!reachable) {
      return WatchCompanionPresence.ready;
    }
    return WatchCompanionPresence.connected;
  }

  bool get canDeliverPlan {
    return presence == WatchCompanionPresence.connected ||
        presence == WatchCompanionPresence.ready;
  }

  static WatchCompanionStatus fromRaw(Object? raw) {
    if (raw is! Map) {
      return unavailable;
    }
    bool flag(String key) {
      final Object? value = raw[key];
      return value == true;
    }

    return WatchCompanionStatus(
      supported: flag('supported'),
      paired: flag('paired'),
      watchAppInstalled: flag('watchAppInstalled'),
      reachable: flag('reachable'),
    );
  }
}

/// User-facing result of replacing the Watch learning plan.
final class WatchSyncResult {
  const WatchSyncResult({required this.outcome, required this.ok});

  final WatchSyncOutcome outcome;
  final bool ok;

  bool get succeeded =>
      ok &&
      (outcome == WatchSyncOutcome.sent ||
          outcome == WatchSyncOutcome.updated ||
          outcome == WatchSyncOutcome.saved);

  static WatchSyncResult unavailable = const WatchSyncResult(
    outcome: WatchSyncOutcome.unavailable,
    ok: false,
  );

  static WatchSyncResult fromRaw(
    Object? raw, {
    WatchSyncOutcome? previous,
    WatchCompanionStatus? status,
  }) {
    if (status != null && (!status.supported || !status.paired)) {
      return unavailable;
    }
    if (status != null && !status.watchAppInstalled) {
      return const WatchSyncResult(
        outcome: WatchSyncOutcome.appNotInstalled,
        ok: false,
      );
    }
    if (raw is Map) {
      final String? named = raw['outcome'] is String
          ? raw['outcome'] as String
          : null;
      final bool ok = raw['ok'] == true;
      WatchSyncOutcome? parsed;
      for (final WatchSyncOutcome value in WatchSyncOutcome.values) {
        if (value.name == named) {
          parsed = value;
          break;
        }
      }
      if (parsed == WatchSyncOutcome.sent &&
          (previous == WatchSyncOutcome.sent ||
              previous == WatchSyncOutcome.updated ||
              previous == WatchSyncOutcome.saved)) {
        parsed = WatchSyncOutcome.updated;
      }
      if (parsed != null) {
        return WatchSyncResult(outcome: parsed, ok: ok);
      }
      if (ok) {
        return WatchSyncResult(
          outcome: status != null && status.reachable
              ? WatchSyncOutcome.sent
              : WatchSyncOutcome.saved,
          ok: true,
        );
      }
    }
    if (raw == true) {
      return const WatchSyncResult(outcome: WatchSyncOutcome.sent, ok: true);
    }
    if (status != null && status.watchAppInstalled && status.paired) {
      return const WatchSyncResult(outcome: WatchSyncOutcome.saved, ok: true);
    }
    return unavailable;
  }
}

typedef WatchChannelInvoke =
    Future<Object?> Function(String method, [dynamic arguments]);

/// Flutter wrapper for `lingo_core/watch_sync`. Widgets never call the channel.
final class WatchCompanionService {
  WatchCompanionService({WatchChannelInvoke? invoke, MethodChannel? channel})
    : _invoke = invoke,
      _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'lingo_core/watch_sync';
  static const String isWatchSupportedMethod = 'isWatchSupported';
  static const String getWatchStatusMethod = 'getWatchStatus';
  static const String sendTestPayloadMethod = 'sendTestPayload';
  static const String syncLearningPlanMethod = 'syncLearningPlan';
  static const String clearLearningPlanMethod = 'clearLearningPlan';

  static WatchCompanionService instance = WatchCompanionService();

  final WatchChannelInvoke? _invoke;
  final MethodChannel _channel;

  @visibleForTesting
  static void resetForTest({WatchCompanionService? service}) {
    instance = service ?? WatchCompanionService();
  }

  Future<bool> isSupported() async {
    final Object? raw = await _call(isWatchSupportedMethod);
    return raw == true;
  }

  Future<WatchCompanionStatus> getStatus() async {
    final Object? raw = await _call(getWatchStatusMethod);
    if (raw == null) {
      return WatchCompanionStatus.unavailable;
    }
    return WatchCompanionStatus.fromRaw(raw);
  }

  Future<bool> sendTestPayload(Map<String, Object?> payload) async {
    final Object? raw = await _call(sendTestPayloadMethod, payload);
    return raw == true || (raw is Map && raw['ok'] == true);
  }

  Future<WatchSyncResult> syncLearningPlan(
    Map<String, Object> payload, {
    WatchSyncOutcome? previous,
  }) {
    return _sync(syncLearningPlanMethod, payload, previous: previous);
  }

  Future<WatchSyncResult> clearLearningPlan({
    Map<String, Object>? payload,
    WatchSyncOutcome? previous,
  }) {
    return _sync(clearLearningPlanMethod, payload, previous: previous);
  }

  Future<WatchSyncResult> _sync(
    String method,
    Map<String, Object>? payload, {
    WatchSyncOutcome? previous,
  }) async {
    final WatchCompanionStatus status = await getStatus();
    if (!status.supported || !status.paired) {
      return WatchSyncResult.unavailable;
    }
    if (!status.watchAppInstalled) {
      return const WatchSyncResult(
        outcome: WatchSyncOutcome.appNotInstalled,
        ok: false,
      );
    }
    final Object? raw = await _call(method, payload);
    return WatchSyncResult.fromRaw(raw, previous: previous, status: status);
  }

  Future<Object?> _call(String method, [dynamic arguments]) async {
    try {
      final WatchChannelInvoke? invoke = _invoke;
      if (invoke != null) {
        return invoke(method, arguments);
      }
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on Object {
      return null;
    }
  }
}
