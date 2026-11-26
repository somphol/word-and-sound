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

# Tiles added beyond the original 60. IDs stay stable; list keys are
# <id>List, matching the convention used by the extracted layout.
EXTRA_TILES = [
    # Missing single onset consonants.
    {"category": "starting", "id": "startingT", "label": "t", "pattern": "t", "kind": "onset", "group": "single", "example": "top"},
    {"category": "starting", "id": "startingM", "label": "m", "pattern": "m", "kind": "onset", "group": "single", "example": "man"},
    {"category": "starting", "id": "startingN", "label": "n", "pattern": "n", "kind": "onset", "group": "single", "example": "no"},
    {"category": "starting", "id": "startingZ", "label": "z", "pattern": "z", "kind": "onset", "group": "single", "example": "zoo"},
    {"category": "starting", "id": "startingZH", "label": "ʒ", "pattern": "ʒ", "kind": "onset", "group": "single", "example": "genre"},
    # Missing onset blends.
    {"category": "starting", "id": "startingBR", "label": "br", "pattern": "br", "kind": "blend", "group": "blend", "example": "bring"},
    {"category": "starting", "id": "startingDR", "label": "dr", "pattern": "dr", "kind": "blend", "group": "blend", "example": "drink"},
    {"category": "starting", "id": "startingDW", "label": "dw", "pattern": "dw", "kind": "blend", "group": "blend", "example": "dwell"},
    {"category": "starting", "id": "startingFR", "label": "fr", "pattern": "fr", "kind": "blend", "group": "blend", "example": "friend"},
    {"category": "starting", "id": "startingGL", "label": "gl", "pattern": "gl", "kind": "blend", "group": "blend", "example": "glass"},
    {"category": "starting", "id": "startingGR", "label": "gr", "pattern": "gr", "kind": "blend", "group": "blend", "example": "green"},
    {"category": "starting", "id": "startingGW", "label": "gw", "pattern": "gw", "kind": "blend", "group": "blend", "example": "Gwen"},
    {"category": "starting", "id": "startingHJ", "label": "hj", "pattern": "hj", "kind": "blend", "group": "blend", "example": "human"},
    {"category": "starting", "id": "startingKL", "label": "kl", "pattern": "kl", "kind": "blend", "group": "blend", "example": "class"},
    {"category": "starting", "id": "startingKR", "label": "kr", "pattern": "kr", "kind": "blend", "group": "blend", "example": "cream"},
    {"category": "starting", "id": "startingKW", "label": "kw", "pattern": "kw", "kind": "blend", "group": "blend", "example": "queen"},
    {"category": "starting", "id": "startingLJ", "label": "lj", "pattern": "lj", "kind": "blend", "group": "blend", "example": "lute"},
    {"category": "starting", "id": "startingMJ", "label": "mj", "pattern": "mj", "kind": "blend", "group": "blend", "example": "music"},
    {"category": "starting", "id": "startingPL", "label": "pl", "pattern": "pl", "kind": "blend", "group": "blend", "example": "play"},
    {"category": "starting", "id": "startingPR", "label": "pr", "pattern": "pr", "kind": "blend", "group": "blend", "example": "price"},
    {"category": "starting", "id": "startingSK", "label": "sk", "pattern": "sk", "kind": "blend", "group": "blend", "example": "sky"},
    {"category": "starting", "id": "startingSKR", "label": "skr", "pattern": "skr", "kind": "blend", "group": "blend", "example": "screen"},
    {"category": "starting", "id": "startingSKW", "label": "skw", "pattern": "skw", "kind": "blend", "group": "blend", "example": "square"},
    {"category": "starting", "id": "startingSL", "label": "sl", "pattern": "sl", "kind": "blend", "group": "blend", "example": "slow"},
    {"category": "starting", "id": "startingSM", "label": "sm", "pattern": "sm", "kind": "blend", "group": "blend", "example": "small"},
    {"category": "starting", "id": "startingSN", "label": "sn", "pattern": "sn", "kind": "blend", "group": "blend", "example": "snow"},
    {"category": "starting", "id": "startingSP", "label": "sp", "pattern": "sp", "kind": "blend", "group": "blend", "example": "spoon"},
    {"category": "starting", "id": "startingSPL", "label": "spl", "pattern": "spl", "kind": "blend", "group": "blend", "example": "splash"},
    {"category": "starting", "id": "startingSPR", "label": "spr", "pattern": "spr", "kind": "blend", "group": "blend", "example": "spring"},
    {"category": "starting", "id": "startingST", "label": "st", "pattern": "st", "kind": "blend", "group": "blend", "example": "stop"},
    {"category": "starting", "id": "startingSW", "label": "sw", "pattern": "sw", "kind": "blend", "group": "blend", "example": "swim"},
    {"category": "starting", "id": "startingTW", "label": "tw", "pattern": "tw", "kind": "blend", "group": "blend", "example": "twin"},
    {"category": "starting", "id": "startingVJ", "label": "vj", "pattern": "vj", "kind": "blend", "group": "blend", "example": "view"},
    {"category": "starting", "id": "startingSHR", "label": "ʃr", "pattern": "ʃr", "kind": "blend", "group": "blend", "example": "shrimp"},
    # Missing single coda consonants.
    {"category": "ending", "id": "endingP", "label": "p", "pattern": "p", "kind": "coda", "group": "single", "example": "up"},
    {"category": "ending", "id": "endingB", "label": "b", "pattern": "b", "kind": "coda", "group": "single", "example": "job"},
    {"category": "ending", "id": "endingG", "label": "g", "pattern": "g", "kind": "coda", "group": "single", "example": "dog"},
    {"category": "ending", "id": "endingM", "label": "m", "pattern": "m", "kind": "coda", "group": "single", "example": "time"},
    {"category": "ending", "id": "endingZ", "label": "z", "pattern": "z", "kind": "coda", "group": "single", "example": "is"},
    {"category": "ending", "id": "endingDH", "label": "ð", "pattern": "ð", "kind": "coda", "group": "single", "example": "bathe"},
    {"category": "ending", "id": "endingZH", "label": "ʒ", "pattern": "ʒ", "kind": "coda", "group": "single", "example": "beige"},
    # Missing coda blends (non-rhotic RP; r-clusters are excluded).
    {"category": "ending", "id": "endingDZ", "label": "dz", "pattern": "dz", "kind": "codaBlend", "group": "blend", "example": "kids"},
    {"category": "ending", "id": "endingKS", "label": "ks", "pattern": "ks", "kind": "codaBlend", "group": "blend", "example": "books"},
    {"category": "ending", "id": "endingKST", "label": "kst", "pattern": "kst", "kind": "codaBlend", "group": "blend", "example": "asked"},
    {"category": "ending", "id": "endingLD", "label": "ld", "pattern": "ld", "kind": "codaBlend", "group": "blend", "example": "old"},
    {"category": "ending", "id": "endingLF", "label": "lf", "pattern": "lf", "kind": "codaBlend", "group": "blend", "example": "self"},
    {"category": "ending", "id": "endingLK", "label": "lk", "pattern": "lk", "kind": "codaBlend", "group": "blend", "example": "milk"},
    {"category": "ending", "id": "endingLP", "label": "lp", "pattern": "lp", "kind": "codaBlend", "group": "blend", "example": "help"},
    {"category": "ending", "id": "endingLS", "label": "ls", "pattern": "ls", "kind": "codaBlend", "group": "blend", "example": "else"},
    {"category": "ending", "id": "endingLT", "label": "lt", "pattern": "lt", "kind": "codaBlend", "group": "blend", "example": "salt"},
    {"category": "ending", "id": "endingLZ", "label": "lz", "pattern": "lz", "kind": "codaBlend", "group": "blend", "example": "fills"},
    {"category": "ending", "id": "endingMF", "label": "mf", "pattern": "mf", "kind": "codaBlend", "group": "blend", "example": "nymph"},
    {"category": "ending", "id": "endingMP", "label": "mp", "pattern": "mp", "kind": "codaBlend", "group": "blend", "example": "jump"},
    {"category": "ending", "id": "endingMPT", "label": "mpt", "pattern": "mpt", "kind": "codaBlend", "group": "blend", "example": "jumped"},
    {"category": "ending", "id": "endingMZ", "label": "mz", "pattern": "mz", "kind": "codaBlend", "group": "blend", "example": "comes"},
    {"category": "ending", "id": "endingND", "label": "nd", "pattern": "nd", "kind": "codaBlend", "group": "blend", "example": "hand"},
    {"category": "ending", "id": "endingNS", "label": "ns", "pattern": "ns", "kind": "codaBlend", "group": "blend", "example": "dance"},
    {"category": "ending", "id": "endingNT", "label": "nt", "pattern": "nt", "kind": "codaBlend", "group": "blend", "example": "want"},
    {"category": "ending", "id": "endingNTS", "label": "nts", "pattern": "nts", "kind": "codaBlend", "group": "blend", "example": "students"},
    {"category": "ending", "id": "endingNZ", "label": "nz", "pattern": "nz", "kind": "codaBlend", "group": "blend", "example": "wins"},
    {"category": "ending", "id": "endingPS", "label": "ps", "pattern": "ps", "kind": "codaBlend", "group": "blend", "example": "maps"},
    {"category": "ending", "id": "endingPT", "label": "pt", "pattern": "pt", "kind": "codaBlend", "group": "blend", "example": "kept"},
    {"category": "ending", "id": "endingSK", "label": "sk", "pattern": "sk", "kind": "codaBlend", "group": "blend", "example": "ask"},
    {"category": "ending", "id": "endingSP", "label": "sp", "pattern": "sp", "kind": "codaBlend", "group": "blend", "example": "wasp"},
    {"category": "ending", "id": "endingTS", "label": "ts", "pattern": "ts", "kind": "codaBlend", "group": "blend", "example": "cats"},
    {"category": "ending", "id": "endingDHD", "label": "ðd", "pattern": "ðd", "kind": "codaBlend", "group": "blend", "example": "bathed"},
    {"category": "ending", "id": "endingNGK", "label": "ŋk", "pattern": "ŋk", "kind": "codaBlend", "group": "blend", "example": "think"},
    {"category": "ending", "id": "endingNGZ", "label": "ŋz", "pattern": "ŋz", "kind": "codaBlend", "group": "blend", "example": "songs"},
    {"category": "ending", "id": "endingNGTH", "label": "ŋθ", "pattern": "ŋθ", "kind": "codaBlend", "group": "blend", "example": "length"},
    {"category": "ending", "id": "endingSHT", "label": "ʃt", "pattern": "ʃt", "kind": "codaBlend", "group": "blend", "example": "washed"},
    {"category": "ending", "id": "endingZHD", "label": "ʒd", "pattern": "ʒd", "kind": "codaBlend", "group": "blend", "example": "massaged"},
    # Vowel additions: a separate square vowel and the two common triphthongs.
    {"category": "vowel", "id": "vowelSquare", "label": "eə", "pattern": "eə", "kind": "vowel", "group": "vowel", "example": "there"},
    {"category": "vowel", "id": "vowelFire", "label": "aɪə", "pattern": "aɪə", "kind": "vowel", "group": "vowel", "example": "fire"},
    {"category": "vowel", "id": "vowelPower", "label": "aʊə", "pattern": "aʊə", "kind": "vowel", "group": "vowel", "example": "power"},
]

