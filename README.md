# Word & Sound (macOS)

A native macOS pronunciation trainer built from the MIT App Inventor project
`WordAndSound.aia`. The app keeps the original's five ways of working on a
sound — starting sounds, starting blends, ending sounds, ending blends and
vowels — and replaces the restricted vocabulary with openly licensed data.

![Word & Sound screenshot](docs/screenshot.png)

## What it does

- **134 sound tiles** across starting sounds, starting blends, ending sounds,
  ending blends and vowels.
- **Curated / Built switch.** *Curated* is the author's original 60 lists.
  *Built* selects words from open IPA data by onset, coda or vowel pattern,
  ranked by frequency, up to 120 words per sound.
- **US and UK IPA**, displayed together when available.
- **Autoplay** with repeat count, delay, four accents (US, UK, Australian,
  Indian), rate and pitch.
- **Four mixed lists**: Core English 3k, Everyday Spoken, Academic English and
  Common English 10k.
- **Import** your own `.txt` or `.csv` word list. Imported lists stay on the
  Mac.
- Keyboard: Space play/pause, ⌘R replay, ⌘←/⌘→ previous/next word.

## Build and run

Requirements: macOS 14 or later, Xcode command-line tools, Python 3.

```bash
make check          # unit tests + headless self-test
make app            # build/WordAndSound.app (release, ad-hoc signed)
make run            # build and open the app
```

The app is not notarized. On first launch from a downloaded copy, right-click
the app and choose **Open**.

## Data pipeline

The generated JSON is committed under `data/`. To rebuild it:

```bash
python3 tools/fetch_corpus.py --kaikki   # downloads sources to data/sources/
make data                                # extract, merge, build pattern lists
make check
```

`make data` expects the original project at `~/Downloads/WordAndSound.aia` and
the Kaikki dump at `/tmp/kaikki_en.jsonl.gz` by default. Override the dump with
`make data KAIAKI=/path/to/kaikki_en.jsonl.gz`.

Pipeline:

1. `tools/extract_aia.py` reads the `.aia`, extracts the 60 authored lists and
   tile metadata, and discards the bundled IPA tables.
2. `tools/build_corpus.py` adds the NGSL/NAWL/NGSL-S/FrequencyWords lists and
   builds US/UK IPA dictionaries from ipa-dict and Kaikki.
3. `tools/build_pattern_lists.py` generates onset, coda, blend and vowel lists.

## Numbers

| Item | Count |
|---|---|
| Sound tiles | 134 |
| Starting sounds | 58 (23 single + 35 blends) |
| Ending sounds | 53 (20 single + 33 blends) |
| Vowels | 23 |
| Authored words | 15,326 |
| Pattern-built words | 11,768 |
| Mixed-list words | 14,484 |
| US IPA entries | 39,886 |
| UK IPA entries | 22,072 |
| Tile-list IPA coverage | 96.8% US, 89.3% UK |

## Project layout

```
Sources/WordAndSoundCore/     models, data loader, sequencer, parser, self-test
Sources/WordAndSound/         SwiftUI app, speech engine, views
Resources/                    generated JSON, provenance, icon
tools/                        extraction and corpus builders
scripts/make_app.sh           release bundle + ad-hoc signing
Tests/                        XCTest coverage of core logic
data/                         generated data and provenance
licenses/                     third-party notices and license texts
```

## Licenses

Code is MIT. Bundled data is CC BY-SA 4.0. See `LICENSES.md` and
`licenses/DATA-NOTICES.md`. Imported lists are the user's responsibility.

The project is not affiliated with Oxford University Press, ETS, EF, or the
publishers of the original vocabulary lists. Those lists are not shipped.

## Known issues

- UK IPA is intentionally conservative: words with several competing British
  forms are left to the US fallback. About 14% of the authored lists fall back.
- Pattern-built lists are frequency-ranked and can include inflected forms and
  proper names; they are drills, not a dictionary.
- Rare clusters have short lists: `ʒ` onset has 3 words, `ŋθ` and `ʒd` have 3
  each, `mf` has 4. Rhotic coda clusters (`rd`, `rk`, `rt`, …) are omitted
  because the tile inventory is non-rhotic RP; US rhotic vowels are still shown
  in the IPA line.
- The app is unsigned/not notarized and is not distributed through the App
  Store (the CC BY-SA data must remain extractable).
- Voice quality depends on the macOS voices installed. Missing voices are
  reported in the player bar.
