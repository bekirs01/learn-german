import 'package:lingo_core/domain/product_config.dart';

/// Resolves the native TTS locale from the **target** product, never from
/// Translation Language / learner UI language.
///
/// A German product sets `targetLanguageCode` (or optional `speechLocale`) to
/// `de` / `de-DE` and pronunciation follows automatically.
abstract final class TargetSpeechLocale {
  static const Map<String, String> _languageToTag = <String, String>{
    'en': 'en-US',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'it': 'it-IT',
    'pt': 'pt-BR',
    'nl': 'nl-NL',
    'pl': 'pl-PL',
    'ru': 'ru-RU',
    'uk': 'uk-UA',
    'ar': 'ar-SA',
    'fa': 'fa-IR',
    'he': 'he-IL',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'zh': 'zh-CN',
    'hi': 'hi-IN',
    'th': 'th-TH',
    'vi': 'vi-VN',
    'id': 'id-ID',
    'ms': 'ms-MY',
    'sv': 'sv-SE',
    'da': 'da-DK',
    'no': 'nb-NO',
    'nb': 'nb-NO',
    'fi': 'fi-FI',
    'el': 'el-GR',
    'cs': 'cs-CZ',
    'ro': 'ro-RO',
    'hu': 'hu-HU',
    'bg': 'bg-BG',
    'hr': 'hr-HR',
    'sk': 'sk-SK',
    'tr': 'tr-TR',
    'lt': 'lt-LT',
    'lv': 'lv-LV',
    'et': 'et-EE',
    'sl': 'sl-SI',
    'sr': 'sr-RS',
    'ca': 'ca-ES',
  };

  /// BCP-47 tag for device TTS (`en-US`, `es-ES`, `ja-JP`, …).
  ///
  /// [learnerLanguageCode] is accepted only so callers can prove it is ignored.
  static String resolve({ProductConfig? product, String? learnerLanguageCode}) {
    final ProductConfig config = product ?? ProductConfig.current;
    final String configured =
        (config.speechProfile.locale ??
                config.speechLocale ??
                config.targetLanguageCode)
            .trim();
    // Learner/translation language is a caller-supplied witness and never used.
    return canonicalize(configured);
  }

  /// `en` → `en-US`. Already-tagged values (`es-MX`) are normalized, not replaced.
  static String canonicalize(String code) {
    final String trimmed = code.trim().replaceAll('_', '-');
    if (trimmed.isEmpty) {
      return 'und';
    }
    final List<String> parts = trimmed.split('-');
    final String language = parts.first.toLowerCase();
    if (parts.length == 1) {
      return _languageToTag[language] ?? language;
    }
    final StringBuffer buffer = StringBuffer(language);
    for (int index = 1; index < parts.length; index++) {
      final String part = parts[index];
      buffer.write('-');
      if (part.length == 2) {
        buffer.write(part.toUpperCase());
      } else if (part.length == 4) {
        buffer.write(
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        );
      } else {
        buffer.write(part);
      }
    }
    return buffer.toString();
  }

  static String languageCode(String tag) {
    final String canonical = canonicalize(tag);
    final int dash = canonical.indexOf('-');
    if (dash <= 0) {
      return canonical.toLowerCase();
    }
    return canonical.substring(0, dash).toLowerCase();
  }
}

/// Picks a stable, natural system voice for a target locale.
///
/// Selection is deterministic. Product config supplies preferred names,
/// identifiers, and gender; UI screens never choose a voice.
abstract final class SpeechVoicePicker {
  static const Set<String> _gimmickTokens = <String>{
    'novelty',
    'whisper',
    'bad guy',
    'superstar',
    'jester',
    'bells',
    'organ',
    'reed',
    'cellos',
    'good news',
    'babu',
    'wobble',
    'princess',
    'grandma',
    'grandpa',
    'boing',
    'trinoids',
    'zarvox',
    'deranged',
  };

  /// Installed-name hints used only when gender metadata is missing.
  static const Set<String> _englishFemaleHints = <String>{
    'samantha',
    'nicky',
    'ava',
    'allison',
    'zoe',
    'susan',
    'kathy',
    'victoria',
    'samantha (enhanced)',
    'samantha (premium)',
    'nicky (enhanced)',
    'nicky (premium)',
  };

  static const Set<String> _englishMaleHints = <String>{
    'alex',
    'daniel',
    'fred',
    'tom',
    'aaron',
    'gordon',
    'nathan',
    'ralph',
    'junior',
    'oliver',
    'nicky (male)',
  };

