#!/usr/bin/env python3
"""Build the license-clean data bundle for the Word & Sound Mac app.

Sources:
  * data/authored_lists.json      - the 60 lists supplied by the app author
  * data/layout.json              - tile layout extracted from the .aia
  * data/sources/ngsl_1.2_stats.csv
  * data/sources/nawl_1.2_stats.csv
  * data/sources/ngsl_s_1.2_stats.csv
  * data/sources/frequency_en_50k.txt
  * data/sources/ipa_en_US.txt
  * Kaikki English JSONL (filtered; not committed)

Outputs:
  * data/library.json
  * data/phonetics_us.json
  * data/phonetics_uk.json
  * data/provenance.json
  * data/coverage.json
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
import unicodedata
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
SOURCES = DATA / "sources"

WORD_RE = re.compile(r"^[A-Za-z][A-Za-z'\-]*$")
BANNED = {
    "rape", "raped", "raping", "sex", "sexual", "porn", "porno",
    "nigger", "nigga", "fuck", "fucking", "shit", "cunt", "dick",
    "cock", "pussy", "whore", "slut", "bastard",
}
JUNK = {
    "http", "https", "www", "com", "org", "net", "html", "php", "jpg",
    "gif", "png", "pdf", "utm", "amp", "nbsp",
}

MIXED = [
    {
        "id": "core_3k",
        "title": "Core English 3k",
        "source": "New General Service List 1.2",
        "author": "Browne, Culligan & Phillips",
        "license": "CC BY-SA 4.0",
        "url": "https://www.newgeneralservicelist.org/",
    },
    {
        "id": "spoken",
        "title": "Everyday Spoken",
        "source": "New General Service List - Spoken 1.2",
        "author": "Browne & Culligan",
        "license": "CC BY-SA 4.0",
        "url": "https://www.newgeneralservicelist.org/",
    },
    {
        "id": "academic",
        "title": "Academic English",
        "source": "New Academic Word List 1.2",
        "author": "Browne & Culligan",
        "license": "CC BY-SA 4.0",
        "url": "https://www.newgeneralservicelist.org/",
    },
    {
        "id": "common_10k",
        "title": "Common English 10k",
        "source": "FrequencyWords (OpenSubtitles 2018)",
        "author": "Hermit Dave; OpenSubtitles contributors",
        "license": "CC BY-SA 4.0",
        "url": "https://github.com/hermitdave/FrequencyWords",
    },
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def clean(word: str) -> str | None:
    word = word.strip().strip("\ufeff")
    if not word or " " in word:
        return None
    if not WORD_RE.fullmatch(word):
        return None
    if len(word) == 1 and word not in ("a", "I"):
        return None
    if word.casefold() in BANNED or word.casefold() in JUNK:
        return None
    return word


def dedupe(words: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for word in words:
        key = word.casefold()
        if key in seen:
            continue
        seen.add(key)
        out.append(word)
    return out


def read_csv_words(path: Path, column: str, expected: int) -> list[str]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise SystemExit(f"no header in {path}")
        if column not in reader.fieldnames:
            column = reader.fieldnames[0]
        words = []
        for row in reader:
            value = (row.get(column) or "").strip()
            cleaned = clean(value)
            if cleaned:
                words.append(cleaned)
    words = dedupe(words)
    print(f"  {path.name:28} {len(words):5} words (expected ~{expected})")
    return words


def read_frequency(path: Path, limit: int) -> list[str]:
    words = []
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        cleaned = clean(parts[0])
        if cleaned:
            words.append(cleaned.casefold() if cleaned != "I" else "I")
        if len(words) >= limit:
            break
    words = dedupe(words)
    print(f"  {path.name:28} {len(words):5} words (top {limit})")
    return words


def normalise_ipa(value: str) -> str | None:
    value = value.strip()
    if not value:
        return None
    # Keep the first phonemic transcription, otherwise the first phonetic one.
    match = re.search(r"/[^/]+/", value)
    if match:
        value = match.group(0)
    else:
        match = re.search(r"\[[^\]]+\]", value)
        if match:
            value = "/" + match.group(0)[1:-1] + "/"
    # Remove tie bars and combining diacritics (aɪ̯ -> aɪ, t͡ʃ -> tʃ,
    # ä -> a). These are transcription detail, not needed for display or
    # pattern matching.
    value = unicodedata.normalize("NFD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    value = value.replace("͡", "").replace("͜", "")
    value = value.strip()
    if not value.startswith("/"):
        value = "/" + value
    if not value.endswith("/"):
        value = value + "/"
    return value

def read_us_ipa(path: Path, wanted: set[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "\t" not in line:
            continue
        word, ipa = line.split("\t", 1)
        key = word.strip().casefold()
        if key not in wanted or key in out:
            continue
        normalised = normalise_ipa(ipa)
        if normalised:
            out[key] = normalised
    print(f"  {path.name:28} {len(out):5} entries")
    return out


WORD_FIELD = re.compile(rb'"word":\s*"((?:[^"\\]|\\.)*)"')


def read_uk_ipa(path: Path, wanted: set[str]) -> dict[str, str]:
    """Extract a conservative British pronunciation for each word.

    The Kaikki data contains many regional and historical variants. To keep the
    display trustworthy we take the first entry that carries sounds, prefer a
    Received Pronunciation tag, then a single UK/British form, then a single
    untagged form. If that entry has several competing forms we leave the word
    without UK IPA and the app falls back to US IPA.
    """
    import gzip

    out: dict[str, str] = {}
    seen: set[str] = set()
    total = 0
    other_regions = (
        "us", "general-american", "canada", "australia", "new-zealand",
        "india", "south-asia", "ireland", "scotland", "wales", "hong-kong",
        "singapore", "south-africa", "general-south-african", "jamaica",
        "multicultural-london-english", "northumbria", "new-york-city",
        "southern-us", "west-country", "east-anglia", "lancashire", "yorkshire",
    )
    weak_tags = (
        "obsolete", "archaic", "dialectal", "nonstandard", "colloquial",
        "uncommon", "early", "modern", "middle", "rare",
    )

    with gzip.open(path, "rb") as handle:
        for raw_line in handle:
            total += 1
            try:
                entry = json.loads(raw_line)
            except json.JSONDecodeError:
                continue
            word = str(entry.get("word", "")).casefold()
            if word not in wanted or word in seen:
                continue
            if entry.get("pos") == "name":
                continue

            rp: list[str] = []
            uk: list[str] = []
            generic_slash: list[str] = []
            generic_bracket: list[str] = []
            any_sound = False
            for sound in entry.get("sounds", []):
                raw_ipa = sound.get("ipa")
                if not raw_ipa:
                    continue
                any_sound = True
                tags = [t.casefold() for t in sound.get("tags", [])]
                if any(t in tags for t in weak_tags):
                    continue
                ipa = normalise_ipa(raw_ipa)
                if not ipa:
                    continue
                if "received-pronunciation" in tags:
                    rp.append(ipa)
                elif any(t in tags for t in ("uk", "british", "england")):
                    if not any(t in tags for t in other_regions):
                        uk.append(ipa)
                elif not any(t in tags for t in other_regions):
                    if raw_ipa.strip().startswith("/"):
                        generic_slash.append(ipa)
                    else:
                        generic_bracket.append(ipa)

            if not any_sound:
                continue
            seen.add(word)

            generic = generic_slash or generic_bracket
            chosen: str | None = None
            if rp:
                chosen = next((ipa for ipa in rp if ipa.startswith("/")), rp[0])
            elif len(uk) == 1:
                chosen = uk[0]
            elif not uk and len(generic) == 1:
                chosen = generic[0]
            if chosen:
                out[word] = chosen

            if total % 250_000 == 0:
                print(f"    ... {total:>9,} lines, {len(out):>5} UK entries", flush=True)

    print(f"  {path.name:28} {len(out):5} entries (scanned {total:,} lines)")
    return out

def coverage(words: list[str], us: dict[str, str], uk: dict[str, str]) -> dict:
    us_hits = sum(1 for w in words if w.casefold() in us)
    uk_hits = sum(1 for w in words if w.casefold() in uk)
    missing_us = [w for w in words if w.casefold() not in us][:12]
    missing_uk = [w for w in words if w.casefold() not in uk][:12]
    return {
        "words": len(words),
        "us": us_hits,
        "uk": uk_hits,
        "usPct": round(100 * us_hits / len(words), 1) if words else 0,
        "ukPct": round(100 * uk_hits / len(words), 1) if words else 0,
        "missingUs": missing_us,
        "missingUk": missing_uk,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--kaikki",
        default="/tmp/kaikki_en.jsonl.gz",
        help="Kaikki English JSONL.gz (not committed)",
    )
    args = parser.parse_args()

    layout = json.loads((DATA / "layout.json").read_text(encoding="utf-8"))
    authored = json.loads((DATA / "authored_lists.json").read_text(encoding="utf-8"))

    print("Reading vocabulary sources")
    mixed_words = {
        "core_3k": read_csv_words(SOURCES / "ngsl_1.2_stats.csv", "Lemma", 2809),
        "spoken": read_csv_words(SOURCES / "ngsl_s_1.2_stats.csv", "Lemma", 721),
        "academic": read_csv_words(SOURCES / "nawl_1.2_stats.csv", "Word", 957),
        "common_10k": read_frequency(SOURCES / "frequency_en_50k.txt", 10_000),
    }

    all_lists = {**authored, **mixed_words}
    candidates = read_frequency(SOURCES / "frequency_en_50k.txt", 50_000)
    wanted = {w.casefold() for words in all_lists.values() for w in words}
    wanted |= {w.casefold() for w in candidates}
    print(f"  unique candidate words: {len(wanted):,}")

    print("Reading pronunciation sources")
    us = read_us_ipa(SOURCES / "ipa_en_US.txt", wanted)
    uk: dict[str, str] = {}
    kaikki = Path(args.kaikki)
    if kaikki.exists():
        uk = read_uk_ipa(kaikki, wanted)
    else:
        print(f"  warning: {kaikki} not found; building without UK IPA", file=sys.stderr)

    layout["mixed"] = MIXED
    layout["lists"] = all_lists

    library = {
        "app": layout["app"],
        "categories": layout["categories"],
        "mixed": layout["mixed"],
        "lists": layout["lists"],
    }
    (DATA / "library.json").write_text(
        json.dumps(library, ensure_ascii=False, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )
    (DATA / "phonetics_us.json").write_text(
        json.dumps(dict(sorted(us.items())), ensure_ascii=False, indent=0) + "\n",
        encoding="utf-8",
    )
    (DATA / "phonetics_uk.json").write_text(
        json.dumps(dict(sorted(uk.items())), ensure_ascii=False, indent=0) + "\n",
        encoding="utf-8",
    )

    report = {
        "generated": date.today().isoformat(),
        "uniqueWords": len(wanted),
        "phoneticsUs": len(us),
        "phoneticsUk": len(uk),
        "lists": {},
    }
    for name, words in all_lists.items():
        report["lists"][name] = coverage(words, us, uk)

    (DATA / "coverage.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    sources = [
        {
            "name": "Authored sound lists",
            "file": "authored_lists.json",
            "license": "CC BY-SA 4.0",
            "note": "Supplied by the app author; cleaned and deduplicated.",
        },
        {
            "name": "New General Service List 1.2",
            "url": "https://www.newgeneralservicelist.org/",
            "file": "ngsl_1.2_stats.csv",
            "sha256": sha256(SOURCES / "ngsl_1.2_stats.csv"),
            "license": "CC BY-SA 4.0",
        },
        {
            "name": "New General Service List - Spoken 1.2",
            "url": "https://www.newgeneralservicelist.org/",
            "file": "ngsl_s_1.2_stats.csv",
            "sha256": sha256(SOURCES / "ngsl_s_1.2_stats.csv"),
            "license": "CC BY-SA 4.0",
        },
        {
            "name": "New Academic Word List 1.2",
            "url": "https://www.newgeneralservicelist.org/",
            "file": "nawl_1.2_stats.csv",
            "sha256": sha256(SOURCES / "nawl_1.2_stats.csv"),
            "license": "CC BY-SA 4.0",
        },
        {
            "name": "FrequencyWords (OpenSubtitles 2018)",
            "url": "https://github.com/hermitdave/FrequencyWords",
            "commit": "072bbed282316a23651aa7068c7173aa7898cf80",
            "file": "frequency_en_50k.txt",
            "sha256": sha256(SOURCES / "frequency_en_50k.txt"),
            "license": "CC BY-SA 4.0",
        },
        {
            "name": "ipa-dict en_US",
            "url": "https://github.com/open-dict-data/ipa-dict",
            "commit": "44accfb5b0c4c7c146e666c9c7161a5b66e61720",
            "file": "ipa_en_US.txt",
            "sha256": sha256(SOURCES / "ipa_en_US.txt"),
            "license": "MIT",
        },
        {
            "name": "English Wiktionary via Kaikki (UK IPA)",
            "url": "https://kaikki.org/dictionary/English/",
            "file": kaikki.name if kaikki.exists() else "not used",
            "license": "CC BY-SA 4.0 and GFDL",
            "note": "Streamed and filtered to bundled words; the full dump is not redistributed.",
        },
    ]
    (DATA / "provenance.json").write_text(
        json.dumps(
            {
                "generated": date.today().isoformat(),
                "dataLicense": "CC BY-SA 4.0",
                "codeLicense": "MIT",
                "sources": sources,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    print("\nCoverage")
    for name in ("core_3k", "spoken", "academic", "common_10k"):
        row = report["lists"][name]
        print(f"  {name:14} {row['words']:5} words  US {row['usPct']:5.1f}%  UK {row['ukPct']:5.1f}%")
    authored_rows = [report["lists"][k] for k in authored]
    us_total = sum(r["us"] for r in authored_rows)
    uk_total = sum(r["uk"] for r in authored_rows)
    words_total = sum(r["words"] for r in authored_rows)
    print(
        f"  authored       {words_total:5} words  "
        f"US {100 * us_total / words_total:5.1f}%  UK {100 * uk_total / words_total:5.1f}%"
    )
    print(f"  unique words   {len(wanted):5}  US {len(us):5}  UK {len(uk):5}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
