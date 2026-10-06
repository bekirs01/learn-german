/// Bundled image paths that are not content-pack IDs.
///
/// Category and alphabet illustrations are referenced from
/// `language_pack.json` → `assetIndex`. Widgets load those paths with
/// [Image.asset] and fall back to painted art if a file is missing.
abstract final class LingoAssets {
  static const String paperCrumpled =
      'assets/images/backgrounds/paper_crumpled.png';

  static const String homeAlphabet = 'assets/images/home/alphabet.png';
  static const String homeWords = 'assets/images/home/words.png';
  static const String homePhrases = 'assets/images/home/phrases.png';
  static const String homeQuiz = 'assets/images/home/quiz.png';
  static const String homeWrongAnswers = 'assets/images/home/wrong_answers.png';
  static const String homeAppleWatch = 'assets/images/home/apple_watch.png';
}

LingoArtKind lingoArtKindFromName(String? name) {
  if (name == null) {
    return LingoArtKind.nature;
  }
  return LingoArtKind.values.asNameMap()[name] ?? LingoArtKind.nature;
}

/// Shared illustration vocabulary. Generated PNGs must match these subjects.
enum LingoArtKind {
  animals,
  food,
  body,
  emotions,
  family,
  home,
  nature,
  work,
  sports,
  shopping,
  travel,
  numbers,
  basics,
  colors,
  people,
  drinks,
  clothing,
  weather,
  school,
  health,
  time,
  places,
  greetings,
  introductions,
  restaurant,
  hotel,
  airport,
  directions,
  doctor,
  emergency,
  shoppingPhrases,
  transportation,
  dailyConversation,
  questions,
  cafe,
  pharmacy,
  socialSituations,
}
