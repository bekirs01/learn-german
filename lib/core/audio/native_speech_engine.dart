import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingo_core/core/audio/speech_text.dart';
import 'package:lingo_core/core/audio/target_speech_locale.dart';
import 'package:lingo_core/domain/product_config.dart';

/// Native or test backend for target-language TTS.
abstract interface class SpeechEngine {
  Future<void> speak({
    required String text,
    required String locale,
    TargetSpeechProfile? profile,
  });

  Future<void> stop();

  Future<void> warmUp();

  void dispose();
}

/// Native iOS/Android speech synthesis. No network, no cloud TTS, no account.
///
/// One long-lived [FlutterTts] instance. The chosen voice is re-applied before
/// every utterance so consecutive items share the same speaker after stop().
final class NativeSpeechEngine implements SpeechEngine {
  NativeSpeechEngine({FlutterTts? tts}) : _injected = tts;

  final FlutterTts? _injected;
  FlutterTts? _tts;
  bool _configured = false;
  bool _unavailable = false;
  bool _disposed = false;
  String? _boundLocale;
  bool? _awaitSpeakCompletion;
  String? _boundVoiceName;
  Iterable<Object?>? _voiceCatalog;
  Completer<void>? _playback;
  int _utteranceGeneration = 0;

  /// Last installed voice name chosen for debug logs. Null until bound.
  String? get debugSelectedVoice => _boundVoiceName;

  @override
  Future<void> speak({
    required String text,
    required String locale,
    TargetSpeechProfile? profile,
  }) async {
    if (_disposed || _unavailable) {
      return;
    }
    final String? cleaned = SpeechTextNormalizer.clean(text);
    if (cleaned == null) {
      return;
    }
    final String spoken = SpeechTextNormalizer.utterance(cleaned);
    final FlutterTts? tts = _ensureTts();
    if (tts == null) {
      return;
    }
    final TargetSpeechProfile resolved = profile ?? _productProfile();
    try {
      await _configure(tts);
      if (_disposed) {
        return;
      }
      await stop();
      if (_disposed) {
        return;
      }
      final bool ready = await _bindLocale(tts, locale, resolved);
      if (_disposed || !ready) {
        return;
      }
      await tts.setSpeechRate(resolved.resolvedRate);
      await tts.setPitch(resolved.resolvedPitch);
      await tts.setVolume(TargetSpeechProfile.defaultVolume);
      final int generation = ++_utteranceGeneration;
      _bindPlaybackHandlers(tts, generation);
      final Completer<void> playback = Completer<void>();
      _playback = playback;
      final Object? result = await tts.speak(spoken);
      if (generation != _utteranceGeneration) {
        return;
      }
      if (!playback.isCompleted) {
        if (_isFailure(result) || _awaitSpeakCompletion == true) {
          playback.complete();
        }
      }
      if (!playback.isCompleted) {
        await playback.future.timeout(
          _utteranceBudget(spoken),
          onTimeout: () {
            if (generation == _utteranceGeneration) {
              _finishPlayback();
              unawaited(tts.stop());
            }
          },
        );
      }
    } on Object {
      _finishPlayback();
      return;
    }
  }

  @override
  Future<void> stop() async {
    _utteranceGeneration++;
    _finishPlayback();
    final FlutterTts? tts = _tts;
    if (tts == null || _disposed) {
      return;
    }
    try {
      await tts.stop();
    } on Object {
      return;
    }
  }

