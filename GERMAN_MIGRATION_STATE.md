# German migration state

Source of truth for this repository. Workspace safety: only `Learn-German-for-Beginners` was modified. Sibling language projects were not opened for writes.

---

## Phase 4 — final production QA + release readiness (DONE)

Final audit of the existing German product. Curriculum, audio library, Watch target, and visuals were verified rather than redesigned. No further language migration should be started from this file.

| Check | Result |
| --- | --- |
| Product name | **Learn German for Beginners** |
| Locale / voice | **de-DE** / **Anna** (compact) |
| Flutter tests | **456 passed / 0 failed / 0 skipped** (same count as Phase 3B) |
| `flutter analyze` | No issues found |
| `dart format --set-exit-if-changed lib test` | OK |
| Word categories / phrase categories | **23 / 17** |
| Alphabet | **30** (A–Z, Ä, Ö, Ü, ß) |
| Vocabulary / phrases / quiz-ready | **1156 / 612 / 1798** |
| Expected audio / present WAV / missing / empty | **1798 / 1798 / 0 / 0** |
| Manifest `generationStatus=generated` | **1798** |
| Asset validation | Pass (pack index 68/68, home/category/alphabet stills, iOS+Watch icons) |
| Source-language remnants | No class-D runtime leftovers. Class A/B retained (engine IDs, learner glosses, `Sprichst du Englisch?`) |
| iOS simulator build | **Pass** — `flutter build ios --simulator --no-codesign -d EFBA090D-EC32-405E-98BF-0556F2D50094` → `build/ios/iphonesimulator/Runner.app` |
| Watch simulator build | **Pass** — `xcodebuild -scheme LingoWatch -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO` → `** BUILD SUCCEEDED **` |
| Watch embed | `Runner.app/Watch/LingoWatch.app`; companion `com.lingocore.learnGerman` |
| Native unit tests | RunnerTests **7 passed**, including stale-English Watch cache detection |
| Android debug APK | **Pass** — `build/app/outputs/flutter-apk/app-debug.apk` (`com.lingocore.learn_german`, label **Learn German for Beginners**, version `0.1.0+1`) |
| Bundle IDs | **App Store identity** `com.lingocore.learnGerman` / `.watchkitapp` / Android `applicationId` `com.lingocore.learn_german` (Kotlin namespace stays `com.lingocore.lingo_core`) |
| Secrets | None committed (no TTS keys, tokens, or certificates in tracked files) |

Launch still opens Home (no dedicated onboarding route). Persistence keys (`lingo.user.*`) store IDs, not English display text. Wrong answers and favorites resolve to current German `text`. Watch payloads send `targetLanguageCode: de` and German `targetText`. Watch lesson TTS is intentionally out of architecture.

### Fixes in this phase (class D)

- German letter names shown in Alphabet: J `jot`, V `fau`, W `we`, Y `Ypsilon`, Z `zett` (replacing English-phonetic `yot` / `fow` / `veh` / `üpsilon` / `tsett`). Glyphs, examples, audio, and IDs unchanged.
- Two calques corrected and WAV regenerated with Anna / `de-DE`:
  - `phrase.greetings.take_it_easy` → `Mach's langsam.`
  - `phrase.social_situations.lets_do_this_again` → `Lass uns das bald wieder machen.`
- `GERMAN_MIGRATION_STATE.md` brought in line with the live App Store bundle IDs (`com.lingocore.learnGerman`).

### Validation commands actually run

```
python3 tools/german_audio/generate.py verify
python3 tools/german_audio/generate.py generate --force \
  --only phrase.greetings.take_it_easy \
  --only phrase.social_situations.lets_do_this_again
dart format --set-exit-if-changed lib test
flutter pub get
flutter analyze
flutter test
flutter clean
flutter pub get
flutter build ios --simulator --no-codesign -d EFBA090D-EC32-405E-98BF-0556F2D50094
xcodebuild -workspace ios/Runner.xcworkspace -scheme LingoWatch \
  -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,id=EFBA090D-EC32-405E-98BF-0556F2D50094' \
  -only-testing:RunnerTests CODE_SIGNING_ALLOWED=NO test
flutter build apk --debug
```

---

## Phase 3B — complete application validation + test hardening (DONE)

Production-readiness pass. Curriculum, audio library, Watch target, and visuals were verified rather than redesigned.

