# Licenses

**Code:** MIT (root `LICENSE`; copy in `licenses/MIT.txt`).

**Bundled data:** CC BY-SA 4.0 (`licenses/CC-BY-SA-4.0.txt`), with the
attributions and change notices in `licenses/DATA-NOTICES.md`.

The app is a collective work: the Swift code is MIT, while the data files are
CC BY-SA 4.0. The data remains extractable from the application bundle.

## Data sources

| Data | Source | License |
|---|---|---|
| 60 sound lists | Supplied by the app author | CC BY-SA 4.0 |
| Pattern-built lists | Generated from the sources below | CC BY-SA 4.0 |
| Core English 3k | NGSL 1.2, Browne, Culligan & Phillips | CC BY-SA 4.0 |
| Everyday Spoken | NGSL-S 1.2, Browne & Culligan | CC BY-SA 4.0 |
| Academic English | NAWL 1.2, Browne & Culligan | CC BY-SA 4.0 |
| Common English 10k | FrequencyWords / OpenSubtitles 2018 | CC BY-SA 4.0 |
| US IPA | ipa-dict en_US (derived from CMUdict) | MIT; CMUdict BSD-2 |
| UK IPA | English Wiktionary via Kaikki | CC BY-SA 4.0 and GFDL |

## Changes

Word lists were cleaned, unescaped, deduplicated, filtered to single words,
and stripped of homograph suffixes. IPA data was subset to the bundled
vocabulary, case-folded for lookup, normalised (tie bars and combining
diacritics removed), and reduced to one conservative British pronunciation per
word. The full Kaikki dump is not redistributed.

## Imported content

Word lists imported by the user are stored locally and are not covered by the
app's data license. The user is responsible for their content.
