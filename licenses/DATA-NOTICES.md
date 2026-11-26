# Third-party data notices

The bundled word data is licensed under Creative Commons
Attribution-ShareAlike 4.0 International (CC BY-SA 4.0). The full legal code is
in `CC-BY-SA-4.0.txt`.

## New General Service List 1.2

- Source: https://www.newgeneralservicelist.org/
- Authors: Charles Browne, Brent Culligan and Joseph Phillips
- License: CC BY-SA 4.0
- Changes: filtered to single-word lemmas, case-folded where appropriate,
  deduplicated.

## New General Service List – Spoken 1.2

- Source: https://www.newgeneralservicelist.org/
- Authors: Charles Browne and Brent Culligan
- License: CC BY-SA 4.0
- Changes: filtered to single-word lemmas, deduplicated.

## New Academic Word List 1.2

- Source: https://www.newgeneralservicelist.org/
- Authors: Charles Browne and Brent Culligan
- License: CC BY-SA 4.0
- Changes: filtered to single-word lemmas, deduplicated.

## FrequencyWords (OpenSubtitles 2018)

- Source: https://github.com/hermitdave/FrequencyWords
- Author: Hermit Dave and contributors
- Corpus: OpenSubtitles 2018 via OPUS
- License: MIT for the generator, CC BY-SA 4.0 for the content
- Changes: top 50,000 words for candidate ranking; top 10,000 for the
  Common English list; profanity and URL tokens removed.

## ipa-dict en_US

- Source: https://github.com/open-dict-data/ipa-dict
- License: MIT
- Derived from cmudict-ipa (MIT), which is derived from the CMU Pronouncing
  Dictionary (BSD-2-Clause; see `CMUDICT.txt`).
- Changes: subset to bundled vocabulary, case-folded keys.

## English Wiktionary via Kaikki (UK IPA)

- Source: https://kaikki.org/dictionary/English/
- License: CC BY-SA 4.0 and GFDL
- Attribution: Wiktionary contributors; Tatu Ylonen, *Wiktextract:
  Wiktionary as Machine-Readable Structured Data*, LREC 2022.
- Changes: streamed and filtered to bundled words; conservative selection of
  one British pronunciation per word; tie bars and combining diacritics
  normalised.

## Authored sound lists

- Source: supplied by the app author.
- License: CC BY-SA 4.0.
- Changes: unescaped, cleaned, homograph suffixes removed, deduplicated.

## Pattern-built lists

- Source: generated from the data above.
- License: CC BY-SA 4.0.
- Changes: selected by onset, coda and vowel patterns; ranked by frequency;
  capped at 120 words per list.

## Minimal pairs

- Source: curated for this app.
- License: CC BY-SA 4.0.
- Purpose: ESL contrast practice; review history and recordings are local.
