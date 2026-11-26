#!/usr/bin/env python3
"""Build pattern-based word lists from open IPA data.

Groups:
  * starting sounds        (single onset phonemes)
  * starting blends        (multi-consonant onsets)
  * ending sounds          (single coda phonemes)
  * ending blends          (multi-consonant codas)
  * vowel sounds           (nucleus phonemes)

Words are ranked by the OpenSubtitles frequency list, then filtered by the
phoneme pattern. Sources: ipa-dict en_US (MIT), Wiktionary/Kaikki UK IPA
(CC BY-SA 4.0 + GFDL), FrequencyWords (CC BY-SA 4.0).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_corpus import BANNED, JUNK, clean  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"

VOWELS = set("ʌɑaæɒɔɛeəɜɐɪiʊuɚɝ")

# Tile id -> (kind, pattern label)
PATTERNS: dict[str, tuple[str, str]] = {
    "startingD": ("onset", "d"),
    "startingL": ("onset", "l"),
    "startingR": ("onset", "r"),
    "startingS": ("onset", "s"),
    "startingCH": ("onset", "tʃ"),
    "startingSH": ("onset", "ʃ"),
    "startingW": ("onset", "w"),
    "startingF": ("onset", "f"),
    "startingV": ("onset", "v"),
    "startingB": ("onset", "b"),
    "startingP": ("onset", "p"),
    "startingTHUMB": ("onset", "θ"),
    "startingTHAT": ("onset", "ð"),
    "startingJ": ("onset", "dʒ"),
    "startingH": ("onset", "h"),
    "startingK": ("onset", "k"),
    "startingY": ("onset", "j"),
    "startingG": ("onset", "g"),
    "startingFEW": ("blend", "fj"),
    "startingNIOR": ("blend", "nj"),
    "startingTHROUGH": ("blend", "θr"),
    "startingTR": ("blend", "tr"),
    "startingBL": ("blend", "bl"),
    "startingSTR": ("blend", "str"),
    "endingD": ("coda", "d"),
    "endingF": ("coda", "f"),
    "endingL": ("coda", "l"),
    "endingN": ("coda", "n"),
    "endingNG": ("coda", "ŋ"),
    "endingS": ("coda", "s"),
    "endingK": ("coda", "k"),
    "endingT": ("coda", "t"),
    "endingTH": ("coda", "θ"),
    "endingJ": ("coda", "dʒ"),
    "endingV": ("coda", "v"),
    "endingSH": ("coda", "ʃ"),
    "endingCH": ("coda", "tʃ"),
    "endingKT": ("codaBlend", "kt"),
    "endingST": ("codaBlend", "st"),
    "endingLM": ("codaBlend", "lm"),
    "vowelNut": ("vowel", "ʌ"),
    "vowelMar": ("vowel", "ɑː"),
    "vowelKit": ("vowel", "ɪ"),
    "vowelBee": ("vowel", "iː"),
    "vowelPut": ("vowel", "ʊ"),
    "vowelPool": ("vowel", "uː"),
    "vowelAhead": ("vowel", "ə"),
    "vowelEarn": ("vowel", "əː"),
    "vowelBet": ("vowel", "ɛ"),
    "vowelDay": ("vowel", "eɪ"),
    "vowelRock": ("vowel", "ɒ"),
    "vowelAwe": ("vowel", "ɔː"),
    "vowelCat": ("vowel", "æ/a"),
    "vowelWear": ("vowel", "ɛː"),
    "vowelGo": ("vowel", "oʊ/əʊ"),
    "vowelNear": ("vowel", "ɪə"),
    "vowelTime": ("vowel", "ʌɪ"),
    "vowelOwl": ("vowel", "aʊ"),
    "vowelBoy": ("vowel", "ɔɪ"),
    "vowelTour": ("vowel", "ʊə"),
}

VOWEL_PATTERNS = {
    "ʌ": r"ʌ",
    "ɑː": r"ɑː",
    "ɪ": r"(?<![eaɔʌ])ɪ(?!ə)",
    "iː": r"iː",
    "ʊ": r"(?<![aəo])ʊ(?!ə)",
    "uː": r"uː",
    "ə": r"(?<![ɪʊe])ə(?!ʊ|ː)",
    "əː": r"əː|ɜː",
    "ɛ": r"ɛ(?!ː)",
    "eɪ": r"eɪ|ɛɪ",
    "ɒ": r"ɒ",
    "ɔː": r"ɔː",
    "æ/a": r"[æa](?!ɪ|ʊ)",
    "ɛː": r"ɛː|ɛə|eə",
    "oʊ/əʊ": r"əʊ|oʊ",
    "ɪə": r"(?<![aeɔ])ɪə",
    "ʌɪ": r"aɪ|ʌɪ|ɑj",
    "aʊ": r"aʊ|ɑʊ",
    "ɔɪ": r"ɔɪ",
    "ʊə": r"(?<![aə])ʊə",
}

# Keep single-sound tiles single: blends have their own tiles.
ONSET_EXCLUSIONS = {
    "d": ("dʒ",),
    "b": ("bl",),
    "f": ("fj",),
    "s": ("str",),
    "θ": ("θr",),
}

LIMIT = 120
LM_EXCLUDE = {"calm", "palm", "psalm", "salmon", "almond", "balm", "yolk", "half", "talk", "walk"}


def norm(ipa: str) -> str:
    value = unicodedata.normalize("NFD", ipa.strip())
    value = "".join(char for char in value if not unicodedata.combining(char))
    value = value.strip("/[]")
    for char in "ˈˌ.()‿͜͡":
        value = value.replace(char, "")
    # ipa-dict and Wiktionary use the alveolar approximant and script g;
    # the app labels use ordinary r and g.
    value = value.replace("ɹ", "r").replace("ɡ", "g").replace("ɫ", "l")
    return value


def matches_one(kind: str, label: str, ipa: str) -> bool:
    if kind == "onset":
        if not ipa.startswith(label):
            return False
        if any(ipa.startswith(prefix) for prefix in ONSET_EXCLUSIONS.get(label, ())):
            return False
        return True
    if kind == "blend":
        return ipa.startswith(label)
    if kind == "codaBlend":
        return ipa.endswith(label)
    if kind == "coda":
        if label == "ʃ" and ipa.endswith("tʃ"):
            return False
        return ipa.endswith(label)
    if kind == "vowel":
        return re.search(VOWEL_PATTERNS[label], ipa) is not None
    return False


def matches(tile_id: str, kind: str, label: str, uk: str | None, us: str | None) -> bool:
    if tile_id == "endingLM":
        return us is not None and norm(us).endswith("lm")
    if not uk:
        return False
    if not matches_one(kind, label, norm(uk)):
        return False
    # A UK/US disagreement usually means a bad or regional UK transcription.
    # For consonants, require both varieties to agree.
    if kind != "vowel" and tile_id not in {"startingNIOR"} and us and not matches_one(kind, label, norm(us)):
        return False
    return True

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=LIMIT)
    args = parser.parse_args()

    library = json.loads((DATA / "library.json").read_text(encoding="utf-8"))
    us = json.loads((DATA / "phonetics_us.json").read_text(encoding="utf-8"))
    uk = json.loads((DATA / "phonetics_uk.json").read_text(encoding="utf-8"))

    ranks: dict[str, int] = {}
    display: dict[str, str] = {}
    for rank, line in enumerate((DATA / "sources/frequency_en_50k.txt").read_text(encoding="utf-8").splitlines()):
        parts = line.split()
        if len(parts) < 2:
            continue
        word = clean(parts[0])
        if not word:
            continue
        key = word.casefold()
        if key not in ranks:
            ranks[key] = rank
            display[key] = word

    for words in library["lists"].values():
        for word in words:
            key = word.casefold()
            if key not in ranks:
                ranks[key] = 60_000
                display[key] = word

    candidates = sorted(
        (rank, key) for key, rank in ranks.items()
        if key in us or key in uk
    )
    print(f"  {len(candidates):,} candidates with IPA")

    tiles = {tile["id"]: tile for category in library["categories"] for tile in category["tiles"]}
    missing = sorted(set(tiles) - set(PATTERNS))
    if missing:
        print(f"error: no pattern for {', '.join(missing)}", file=sys.stderr)
        return 1

    lists: dict[str, list[str]] = {}
    report: dict[str, dict] = {}
    for tile_id, (kind, label) in PATTERNS.items():
        selected: list[str] = []
        seen: set[str] = set()
        for _, key in candidates:
            if key in seen:
                continue
            if tile_id == "endingLM" and key in LM_EXCLUDE:
                continue
            if matches(tile_id, kind, label, uk.get(key), us.get(key)):
                seen.add(key)
                selected.append(display.get(key, key))
                if len(selected) >= args.limit:
                    break
        lists[tile_id] = selected
        tile = tiles[tile_id]
        report[tile_id] = {
            "label": tile["label"],
            "group": kind,
            "pattern": label,
            "count": len(selected),
            "samples": selected[:12],
        }
        print(f"  {tile_id:16} {label:8} {len(selected):4}  {', '.join(selected[:8])}")

    payload = {
        "source": "Generated from ipa-dict en_US (MIT), Wiktionary/Kaikki UK IPA (CC BY-SA 4.0 + GFDL), FrequencyWords (CC BY-SA 4.0)",
        "license": "CC BY-SA 4.0",
        "limit": args.limit,
        "lists": lists,
    }
    (DATA / "pattern_lists.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (DATA / "pattern_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    provenance_path = DATA / "provenance.json"
    if provenance_path.exists():
        provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
        provenance["sources"] = [
            source for source in provenance["sources"]
            if source.get("name") != "Pattern-built lists"
        ]
        provenance["sources"].append({
            "name": "Pattern-built lists",
            "license": "CC BY-SA 4.0",
            "note": "Onset/coda/vowel word lists generated from open IPA and frequency data.",
        })
        provenance_path.write_text(
            json.dumps(provenance, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )

    counts = [item["count"] for item in report.values()]
    print(f"  total {sum(counts)} words, min {min(counts)}, max {max(counts)}")
    if min(counts) == 0:
        print("warning: some patterns produced no words", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
