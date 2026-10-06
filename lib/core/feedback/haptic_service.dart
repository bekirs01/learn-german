import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lingo_core/core/feedback/feedback_event.dart';

/// Plays one of the four haptic levels. Inject [HapticDriver] in tests.
///
/// Soft levels (light / selection) are coalesced. Success and error always
/// play. Platform and simulator failures are swallowed.
final class HapticService {
  HapticService({this.enabled = true, HapticDriver? driver})
    : _driver = driver ?? const SystemHapticDriver();

  bool enabled;
  final HapticDriver _driver;
  final Stopwatch _clock = Stopwatch()..start();
  int _lastSoftMs = -9999;

  Future<void> play(HapticLevel level) async {
    if (!enabled || level == HapticLevel.none) {
      return;
    }
    if (isSoftHaptic(level)) {
      final int now = _clock.elapsedMilliseconds;
      if (now - _lastSoftMs < FeedbackThrottle.softHapticMinIntervalMs) {
        return;
      }
      _lastSoftMs = now;
    }
    try {
      await _driver.play(level);
    } on Object {
      return;
    }
  }
}

/// Platform backend for [HapticService].
abstract interface class HapticDriver {
  Future<void> play(HapticLevel level);
}

/// No-op backend for widget tests. Avoids platform-channel hangs.
final class SilentHapticDriver implements HapticDriver {
  const SilentHapticDriver();

  @override
  Future<void> play(HapticLevel level) async {}
}

/// Flutter [HapticFeedback] mapping. Error uses medium impact, not a long
/// vibrate, so a wrong answer stays firm but not aggressive.
final class SystemHapticDriver implements HapticDriver {
  const SystemHapticDriver();

  @override
  Future<void> play(HapticLevel level) {
    try {
      switch (level) {
        case HapticLevel.none:
          break;
        case HapticLevel.lightTap:
          unawaited(HapticFeedback.lightImpact());
        case HapticLevel.selection:
          unawaited(HapticFeedback.selectionClick());
        case HapticLevel.success:
        case HapticLevel.warningError:
          unawaited(HapticFeedback.mediumImpact());
      }
    } on Object {
      return SynchronousFuture<void>(null);
    }
    return SynchronousFuture<void>(null);
  }
}
