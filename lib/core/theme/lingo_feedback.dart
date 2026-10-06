import 'dart:async';

import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/lingo_identity.dart';

/// Sensory cues for interactive components.
///
/// Haptics go through [FeedbackService] so the Settings toggle and platform
/// failures apply to every control. Sound stays on explicit [FeedbackEvent]
/// calls; missing cue files are skipped by [SoundService].
enum LingoFeedbackKind { none, tap, select, success, error }

abstract final class LingoFeedback {
  static void play(
    LingoFeedbackKind kind, {
    LingoIdentity identity = LingoIdentity.lingoCore,
  }) {
    if (kind == LingoFeedbackKind.none || !identity.hapticsEnabled) {
      return;
    }
    unawaited(FeedbackService.instance.haptics.play(_hapticLevelFor(kind)));
  }
}

HapticLevel _hapticLevelFor(LingoFeedbackKind kind) {
  switch (kind) {
    case LingoFeedbackKind.none:
      return HapticLevel.none;
    case LingoFeedbackKind.tap:
      return HapticLevel.lightTap;
    case LingoFeedbackKind.select:
      return HapticLevel.selection;
    case LingoFeedbackKind.success:
      return HapticLevel.success;
    case LingoFeedbackKind.error:
      return HapticLevel.warningError;
  }
}
