#!/usr/bin/env python3
"""Generate and verify bundled German pronunciation audio with native TTS.

Development-machine only. The app ships the WAV clips and never needs
network or an API key at runtime.

Engine: macOS `say` (AVSpeech / native de-DE)
Voice: best installed native German voice (Anna family, then Helena/Petra)
Locale: de-DE
Container: 24 kHz mono 16-bit PCM WAV

Usage:
  python3 generate.py voices
  python3 generate.py catalog
  python3 generate.py generate --sample
  python3 generate.py generate
  python3 generate.py generate --only ID
  python3 generate.py generate --force
  python3 generate.py verify
"""

from __future__ import annotations

import argparse
import array
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time
import wave
from collections import Counter
from pathlib import Path
from typing import Any

TOOL_DIR = Path(__file__).resolve().parent
ROOT = TOOL_DIR.parents[1]
MANIFEST_PATH = ROOT / "docs" / "expected_audio_manifest.json"
REPORT_PATH = TOOL_DIR / "verification.json"
AUDIO_ROOT = ROOT / "assets" / "audio" / "de"

PIPELINE_VERSION = 1
ENGINE_ID = "macOS say / AVSpeech native TTS"
LOCALE = "de-DE"
SAMPLE_RATE = 24000
SAY_RATE_WPM = 165  # ~product AVSpeech rate 0.47; natural, not exaggerated-slow
MAX_RETRIES = 3
RETRY_SLEEP_S = 0.4
SAY_TIMEOUT_S = 30
MIN_BYTES = 1500
MIN_DURATION_S = 0.12
MAX_DURATION_S = 12.0
MIN_PEAK = 800
GIMMICK_TOKENS = (
    "novelty",
    "whisper",
    "bad guy",
    "superstar",
    "jester",
    "bells",
    "organ",
    "reed",
    "cellos",
    "good news",
    "babu",
    "wobble",
    "princess",
    "grandma",
    "grandpa",
    "boing",
    "trinoids",
    "zarvox",
    "deranged",
    "eddy",
    "flo",
    "rocko",
    "sandy",
    "shelley",
    "eloquence",
)
PREFERRED_VOICES = (
    "Anna (Premium)",
    "Anna (Enhanced)",
    "Helena (Premium)",
    "Helena (Enhanced)",
    "Helena",
    "Petra (Enhanced)",
    "Petra",
    "Anna",
)
SAMPLE_IDS = (
    "letter.a",
    "letter.r",
    "letter.auml",
    "letter.ouml",
    "letter.uuml",
    "letter.eszett",
    "word.basics.hello",
    "word.basics.like",
    "word.number.five",
    "word.food.apple",
    "word.home.house",
    "word.number.half",
    "phrase.greetings.hello",
    "phrase.greetings.how_are_you",
    "phrase.daily_conversation.lets_go",
    "phrase.directions.where_is_the_station",
    "phrase.hotel.could_i_have_another_room_key",
)

_ISOLATED_LETTER = re.compile(r"^\w$", re.UNICODE)


def die(message: str, code: int = 1) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(code)


