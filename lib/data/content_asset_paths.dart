final class ContentAssetPaths {
  const ContentAssetPaths(this.root);

  final String root;

  String get languagePack => '$root/language_pack.json';
  String get alphabet => '$root/alphabet.json';
  String get wordCategories => '$root/word_categories.json';
  String get words => '$root/words.json';
  String get phraseCategories => '$root/phrase_categories.json';
  String get phrases => '$root/phrases.json';

  String translation(String languageCode) {
    return '$root/translations/$languageCode.json';
  }
}
