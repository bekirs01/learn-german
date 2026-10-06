# Language pack guide

This repository ships **Learn German for Beginners**. The pack format below is the family content contract (JSON, images, audio IDs). Do not rewrite navigation, favorites, quiz, persistence, feedback, screens, or the content repository to add German — that content is already in `assets/content/` and `assets/audio/de/`.

## Replace these files

| What | Where |
| --- | --- |
| Display name, accent, target language, direction, writing system, translation languages | `assets/product.json` |
| Script family, pack identity, translation file list, image ID map | `assets/content/language_pack.json` |
| Letters / kana / hangul / other glyphs | `assets/content/alphabet.json` |
| Word categories and words | `assets/content/word_categories.json`, `assets/content/words.json` |
| Phrase categories and phrases | `assets/content/phrase_categories.json`, `assets/content/phrases.json` |
| Learner meanings and category labels | `assets/content/translations/<code>.json` |
| Category / paper illustrations | `assets/images/…` via `assetIndex` IDs |

Do not add Dart screens, APIs, accounts, or databases for a new language.

## 1. Product configuration

Edit `assets/product.json`:

- `id`, `displayName`
- `targetLanguageName`, `targetLanguageCode`, `nativeLanguageName`
- `textDirection`: `ltr` or `rtl`
- `writingSystem`: `alphabet`, `syllabary`, `characters`, or `other`
- `primaryAccentColor`: `#RRGGBB`
- `contentPackPath`: usually `assets/content`
- `defaultTranslationLanguage` and `supportedTranslationLanguages`
- optional `speechLocale` (native TTS locale; defaults to `targetLanguageCode`)
- optional `speech` object: `preferredVoiceName`, `preferredVoiceNames`,
  `preferredVoiceIdentifier`, `preferredGender` (`female` / `male` /
  omit), `rate`, `pitch`. Missing voices fall back deterministically.
- `featureFlags.alphabet`, `featureFlags.audio`

`writingSystem: other` with `featureFlags.alphabet: false` leaves the Alphabet tab in place and shows an empty state.

Romanization is an optional content field, not a product flag. When a unit or item has `romanization` distinct from `pronunciation`, Alphabet shows it.

Platform display name, icon, and bundle ID stay on the native projects. Change those when the cloned app is named for the store, not in this pack.

## 2. Language pack

Edit `assets/content/language_pack.json`:

- `id`, `name`, `version`
- `targetLanguageCode`, `targetLanguageName` (match the product file)
- `scriptFamily`: `latin`, `cyrillic`, `arabic`, `han`, `japanese`, `korean`, `other`, or `none`
- `textDirection`: `ltr` or `rtl`
- `hasAlphabet`
- `defaultTranslationLanguageCode` and `translationLanguageCodes` (must match the translation files you ship)
- `assetIndex`: stable image (and optional audio) IDs → bundled file paths

## 3. Alphabet

`alphabet.json` is a list of `units`. Use letters, kana, hangul syllables, or other graphemes. Each unit needs a stable `id` and `glyph`. Optional: `pronunciation`, `pronunciationSpeechText` / `speechText` (what the play button speaks; never the example word), `romanization`, `example`, `imageAsset` / `imageAssetId`, `audioAsset` / `audioAssetId`, `sortOrder`, `quizEnabled`.

This German pack teaches A–Z plus **Ä, Ö, Ü, ß** after Z. Extra IDs are `letter.auml`, `letter.ouml`, `letter.uuml`, `letter.eszett`. ß is a single beginner glyph (not paired with ẞ/SS). `example` is a German word; learner glosses live in `translations/*.json`.

If the language has no character inventory, set the product flags above and leave `units` empty.

## 4. Words

Categories live in `word_categories.json`. Entries live in `words.json`. Every word `categoryId` must match a category `id`.

To add a word:

1. Choose an existing category (or add a category first).
2. Append an object in `words.json` → `items`.
3. Add the same ID to every learner file in `translations/`.

