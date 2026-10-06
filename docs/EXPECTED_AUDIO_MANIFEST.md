# Expected German audio manifest

Deterministic pronunciation inventory and production recordings for
Learn German for Beginners.

Machine-readable inventory:

`docs/expected_audio_manifest.json`

Generator (development machine only):

`tools/german_audio/generate.py`

## Pipeline

| Step | Value |
| --- | --- |
| Provider | Native on-device TTS (`say` / AVSpeech). No cloud TTS. |
| Locale | `de-DE` |
| Selected voice | **Anna** (`com.apple.voice.super-compact.de-DE.Anna`) |
| Rejected | Eloquence character voices (Eddy, Flo, Grandma, Grandpa, Reed, Rocko, Sandy, Shelley). Helena/Petra Premium were not installed. |
| Gender | female |
| Rate | `0.47` AVSpeech / `165` WPM for `say` |
| Pitch | `1.0` |
| Container | 24 kHz mono 16-bit PCM WAV, one file per content ID |
| Lookup | `assets/audio/de/<kind>/<contentId>.wav` |

Filenames are ASCII because content IDs are ASCII (`letter.auml`, `word.food.apple`).
German letters in spoken text (`ä`, `ö`, `ü`, `ß`) stay in `speechText` metadata.
Isolated letters are synthesized lowercase so Apple voices do not announce a case label. `ß` stays `ß`.

Playback: bundled WAV if the file exists, otherwise native `de-DE` TTS.
The engine never falls back to an English (or other-language) voice.

## Counts

**1798** items (30 alphabet + 1156 words + 612 phrases). All generated.

Quiz listening prompts reuse the same files (same content IDs). There is no
separate quiz audio set.

Alphabet clips are letter names (A–Z, Ä, Ö, Ü, ß), not example-word clips.

Watch rows send the same content ID as `pronunciationId`. Watch does **not**
play lesson audio; it shows synchronized German `targetText` plus UI SFX only.

## Kind folders

```
assets/audio/de/alphabet/<id>.wav
assets/audio/de/words/<id>.wav
assets/audio/de/phrases/<id>.wav
```