  @override
  Future<void> warmUp() async {
    if (_disposed || _unavailable) {
      return;
    }
    final FlutterTts? tts = _ensureTts();
    if (tts == null) {
      return;
    }
    try {
      await _configure(tts);
      if (_disposed) {
        return;
      }
      await _bindLocale(tts, TargetSpeechLocale.resolve(), _productProfile());
    } on Object {
      return;
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _utteranceGeneration++;
    _finishPlayback();
    final FlutterTts? tts = _tts;
    _tts = null;
    if (tts == null) {
      return;
    }
    unawaited(_disposeTts(tts));
  }

  FlutterTts? _ensureTts() {
    if (_unavailable || _disposed) {
      return null;
    }
    final FlutterTts? existing = _tts;
    if (existing != null) {
      return existing;
    }
    try {
      final FlutterTts tts = _injected ?? FlutterTts();
      _tts = tts;
      _bindPlaybackHandlers(tts, _utteranceGeneration);
      return tts;
    } on Object {
      _unavailable = true;
      return null;
    }
  }

  Future<void> _configure(FlutterTts tts) async {
    if (_configured) {
      return;
    }
    try {
      await tts.setSharedInstance(true);
    } on Object {
      // Android has no shared-instance concept.
    }
    try {
      await tts.awaitSpeakCompletion(true);
      _awaitSpeakCompletion = true;
    } on Object {
      _awaitSpeakCompletion = false;
    }
    try {
      await tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        <IosTextToSpeechAudioCategoryOptions>[
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    } on Object {
      // Android ignores iOS session configuration.
    }
    try {
      await tts.setQueueMode(0);
    } on Object {
      // iOS has no queue-mode API; stop() already replaces in-flight speech.
    }
    _configured = true;
  }

  Future<bool> _bindLocale(
    FlutterTts tts,
    String locale,
    TargetSpeechProfile profile,
  ) async {
    final String tag = TargetSpeechLocale.canonicalize(locale);
    try {
      final Object? available = await tts.isLanguageAvailable(tag);
      if (_isFailure(available)) {
        final String language = TargetSpeechLocale.languageCode(tag);
        final Object? languageAvailable = await tts.isLanguageAvailable(
          language,
        );
        if (_isFailure(languageAvailable)) {
          // Still try setLanguage; some engines accept tags they do not list.
        }
      }
      final Object? languageResult = await tts.setLanguage(tag);
      if (_isFailure(languageResult)) {
        final Object? languageOnly = await tts.setLanguage(
          TargetSpeechLocale.languageCode(tag),
        );
        if (_isFailure(languageOnly)) {
          // Do not continue into a different-language system default.
          return false;
        }
      }
      // Re-apply the cached pick every utterance. stop() can reset the voice.
      final Iterable<Object?>? catalog = await _voices(tts);
      final Map<String, String>? voice = catalog == null
          ? null
          : SpeechVoicePicker.select(
              voices: catalog,
              locale: tag,
              profile: profile,
            );
      if (voice != null) {
        try {
          await tts.setVoice(<String, String>{
            'name': voice['name']!,
            'locale': voice['locale']!,
          });
          if (_boundVoiceName != voice['name'] || _boundLocale != tag) {
            _logVoice(voice);
          }
          _boundVoiceName = voice['name'];
        } on Object {
          _boundVoiceName = null;
        }
      } else if (catalog != null && catalog.isNotEmpty) {
        // Installed voices exist, but none match the target language.
        // Never silently speak English (or any other language) instead.
        if (kDebugMode) {
          debugPrint('Lingo pronunciation voice: no compatible voice for $tag');
        }
        _boundVoiceName = null;
        return false;
      } else {
        if (_boundVoiceName != null || _boundLocale != tag) {
          if (kDebugMode) {
            debugPrint(
              'Lingo pronunciation voice: locale $tag (system default)',
            );
          }
        }
        _boundVoiceName = null;
      }
      _boundLocale = tag;
      return true;
    } on Object {
      return false;
    }
  }

  Future<Iterable<Object?>?> _voices(FlutterTts tts) async {
    final Iterable<Object?>? cached = _voiceCatalog;
    if (cached != null) {
      return cached;
    }
    try {
      final Object? voices = await tts.getVoices;
      if (voices is! Iterable) {
        return null;
      }
      final List<Object?> catalog = List<Object?>.from(voices);
      _voiceCatalog = catalog;
      return catalog;
    } on Object {
      return null;
    }
  }

  void _logVoice(Map<String, String> voice) {
    if (!kDebugMode) {
      return;
    }
    final String quality = voice['quality']!.trim();
    final String gender = voice['gender']!.trim();
    debugPrint(
      'Lingo pronunciation voice: ${voice['name']} '
      'locale=${voice['locale']}'
      '${quality.isEmpty ? '' : ' quality=$quality'}'
      '${gender.isEmpty ? '' : ' gender=$gender'}',
    );
  }

  static Duration _utteranceBudget(String spoken) {
    final int ms = 800 + (spoken.length * 80);
    if (ms < 2000) {
      return const Duration(seconds: 2);
    }
    if (ms > 12000) {
      return const Duration(seconds: 12);
    }
    return Duration(milliseconds: ms);
  }

  static TargetSpeechProfile _productProfile() {
    return ProductConfig.current.speechProfile;
  }

  void _bindPlaybackHandlers(FlutterTts tts, int generation) {
    void onDone() {
      if (generation != _utteranceGeneration) {
        return;
      }
      _finishPlayback();
    }

    tts.setCompletionHandler(onDone);
    tts.setCancelHandler(onDone);
    tts.setErrorHandler((Object? _) {
      onDone();
    });
  }

  void _finishPlayback() {
    final Completer<void>? playback = _playback;
    _playback = null;
    if (playback != null && !playback.isCompleted) {
      playback.complete();
    }
  }

  Future<void> _disposeTts(FlutterTts tts) async {
    try {
      await tts.stop();
    } on Object {
      return;
    }
  }

  static bool _isFailure(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return !value;
    }
    if (value is num) {
      return value == 0;
    }
    return false;
  }
}
