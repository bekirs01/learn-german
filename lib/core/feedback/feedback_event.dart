/// Learning and UI moments that may play sound and/or haptics.
///
/// Future screens: `FeedbackService.play(event)`. Never fire from scroll
/// handlers, pointer-move, or layout rebuilds.
///
/// Recommended mappings:
/// - normal tap → light haptic; tap SFX only, coalesced
/// - selected answer → selection haptic + short selection SFX
/// - correct answer → success haptic + short positive SFX
/// - wrong answer → error haptic + short negative SFX
/// - favorite → selection haptic, no SFX
/// - alphabet letter → selection haptic, no SFX
enum FeedbackEvent {
  tap,
  selection,
  success,
  error,
  quizCorrect,
  quizWrong,
  favoriteAdded,
  favoriteRemoved,
  learnedMarked,
  learnedUnmarked,
  letterSelected,
  audioPlay,
}

/// Restrained haptic intensities. [warningError] is for real mistakes only.
enum HapticLevel { none, lightTap, selection, success, warningError }

/// Bundled cue slots. Final WAV files land at the paths in [SoundAssets].
enum SoundCue { none, tap, correct, wrong, success, selection }

/// Shared timing so rapid input cannot stack cues.
abstract final class FeedbackThrottle {
  /// Same-cue tap/selection SFX window.
  static const int softCueMinIntervalMs = 70;

  /// Light tap / selection haptic window.
  static const int softHapticMinIntervalMs = 28;
}

/// Maps a feedback event to a haptic level.
HapticLevel hapticLevelFor(FeedbackEvent event) {
  switch (event) {
    case FeedbackEvent.tap:
    case FeedbackEvent.audioPlay:
      return HapticLevel.lightTap;
    case FeedbackEvent.selection:
    case FeedbackEvent.favoriteAdded:
    case FeedbackEvent.favoriteRemoved:
    case FeedbackEvent.learnedMarked:
    case FeedbackEvent.learnedUnmarked:
    case FeedbackEvent.letterSelected:
      return HapticLevel.selection;
    case FeedbackEvent.success:
    case FeedbackEvent.quizCorrect:
      return HapticLevel.success;
    case FeedbackEvent.error:
    case FeedbackEvent.quizWrong:
      return HapticLevel.warningError;
  }
}

/// Maps a feedback event to a sound cue.
///
/// Favorites, letters, and spoken-audio starts stay silent so browsing the
/// alphabet or starring items never becomes a sound bed.
SoundCue soundCueFor(FeedbackEvent event) {
  switch (event) {
    case FeedbackEvent.tap:
      return SoundCue.tap;
    case FeedbackEvent.selection:
      return SoundCue.selection;
    case FeedbackEvent.success:
      return SoundCue.success;
    case FeedbackEvent.quizCorrect:
      return SoundCue.correct;
    case FeedbackEvent.error:
    case FeedbackEvent.quizWrong:
      return SoundCue.wrong;
    case FeedbackEvent.favoriteAdded:
    case FeedbackEvent.favoriteRemoved:
    case FeedbackEvent.learnedMarked:
    case FeedbackEvent.learnedUnmarked:
    case FeedbackEvent.letterSelected:
    case FeedbackEvent.audioPlay:
      return SoundCue.none;
  }
}

bool isSoftHaptic(HapticLevel level) {
  return level == HapticLevel.lightTap || level == HapticLevel.selection;
}

bool isSoftSoundCue(SoundCue cue) {
  return cue == SoundCue.tap || cue == SoundCue.selection;
}
