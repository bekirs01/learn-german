import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:lingo_core/core/audio/bundled_asset_audio.dart';
import 'package:lingo_core/core/audio/expected_audio.dart';
import 'package:lingo_core/core/audio/native_speech_engine.dart';
import 'package:lingo_core/core/audio/speech_text.dart';
import 'package:lingo_core/core/audio/target_speech_locale.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/product_config.dart';

export 'package:lingo_core/core/audio/native_speech_engine.dart';
export 'package:lingo_core/core/audio/speech_text.dart';
export 'package:lingo_core/core/audio/target_speech_locale.dart';

/// Spoken clip resolved from language-pack data.
///
/// [assetPath] is an optional bundled recording. [speechText] is the
/// target-language text for native TTS when no usable file is present.
final class PronunciationClip {
  const PronunciationClip({required this.id, this.assetPath, this.speechText});

  factory PronunciationClip.fromAlphabet(AlphabetUnit unit) {
    return PronunciationClip(
      id: unit.id,
      assetPath: ExpectedAudio.resolveDeclaredOrExpected(
        declared: unit.audioAsset,
        contentId: unit.id,
      ),
      speechText: PronunciationSpeechText.ofAlphabet(unit),
    );
  }

  factory PronunciationClip.fromWord(WordEntry word) {
    return PronunciationClip(
      id: word.id,
      assetPath: ExpectedAudio.resolveDeclaredOrExpected(
        declared: word.audioAsset,
        contentId: word.id,
      ),
      speechText: PronunciationSpeechText.ofWord(word),
    );
  }

  factory PronunciationClip.fromPhrase(PhraseEntry phrase) {
    return PronunciationClip(
      id: phrase.id,
      assetPath: ExpectedAudio.resolveDeclaredOrExpected(
        declared: phrase.audioAsset,
        contentId: phrase.id,
      ),
      speechText: PronunciationSpeechText.ofPhrase(phrase),
    );
  }

  factory PronunciationClip.fromQuizItem(QuizReadyItem item) {
    return PronunciationClip(
      id: item.id,
      assetPath: ExpectedAudio.resolveDeclaredOrExpected(
        declared: item.audioAsset,
        contentId: item.id,
      ),
      speechText: PronunciationSpeechText.ofQuizItem(item),
    );
  }

  /// Resolves alphabet, word, or phrase audio through the repository.
  factory PronunciationClip.fromContent(ContentRepository content, String id) {
    final AlphabetUnit? unit = content.alphabetUnitById(id);
    if (unit != null) {
      return PronunciationClip.fromAlphabet(unit);
    }
    final WordEntry? word = content.wordById(id);
    if (word != null) {
      return PronunciationClip.fromWord(word);
    }
    final PhraseEntry? phrase = content.phraseById(id);
    if (phrase != null) {
      return PronunciationClip.fromPhrase(phrase);
    }
    return PronunciationClip(
      id: id,
      assetPath: content.pronunciationAssetFor(id),
    );
  }

  final String id;
  final String? assetPath;
  final String? speechText;

  bool get hasReference {
    final String? path = assetPath;
    return path != null && path.isNotEmpty;
  }

  bool get hasSpeechText => SpeechTextNormalizer.clean(speechText) != null;

  bool get canPlay => hasReference || hasSpeechText;
}

/// Data-driven spoken form. Never uses learner translations or example words.
abstract final class PronunciationSpeechText {
  /// Alphabet TTS input. Uses the pack's dedicated [AlphabetUnit.speechText]
  /// when present, otherwise the written glyph. Never pronunciation cues,
  /// example words, accessibility labels, or case descriptions.
  static String? ofAlphabet(AlphabetUnit unit) {
    return firstSpeakable(<String?>[unit.speechText, unit.glyph]);
  }

  static String? ofWord(WordEntry word) =>
      SpeechTextNormalizer.clean(word.text);

  static String? ofPhrase(PhraseEntry phrase) {
    return SpeechTextNormalizer.clean(phrase.text);
  }

  static String? ofQuizItem(QuizReadyItem item) {
    return SpeechTextNormalizer.clean(item.prompt);
  }

  static String? firstSpeakable(Iterable<String?> values) {
    for (final String? value in values) {
      final String? speakable = SpeechTextNormalizer.clean(value);
      if (speakable != null) {
        return speakable;
      }
    }
    return null;
  }
}