  static const Set<String> _germanFemaleHints = <String>{
    'anna',
    'helena',
    'petra',
    'anna (enhanced)',
    'anna (premium)',
    'helena (enhanced)',
    'helena (premium)',
    'petra (enhanced)',
    'petra (premium)',
  };

  static const Set<String> _germanMaleHints = <String>{
    'martin',
    'markus',
    'yannick',
    'stefan',
    'viktor',
  };

  /// Returns `{name, locale}` for [FlutterTts.setVoice], or null to keep
  /// [FlutterTts.setLanguage] as the only selection.
  static Map<String, String>? select({
    required Iterable<Object?> voices,
    required String locale,
    TargetSpeechProfile profile = TargetSpeechProfile.empty,
  }) {
    final String requested = TargetSpeechLocale.canonicalize(locale);
    final String requestedLanguage = TargetSpeechLocale.languageCode(requested);
    _ScoredVoice? best;
    for (final Object? raw in voices) {
      final Map<String, String>? voice = _asVoice(raw);
      if (voice == null) {
        continue;
      }
      final int score = _score(
        voice: voice,
        requested: requested,
        requestedLanguage: requestedLanguage,
        profile: profile,
      );
      if (score < 0) {
        continue;
      }
      final _ScoredVoice candidate = _ScoredVoice(voice: voice, score: score);
      if (best == null || candidate.compareTo(best) < 0) {
        best = candidate;
      }
    }
    return best?.voice;
  }

  static Map<String, String>? _asVoice(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final Object? name = raw['name'];
    final Object? locale = raw['locale'] ?? raw['localeId'] ?? raw['language'];
    if (name is! String || name.trim().isEmpty) {
      return null;
    }
    if (locale is! String || locale.trim().isEmpty) {
      return null;
    }
    return <String, String>{
      'name': name.trim(),
      'locale': locale.trim(),
      'quality': '${raw['quality'] ?? ''}',
      'gender': '${raw['gender'] ?? ''}',
      'identifier': '${raw['identifier'] ?? raw['id'] ?? ''}',
    };
  }

  static int _score({
    required Map<String, String> voice,
    required String requested,
    required String requestedLanguage,
    required TargetSpeechProfile profile,
  }) {
    final String voiceLocale = TargetSpeechLocale.canonicalize(
      voice['locale']!,
    );
    final String voiceLanguage = TargetSpeechLocale.languageCode(voiceLocale);
    if (voiceLanguage != requestedLanguage) {
      return -1;
    }
    final String name = voice['name']!.toLowerCase();
    final String quality = voice['quality']!.toLowerCase();
    final String identifier = voice['identifier']!.toLowerCase();
    final String blob = '$name $quality $identifier';
    for (final String token in _gimmickTokens) {
      if (blob.contains(token)) {
        return -1;
      }
    }

    int score = 10;
    if (voiceLocale.toLowerCase() == requested.toLowerCase()) {
      score += 100;
    }

    final String? preferredIdentifier = profile.preferredVoiceIdentifier
        ?.trim()
        .toLowerCase();
    if (preferredIdentifier != null &&
        preferredIdentifier.isNotEmpty &&
        identifier == preferredIdentifier) {
      score += 220;
    }

    final bool compact = _isCompact(quality: quality, blob: blob);
    final bool networked = _isNetworked(blob);
    final List<String> preferredNames = profile.voiceNamePreferences;
    final int nameRank = _preferredNameRank(name, identifier, preferredNames);
    if (nameRank >= 0) {
      score += compact ? 80 - nameRank : 200 - nameRank;
    }

    score += _qualityBonus(blob: blob, quality: quality);
    if (compact) {
      score -= 25;
    }
    if (networked) {
      score -= 80;
    }
    if (blob.contains('local') ||
        blob.contains('embedded') ||
        blob.contains('offline')) {
      score += 12;
    }

    score += _genderBonus(
      voice: voice,
      name: name,
      identifier: identifier,
      language: requestedLanguage,
      preferred: profile.preferredGender,
    );
    return score;
  }

  static int _preferredNameRank(
    String name,
    String identifier,
    List<String> preferredNames,
  ) {
    for (int index = 0; index < preferredNames.length; index++) {
      final String preferred = preferredNames[index].toLowerCase();
      if (_nameMatchesPreference(name, identifier, preferred)) {
        return index;
      }
    }
    return -1;
  }

