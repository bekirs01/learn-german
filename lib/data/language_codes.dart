const Set<String> kSupportedLanguageCodes = <String>{
  'und',
  'en',
  'tr',
  'de',
  'fr',
  'es',
  'it',
  'pt',
  'nl',
  'pl',
  'ru',
  'uk',
  'ar',
  'fa',
  'he',
  'ja',
  'ko',
  'zh',
  'hi',
  'th',
  'vi',
  'id',
  'ms',
  'sv',
  'da',
  'no',
  'fi',
  'el',
  'cs',
  'ro',
  'hu',
  'bg',
  'hr',
  'sk',
  'lt',
  'lv',
  'et',
  'sl',
  'sr',
  'ca',
};

final RegExp _languageCodePattern = RegExp(r'^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$');

/// True for a common catalog code or any well-formed BCP-47 tag.
bool isSupportedLanguageCode(String code) {
  if (kSupportedLanguageCodes.contains(code)) {
    return true;
  }
  return _languageCodePattern.hasMatch(code);
}