| Check | Result |
| --- | --- |
| Flutter tests | **456 passed / 0 failed** |
| `flutter analyze` | No issues found |
| Word categories / phrase categories | **23 / 17** |
| Alphabet | **30** (A–Z, Ä, Ö, Ü, ß) |
| Vocabulary / phrases / quiz-ready | **1156 / 612 / 1798** |
| Expected audio / present WAV / missing / empty | **1798 / 1798 / 0 / 0** |

---

## Phase 3A — production German audio (DONE)

| Field | Value |
| --- | --- |
| Selected voice | **Anna** (`de-DE`, compact). Only installed native German voice. |
| Rejected voices | Eloquence characters (Eddy, Flo, Grandma, Grandpa, Reed, Rocko, Sandy, Shelley). Helena/Petra Premium/Enhanced were not installed. |
| Provider / pipeline | Native TTS: macOS `say` / AVSpeech. `tools/german_audio/generate.py`. No cloud TTS. |
| Locale | `de-DE` |
| Rate / pitch | `0.47` / `165` WPM, pitch `1.0` |
| Format | 24 kHz mono 16-bit PCM WAV |
| Expected / generated | **1798 / 1798** |
| Watch audio | Lesson TTS **not** played on Watch. Synced German `targetText` + `pronunciationId`. Watch ships UI SFX only (`sfx_*.wav`). |
| iPhone audio | Bundled WAV first, native `de-DE` Anna TTS fallback. |

Isolated letters are synthesized lowercase so Apple does not announce a case label. Spoken German text (umlauts, ß) is unchanged; filenames stay ASCII IDs.

---

## Phase 2A — complete German curriculum (DONE)

Curriculum `text` is German. Architecture, IDs, categories, quiz engine, progress, Watch sync, and audio lookup are unchanged. Pack version `2.1.0`.

| Item | Count |
| --- | --- |
| Word categories (lesson units) | **23** |
| Phrase categories (lesson units) | **17** |
| Alphabet course | **1** (30 letters: A–Z, Ä, Ö, Ü, ß) |
| Vocabulary items | **1156** |
| Phrases | **612** |
| Quiz-ready items | **1798** |
| Gendered nouns (`der` / `die` / `das`) | **870** |
| Nouns with plural line | **694** |
| Learner translation bundles | **15** (default `en`) |

Quizzes are generated at runtime from quiz-ready items. There is no separate quiz JSON.

### Pedagogy

- Target: `de` / `de-DE`. Learner glosses stay in the existing 15 bundles; do **not** assume Turkish.
- Nouns teach article + capitalized noun in `text` (`das Haus`) plus optional `grammaticalGender` and `plural` (`die Häuser`).
- Informal `du` in greetings, introductions, daily talk, questions, and social situations.
- Formal `Sie` kept deliberately in service/stranger categories.
- `Ich lerne Deutsch` / `Ich spreche ein bisschen Deutsch` replace English-learning source sentences. `Sprichst du Englisch?` is kept as a useful phrase.

---

## Phase 2B — alphabet + visuals (DONE — do not redo)

30 units: A–Z then Ä Ö Ü ß (`letter.auml`, `letter.ouml`, `letter.uuml`, `letter.eszett`). Examples are German. Dedicated stills exist; leftover English stills were removed.

---

## Phase 2C — identity + iOS + Watch + audio pipeline (DONE — do not redo)

| Field | Value |
| --- | --- |
| App name | Learn German for Beginners |
| Watch mark | Learn German |
| Native name | Deutsch |
| Product id | `learn_german` |
| Speech | `de-DE`, Anna, rate `0.47` |
| Bundles | `com.lingocore.learnGerman` / `.watchkitapp` |
| Audio path | `assets/audio/de/{alphabet,words,phrases}/<id>.wav` |

---

## Curriculum map

| Source | Role |
| --- | --- |
| `assets/content/alphabet.json` | 30 German letters + examples |
| `assets/content/words.json` | 1156 German words; optional `grammaticalGender` / `plural` |
| `assets/content/phrases.json` | 612 natural German sentences |
| `assets/content/word_categories.json` | 23 categories (IDs frozen; English fallback titles) |
| `assets/content/phrase_categories.json` | 17 categories (IDs frozen; English fallback titles) |
| `assets/content/translations/*.json` | 15 learner glosses for every content ID |
| `assets/content/language_pack.json` | `learn_german` / `de` / version `2.1.0` |
| `docs/expected_audio_manifest.json` | 1798 expected WAV mappings |
| Watch catalog | Shared JSON; preview sample uses `Hallo` |

