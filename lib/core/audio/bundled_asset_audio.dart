import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Path helpers for bundled audio. Language packs pass Flutter asset paths
/// (`assets/audio/...`); [audioplayers] expects the path after `assets/`.
abstract final class BundledAudioPaths {
  static String sourcePathFor(String flutterAssetPath) {
    const String prefix = 'assets/';
    if (flutterAssetPath.startsWith(prefix)) {
      return flutterAssetPath.substring(prefix.length);
    }
    return flutterAssetPath;
  }

  static String? mimeTypeFor(String flutterAssetPath) {
    final String path = flutterAssetPath.toLowerCase();
    if (path.endsWith('.wav')) {
      return 'audio/wav';
    }
    if (path.endsWith('.mp3')) {
      return 'audio/mpeg';
    }
    if (path.endsWith('.m4a') || path.endsWith('.aac')) {
      return 'audio/mp4';
    }
    return null;
  }
}

/// One-voice offline player for bundled files. Missing plugins and decode
/// errors are swallowed. Used by UI SFX and spoken pronunciation with
/// different [mode] / [context] values.
final class BundledAssetAudio {
  BundledAssetAudio({
    required this.mode,
    required AudioContext Function() context,
    this.configureGlobalSession = false,
    this.waitForCompletion = false,
  }) : _contextFor = context;

  final PlayerMode mode;
  final AudioContext Function() _contextFor;
  final bool configureGlobalSession;
  final bool waitForCompletion;

  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;
  Completer<void>? _playback;
  bool _unavailable = false;
  bool _configured = false;
  bool _disposed = false;

  Future<void> play(String flutterAssetPath) async {
    if (_disposed) {
      return;
    }
    final AudioPlayer? player = _ensurePlayer();
    if (player == null) {
      return;
    }
    try {
      await _configure(player);
      if (_disposed) {
        return;
      }
      await stop();
      if (_disposed) {
        return;
      }
      Completer<void>? playback;
      if (waitForCompletion) {
        playback = Completer<void>();
        _playback = playback;
        await _completeSub?.cancel();
        _completeSub = player.onPlayerComplete.listen((_) {
          _finishPlayback();
        });
      }
      await player.play(
        AssetSource(
          BundledAudioPaths.sourcePathFor(flutterAssetPath),
          mimeType: BundledAudioPaths.mimeTypeFor(flutterAssetPath),
        ),
        mode: mode,
      );
      if (playback != null) {
        await playback.future;
      }
    } on Object {
      _finishPlayback();
      return;
    }
  }

  Future<void> stop() async {
    _finishPlayback();
    final AudioPlayer? player = _player;
    if (player == null || _disposed) {
      return;
    }
    try {
      await player.stop();
    } on Object {
      return;
    }
  }

  Future<void> warmUp({List<String> assetPaths = const <String>[]}) async {
    if (_disposed) {
      return;
    }
    final AudioPlayer? player = _ensurePlayer();
    if (player == null) {
      return;
    }
    try {
      await _configure(player);
      if (assetPaths.isEmpty) {
        return;
      }
      await player.audioCache.loadAll(<String>[
        for (final String path in assetPaths)
          BundledAudioPaths.sourcePathFor(path),
      ]);
    } on Object {
      return;
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _finishPlayback();
    final AudioPlayer? player = _player;
    _player = null;
    final StreamSubscription<void>? sub = _completeSub;
    _completeSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    if (player == null) {
      return;
    }
    unawaited(_disposePlayer(player));
  }

  AudioPlayer? _ensurePlayer() {
    if (_unavailable || _disposed) {
      return null;
    }
    final AudioPlayer? existing = _player;
    if (existing != null) {
      return existing;
    }
    try {
      final AudioPlayer player = AudioPlayer();
      _player = player;
      return player;
    } on Object {
      _unavailable = true;
      return null;
    }
  }

  Future<void> _configure(AudioPlayer player) async {
    if (_configured) {
      return;
    }
    final AudioContext context = _contextFor();
    if (configureGlobalSession) {
      try {
        await AudioPlayer.global.setAudioContext(context);
      } on Object {
        // Per-player context still applies when the global session fails.
      }
    }
    await player.setAudioContext(context);
    await player.setReleaseMode(ReleaseMode.stop);
    _configured = true;
  }

  void _finishPlayback() {
    final Completer<void>? playback = _playback;
    _playback = null;
    if (playback != null && !playback.isCompleted) {
      playback.complete();
    }
  }

  Future<void> _disposePlayer(AudioPlayer player) async {
    try {
      await player.stop();
      await player.dispose();
    } on Object {
      return;
    }
  }
}
