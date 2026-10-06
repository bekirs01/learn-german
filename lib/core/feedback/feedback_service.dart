import 'dart:async';

import 'package:lingo_core/core/feedback/feedback_event.dart';
import 'package:lingo_core/core/feedback/haptic_service.dart';
import 'package:lingo_core/core/feedback/sound_service.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';

export 'package:lingo_core/core/feedback/feedback_event.dart';
export 'package:lingo_core/core/feedback/haptic_service.dart';
export 'package:lingo_core/core/feedback/sound_service.dart';

/// Single entry point for UI cues:
/// `FeedbackService.play(FeedbackEvent.quizCorrect);`
///
/// Sound and haptics are toggled independently on [instance]. Spoken
/// pronunciation uses [PronunciationService].
final class FeedbackService {
  FeedbackService({
    HapticService? haptics,
    SoundService? sound,
    bool hapticsEnabled = true,
    bool soundEnabled = true,
  }) : haptics =
           haptics ??
           HapticService(
             enabled: hapticsEnabled,
             driver: lingoInWidgetTest
                 ? const SilentHapticDriver()
                 : const SystemHapticDriver(),
           ),
       sound =
           sound ??
           SoundService(
             enabled: soundEnabled,
             player: lingoInWidgetTest
                 ? const SilentSoundPlayer()
                 : BundledSoundPlayer(),
           ) {
    this.haptics.enabled = hapticsEnabled;
    this.sound.enabled = soundEnabled;
  }

  /// App-wide instance. Tests may replace it; call [resetInstance] after.
  static FeedbackService instance = FeedbackService();

  static void resetInstance() {
    instance.dispose();
    instance = FeedbackService();
  }

  /// Fire-and-forget API for screens. Never throws.
  static void play(FeedbackEvent event) {
    unawaited(instance.dispatch(event));
  }

  final HapticService haptics;
  final SoundService sound;
  bool _disposed = false;

  bool get hapticsEnabled => haptics.enabled;

  set hapticsEnabled(bool value) {
    haptics.enabled = value;
  }

  bool get soundEnabled => sound.enabled;

  set soundEnabled(bool value) {
    sound.enabled = value;
  }

  Future<void> dispatch(FeedbackEvent event) async {
    if (_disposed) {
      return;
    }
    try {
      await Future.wait<void>(<Future<void>>[
        haptics.play(hapticLevelFor(event)),
        sound.play(soundCueFor(event)),
      ]);
    } on Object {
      return;
    }
  }

  Future<void> warmUp() => sound.warmUp();

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    sound.dispose();
  }
}
