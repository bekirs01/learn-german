import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/feedback/feedback_harness.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';

void main() {
  tearDown(FeedbackService.resetInstance);

  group('event mapping', () {
    test('uses the recommended haptic palette', () {
      expect(hapticLevelFor(FeedbackEvent.tap), HapticLevel.lightTap);
      expect(hapticLevelFor(FeedbackEvent.selection), HapticLevel.selection);
      expect(hapticLevelFor(FeedbackEvent.quizCorrect), HapticLevel.success);
      expect(hapticLevelFor(FeedbackEvent.quizWrong), HapticLevel.warningError);
      expect(
        hapticLevelFor(FeedbackEvent.favoriteAdded),
        HapticLevel.selection,
      );
      expect(
        hapticLevelFor(FeedbackEvent.favoriteRemoved),
        HapticLevel.selection,
      );
      expect(
        hapticLevelFor(FeedbackEvent.letterSelected),
        HapticLevel.selection,
      );
      expect(hapticLevelFor(FeedbackEvent.audioPlay), HapticLevel.lightTap);
      expect(hapticLevelFor(FeedbackEvent.success), HapticLevel.success);
      expect(hapticLevelFor(FeedbackEvent.error), HapticLevel.warningError);
    });

    test('keeps favorites, letters, and spoken audio silent', () {
      expect(soundCueFor(FeedbackEvent.tap), SoundCue.tap);
      expect(soundCueFor(FeedbackEvent.selection), SoundCue.selection);
      expect(soundCueFor(FeedbackEvent.quizCorrect), SoundCue.correct);
      expect(soundCueFor(FeedbackEvent.quizWrong), SoundCue.wrong);
      expect(soundCueFor(FeedbackEvent.success), SoundCue.success);
      expect(soundCueFor(FeedbackEvent.error), SoundCue.wrong);
      expect(soundCueFor(FeedbackEvent.favoriteAdded), SoundCue.none);
      expect(soundCueFor(FeedbackEvent.favoriteRemoved), SoundCue.none);
      expect(soundCueFor(FeedbackEvent.letterSelected), SoundCue.none);
      expect(soundCueFor(FeedbackEvent.audioPlay), SoundCue.none);
    });

    test('sound asset paths stay under the sounds folder', () {
      expect(SoundAssets.pathFor(SoundCue.none), isNull);
      expect(SoundAssets.pathFor(SoundCue.tap), 'assets/sounds/sfx_tap.wav');
      expect(
        SoundAssets.pathFor(SoundCue.correct),
        'assets/sounds/sfx_correct.wav',
      );
      expect(
        SoundAssets.pathFor(SoundCue.wrong),
        'assets/sounds/sfx_wrong.wav',
      );
      expect(
        SoundAssets.pathFor(SoundCue.success),
        'assets/sounds/sfx_success.wav',
      );
      expect(
        SoundAssets.pathFor(SoundCue.selection),
        'assets/sounds/sfx_selection.wav',
      );
      expect(SoundAssets.allPaths, hasLength(5));
      expect(SoundAssets.sourcePathFor(SoundAssets.tap), 'sounds/sfx_tap.wav');
    });

    test('ships original short pcm wav files', () {
      int totalBytes = 0;
      for (final String path in SoundAssets.allPaths) {
        final File file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        final int size = file.lengthSync();
        totalBytes += size;
        expect(size, greaterThan(44), reason: path);
        expect(size, lessThan(40 * 1024), reason: path);
        final Uint8List bytes = file.readAsBytesSync();
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: path);
        expect(
          String.fromCharCodes(bytes.sublist(8, 12)),
          'WAVE',
          reason: path,
        );
      }
      expect(totalBytes, lessThan(40 * 1024));
    });
  });

  group('HapticService', () {
    test('plays through the driver when enabled', () async {
      final _RecordingHapticDriver driver = _RecordingHapticDriver();
      final HapticService service = HapticService(driver: driver);

      await service.play(HapticLevel.success);
      await service.play(HapticLevel.warningError);
      await service.play(HapticLevel.none);

      expect(driver.played, <HapticLevel>[
        HapticLevel.success,
        HapticLevel.warningError,
      ]);
    });

    test('coalesces rapid light taps', () async {
      final _RecordingHapticDriver driver = _RecordingHapticDriver();
      final HapticService service = HapticService(driver: driver);

      for (int i = 0; i < 20; i++) {
        await service.play(HapticLevel.lightTap);
      }

      expect(driver.played, <HapticLevel>[HapticLevel.lightTap]);
    });

    test('does not play when disabled', () async {
      final _RecordingHapticDriver driver = _RecordingHapticDriver();
      final HapticService service = HapticService(
        enabled: false,
        driver: driver,
      );

      await service.play(HapticLevel.success);

      expect(driver.played, isEmpty);
    });

    test('swallows simulator and plugin failures', () async {
      final HapticService service = HapticService(
        driver: const _ThrowingHapticDriver(),
      );

      await service.play(HapticLevel.success);
    });
  });

  group('SoundService', () {
    test('plays mapped cues with placeholder asset paths', () async {
      final _RecordingSoundPlayer player = _RecordingSoundPlayer();
      final SoundService service = SoundService(
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      await service.play(SoundCue.tap);
      await service.play(SoundCue.correct);
      await service.play(SoundCue.none);

      expect(player.cues, <SoundCue>[SoundCue.tap, SoundCue.correct]);
      expect(player.paths, <String>[SoundAssets.tap, SoundAssets.correct]);
    });

    test('drops overlapping rapid taps instead of stacking', () async {
      final _RecordingSoundPlayer player = _RecordingSoundPlayer();
      final SoundService service = SoundService(
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      final List<Future<void>> plays = <Future<void>>[
        for (int i = 0; i < 20; i++) service.play(SoundCue.tap),
      ];
      await Future.wait(plays);

      expect(player.cues, <SoundCue>[SoundCue.tap]);
      expect(player.stopCount, 0);
    });

    test('interrupts a previous cue when a new distinct cue arrives', () async {
      final _DelayedSoundPlayer player = _DelayedSoundPlayer();
      final SoundService service = SoundService(
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      final Future<void> first = service.play(SoundCue.correct);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final Future<void> second = service.play(SoundCue.wrong);
      await Future.wait<void>(<Future<void>>[first, second]);

      expect(player.cues, <SoundCue>[SoundCue.correct, SoundCue.wrong]);
      expect(player.stopCount, 1);
    });

    test('skips missing assets and does not call the player', () async {
      final _RecordingSoundPlayer player = _RecordingSoundPlayer();
      final SoundService service = SoundService(
        player: player,
        probe: const _MissingSoundAssetProbe(),
      );

      await service.play(SoundCue.success);

      expect(player.cues, isEmpty);
    });

    test('missing bundle assets never throw', () async {
      final SoundService service = SoundService(
        probe: BundleSoundAssetProbe(bundle: _MissingAssetBundle()),
      );

      await service.warmUp();
      await service.play(SoundCue.tap);
    });

    test('player failures never throw', () async {
      final SoundService service = SoundService(
        player: const _ThrowingSoundPlayer(),
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      await service.play(SoundCue.wrong);
    });

    test('does not play when disabled', () async {
      final _RecordingSoundPlayer player = _RecordingSoundPlayer();
      final SoundService service = SoundService(
        enabled: false,
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      await service.play(SoundCue.success);

      expect(player.cues, isEmpty);
    });

    test('warms the player even when sound is disabled', () async {
      final _RecordingSoundPlayer player = _RecordingSoundPlayer();
      final SoundService service = SoundService(
        enabled: false,
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      await service.warmUp();
      await service.play(SoundCue.tap);

      expect(player.warmUpCount, 1);
      expect(player.cues, isEmpty);
    });

    test('dispose is idempotent and blocks later plays', () async {
      final _RecordingSoundPlayer player = _RecordingSoundPlayer();
      final SoundService service = SoundService(
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      service.dispose();
      service.dispose();
      await service.play(SoundCue.tap);

      expect(player.disposed, isTrue);
      expect(player.cues, isEmpty);
    });

    test('default player fails closed without a platform plugin', () async {
      final SoundService service = SoundService(
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      await service.warmUp();
      await service.play(SoundCue.tap);
      await service.play(SoundCue.tap);
      await service.play(SoundCue.correct);
      service.dispose();
      service.dispose();
    });
  });

  group('BundledSoundPlayer', () {
    test('play stop warmUp and dispose never throw', () async {
      final BundledSoundPlayer player = BundledSoundPlayer();

      await player.warmUp();
      await player.play(SoundCue.correct, SoundAssets.correct);
      await player.play(SoundCue.wrong, SoundAssets.wrong);
      await player.play(SoundCue.success, SoundAssets.success);
      await player.play(SoundCue.selection, SoundAssets.selection);
      await player.play(SoundCue.tap, SoundAssets.tap);
      await player.stop();
      player.dispose();
      await player.play(SoundCue.tap, SoundAssets.tap);
      await player.stop();
      player.dispose();
    });

    test('rapid repeated playback stays single-voice', () async {
      final BundledSoundPlayer player = BundledSoundPlayer();

      await Future.wait(<Future<void>>[
        for (int i = 0; i < 12; i++)
          player.play(SoundCue.correct, SoundAssets.correct),
      ]);
      await player.stop();
      player.dispose();
    });
  });

  group('FeedbackService', () {
    test('plays haptics and sound together', () async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      final FeedbackService service = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      await service.dispatch(FeedbackEvent.quizCorrect);
      await service.dispatch(FeedbackEvent.quizWrong);
      await service.dispatch(FeedbackEvent.letterSelected);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await service.dispatch(FeedbackEvent.favoriteAdded);

      expect(haptics.played, <HapticLevel>[
        HapticLevel.success,
        HapticLevel.warningError,
        HapticLevel.selection,
        HapticLevel.selection,
      ]);
      expect(sounds.cues, <SoundCue>[SoundCue.correct, SoundCue.wrong]);
    });

    test('starts sound without waiting for a slow haptic', () async {
      final _SlowHapticDriver haptics = _SlowHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      final FeedbackService service = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      final Future<void> pending = service.dispatch(FeedbackEvent.quizCorrect);
      await Future<void>.delayed(Duration.zero);
      expect(sounds.cues, <SoundCue>[SoundCue.correct]);
      expect(haptics.started, isTrue);
      expect(haptics.played, isEmpty);
      haptics.complete();
      await pending;
      expect(haptics.played, <HapticLevel>[HapticLevel.success]);
    });

    test('quiz correct, wrong, and success still play SFX', () async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      final FeedbackService service = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      await service.dispatch(FeedbackEvent.quizCorrect);
      await service.dispatch(FeedbackEvent.quizWrong);
      await service.dispatch(FeedbackEvent.success);

      expect(sounds.cues, <SoundCue>[
        SoundCue.correct,
        SoundCue.wrong,
        SoundCue.success,
      ]);
      expect(haptics.played, <HapticLevel>[
        HapticLevel.success,
        HapticLevel.warningError,
        HapticLevel.success,
      ]);
    });

    test('toggles sound and haptics independently', () async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      final FeedbackService service = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      service.soundEnabled = false;
      await service.dispatch(FeedbackEvent.quizCorrect);
      expect(haptics.played, <HapticLevel>[HapticLevel.success]);
      expect(sounds.cues, isEmpty);

      service.soundEnabled = true;
      service.hapticsEnabled = false;
      await service.dispatch(FeedbackEvent.quizWrong);
      expect(haptics.played, <HapticLevel>[HapticLevel.success]);
      expect(sounds.cues, <SoundCue>[SoundCue.wrong]);
    });

    test('sound effects toggle immediately gates mapped cues', () async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      final FeedbackService service = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      await service.dispatch(FeedbackEvent.quizCorrect);
      await service.dispatch(FeedbackEvent.selection);
      await service.dispatch(FeedbackEvent.tap);
      await service.dispatch(FeedbackEvent.success);
      expect(sounds.cues, <SoundCue>[
        SoundCue.correct,
        SoundCue.selection,
        SoundCue.tap,
        SoundCue.success,
      ]);

      service.soundEnabled = false;
      await service.dispatch(FeedbackEvent.quizWrong);
      await service.dispatch(FeedbackEvent.success);
      expect(sounds.cues, <SoundCue>[
        SoundCue.correct,
        SoundCue.selection,
        SoundCue.tap,
        SoundCue.success,
      ]);
      expect(haptics.played, isNotEmpty);

      service.soundEnabled = true;
      await service.dispatch(FeedbackEvent.quizWrong);
      expect(sounds.cues.last, SoundCue.wrong);
    });

    test('static play uses the shared instance', () async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      FeedbackService.instance = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          player: _RecordingSoundPlayer(),
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      FeedbackService.play(FeedbackEvent.letterSelected);
      await Future<void>.delayed(Duration.zero);
      expect(haptics.played, <HapticLevel>[HapticLevel.selection]);

      FeedbackService.instance.hapticsEnabled = false;
      FeedbackService.instance.soundEnabled = false;
      expect(FeedbackService.instance.hapticsEnabled, isFalse);
      expect(FeedbackService.instance.soundEnabled, isFalse);
    });
  });

  group('LingoFeedback', () {
    test('routes through HapticService and respects the toggle', () async {
      final _RecordingHapticDriver driver = _RecordingHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      FeedbackService.instance = FeedbackService(
        haptics: HapticService(driver: driver),
        sound: SoundService(
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      LingoFeedback.play(LingoFeedbackKind.tap);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      LingoFeedback.play(LingoFeedbackKind.select);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      LingoFeedback.play(LingoFeedbackKind.success);
      LingoFeedback.play(LingoFeedbackKind.error);
      await Future<void>.delayed(Duration.zero);

      expect(driver.played, <HapticLevel>[
        HapticLevel.lightTap,
        HapticLevel.selection,
        HapticLevel.success,
        HapticLevel.warningError,
      ]);
      expect(sounds.cues, isEmpty);

      FeedbackService.instance.hapticsEnabled = false;
      LingoFeedback.play(LingoFeedbackKind.tap);
      await Future<void>.delayed(Duration.zero);
      expect(driver.played, hasLength(4));
    });

    test('swallows platform haptic failures from controls', () async {
      FeedbackService.instance = FeedbackService(
        haptics: HapticService(driver: const _ThrowingHapticDriver()),
        sound: SoundService(
          player: _RecordingSoundPlayer(),
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      LingoFeedback.play(LingoFeedbackKind.error);
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('FeedbackHarness', () {
    testWidgets('is a developer surface and does not throw', (
      WidgetTester tester,
    ) async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      final FeedbackService service = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: FeedbackHarness(service: service)),
      );

      expect(find.text('Feedback harness'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Haptics'), findsOneWidget);

      await tester.tap(find.text('quizCorrect'));
      await tester.pump();
      await tester.tap(find.text('letterSelected'));
      await tester.pump();

      expect(haptics.played, isNotEmpty);
      expect(sounds.cues, <SoundCue>[SoundCue.correct]);
    });
  });
}

final class _RecordingHapticDriver implements HapticDriver {
  final List<HapticLevel> played = <HapticLevel>[];

  @override
  Future<void> play(HapticLevel level) async {
    played.add(level);
  }
}

final class _ThrowingHapticDriver implements HapticDriver {
  const _ThrowingHapticDriver();

  @override
  Future<void> play(HapticLevel level) {
    throw MissingPluginException('simulator');
  }
}

final class _SlowHapticDriver implements HapticDriver {
  final Completer<void> _done = Completer<void>();
  final List<HapticLevel> played = <HapticLevel>[];
  bool started = false;

  @override
  Future<void> play(HapticLevel level) async {
    started = true;
    await _done.future;
    played.add(level);
  }

  void complete() {
    if (!_done.isCompleted) {
      _done.complete();
    }
  }
}

final class _RecordingSoundPlayer implements SoundPlayer {
  final List<SoundCue> cues = <SoundCue>[];
  final List<String> paths = <String>[];
  int stopCount = 0;
  bool disposed = false;
  int warmUpCount = 0;

  @override
  Future<void> play(SoundCue cue, String assetPath) async {
    cues.add(cue);
    paths.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> warmUp() async {
    warmUpCount++;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

final class _DelayedSoundPlayer extends _RecordingSoundPlayer {
  @override
  Future<void> play(SoundCue cue, String assetPath) async {
    await super.play(cue, assetPath);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

final class _ThrowingSoundPlayer implements SoundPlayer {
  const _ThrowingSoundPlayer();

  @override
  Future<void> play(SoundCue cue, String assetPath) {
    throw FlutterError('missing decoder');
  }

  @override
  Future<void> stop() {
    throw FlutterError('stop failed');
  }

  @override
  Future<void> warmUp() {
    throw FlutterError('warm up failed');
  }

  @override
  void dispose() {}
}

final class _MissingSoundAssetProbe implements SoundAssetProbe {
  const _MissingSoundAssetProbe();

  @override
  Future<bool> exists(String path) async => false;
}

final class _MissingAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) {
    throw FlutterError('unable to load asset: $key');
  }
}
