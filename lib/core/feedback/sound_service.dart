import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lingo_core/core/audio/bundled_asset_audio.dart';
import 'package:lingo_core/core/feedback/feedback_event.dart';

/// Bundled SFX paths. Register each file in `pubspec.yaml`.
abstract final class SoundAssets {
  static const String directory = 'assets/sounds';

  static const String tap = '$directory/sfx_tap.wav';
  static const String correct = '$directory/sfx_correct.wav';
  static const String wrong = '$directory/sfx_wrong.wav';
  static const String success = '$directory/sfx_success.wav';
  static const String selection = '$directory/sfx_selection.wav';

  static const List<String> allPaths = <String>[
    tap,
    selection,
    correct,
    wrong,
    success,
  ];

  static String? pathFor(SoundCue cue) {
    switch (cue) {
      case SoundCue.none:
        return null;
      case SoundCue.tap:
        return tap;
      case SoundCue.correct:
        return correct;
      case SoundCue.wrong:
        return wrong;
      case SoundCue.success:
        return success;
      case SoundCue.selection:
        return selection;
    }
  }

  /// [AssetSource] path: Flutter asset path without the `assets/` prefix.
  static String sourcePathFor(String flutterAssetPath) {
    return BundledAudioPaths.sourcePathFor(flutterAssetPath);
  }
}

/// True when [path] can be loaded from the bundle. Results are cached.
abstract interface class SoundAssetProbe {
  Future<bool> exists(String path);
}

/// [rootBundle] probe. Missing files, simulators, and tests without a binding
/// resolve to false and never throw to UI.
final class BundleSoundAssetProbe implements SoundAssetProbe {
  BundleSoundAssetProbe({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;
  final Map<String, bool> _cache = <String, bool>{};

  @override
  Future<bool> exists(String path) async {
    final bool? cached = _cache[path];
    if (cached != null) {
      return cached;
    }
    try {
      await (_bundle ?? rootBundle).load(path);
      return _cache[path] = true;
    } on Object {
      return _cache[path] = false;
    }
  }
}

/// Unit-test probe that skips the asset bundle.
final class AlwaysPresentSoundAssetProbe implements SoundAssetProbe {
  const AlwaysPresentSoundAssetProbe();

  @override
  Future<bool> exists(String path) {
    return SynchronousFuture<bool>(true);
  }
}

/// Plays short UI cues. One voice: a new cue stops the previous so rapid taps
/// cannot stack. Soft cues are also coalesced. Missing assets are skipped.
final class SoundService {
  SoundService({
    this.enabled = true,
    SoundPlayer? player,
    SoundAssetProbe? probe,
  }) : _player = player ?? BundledSoundPlayer(),
       _probe = probe ?? BundleSoundAssetProbe();

  bool enabled;
  final SoundPlayer _player;
  final SoundAssetProbe _probe;
  final Stopwatch _clock = Stopwatch()..start();
  final Map<String, bool> _availability = <String, bool>{};

  int _playGeneration = 0;
  int _lastSoftMs = -9999;
  SoundCue? _lastSoftCue;
  bool _voiceActive = false;
  bool _disposed = false;

  Future<void> play(SoundCue cue) async {
    if (_disposed || !enabled || cue == SoundCue.none) {
      return;
    }
    if (isSoftSoundCue(cue)) {
      final int now = _clock.elapsedMilliseconds;
      if (cue == _lastSoftCue &&
          now - _lastSoftMs < FeedbackThrottle.softCueMinIntervalMs) {
        return;
      }
      _lastSoftCue = cue;
      _lastSoftMs = now;
    }

    final int generation = ++_playGeneration;
    final String? path = SoundAssets.pathFor(cue);
    if (path == null) {
      return;
    }

    try {
      if (_voiceActive) {
        await _player.stop();
        _voiceActive = false;
        if (_disposed || generation != _playGeneration) {
          return;
        }
      }
      if (!await _hasAsset(path)) {
        return;
      }
      if (_disposed || generation != _playGeneration) {
        return;
      }
      _voiceActive = true;
      await _player.play(cue, path);
      if (generation == _playGeneration) {
        _voiceActive = false;
      }
    } on Object {
      _voiceActive = false;
      return;
    }
  }

  /// Prepares the player and probes every known cue once so later plays hit
  /// the cache.
  Future<void> warmUp() async {
    if (_disposed) {
      return;
    }
    try {
      await _player.warmUp();
    } on Object {
      // Player setup must never surface to UI.
    }
    if (!enabled) {
      return;
    }
    for (final String path in SoundAssets.allPaths) {
      await _hasAsset(path);
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _playGeneration++;
    _player.dispose();
  }

  Future<bool> _hasAsset(String path) {
    final bool? known = _availability[path];
    if (known != null) {
      return SynchronousFuture<bool>(known);
    }
    return _probe.exists(path).then((bool exists) {
      _availability[path] = exists;
      return exists;
    });
  }
}

/// Platform or test backend for [SoundService].
abstract interface class SoundPlayer {
  Future<void> play(SoundCue cue, String assetPath);

  Future<void> stop();

  Future<void> warmUp();

  void dispose();
}

/// No-op backend for widget tests. Avoids audioplayer plugin hangs.
final class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();

  @override
  Future<void> play(SoundCue cue, String assetPath) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

/// One-voice bundled WAV player. Offline assets only; no streaming.
///
/// A new cue stops the previous cue. Missing plugins, missing files, and
/// decode errors are swallowed so learning UI never depends on audio.
final class BundledSoundPlayer implements SoundPlayer {
  BundledSoundPlayer()
    : _audio = BundledAssetAudio(
        mode: PlayerMode.lowLatency,
        context: _sfxContext,
        configureGlobalSession: true,
      );

  final BundledAssetAudio _audio;

  static AudioContext _sfxContext() {
    return AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const <AVAudioSessionOptions>{
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
  }

  @override
  Future<void> play(SoundCue cue, String assetPath) {
    return _audio.play(assetPath);
  }

  @override
  Future<void> stop() => _audio.stop();

  @override
  Future<void> warmUp() {
    return _audio.warmUp(assetPaths: SoundAssets.allPaths);
  }

  @override
  void dispose() {
    _audio.dispose();
  }
}