No bundled database, no seed SQL, no Watch-only lesson files.

---

## Intentionally retained source-language / ASCII references

Classify leftover English as **A** (technical), **B** (intentional), not **D** (migration error).

| Kind | Examples | Class |
| --- | --- | --- |
| Stable content IDs | `word.food.apple`, `phrase.greetings.hello` | A |
| Image IDs / files | `alphabet.apple` → `apple.png` for Apfel | A |
| Category fallback titles | `"title": "Family"` in category JSON | A |
| Learner English | `en.json` meanings; UI chrome in 15 languages | A |
| Engine type names | `LingoCoreApp`, Kotlin namespace `com.lingocore.lingo_core` | A |
| Test fixtures | In-memory English/Spanish packs; Nicky/`en-US` voice-selection tests | A/C |
| Useful English phrase | `Sprichst du Englisch?` | B |
| German loanwords | Plus, Minus, Okay, Hi., Check-in, Gate, WLAN | B |
| ASCII audio filenames | `letter.auml.wav`, `letter.eszett.wav` | A |
| `und` locale fallback | IETF undefined in `TargetSpeechLocale` | A |

No English target `text` remains in `words.json` / `phrases.json`.

---

## Remaining issues (external / architecture — not code defects)

- **App Store / Play signing:** `DEVELOPMENT_TEAM` is present in the Xcode project from earlier work; a signed archive was **not** produced here (`CODE_SIGNING_ALLOWED=NO` for simulator/Watch). Android `release` still uses the debug signing config (commented TODO in `android/app/build.gradle.kts`). Do not invent certificates, provisioning profiles, or App Store Connect IDs.
- **No dedicated onboarding screen:** launch → Home is the current architecture.
- **Untagged Watch cache:** English snapshots that stored `targetLanguage` are dropped. A pre-migration cache with **no** language field is kept until the next iPhone sync.
- **Watch lesson audio** still out of architecture; `pronunciationId` is on the payload. Watch ships UI SFX only.
- **Watch alphabet module** is not in the current architecture.
- **Some alphabet stills reused** where the German example still matches (`apple.png` / Apfel, `cat.png` / Katze).
- **Mass nouns** often omit `plural` (Wasser, Milch, Blut).
- **IPA** is espeak-ng quality inside `/slashes/`, not a studio transcription.
- **Marketing version** is `0.1.0+1` (`pubspec.yaml` / Flutter build name). Bump at store submission if 1.0.0 is required.
- **Watch `CFBundleName`** remains the target name `LingoWatch`; **display name** is `Learn German`.

---

## Phase 4 release checklist

| Area | Status |
| --- | --- |
| PRODUCT IDENTITY | **PASS** |
| CURRICULUM | **PASS** |
| GERMAN LANGUAGE QUALITY | **PASS** |
| ALPHABET | **PASS** |
| AUDIO | **PASS** |
| IMAGES | **PASS** |
| QUIZZES | **PASS** |
| LOCALIZATION | **PASS** |
| IPHONE | **PASS** |
| IPAD | **PASS** (orientations + shared Flutter UI; layout tests cover compact/standard) |
| APPLE WATCH | **PASS** (text lessons + SFX; no lesson TTS by design) |
| WATCH SYNC | **PASS** |
| ANDROID | **PASS** (support retained; debug APK command run in this phase) |
| PERSISTENCE | **PASS** |
| TESTS | **PASS** (456/456) |
| IOS BUILD | **PASS** (simulator, unsigned) |
| WATCH BUILD | **PASS** (simulator, unsigned) |
| RELEASE CONFIGURATION | **BLOCKED** — signed App Store / Play archive needs external signing credentials |

---

## Naming conventions (frozen)

- Product id: `learn_german`
- Content IDs: `word.{group}.{slug}`, `phrase.{category}.{slug}`, `letter.{slug}`
- Image IDs: `words.food`, `phrases.greetings`, `alphabet.apple`
- Audio: `assets/audio/de/<kind>/<id>.wav`
- UI keys: `nav.*`, `quiz.*`, `watch.*`
- Preference keys: `lingo.user.*`
- MethodChannel: `lingo_core/watch_sync`
- iOS bundle: `com.lingocore.learnGerman`
- Watch bundle: `com.lingocore.learnGerman.watchkitapp`
- Android applicationId: `com.lingocore.learn_german`

---

## Validation commands

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
python3 tools/german_audio/generate.py verify
```
