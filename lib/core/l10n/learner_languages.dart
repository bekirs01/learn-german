import 'package:flutter/widgets.dart';

/// Shipped learner UI / translation languages. Content packs may offer a
/// subset; English is the safe fallback.
final class LearnerLanguage {
  const LearnerLanguage({
    required this.code,
    required this.nativeName,
    required this.textDirection,
    required this.flagEmoji,
  });

  final String code;
  final String nativeName;
  final TextDirection textDirection;

  /// Compact regional flag used in the Translation Language picker.
  final String flagEmoji;

  bool get isRtl => textDirection == TextDirection.rtl;
}

/// Catalog of learner languages. Screens look up data here instead of
/// branching on language codes.
abstract final class LearnerLanguages {
  static const String fallbackCode = 'en';

  static const LearnerLanguage english = LearnerLanguage(
    code: 'en',
    nativeName: 'English',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇺🇸',
  );
  static const LearnerLanguage turkish = LearnerLanguage(
    code: 'tr',
    nativeName: 'Türkçe',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇹🇷',
  );
  static const LearnerLanguage spanish = LearnerLanguage(
    code: 'es',
    nativeName: 'Español',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇪🇸',
  );
  static const LearnerLanguage arabic = LearnerLanguage(
    code: 'ar',
    nativeName: 'العربية',
    textDirection: TextDirection.rtl,
    flagEmoji: '🇸🇦',
  );
  static const LearnerLanguage french = LearnerLanguage(
    code: 'fr',
    nativeName: 'Français',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇫🇷',
  );
  static const LearnerLanguage german = LearnerLanguage(
    code: 'de',
    nativeName: 'Deutsch',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇩🇪',
  );
  static const LearnerLanguage russian = LearnerLanguage(
    code: 'ru',
    nativeName: 'Русский',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇷🇺',
  );
  static const LearnerLanguage portuguese = LearnerLanguage(
    code: 'pt',
    nativeName: 'Português',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇵🇹',
  );
  static const LearnerLanguage italian = LearnerLanguage(
    code: 'it',
    nativeName: 'Italiano',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇮🇹',
  );
  static const LearnerLanguage japanese = LearnerLanguage(
    code: 'ja',
    nativeName: '日本語',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇯🇵',
  );
  static const LearnerLanguage korean = LearnerLanguage(
    code: 'ko',
    nativeName: '한국어',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇰🇷',
  );
  static const LearnerLanguage chinese = LearnerLanguage(
    code: 'zh',
    nativeName: '简体中文',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇨🇳',
  );
  static const LearnerLanguage hindi = LearnerLanguage(
    code: 'hi',
    nativeName: 'हिन्दी',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇮🇳',
  );
  static const LearnerLanguage indonesian = LearnerLanguage(
    code: 'id',
    nativeName: 'Bahasa Indonesia',
    textDirection: TextDirection.ltr,
    flagEmoji: '🇮🇩',
  );
  static const LearnerLanguage persian = LearnerLanguage(
    code: 'fa',
    nativeName: 'فارسی',
    textDirection: TextDirection.rtl,
    flagEmoji: '🇮🇷',
  );

  static const List<LearnerLanguage> all = <LearnerLanguage>[
    english,
    turkish,
    spanish,
    arabic,
    french,
    german,
    russian,
    portuguese,
    italian,
    japanese,
    korean,
    chinese,
    hindi,
    indonesian,
    persian,
  ];

  static const Set<String> codes = <String>{
    'en',
    'tr',
    'es',
    'ar',
    'fr',
    'de',
    'ru',
    'pt',
    'it',
    'ja',
    'ko',
    'zh',
    'hi',
    'id',
    'fa',
  };

  static const Set<String> rtlCodes = <String>{'ar', 'fa'};

  static List<String> get orderedCodes => <String>[
    for (final LearnerLanguage language in all) language.code,
  ];

  /// Native or familiar name used in the Translation Language picker.
  static String labelFor(String languageCode, {String? fallback}) {
    final LearnerLanguage? language = byCode(languageCode);
    if (language != null) {
      return language.nativeName;
    }
    final String? named = fallback?.trim();
    if (named != null && named.isNotEmpty) {
      return named;
    }
    final String trimmed = languageCode.trim();
    return trimmed.isEmpty ? fallbackCode : trimmed;
  }

  static String baseCode(String languageCode) {
    final String trimmed = languageCode.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return fallbackCode;
    }
    return trimmed.split('-').first;
  }

  static LearnerLanguage? byCode(String languageCode) {
    final String code = baseCode(languageCode);
    for (final LearnerLanguage language in all) {
      if (language.code == code) {
        return language;
      }
    }
    return null;
  }

  static bool isSupported(String languageCode) {
    return codes.contains(baseCode(languageCode));
  }

  static String nativeName(String languageCode) {
    return byCode(languageCode)?.nativeName ?? languageCode.trim();
  }

  static TextDirection textDirectionFor(String languageCode) {
    return byCode(languageCode)?.textDirection ?? TextDirection.ltr;
  }

  static bool isRtl(String languageCode) {
    return rtlCodes.contains(baseCode(languageCode));
  }

  /// Regional flag for the Translation Language picker. Unknown codes have none.
  static String? flagEmojiFor(String languageCode) {
    return byCode(languageCode)?.flagEmoji;
  }
}
