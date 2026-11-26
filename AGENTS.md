# AGENTS.md

## What it is

Word & Sound is a native SwiftUI macOS pronunciation trainer derived from the
MIT App Inventor project `WordAndSound.aia`. It drills English sounds through
134 phoneme tiles grouped into starting sounds, starting blends, ending sounds,
ending blends and vowels, with US/UK IPA, TTS, autoplay, mixed vocabulary lists
and user-imported lists. It is not a dictionary, an LMS, or a mobile port.

## Commands

```bash
make check                         # swift test + --selftest
make app                           # build/WordAndSound.app, ad-hoc signed
make run                           # build and open
swift run wordandsound-selftest    # headless data + sequencer + parser checks
swift run WordAndSound --snapshot docs/screenshot.png --category vowel --tile vowelMar
```

Rebuilding data:

```bash
python3 tools/fetch_corpus.py --kaikki
make data                          # needs ~/Downloads/WordAndSound.aia and /tmp/kaikki_en.jsonl.gz
```

`make data` order matters: `extract_aia.py`, then `build_corpus.py`, then
`build_pattern_lists.py`, then copy the JSON into
`Sources/WordAndSoundCore/Resources/`.

## Architecture

- `tools/extract_aia.py` reads the `.aia`, extracts the authored lists and tile
  metadata, and deliberately ignores the bundled IPA tables.
- `tools/build_corpus.py` writes `library.json`, `phonetics_us.json`,
  `phonetics_uk.json`, `provenance.json` and `coverage.json`.
- `tools/build_pattern_lists.py` writes `pattern_lists.json` and
  `pattern_report.json`, keyed by tile id.
- `Sources/WordAndSoundCore` owns the Codable models, `LibraryStore` (resource
  loading), the pure `PlaybackSequencer`, `WordListParser`, and `SelfTest`.
- `Sources/WordAndSound` owns `AppModel`, `SpeechEngine` (AVSpeechSynthesizer),
  `Snapshot`, commands and the SwiftUI views. `AppModel` is the single owner of
  list selection, playback state and imported lists.
- `scripts/make_app.sh` builds the SwiftPM binary, copies the generated
  `WordAndSound_WordAndSoundCore.bundle` into `Contents/Resources`, builds the
  icon, writes `Info.plist`, copies licenses, and ad-hoc signs.

## Decisions and constraints

- **Do not ship the original mixed lists.** Oxford 5000, GRE, EF, TOEFL and SVL
  are replaced by NGSL/NAWL/NGSL-S/FrequencyWords. Brand strings are checked by
  `SelfTest`.
- **Do not ship the original IPA tables.** US IPA is ipa-dict en_US (MIT,
  CMUdict-derived); UK IPA is conservative Wiktionary/Kaikki selection
  (CC BY-SA). `ipa-dict en_UK` is GPL-3.0-derived and must not be added.
- **Code MIT, data CC BY-SA 4.0.** Data must stay extractable and reusable; no
  DRM. This is why the app is not an App Store build.
- **Tile inventory is data-driven.** The original 60 tiles are extended to 134
  by `EXTRA_TILES` in `build_pattern_lists.py`; every tile has a `group`
  (`single`, `blend`, `vowel`) and a pattern list keyed by tile id. The UI
  splits groups using that field, not a hardcoded ID list.
- **UK IPA is conservative.** The extractor takes the first entry with sounds,
  prefers RP, then a single UK form, then a single untagged form. If several
  forms compete, it leaves the word without UK IPA; do not "fix" this by taking
  an arbitrary variant.
- **Resources are copied, not flattened.** `Bundle.module` expects the
  `WordAndSound_WordAndSoundCore.bundle` directory in the app's Resources.
- **Offline at runtime.** No analytics, no network calls, no remote fonts.

## Known issues

- About 14% of authored-list words have no UK IPA and fall back to US.
- Kaikki contains noisy regional variants; the conservative filter drops some
  valid pronunciations (for example `film` has no UK entry).
- Rare clusters have short lists: `ʒ` onset 3 words, `ŋθ` 3, `ʒd` 3, `mf` 4.
- Rhotic coda clusters (`rd`, `rk`, `rt`, …) are not tiles; the inventory is
  non-rhotic RP, with US IPA shown only as reference.
- Pattern lists are frequency-ranked and include inflections/names.
- The app is unsigned and not notarized.
- `--snapshot` renders through `NSHostingView`; it is for visual checks, not a
  pixel-perfect screenshot of a live window.
- The mixed lists contain 4 lists, not the original 13; subject lists were not
  regenerated.

## Continuity

Local project: `~/Projects/word-and-sound-mac`.
GitHub: https://github.com/somphol/word-and-sound-mac (public).
Built app: `build/WordAndSound.app` (not committed).
No hosted deployment; distribution is the GitHub source and release artifact.
The original `.aia` remains at `~/Downloads/WordAndSound.aia` and is not
committed.
