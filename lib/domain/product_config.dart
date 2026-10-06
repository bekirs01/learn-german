import 'package:lingo_core/domain/content_models.dart';

/// How the target language is written. Drives the character inventory,
/// not UI chrome.
enum WritingSystem { alphabet, syllabary, characters, other }

final class ProductFeatureFlags {
  const ProductFeatureFlags({this.alphabet = true, this.audio = true});

  /// When false, the character inventory stays empty even if a file exists.
  final bool alphabet;

  /// Spoken pronunciation (bundled recordings + native TTS). Independent of UI SFX.
  final bool audio;

  ProductFeatureFlags copyWith({bool? alphabet, bool? audio}) {
    return ProductFeatureFlags(
      alphabet: alphabet ?? this.alphabet,
      audio: audio ?? this.audio,
    );
  }
}

/// Preferred speaker gender for target-language TTS.
enum PreferredSpeechGender { unspecified, female, male }

/// Per-product spoken-audio preferences. Future language clones set these
/// in `product.json`; screens never choose a voice.
final class TargetSpeechProfile {
  const TargetSpeechProfile({
    this.locale,
    this.preferredVoiceName,
    this.preferredVoiceIdentifier,
    this.preferredVoiceNames = const <String>[],
    this.preferredGender = PreferredSpeechGender.unspecified,
    this.rate,
    this.pitch,
  });

  static const TargetSpeechProfile empty = TargetSpeechProfile();

  /// Slightly deliberate learning rate. Native engines treat `0.5` as default.
  static const double defaultRate = 0.47;

  static const double defaultPitch = 1.0;

  static const double defaultVolume = 1.0;

  /// Optional BCP-47 tag. Overrides [ProductConfig.speechLocale] when set.
  final String? locale;

  /// Exact or prefix match against an installed system voice name.
  final String? preferredVoiceName;

  /// Optional platform identifier (`com.apple.voice…`). Ignored if missing.
  final String? preferredVoiceIdentifier;

  /// Ordered fallbacks after [preferredVoiceName] (Anna, Helena, …).
  final List<String> preferredVoiceNames;

  final PreferredSpeechGender preferredGender;

  /// Native TTS rate in `0..1`. Null keeps [defaultRate].
  final double? rate;

  /// Native TTS pitch. Null keeps a neutral [defaultPitch].
  final double? pitch;

  List<String> get voiceNamePreferences {
    final List<String> names = <String>[];
    void add(String? value) {
      final String? trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return;
      }
      for (final String existing in names) {
        if (existing.toLowerCase() == trimmed.toLowerCase()) {
          return;
        }
      }
      names.add(trimmed);
    }

    add(preferredVoiceName);
    for (final String name in preferredVoiceNames) {
      add(name);
    }
    return names;
  }

  double get resolvedRate {
    final double value = rate ?? defaultRate;
    if (value < 0.25) {
      return 0.25;
    }
    if (value > 0.65) {
      return 0.65;
    }
    return value;
  }

  double get resolvedPitch {
    final double value = pitch ?? defaultPitch;
    if (value < 0.8) {
      return 0.8;
    }
    if (value > 1.2) {
      return 1.2;
    }
    return value;
  }
}

/// Single switch-file for cloning this master into another language product.
final class ProductConfig {
  const ProductConfig({
    required this.id,
    required this.displayName,
    required this.targetLanguageName,
    required this.targetLanguageCode,
    required this.nativeLanguageName,
    required this.textDirection,
    required this.writingSystem,
    required this.primaryAccentColor,
    required this.contentPackPath,
    required this.defaultTranslationLanguage,
    required this.supportedTranslationLanguages,
    this.speechLocale,
    this.speechProfile = const TargetSpeechProfile(),
    this.featureFlags = const ProductFeatureFlags(),
  });

  static const String assetPath = 'assets/product.json';

  static ProductConfig _current = fallback;

  static ProductConfig get current => _current;

  static void bind(ProductConfig config) {
    _current = config;
  }

  static void reset() {
    _current = fallback;
  }

  static const ProductConfig fallback = ProductConfig(
    id: 'learn_german',
    displayName: 'Learn German for Beginners',
    targetLanguageName: 'German',
    targetLanguageCode: 'de',
    nativeLanguageName: 'Deutsch',
    textDirection: ContentTextDirection.ltr,
    writingSystem: WritingSystem.alphabet,
    primaryAccentColor: '#C46A3C',
    contentPackPath: 'assets/content',
    defaultTranslationLanguage: 'en',
    supportedTranslationLanguages: <String>['en'],
    speechLocale: 'de-DE',
    speechProfile: TargetSpeechProfile(
      preferredVoiceName: 'Anna',
      preferredVoiceNames: <String>[
        'Anna (Premium)',
        'Anna (Enhanced)',
        'Helena (Premium)',
        'Helena (Enhanced)',
        'Helena',
        'Petra (Enhanced)',
        'Petra',
      ],
      preferredGender: PreferredSpeechGender.female,
      rate: 0.47,
      pitch: 1.0,
    ),
  );

  final String id;
  final String displayName;
  final String targetLanguageName;
  final String targetLanguageCode;
  final String nativeLanguageName;
  final ContentTextDirection textDirection;
  final WritingSystem writingSystem;
  final String primaryAccentColor;
  final String contentPackPath;
  final String defaultTranslationLanguage;
  final List<String> supportedTranslationLanguages;

  /// Optional BCP-47 / language code for native TTS. When omitted, speech
  /// follows [targetLanguageCode]. Never derived from Translation Language.
  final String? speechLocale;

  /// Voice, rate, and pitch for the language being learned.
  final TargetSpeechProfile speechProfile;
  final ProductFeatureFlags featureFlags;

  bool get showsCharacterInventory {
    return featureFlags.alphabet && writingSystem != WritingSystem.other;
  }

  ProductConfig copyWith({
    String? targetLanguageCode,
    String? speechLocale,
    TargetSpeechProfile? speechProfile,
    ProductFeatureFlags? featureFlags,
  }) {
    final bool languageChanged =
        targetLanguageCode != null &&
        targetLanguageCode != this.targetLanguageCode;
    return ProductConfig(
      id: id,
      displayName: displayName,
      targetLanguageName: targetLanguageName,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      nativeLanguageName: nativeLanguageName,
      textDirection: textDirection,
      writingSystem: writingSystem,
      primaryAccentColor: primaryAccentColor,
      contentPackPath: contentPackPath,
      defaultTranslationLanguage: defaultTranslationLanguage,
      supportedTranslationLanguages: supportedTranslationLanguages,
      speechLocale:
          speechLocale ?? (languageChanged ? null : this.speechLocale),
      speechProfile: speechProfile ?? this.speechProfile,
      featureFlags: featureFlags ?? this.featureFlags,
    );
  }
}
