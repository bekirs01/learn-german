import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/validation.dart';

/// Loads bundled language-pack JSON and exposes typed content.
/// User-facing widgets read from this contract and never parse JSON.
abstract interface class ContentRepository {
  LanguagePack get pack;

  List<AlphabetUnit> get alphabet;

  List<ContentCategory> get wordCategories;

  List<ContentCategory> get phraseCategories;

  List<TranslationBundle> get translationBundles;

  List<QuizReadyItem> get quizItems;

  /// Stable catalog IDs the learner has marked. Backed by local preferences.
  Set<String> get favoriteIds;

  /// Stable catalog IDs the learner has marked as known. Shared everywhere.
  Set<String> get learnedIds;

  List<WordEntry> wordsForCategory(String categoryId);

  List<PhraseEntry> phrasesForCategory(String categoryId);

  AlphabetUnit? alphabetUnitById(String id);

  WordEntry? wordById(String id);

  PhraseEntry? phraseById(String id);

  ContentCategory? wordCategoryById(String id);

  ContentCategory? phraseCategoryById(String id);

  /// Meaning or UI label for [id] in [languageCode], falling back to the pack
  /// default translation language.
  String? translation(String id, {String? languageCode});

  String labelFor(String id, String fallback, {String? languageCode});

  ProductConfig get product;

  ValidationReport get validation;

  /// Spoken-audio product flag. Independent of the Sound Effects setting.
  bool get pronunciationEnabled;

  /// Bundled pronunciation path for a content ID, if the pack declared one.
  String? pronunciationAssetFor(String id);

  bool isFavorite(String id);

  void setFavorite(String id, bool value);

  bool isLearned(String id);

  void setLearned(String id, bool value);
}
