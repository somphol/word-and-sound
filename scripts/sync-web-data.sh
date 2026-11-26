#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$ROOT/web/public/data"
mkdir -p "$DATA" "$ROOT/web/public/icons"
cp "$ROOT/data/library.json" "$DATA/library.json"
cp "$ROOT/data/phonetics_us.json" "$DATA/phonetics_us.json"
cp "$ROOT/data/phonetics_uk.json" "$DATA/phonetics_uk.json"
cp "$ROOT/data/pattern_lists.json" "$DATA/pattern_lists.json"
cp "$ROOT/data/minimal_pairs.json" "$DATA/minimal_pairs.json"
cp "$ROOT/data/provenance.json" "$DATA/provenance.json"
cp "$ROOT/data/articulation.json" "$DATA/articulation.json"
cp "$ROOT/data/AppIcon.png" "$ROOT/web/public/icons/icon-512.png"
if command -v sips >/dev/null 2>&1; then
  sips -z 192 192 "$ROOT/data/AppIcon.png" --out "$ROOT/web/public/icons/icon-192.png" >/dev/null
else
  echo "sips not found; keeping the committed 192 px icon"
fi
echo "Synced web data"