Required fields: `id`, `categoryId`, `text`. Use `sortOrder` (integer, unique inside the category, smaller = earlier). Set `quizEnabled` to `true` when the item is ready for quizzes.

Allowed row fields: `id`, `categoryId`, `text`, `pronunciation`, `romanization`, `sortOrder`, `quizEnabled`, optional `imageAsset` / `imageAssetId` / `audioAsset` / `audioAssetId`, and for German nouns optional `grammaticalGender` (`der` / `die` / `das` / `none`) and `plural` (nominative plural with article). Never put learner glosses (`en`, `tr`, or other language codes) on the row.

Stable IDs: `word.{group}.{slug}` such as `word.food.apple` and `word.number.twenty`. Never use list-position IDs (`word.12`). Do not reuse a deleted ID.

The `text` field is the **target** (what the learner is studying). Do not put learner-language glosses there.

Pronunciation: Latin/Cyrillic quiz items use IPA in slashes (`/kæt/`). Other scripts may use any non-empty spoken form. Missing or invalid forms are validation warnings.

This German pack stores target `text` in German. Nouns use the definite article in `text` (`das Haus`) plus `grammaticalGender` and `plural` when they are countable nouns. Prefer useful everyday beginner German over padding a count.

## 5. Phrases

Same pattern: `phrase_categories.json` + `phrases.json`. Phrase IDs must not collide with word, category, or alphabet IDs.

To add a phrase:

1. Choose an existing category (or add a category first).
2. Append an object in `phrases.json` → `items`.
3. Add the same ID to every learner file in `translations/`.

Required fields: `id`, `categoryId`, `text`. Use complete natural sentences. Use `sortOrder` unique inside the category. Set `quizEnabled` to `true` when the sentence is quiz-ready. Allowed row fields match words. Never put learner glosses on the row.

Stable IDs: `phrase.{category}.{slug}` such as `phrase.restaurant.can_i_see_the_menu`. Never use numeric position IDs.

The `text` field is the **target sentence**. Learner meanings belong only in translation bundles.

Pronunciation and quiz rules match words.

The master pack ships practical situation phrases. Prefer coverage a learner can actually use over padding.

## 6. Translations

Learner languages explain the target. They never replace it.

One file per learner language: `translations/<code>.json`. Shape:

```
{
  "languageCode": "en",
  "languageName": "English",
  "strings": {
    "word.food.apple": "Apple"
  }
}
```

`languageCode` and `languageName` are bundle metadata, not content keys. Keys inside `strings` are content IDs:

- `word_category.*`, `phrase_category.*` — category labels
- `word.*`, `phrase.*` — meanings
- `letter.*` — alphabet example meanings (when the unit has an example)

Do not store UI chrome (`nav.*`, `settings.*`, `quiz.*`) here. Those keys live in the UI catalog.

Every current content ID must have a non-empty string in every shipped learner file. Remove keys for deleted content. Missing keys are validation warnings; the app falls back to the default learner language, then to `text` / `title`.

This sample pack uses English as the target. The English learner file therefore matches `text`. The Turkish file is a learner gloss (`Cat` → `Kedi`, `Hello.` → `Merhaba.`). Switching Translation Language must not change the English target row.

List every file’s code in both `product.json` → `supportedTranslationLanguages` and `language_pack.json` → `translationLanguageCodes`.

## 7. Quiz eligibility

Set `quizEnabled` to `true` only when the row is a real study item:

- target `text` is non-empty
- pronunciation is valid for the script
- every learner bundle has a non-empty meaning for that ID
- meanings are unique inside that learner language so distractors stay distinct

The master word and phrase rows are all quiz-enabled. Leave `quizEnabled` false for drafts, not for shipped curriculum.

When a learner translation matches the target `text` (this English master with English UI), forward multiple choice is skipped because the prompt and meaning are the same. Reverse multiple choice, Type Answer, and Build Phrase still run using the item's pronunciation as the cue. Distinct learner glosses (Turkish, Arabic, …) always use those meanings.

