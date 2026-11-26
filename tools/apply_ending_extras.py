#!/usr/bin/env python3
"""Merge curated ending-blend words into data/pattern_lists.json.

Only words with an existing US or UK IPA transcription that ends in the tile
target are accepted. Re-running is safe (duplicates are skipped).
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"


def normalise(value: str) -> str:
    return (
        value.strip("/")
        .replace("ˈ", "")
        .replace("ˌ", "")
        .replace("ɫ", "l")
        .replace("ɹ", "r")
        .replace("ɡ", "g")
        .replace("ɝ", "ɜ")
        .replace("ɚ", "ə")
    )


def main() -> int:
    library = json.loads((DATA / "library.json").read_text(encoding="utf-8"))
    payload = json.loads((DATA / "pattern_lists.json").read_text(encoding="utf-8"))
    report = json.loads((DATA / "pattern_report.json").read_text(encoding="utf-8"))
    us = json.loads((DATA / "phonetics_us.json").read_text(encoding="utf-8"))
    uk = json.loads((DATA / "phonetics_uk.json").read_text(encoding="utf-8"))
    extras = json.loads((DATA / "ending_extras.json").read_text(encoding="utf-8"))["lists"]
    tiles = {
        tile["id"]: tile
        for category in library["categories"]
        for tile in category["tiles"]
    }

    added = 0
    skipped: list[str] = []
    for tile_id, words in extras.items():
        tile = tiles.get(tile_id)
        if not tile or tile_id not in payload["lists"]:
            skipped.append(f"{tile_id}: unknown tile")
            continue
        target = normalise(tile["label"])
        existing = {word.lower() for word in payload["lists"][tile_id]}
        for word in words:
            key = word.lower()
            if key in existing:
                continue
            transcriptions = [us.get(key), uk.get(key)]
            if not any(ipa and normalise(ipa).endswith(target) for ipa in transcriptions):
                skipped.append(f"{tile_id}: {word} has no matching IPA")
                continue
            payload["lists"][tile_id].append(word)
            existing.add(key)
            added += 1
        if tile_id in report:
            report[tile_id]["count"] = len(payload["lists"][tile_id])

    (DATA / "pattern_lists.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (DATA / "pattern_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Added {added} curated ending words")
    for tile_id in extras:
        if tile_id in payload["lists"]:
            print(f"  {tile_id:16} {len(payload['lists'][tile_id]):3}")
    for message in skipped:
        print(f"  skipped {message}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