  static bool _nameMatchesPreference(
    String name,
    String identifier,
    String preferred,
  ) {
    if (name == preferred || identifier == preferred) {
      return true;
    }
    if (name.startsWith('$preferred ') || name.startsWith('$preferred(')) {
      return true;
    }
    if (identifier.contains(preferred)) {
      return true;
    }
    return false;
  }

  static bool _isCompact({required String quality, required String blob}) {
    return blob.contains('compact') || quality == '100' || quality == '200';
  }

  static bool _isNetworked(String blob) {
    return blob.contains('network') ||
        blob.contains('online') ||
        blob.contains('cloud') ||
        blob.contains('remote');
  }

  static int _qualityBonus({required String blob, required String quality}) {
    if (blob.contains('premium')) {
      return 40;
    }
    if (blob.contains('enhanced')) {
      return 35;
    }
    if (blob.contains('neural') || blob.contains('siri')) {
      return 30;
    }
    if (blob.contains('very high') ||
        quality == '500' ||
        blob.contains('veryhigh')) {
      return 25;
    }
    if (blob.contains('high') || quality == '400') {
      return 20;
    }
    if (blob.contains('default') || quality == '300') {
      return 8;
    }
    return 0;
  }

  static int _genderBonus({
    required Map<String, String> voice,
    required String name,
    required String identifier,
    required String language,
    required PreferredSpeechGender preferred,
  }) {
    if (preferred == PreferredSpeechGender.unspecified) {
      return 0;
    }
    final PreferredSpeechGender detected = _detectGender(
      gender: voice['gender']!,
      name: name,
      identifier: identifier,
      language: language,
    );
    if (detected == preferred) {
      return 90;
    }
    if (detected == PreferredSpeechGender.unspecified) {
      return 0;
    }
    return -40;
  }

  static PreferredSpeechGender _detectGender({
    required String gender,
    required String name,
    required String identifier,
    required String language,
  }) {
    final String normalized = gender.trim().toLowerCase();
    if (normalized == 'female' ||
        normalized == 'f' ||
        normalized.contains('female')) {
      return PreferredSpeechGender.female;
    }
    if (normalized == 'male' ||
        normalized == 'm' ||
        normalized.contains('male')) {
      return PreferredSpeechGender.male;
    }
    final String blob = '$name $identifier';
    if (blob.contains('female') ||
        blob.contains('_f_') ||
        blob.contains('-f-') ||
        blob.contains('siri_female')) {
      return PreferredSpeechGender.female;
    }
    if (RegExp(r'(^|[^a-z])male([^a-z]|$)').hasMatch(blob) ||
        blob.contains('_m_') ||
        blob.contains('-m-') ||
        blob.contains('siri_male')) {
      return PreferredSpeechGender.male;
    }
    if (name.contains('-sfg-') ||
        name.contains('-tpf-') ||
        name.contains('-sfb-') ||
        name.contains('-cfn-')) {
      return PreferredSpeechGender.female;
    }
    if (name.contains('-tpd-') ||
        name.contains('-tpc-') ||
        name.contains('-iob-')) {
      return PreferredSpeechGender.male;
    }
    if (language == 'en') {
      if (_englishFemaleHints.contains(name) ||
          _englishFemaleHints.any(name.startsWith)) {
        return PreferredSpeechGender.female;
      }
      if (_englishMaleHints.contains(name) ||
          _englishMaleHints.any(name.startsWith)) {
        return PreferredSpeechGender.male;
      }
      return PreferredSpeechGender.unspecified;
    }
    if (language == 'de') {
      if (_germanFemaleHints.contains(name) ||
          _germanFemaleHints.any(name.startsWith)) {
        return PreferredSpeechGender.female;
      }
      if (_germanMaleHints.contains(name) ||
          _germanMaleHints.any(name.startsWith)) {
        return PreferredSpeechGender.male;
      }
    }
    return PreferredSpeechGender.unspecified;
  }
}

final class _ScoredVoice implements Comparable<_ScoredVoice> {
  const _ScoredVoice({required this.voice, required this.score});

  final Map<String, String> voice;
  final int score;

  @override
  int compareTo(_ScoredVoice other) {
    final int byScore = other.score.compareTo(score);
    if (byScore != 0) {
      return byScore;
    }
    return voice['name']!.compareTo(other.voice['name']!);
  }
}
