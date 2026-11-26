#!/usr/bin/env python3
"""Download the open data sources used by the build.

The generated data is committed; this script exists so the pipeline can be
reproduced from scratch. Kaikki is optional because the English extract is
large (about 500 MB compressed).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "data" / "sources"

FILES = [
    (
        "ngsl_1.2_stats.csv",
        "https://www.newgeneralservicelist.com/s/NGSL_12_stats.csv",
        None,
    ),
    (
        "nawl_1.2_stats.csv",
        "https://www.newgeneralservicelist.com/s/NAWL_12_stats.csv",
        None,
    ),
    (
        "ngsl_s_1.2_stats.csv",
        "https://www.newgeneralservicelist.com/s/NGSL-Spoken_12_stats.csv",
        None,
    ),
    (
        "ipa_en_US.txt",
        "https://raw.githubusercontent.com/open-dict-data/ipa-dict/"
        "44accfb5b0c4c7c146e666c9c7161a5b66e61720/data/en_US.txt",
        None,
    ),
    (
        "frequency_en_50k.txt",
        "https://raw.githubusercontent.com/hermitdave/FrequencyWords/"
        "072bbed282316a23651aa7068c7173aa7898cf80/content/2018/en/en_50k.txt",
        None,
    ),
]

KAIKKI = (
    "kaikki_en.jsonl.gz",
    "https://kaikki.org/dictionary/English/kaikki.org-dictionary-English.jsonl.gz",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(name: str, url: str, force: bool) -> dict:
    SOURCES.mkdir(parents=True, exist_ok=True)
    target = SOURCES / name
    if target.exists() and not force:
        print(f"  keep {name} ({target.stat().st_size:,} bytes)")
    else:
        print(f"  fetch {name}")
        subprocess.run(
            ["curl", "-L", "--fail", "--retry", "3", "--progress-bar", "-o", str(target), url],
            check=True,
        )
    return {
        "file": name,
        "url": url,
        "bytes": target.stat().st_size,
        "sha256": sha256(target),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--kaikki", action="store_true", help="also fetch the ~500 MB Kaikki dump")
    args = parser.parse_args()

    print("Fetching open data sources")
    entries = [download(name, url, args.force) for name, url, _ in FILES]
    if args.kaikki:
        entries.append(download(KAIKKI[0], KAIKKI[1], args.force))

    manifest = {"fetched": date.today().isoformat(), "files": entries}
    path = SOURCES / "manifest.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"  wrote {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