for _extra in EXTRA_TILES:
    PATTERNS[_extra["id"]] = (_extra["kind"], _extra["pattern"])


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
    "ɛː": r"ɛː",
    "eə": r"eə|ɛə",
    "aɪə": r"aɪə",
    "aʊə": r"aʊə",
    "oʊ/əʊ": r"əʊ|oʊ",
    "ɪə": r"(?<![aeɔ])ɪə",
    "ʌɪ": r"aɪ|ʌɪ|ɑj",
    "aʊ": r"aʊ|ɑʊ",
    "ɔɪ": r"ɔɪ",
    "ʊə": r"(?<![aə])ʊə",
}

# Keep single-sound tiles single: blends have their own tiles.
ONSET_EXCLUSIONS = {
    "b": ("bl", "br"),
    "d": ("dʒ", "dr", "dw"),
    "f": ("fj", "fl", "fr"),
    "g": ("gl", "gr", "gw"),
    "h": ("hj",),
    "k": ("kl", "kr", "kw"),
    "l": ("lj",),
    "m": ("mj",),
    "n": ("nj",),
    "p": ("pl", "pr"),
    "s": ("sk", "sl", "sm", "sn", "sp", "st", "sw", "str", "spl", "spr", "skr", "skw"),
    "ʃ": ("ʃr",),
    "t": ("tʃ", "tr", "tw"),
    "v": ("vj",),
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
        if label == "ŋθ":
            return re.search(r"ŋk?θ$", ipa) is not None
        if label == "ʒd" and ipa.endswith("dʒd"):
            return False
        return ipa.endswith(label)
    if kind == "coda":
        if label == "ʃ" and ipa.endswith("tʃ"):
            return False
        if label == "ʒ" and ipa.endswith("dʒ"):
            return False
        return ipa.endswith(label)
    if kind == "vowel":
        return re.search(VOWEL_PATTERNS[label], ipa) is not None
    return False


def matches(tile_id: str, kind: str, label: str, uk: str | None, us: str | None) -> bool:
    if tile_id == "endingLM":
        return us is not None and norm(us).endswith("lm")
    if tile_id == "endingZHD":
        return us is not None and norm(us).endswith("ʒd") and not norm(us).endswith("dʒd")
    if not uk:
        return False
    if not matches_one(kind, label, norm(uk)):
        return False
    # A UK/US disagreement usually means a bad or regional UK transcription.
    # For consonants, require both varieties to agree.
    no_us_check = {"startingNIOR", "startingLJ", "startingMJ", "startingVJ", "startingHJ"}
    if kind != "vowel" and tile_id not in no_us_check and us and not matches_one(kind, label, norm(us)):
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
    extra_by_id = {tile["id"]: tile for tile in EXTRA_TILES}
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
        tile = tiles.get(tile_id) or extra_by_id[tile_id]
        report[tile_id] = {
            "label": tile["label"],
            "group": kind,
            "pattern": label,
            "count": len(selected),
            "samples": selected[:12],
        }
        print(f"  {tile_id:16} {label:8} {len(selected):4}  {', '.join(selected[:8])}")

    # Add the new tiles to the library and give them their generated list as a
    # curated fallback. Existing tiles keep their authored lists.
    for extra in EXTRA_TILES:
        category = next(
            category for category in library["categories"]
            if category["id"] == extra["category"]
        )
        if not any(tile["id"] == extra["id"] for tile in category["tiles"]):
            category["tiles"].append({
                "id": extra["id"],
                "label": extra["label"],
                "exampleWord": extra["example"],
                "listKey": extra["id"] + "List",
                "group": extra["group"],
            })
        library["lists"][extra["id"] + "List"] = lists[extra["id"]]

    (DATA / "library.json").write_text(
        json.dumps(library, ensure_ascii=False, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )

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