def load_manifest() -> dict[str, Any]:
    if not MANIFEST_PATH.is_file():
        die(f"missing inventory: {MANIFEST_PATH}")
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def items_from(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    rows = manifest.get("items")
    if not isinstance(rows, list) or not rows:
        die("expected_audio_manifest.json has no items")
    return [row for row in rows if isinstance(row, dict)]


def utterance_for(speech_text: str) -> str:
    """Match SpeechTextNormalizer.utterance: isolated letters are lowercased.

    Uppercase single letters make Apple voices announce a case label.
    German ß stays ß and is never expanded to SS.
    """
    value = speech_text.strip()
    if not value:
        return value
    if value in {"ß", "ẞ"}:
        return "ß"
    if _ISOLATED_LETTER.match(value):
        return value.lower()
    return value


def list_say_voices() -> list[tuple[str, str]]:
    result = subprocess.run(
        ["say", "-v", "?"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        die(f"say -v '?' failed: {result.stderr.strip()}")
    voices: list[tuple[str, str]] = []
    for line in result.stdout.splitlines():
        if "#" not in line:
            continue
        left, _hash, _sample = line.partition("#")
        parts = left.split()
        if len(parts) < 2:
            continue
        locale = parts[-1].replace("_", "-")
        name = " ".join(parts[:-1]).strip()
        voices.append((name, locale))
    return voices


def is_gimmick(name: str) -> bool:
    blob = name.lower()
    return any(token in blob for token in GIMMICK_TOKENS)


def select_voice() -> dict[str, str]:
    installed = list_say_voices()
    german = [
        (name, locale)
        for name, locale in installed
        if locale.lower().startswith("de") and not is_gimmick(name)
    ]
    if not german:
        die("no native German de-DE voice is installed")
    by_name = {name.lower(): (name, locale) for name, locale in german}
    for preferred in PREFERRED_VOICES:
        hit = by_name.get(preferred.lower())
        if hit is not None:
            name, locale = hit
            return {
                "name": name,
                "locale": "de-DE" if locale.lower().startswith("de-de") else locale,
                "engine": ENGINE_ID,
                "quality": "premium"
                if "premium" in name.lower()
                else "enhanced"
                if "enhanced" in name.lower()
                else "compact",
            }
    name, locale = german[0]
    return {
        "name": name,
        "locale": "de-DE" if locale.lower().startswith("de-de") else locale,
        "engine": ENGINE_ID,
        "quality": "compact",
    }


def catalog_counts(items: list[dict[str, Any]]) -> dict[str, int]:
    counts = Counter(str(item.get("kind") or "unknown") for item in items)
    return {
        "alphabet": int(counts.get("alphabet", 0)),
        "words": int(counts.get("words", 0)),
        "phrases": int(counts.get("phrases", 0)),
        "total": len(items),
    }


def inspect_wav(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {"ok": False, "error": "missing"}
    size = path.stat().st_size
    if size < MIN_BYTES:
        return {"ok": False, "error": f"too-small:{size}", "bytes": size}
    try:
        with wave.open(str(path), "rb") as handle:
            channels = handle.getnchannels()
            rate = handle.getframerate()
            width = handle.getsampwidth()
            frames = handle.getnframes()
            comptype = handle.getcomptype()
            raw = handle.readframes(frames)
    except wave.Error as exc:
        return {"ok": False, "error": f"undecodable:{exc}", "bytes": size}
    duration = frames / float(rate) if rate else 0.0
    if channels != 1:
        return {"ok": False, "error": f"channels:{channels}", "bytes": size}
    if rate != SAMPLE_RATE:
        return {"ok": False, "error": f"rate:{rate}", "bytes": size}
    if width != 2:
        return {"ok": False, "error": f"width:{width}", "bytes": size}
    if comptype not in {"NONE", "none", "NONE"}:
        # Apple WAVE from `say` reports NONE.
        if comptype.upper() != "NONE":
            return {"ok": False, "error": f"codec:{comptype}", "bytes": size}
    if duration < MIN_DURATION_S:
        return {
            "ok": False,
            "error": f"short:{duration:.3f}",
            "bytes": size,
            "duration": duration,
        }
    if duration > MAX_DURATION_S:
        return {
            "ok": False,
            "error": f"long:{duration:.3f}",
            "bytes": size,
            "duration": duration,
        }
    samples = array.array("h")
    samples.frombytes(raw)
    if not samples:
        return {"ok": False, "error": "empty-pcm", "bytes": size}
    peak = max(abs(sample) for sample in samples)
    if peak < MIN_PEAK:
        return {
            "ok": False,
            "error": f"silent:{peak}",
            "bytes": size,
            "duration": duration,
            "peak": peak,
        }
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return {
        "ok": True,
        "bytes": size,
        "duration": round(duration, 4),
        "peak": peak,
        "sha256": digest,
        "channels": channels,
        "sampleRate": rate,
        "sampleWidth": width,
    }


def synthesize(text: str, voice: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="lingo-de-tts-") as tmp:
        raw_path = Path(tmp) / "utterance.wav"
        cmd = [
            "say",
            "-v",
            voice,
            "--data-format=LEI16@24000",
            "-r",
            str(SAY_RATE_WPM),
            "-o",
            str(raw_path),
            "--",
            text,
        ]
        result = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=SAY_TIMEOUT_S,
        )
        if result.returncode != 0 or not raw_path.is_file():
            err = (result.stderr or result.stdout or "say failed").strip()
            raise RuntimeError(err)
        shutil.move(str(raw_path), str(dest))


def generate_one(
    item: dict[str, Any],
    voice: dict[str, str],
    *,
    force: bool,
) -> dict[str, Any]:
    content_id = str(item["contentId"])
    speech = str(item.get("speechText") or "").strip()
    asset_path = ROOT / str(item["assetPath"])
    record: dict[str, Any] = {
        "contentId": content_id,
        "kind": item.get("kind"),
        "contentType": item.get("kind"),
        "audioKey": item.get("audioKey") or content_id,
        "filename": item.get("filename"),
        "assetPath": item.get("assetPath"),
        "speechText": speech,
        "locale": LOCALE,
        "voice": voice["name"],
    }
    if not speech:
        record["generationStatus"] = "failed"
        record["error"] = "empty-speech-text"
        return record
    if asset_path.is_file() and not force:
        inspection = inspect_wav(asset_path)
        if inspection.get("ok"):
            record["generationStatus"] = "generated"
            record.update(
                {
                    "bytes": inspection["bytes"],
                    "durationSeconds": inspection["duration"],
                    "sha256": inspection["sha256"],
                    "cached": True,
                }
            )
            return record
    spoken = utterance_for(speech)
    last_error = "unknown"
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            synthesize(spoken, voice["name"], asset_path)
            inspection = inspect_wav(asset_path)
            if not inspection.get("ok"):
                last_error = str(inspection.get("error") or "invalid-wav")
                if asset_path.exists():
                    asset_path.unlink()
                raise RuntimeError(last_error)
            record["generationStatus"] = "generated"
            record.update(
                {
                    "bytes": inspection["bytes"],
                    "durationSeconds": inspection["duration"],
                    "sha256": inspection["sha256"],
                    "retries": attempt - 1,
                    "utterance": spoken,
                    "cached": False,
                }
            )
            return record
        except subprocess.TimeoutExpired:
            last_error = "timeout"
        except Exception as exc:  # noqa: BLE001 — pipeline must keep going
            last_error = str(exc)
        if attempt < MAX_RETRIES:
            time.sleep(RETRY_SLEEP_S * attempt)
    if asset_path.exists():
        asset_path.unlink()
    record["generationStatus"] = "failed"
    record["error"] = last_error
    record["retries"] = MAX_RETRIES
    return record


def selected_items(
    items: list[dict[str, Any]],
    *,
    sample: bool,
    only: list[str],
) -> list[dict[str, Any]]:
    if only:
        wanted = set(only)
        chosen = [
            item
            for item in items
            if item.get("contentId") in wanted or item.get("assetPath") in wanted
        ]
        missing = wanted - {item.get("contentId") for item in chosen} - {
            item.get("assetPath") for item in chosen
        }
        if missing:
            die("unknown --only ids: " + ", ".join(sorted(str(x) for x in missing)))
        return chosen
    if sample:
        wanted = set(SAMPLE_IDS)
        chosen = [item for item in items if item.get("contentId") in wanted]
        missing = wanted - {item.get("contentId") for item in chosen}
        if missing:
            die("sample ids missing from inventory: " + ", ".join(sorted(missing)))
        return chosen
    return items


def write_updated_manifest(
    manifest: dict[str, Any],
    voice: dict[str, str],
    results: dict[str, dict[str, Any]],
) -> None:
    updated_items: list[dict[str, Any]] = []
    for item in items_from(manifest):
        content_id = str(item["contentId"])
        result = results.get(content_id, {})
        row = {
            "contentId": content_id,
            "kind": item.get("kind"),
            "contentType": item.get("kind"),
            "audioKey": item.get("audioKey") or content_id,
            "filename": item.get("filename"),
            "assetPath": item.get("assetPath"),
            "speechText": item.get("speechText"),
            "locale": LOCALE,
            "voice": voice["name"],
            "generationStatus": result.get("generationStatus")
            or item.get("generationStatus")
            or "pending",
        }
        if result.get("bytes") is not None:
            row["bytes"] = result["bytes"]
        elif item.get("bytes") is not None:
            row["bytes"] = item["bytes"]
        if result.get("durationSeconds") is not None:
            row["durationSeconds"] = result["durationSeconds"]
        elif item.get("durationSeconds") is not None:
            row["durationSeconds"] = item["durationSeconds"]
        if result.get("error"):
            row["error"] = result["error"]
        updated_items.append(row)
    payload = dict(manifest)
    payload.update(
        {
            "locale": LOCALE,
            "languageCode": "de",
            "extension": "wav",
            "provider": "native_tts",
            "engine": voice["engine"],
            "pipelineVersion": PIPELINE_VERSION,
            "voice": {
                "preferredVoiceName": voice["name"],
                "preferredVoiceNames": list(PREFERRED_VOICES),
                "preferredGender": "female",
                "rate": 0.47,
                "sayRateWpm": SAY_RATE_WPM,
                "pitch": 1.0,
                "quality": voice["quality"],
            },
            "count": len(updated_items),
            "items": updated_items,
        }
    )
    MANIFEST_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def cmd_voices() -> None:
    installed = list_say_voices()
    print("Installed German-capable voices:")
    for name, locale in installed:
        if not locale.lower().startswith("de"):
            continue
        mark = "REJECT gimmick" if is_gimmick(name) else "candidate"
        print(f"  {name:40} {locale:8} {mark}")
    selected = select_voice()
    print()
    print("Selected:", json.dumps(selected, ensure_ascii=False))


def cmd_catalog() -> None:
    manifest = load_manifest()
    items = items_from(manifest)
    counts = catalog_counts(items)
    print(json.dumps(counts, indent=2))
    texts = [str(item.get("speechText") or "") for item in items]
    dup_texts = [text for text, count in Counter(texts).items() if text and count > 1]
    print("duplicateSpeechTextGroups", len(dup_texts))
    print("emptySpeechText", sum(1 for text in texts if not text.strip()))


def cmd_generate(args: argparse.Namespace) -> None:
    manifest = load_manifest()
    items = items_from(manifest)
    voice = select_voice()
    chosen = selected_items(items, sample=args.sample, only=args.only or [])
    print(
        f"voice={voice['name']} locale={voice['locale']} quality={voice['quality']} "
        f"items={len(chosen)}/{len(items)} force={args.force}"
    )
    results: dict[str, dict[str, Any]] = {}
    generated = 0
    cached = 0
    failed = 0
    retries = 0
    started = time.time()
    for index, item in enumerate(chosen, start=1):
        record = generate_one(item, voice, force=args.force)
        results[str(item["contentId"])] = record
        retries += int(record.get("retries") or 0)
        status = record.get("generationStatus")
        if status == "generated":
            if record.get("cached"):
                cached += 1
            else:
                generated += 1
        else:
            failed += 1
            print(
                f"FAIL {item['contentId']}: {record.get('error')}",
                file=sys.stderr,
            )
        if index % 50 == 0 or index == len(chosen):
            elapsed = time.time() - started
            print(
                f"[{index}/{len(chosen)}] new={generated} cached={cached} "
                f"failed={failed} elapsed={elapsed:.0f}s"
            )
    write_updated_manifest(manifest, voice, results)
    summary = {
        "voice": voice,
        "expected": len(items),
        "targeted": len(chosen),
        "generatedNew": generated,
        "cached": cached,
        "failed": failed,
        "retries": retries,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    if failed:
        raise SystemExit(2)


def _punctuation_equivalent(texts: list[str]) -> bool:
    normalized = {
        re.sub(r"[.!?…]+$", "", text.strip())
        for text in texts
        if text.strip()
    }
    return len(normalized) == 1


def verify_collection(items: list[dict[str, Any]]) -> dict[str, Any]:
    missing: list[str] = []
    corrupt: list[str] = []
    failed_status: list[str] = []
    inspections: list[dict[str, Any]] = []
    hashes: dict[str, list[str]] = {}
    path_owners: dict[str, str] = {}
    collisions: list[str] = []
    by_id = {str(item["contentId"]): item for item in items}
    for item in items:
        content_id = str(item["contentId"])
        rel = str(item["assetPath"])
        path = ROOT / rel
        previous = path_owners.get(rel)
        if previous and previous != content_id:
            collisions.append(rel)
        else:
            path_owners[rel] = content_id
        inspection = inspect_wav(path)
        row = {"contentId": content_id, "assetPath": rel, **inspection}
        inspections.append(row)
        if not path.is_file():
            missing.append(rel)
            continue
        if not inspection.get("ok"):
            corrupt.append(f"{rel}:{inspection.get('error')}")
            continue
        hashes.setdefault(str(inspection["sha256"]), []).append(content_id)
        if item.get("generationStatus") == "failed":
            failed_status.append(content_id)
    punctuation_duplicates: dict[str, list[str]] = {}
    unexpected_duplicates: dict[str, list[str]] = {}
    for digest, ids in hashes.items():
        if len(ids) < 2:
            continue
        texts = [str(by_id[i].get("speechText") or "") for i in ids]
        if _punctuation_equivalent(texts):
            punctuation_duplicates[digest] = ids
        else:
            unexpected_duplicates[digest] = ids
    duplicate_binaries = unexpected_duplicates
    kinds = catalog_counts(items)
    present = [
        row for row in inspections if row.get("ok")
    ]
    report = {
        "expected": len(items),
        "presentOk": len(present),
        "missing": missing,
        "corrupt": corrupt,
        "failedStatus": failed_status,
        "filenameCollisions": collisions,
        "duplicateBinaries": duplicate_binaries,
        "punctuationEquivalentDuplicates": punctuation_duplicates,
        "counts": kinds,
        "minBytes": min((row["bytes"] for row in present), default=0),
        "maxBytes": max((row["bytes"] for row in present), default=0),
        "minDuration": min((row["duration"] for row in present), default=0),
        "maxDuration": max((row["duration"] for row in present), default=0),
        "totalBytes": sum((row["bytes"] for row in present), start=0),
    }
    REPORT_PATH.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return report


def cmd_verify() -> None:
    items = items_from(load_manifest())
    report = verify_collection(items)
    print(
        json.dumps(
            {
                key: report[key]
                for key in (
                    "expected",
                    "presentOk",
                    "counts",
                    "minBytes",
                    "maxBytes",
                    "minDuration",
                    "maxDuration",
                    "totalBytes",
                )
            },
            indent=2,
        )
    )
    print("missing", len(report["missing"]))
    print("corrupt", len(report["corrupt"]))
    print("filenameCollisions", len(report["filenameCollisions"]))
    print("duplicateBinaries", len(report["duplicateBinaries"]))
    print(
        "punctuationEquivalentDuplicates",
        len(report["punctuationEquivalentDuplicates"]),
    )
    if (
        report["missing"]
        or report["corrupt"]
        or report["filenameCollisions"]
        or report["duplicateBinaries"]
    ):
        if report["missing"][:10]:
            print("missing sample", report["missing"][:10])
        if report["corrupt"][:10]:
            print("corrupt sample", report["corrupt"][:10])
        raise SystemExit(2)
    if report["presentOk"] != report["expected"]:
        raise SystemExit(2)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("voices")
    sub.add_parser("catalog")
    gen = sub.add_parser("generate")
    gen.add_argument("--sample", action="store_true")
    gen.add_argument("--force", action="store_true")
    gen.add_argument("--only", action="append", default=[])
    sub.add_parser("verify")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    if args.command == "voices":
        cmd_voices()
    elif args.command == "catalog":
        cmd_catalog()
    elif args.command == "generate":
        cmd_generate(args)
    elif args.command == "verify":
        cmd_verify()
    else:
        die(f"unknown command {args.command}")


if __name__ == "__main__":
    main()