enum PronunciationPhase { idle, loading, playing }

enum PronunciationAvailability { disabled, missing, ready }

enum PronunciationSource { bundled, tts }

/// Product-level spoken audio. Independent of the Sound Effects toggle.
///
/// Screens call `PronunciationService.play(clip)` or [PronunciationControl].
final class PronunciationService extends ChangeNotifier {
  PronunciationService({
    bool? audioEnabled,
    PronunciationPlayer? player,
    SpeechEngine? speech,
    SoundAssetProbe? probe,
    String? speechLocale,
    TargetSpeechProfile? speechProfile,
    void Function()? onStarted,
  }) : _capabilityOverride = audioEnabled,
       _player =
           player ??
           (lingoInWidgetTest
               ? const SilentPronunciationPlayer()
               : BundledPronunciationPlayer()),
       _speech =
           speech ??
           (lingoInWidgetTest
               ? const SilentSpeechEngine()
               : NativeSpeechEngine()),
       _probe = probe ?? BundleSoundAssetProbe(),
       _speechLocaleOverride = speechLocale,
       _speechProfileOverride = speechProfile,
       _onStarted = onStarted;

  /// App-wide instance. Tests may replace it; call [resetInstance] after.
  static PronunciationService instance = PronunciationService();

  static void resetInstance() {
    instance.dispose();
    instance = PronunciationService();
  }

  /// Fire-and-forget API for screens. Never throws.
  static void play(PronunciationClip clip) {
    unawaited(instance.playClip(clip));
  }

  final PronunciationPlayer _player;
  final SpeechEngine _speech;
  final SoundAssetProbe _probe;
  final String? _speechLocaleOverride;
  final TargetSpeechProfile? _speechProfileOverride;
  final void Function()? _onStarted;
  final Map<String, bool> _availability = <String, bool>{};
  final Stopwatch _clock = Stopwatch()..start();

  bool? _capabilityOverride;
  PronunciationPhase _phase = PronunciationPhase.idle;
  PronunciationSource? _activeSource;
  String? _activeId;
  int _playGeneration = 0;
  int _lastPlayMs = -9999;
  String? _lastPlayId;
  bool _disposed = false;

  /// Spoken-audio product flag. Not the Settings Sound Effects switch.
  bool get audioEnabled {
    return _capabilityOverride ?? ProductConfig.current.featureFlags.audio;
  }

  set audioEnabled(bool value) {
    if (_capabilityOverride == value) {
      return;
    }
    _capabilityOverride = value;
    if (!value) {
      unawaited(stop());
    }
    notifyListeners();
  }

  /// Target-language TTS locale. Independent of Translation Language.
  String get speechLocale {
    return TargetSpeechLocale.canonicalize(
      _speechLocaleOverride ?? TargetSpeechLocale.resolve(),
    );
  }

  /// Voice, rate, and pitch for the language being learned.
  TargetSpeechProfile get speechProfile {
    return _speechProfileOverride ?? ProductConfig.current.speechProfile;
  }

  PronunciationPhase get phase => _phase;

  PronunciationSource? get activeSource => _activeSource;

  String? get activeId => _activeId;

  bool get isPlaying => _phase == PronunciationPhase.playing;

  bool isPlayingClip(PronunciationClip clip) {
    return isPlaying && _activeId == clip.id;
  }

  /// True when the product allows spoken audio and the item can be played.
  bool isOffered(PronunciationClip clip) {
    return audioEnabled && clip.canPlay;
  }

  Future<PronunciationAvailability> availabilityFor(
    PronunciationClip clip,
  ) async {
    if (_disposed || !audioEnabled) {
      return PronunciationAvailability.disabled;
    }
    if (clip.hasReference && await _hasAsset(clip.assetPath!)) {
      return PronunciationAvailability.ready;
    }
    if (clip.hasSpeechText) {
      return PronunciationAvailability.ready;
    }
    if (clip.hasReference) {
      return PronunciationAvailability.missing;
    }
    return PronunciationAvailability.missing;
  }

