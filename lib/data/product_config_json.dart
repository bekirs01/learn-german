import 'package:lingo_core/data/content_json.dart';
import 'package:lingo_core/data/language_codes.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/validation.dart';

ProductConfig parseProductConfig(
  Object? decoded, [
  List<ValidationIssue>? issues,
]) {
  final List<ValidationIssue> collected = issues ?? <ValidationIssue>[];
  final Map<String, Object?> json = jsonObject(decoded, 'product');
  final ProductConfig fallback = ProductConfig.fallback;

  final String defaultTranslation = jsonStringOrFallback(
    json,
    'defaultTranslationLanguage',
    fallback.defaultTranslationLanguage,
    collected,
  );
  List<String> supported = jsonStringList(
    json,
    'supportedTranslationLanguages',
  );
  if (supported.isEmpty) {
    supported = <String>[defaultTranslation];
  }

  final String? speechLocale = jsonOptionalString(json, 'speechLocale');
  final TargetSpeechProfile speechProfile = parseTargetSpeechProfile(
    json['speech'],
  );

  for (final String code in <String>[
    jsonOptionalString(json, 'targetLanguageCode') ??
        fallback.targetLanguageCode,
    ?speechLocale,
    ?speechProfile.locale,
    defaultTranslation,
    ...supported,
  ]) {
    if (!isSupportedLanguageCode(code)) {
      collected.add(
        ValidationIssue(
          code: ValidationCodes.unsupportedLanguageCode,
          message:
              'Unsupported language code "$code" in product configuration.',
          id: code,
        ),
      );
    }
  }

  return ProductConfig(
    id: jsonStringOrFallback(json, 'id', fallback.id, collected),
    displayName: jsonStringOrFallback(
      json,
      'displayName',
      fallback.displayName,
      collected,
    ),
    targetLanguageName: jsonStringOrFallback(
      json,
      'targetLanguageName',
      fallback.targetLanguageName,
      collected,
    ),
    targetLanguageCode: jsonStringOrFallback(
      json,
      'targetLanguageCode',
      fallback.targetLanguageCode,
      collected,
    ),
    nativeLanguageName: jsonStringOrFallback(
      json,
      'nativeLanguageName',
      fallback.nativeLanguageName,
      collected,
    ),
    textDirection: parseTextDirection(
      jsonOptionalString(json, 'textDirection'),
    ),
    writingSystem: parseWritingSystem(
      jsonOptionalString(json, 'writingSystem'),
    ),
    primaryAccentColor:
        jsonOptionalString(json, 'primaryAccentColor') ??
        fallback.primaryAccentColor,
    contentPackPath: jsonStringOrFallback(
      json,
      'contentPackPath',
      fallback.contentPackPath,
      collected,
    ),
    defaultTranslationLanguage: defaultTranslation,
    supportedTranslationLanguages: supported,
    speechLocale: speechLocale,
    speechProfile: speechProfile,
    featureFlags: _parseFlags(json['featureFlags']),
  );
}

TargetSpeechProfile parseTargetSpeechProfile(Object? value) {
  final Map<String, Object?>? json = jsonObjectOrNull(value);
  if (json == null) {
    return const TargetSpeechProfile();
  }
  return TargetSpeechProfile(
    locale: jsonOptionalString(json, 'locale'),
    preferredVoiceName: jsonOptionalString(json, 'preferredVoiceName'),
    preferredVoiceIdentifier: jsonOptionalString(
      json,
      'preferredVoiceIdentifier',
    ),
    preferredVoiceNames: jsonStringList(json, 'preferredVoiceNames'),
    preferredGender: _parsePreferredGender(
      jsonOptionalString(json, 'preferredGender'),
    ),
    rate: jsonOptionalDouble(json, 'rate'),
    pitch: jsonOptionalDouble(json, 'pitch'),
  );
}

PreferredSpeechGender _parsePreferredGender(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'female':
    case 'f':
      return PreferredSpeechGender.female;
    case 'male':
    case 'm':
      return PreferredSpeechGender.male;
    default:
      return PreferredSpeechGender.unspecified;
  }
}

ProductFeatureFlags _parseFlags(Object? value) {
  final Map<String, Object?>? json = jsonObjectOrNull(value);
  if (json == null) {
    return const ProductFeatureFlags();
  }
  return ProductFeatureFlags(
    alphabet: jsonBool(json, 'alphabet', fallback: true),
    audio: jsonBool(json, 'audio', fallback: true),
  );
}
