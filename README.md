# Learn German for Beginners

Premium offline German-learning app for iPhone, iPad, Apple Watch, and Android. No account required.

This repository is the **Learn German for Beginners** product (`de` / `de-DE`). Dart screens and the shared Lingo engine stay data-driven; German lives in the content pack, audio library, and store identity.

## Technology

Flutter and Dart. iOS-first, Android compatible. Offline-first. No backend, Firebase, Supabase, authentication, ads, or analytics.

## Run

```bash
flutter pub get
flutter run
```

Then:

```bash
dart format .
flutter analyze
flutter test
```

## Product identity

- English name: Learn German for Beginners
- App Store title: Learn German Words & Phrases!
- Watch mark: Learn German
- Target language: German / Deutsch
- ISO 639-1: `de`
- Primary speech locale: `de-DE`
- Native TTS voice: Anna (`de-DE`), then Helena / Petra
- Product id: `learn_german`
- Dart package name remains `lingo_core` (engine imports)
- iOS bundle ID: `com.lingocore.learnGerman`
- Watch bundle ID: `com.lingocore.learnGerman.watchkitapp`
- Android applicationId: `com.lingocore.learn_german` (Kotlin namespace stays `com.lingocore.lingo_core`)
- Privacy Policy: https://bekirs01.github.io/learn-german/privacy.html
- Support: https://bekirs01.github.io/learn-german/support.html

The German alphabet (A–Z plus Ä Ö Ü ß) is in `assets/content/alphabet.json`. Vocabulary and phrases are German in `assets/content/words.json` and `assets/content/phrases.json`. Bundled pronunciation WAVs are under `assets/audio/de/` and inventoried in `docs/expected_audio_manifest.json`. See `GERMAN_MIGRATION_STATE.md`.

## How the layers fit

| Layer | Where | What it does |
| --- | --- | --- |
| Product identity | `assets/product.json` | Name, accent, target language, direction, writing system, translation languages, `alphabet` / `audio` flags |
| Target-language content | `assets/content/*.json` | Glyphs, words, phrases, optional romanization and audio IDs |
| Learner meanings | `assets/content/translations/<code>.json` | Gloss of each content ID in the learner's language |
| UI chrome | `lib/core/l10n/` | Nav, settings, quiz, empty states |

Switching Translation Language changes learner glosses and UI chrome. It never replaces the target-language `text` / `glyph`.

## Feature flags

- `alphabet`: when false (or `writingSystem` is `other`), the Alphabet tab stays but shows an empty inventory.
- `audio`: when true, play controls speak the target language (bundled recording if present, otherwise native TTS). UI sound effects are separate and gated by Settings.

## Apple Watch

Watch is a companion app. Lessons sync as German `targetText` plus content IDs over WatchConnectivity. Watch does **not** play lesson TTS; it ships UI sound effects only.

## Principles

- English-only code, comments, docs, identifiers, and base UI copy
- Modular, reusable architecture; data-driven learning content
- Small widgets, no duplicated business logic, `const` where it belongs
- Premium UI with motion, depth, sound, and haptics that stay fast and accessible
- No extra packages or architecture changes without an explicit reason