  Future<void> playClip(PronunciationClip clip) async {
    if (_disposed || !audioEnabled || !clip.canPlay) {
      return;
    }
    final int now = _clock.elapsedMilliseconds;
    if (clip.id == _lastPlayId &&
        now - _lastPlayMs < FeedbackThrottle.softCueMinIntervalMs) {
      return;
    }
    _lastPlayId = clip.id;
    _lastPlayMs = now;

    final int generation = ++_playGeneration;
    _phase = PronunciationPhase.loading;
    _activeId = clip.id;
    _activeSource = null;
    notifyListeners();

    try {
      await _haltEngines();
      if (_disposed || generation != _playGeneration) {
        return;
      }
      final String? assetPath = clip.assetPath;
      if (clip.hasReference && await _hasAsset(assetPath!)) {
        if (_disposed || generation != _playGeneration) {
          return;
        }
        _phase = PronunciationPhase.playing;
        _activeSource = PronunciationSource.bundled;
        notifyListeners();
        _notifyStarted();
        await _player.play(assetPath);
        if (generation == _playGeneration) {
          _idle();
        }
        return;
      }
      final String? spoken = SpeechTextNormalizer.clean(clip.speechText);
      if (spoken == null) {
        if (generation == _playGeneration) {
          _idle();
        }
        return;
      }
      if (_disposed || generation != _playGeneration) {
        return;
      }
      _phase = PronunciationPhase.playing;
      _activeSource = PronunciationSource.tts;
      notifyListeners();
      _notifyStarted();
      await _speech.speak(
        text: spoken,
        locale: speechLocale,
        profile: speechProfile,
      );
      if (generation == _playGeneration) {
        _idle();
      }
    } on Object {
      if (generation == _playGeneration) {
        _idle();
      }
    }
  }

  Future<void> stop() async {
    _playGeneration++;
    try {
      await _haltEngines();
    } on Object {
      // Stop is best-effort.
    }
    if (_disposed) {
      return;
    }
    _idle();
  }

  Future<void> warmUp() async {
    if (_disposed || !audioEnabled) {
      return;
    }
    try {
      await _player.warmUp();
      await _speech.warmUp();
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
    _playGeneration++;
    _player.dispose();
    _speech.dispose();
    super.dispose();
  }

  void _idle() {
    _phase = PronunciationPhase.idle;
    _activeId = null;
    _activeSource = null;
    notifyListeners();
  }

  Future<void> _haltEngines() async {
    try {
      await _player.stop();
    } on Object {
      // Best-effort.
    }
    try {
      await _speech.stop();
    } on Object {
      // Best-effort.
    }
  }

  void _notifyStarted() {
    final void Function()? onStarted = _onStarted;
    if (onStarted != null) {
      onStarted();
      return;
    }
    FeedbackService.play(FeedbackEvent.audioPlay);
  }

  Future<bool> _hasAsset(String path) async {
    final bool? known = _availability[path];
    if (known != null) {
      return known;
    }
    final bool exists = await _probe.exists(path);
    _availability[path] = exists;
    return exists;
  }
}

/// Platform or test backend for bundled pronunciation files.
abstract interface class PronunciationPlayer {
  Future<void> play(String assetPath);

  Future<void> stop();

  Future<void> warmUp();

  void dispose();
}

/// No-op backend for widget tests. Avoids audioplayer plugin hangs.
final class SilentPronunciationPlayer implements PronunciationPlayer {
  const SilentPronunciationPlayer();

  @override
  Future<void> play(String assetPath) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

/// No-op TTS for widget tests. Avoids flutter_tts plugin hangs.
final class SilentSpeechEngine implements SpeechEngine {
  const SilentSpeechEngine();

  @override
  Future<void> speak({
    required String text,
    required String locale,
    TargetSpeechProfile? profile,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

/// Spoken content player. Uses a separate voice from UI SFX.
final class BundledPronunciationPlayer implements PronunciationPlayer {
  BundledPronunciationPlayer()
    : _audio = BundledAssetAudio(
        mode: PlayerMode.mediaPlayer,
        context: _speechContext,
        waitForCompletion: true,
      );

  final BundledAssetAudio _audio;

  static AudioContext _speechContext() {
    return AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
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
  Future<void> play(String assetPath) => _audio.play(assetPath);

  @override
  Future<void> stop() => _audio.stop();

  @override
  Future<void> warmUp() => _audio.warmUp();

  @override
  void dispose() {
    _audio.dispose();
  }
}