## 8. Images

Do not hardcode image paths in widgets. Put a stable ID in `language_pack.json` → `assetIndex`, then set `imageAssetId` on the category or item. Replace the PNG (or point the ID at a new path) without changing Dart. Missing images fall back to painted art.

Optional spoken audio uses the same ID/path pattern. Omit audio fields when
unused. Do not point pronunciation at UI SFX files.

Content IDs are data, not Dart. You may keep the sample IDs and only change `text` / translations, or replace IDs as long as references stay consistent. Screens never hardcode `word.cat` or `letter.a`.

Latin/Cyrillic quiz items should use IPA in slashes (`/kæt/`). Other scripts may use any non-empty pronunciation. Missing or invalid forms are warnings; the app still runs.

## 9. Pronunciation audio (optional recordings + native TTS)

Spoken audio is learning content, not a sound effect. The Settings Sound
Effects toggle does not control it.

Playback order:

1. Bundled item audio (`audioAsset` / `audioAssetId`) when the file exists.
2. Native device TTS in the **target** language (`speechLocale`, or
   `targetLanguageCode` when omitted).

Learner / translation language never changes the spoken language.

1. Keep `featureFlags.audio` `true` unless the product should hide speakers.
2. Optionally add an `audioAsset` path (or `audioAssetId` in `assetIndex`) on
   each alphabet unit, word, or phrase that has a recording.
3. Register those files in `pubspec.yaml`.
4. Keep UI SFX in `assets/sounds/`. Keep spoken files separate, for example:

```
assets/audio/de/alphabet/<id>.wav
assets/audio/de/words/<id>.wav
assets/audio/de/phrases/<id>.wav
```

Dart does not encode English (or any language) pronunciation rules. A cloned
Spanish, Japanese, Korean, Arabic, or Russian product only needs a target
language code, content, and optional recordings. TTS follows the product.

Missing files fall back to TTS and never crash. No backend and no cloud TTS.

Alphabet play uses `pronunciationSpeechText` / `speechText`, then
`pronunciation`, then the glyph — never the example word. Word and phrase play
use the target `text`, never IPA or the learner gloss.

## Clone checklist

A Spanish, Japanese, or Korean product is this app with a new pack. Do not change Words/Phrases screens or the Quiz Engine.

1. Copy this project.
2. Fill `assets/product.json` (codes, `ltr`/`rtl`, writing system, accent, display name, translation languages, `featureFlags.alphabet` / `audio`).
3. Fill `assets/content/language_pack.json` (`scriptFamily`, direction, translation codes, `assetIndex`).
4. Replace target `text` in `words.json` and `phrases.json`, plus pronunciation / romanization.
5. Keep or adapt category IDs. You may keep `word.food.apple` and only change `text` to `manzana` / `りんご` / `사과`.
6. Rewrite `translations/*.json` so learner meanings match the new target. If English remains a learner language, `en.json` becomes an English gloss of the new target, not a copy of `text`.
7. Reuse category illustration IDs. Replace a PNG only when the subject is language-specific. Missing files are safe.
8. Optional: ship spoken WAV/MP3 files, set `audioAsset` / `audioAssetId`, and register the files in `pubspec.yaml`. Native TTS covers items without a recording.
9. Later, set that product’s name, icon, bundle ID, and store metadata in the iOS/Android projects.
10. Run `dart format .`, `flutter analyze`, and `flutter test`.
11. `test/canonical_curriculum_test.dart` checks catalog structure and quality (IDs, translations, quiz readiness). After a clone, retarget sample-specific assertions such as English `text` matching `en.json`.

The engine loads JSON only. Widgets never parse packs. Validation flags duplicate IDs, empty categories, missing translations/categories, bad category or asset refs, invalid pronunciation, quiz-unreadiness, malformed rows, empty required fields, and malformed language codes.
