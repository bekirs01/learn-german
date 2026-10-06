# Sound asset manifest

Learn German for Beginners UI cues. Drop a replacement file at the same path with the same
filename; no Dart changes are required. Each WAV is registered in
`pubspec.yaml`.

Playback is one-voice: a new cue stops the previous cue. Tap and selection
SFX are also coalesced (~70 ms) so repeated rapid taps cannot stack. Missing
files are probed once, cached as absent, and never crash the app. The Settings
Sound Effects toggle gates playback immediately.

## Shared sound direction

- Short, clean, premium, soft, modern
- Soft UI punctuation, not a game soundtrack
- Mono, 24 kHz, 16-bit PCM WAV
- Peak around -14 dBTP; loudness around -18 LUFS, never louder than speech
- Tiny files: target under 20 KB each (reject anything over 40 KB)
- No third-party random downloads; author original one-shot cues

## What to avoid (all files)

Arcade blips, chiptune, cartoon boings, childlike xylophone, long tails,
heavy reverb, voices, lyrics, bass drops, stacked notification triads,
casino stingers, looping beds, and anything over 220 ms.

## Event mapping

| UI moment | Haptic | Sound |
| --- | --- | --- |
| Normal tap | light | `sfx_tap.wav` (coalesced) |
| Selected answer | selection | `sfx_selection.wav` (coalesced) |
| Correct answer | success (medium) | `sfx_correct.wav` |
| Wrong answer | error (medium) | `sfx_wrong.wav` |
| Favorite add/remove | selection | none |
| Alphabet letter | selection | none |
| Spoken audio play | light | none |
| Generic success | success (medium) | `sfx_success.wav` |

Do not attach feedback to scrolling.

## Cues

| Filename | Event | Intended character | Duration target | Loudness character | What to avoid |
| --- | --- | --- | --- | --- | --- |
| `sfx_tap.wav` | tap | Soft rounded tick, felt more than heard | 40–70 ms | Very quiet, a whisper under UI | Clicky mouse, mechanical keyboard, sharp transient |
| `sfx_selection.wav` | selected answer | Dry muted tick, slightly higher than tap | 50–80 ms | Quiet, one thin layer | Toggle “boop”, bubble pop, glass ping |
| `sfx_correct.wav` | quiz correct | Two close, warm intervals resolving up | 120–180 ms | Soft confirmation, not a reward fanfare | Major-key jingle, coin collect, sparkle shower |
| `sfx_wrong.wav` | error, quiz wrong | Short low muted thud, polite | 100–160 ms | Soft warning, no sting | Buzzer, error honk, descending cartoon fail |
| `sfx_success.wav` | generic success | Single warm lifted tone, calmer than correct | 150–200 ms | Gentle settle, still short | Triumph brass, level-up, long shimmer tail |

## Paths

```
assets/sounds/sfx_tap.wav
assets/sounds/sfx_selection.wav
assets/sounds/sfx_correct.wav
assets/sounds/sfx_wrong.wav
assets/sounds/sfx_success.wav
```

These five original PCM WAV files ship with the app. `BundledSoundPlayer`
decodes them through a single `audioplayers` voice. Do not add a second SFX
package.

## Two audio systems

UI sound effects (this file) are not spoken pronunciation.

| System | Source | Gated by | Player |
| --- | --- | --- | --- |
| Sound effects | `assets/sounds/sfx_*.wav` | Settings → Sound effects | `SoundService` / `BundledSoundPlayer` |
| Pronunciation | optional language-pack `audioAsset`, else native TTS | `product.json` → `featureFlags.audio` | `PronunciationService` |

Do not play SFX as pronunciation. Do not use cloud or network TTS. Speech
locale comes from `speechLocale` / `targetLanguageCode`, never Translation
Language. A cloned language product can ship files under `assets/audio/<code>/`
later; TTS covers a missing-file gap. This German product ships recordings at
`assets/audio/de/{alphabet,words,phrases}/<contentId>.wav`. See
`docs/EXPECTED_AUDIO_MANIFEST.md` and `docs/LANGUAGE_PACK_GUIDE.md`.
