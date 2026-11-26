# AGENTS.md

## What it is

Word & Sound is a SwiftUI macOS pronunciation trainer plus a React PWA in
`web/`, both derived from the MIT App Inventor project `WordAndSound.aia`.
They drill English sounds through 134 phoneme tiles grouped into starting
sounds, starting blends, ending sounds, ending blends and vowels, with US/UK
IPA, TTS, autoplay, mixed vocabulary lists and user-imported lists. The two
clients share `data/*.json` but have independent UI code and local storage.
It is not a dictionary, an LMS, or a mobile port.

## Commands

```bash
make check                         # swift test + --selftest
make app                           # build/WordAndSound.app, ad-hoc signed
make run                           # build and open
swift run wordandsound-selftest    # headless data + sequencer + parser checks
make web-data                      # copy data/*.json + icons into web/public/
make web                           # web: npm ci, Vitest, production build
make web-dev                       # web: Vite dev server on 127.0.0.1:5173
cd web && npm run og               # regenerate public/og.png (Chrome; sips on macOS)
swift run WordAndSound --snapshot-practice /tmp/practice.png
swift run WordAndSound --snapshot-record /tmp/record.png
swift run WordAndSound --snapshot-search /tmp/search.png --query "θ"
swift run WordAndSound --snapshot-coach /tmp/coach.png --tile startingR
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
- `web/` is a Vite + React + TypeScript PWA. `web/src/App.tsx` owns selection,
  playback, autoplay, review, search, sheets and modal state;
  `web/src/components/FocusCard.tsx` is the practice surface (hero word, IPA,
  transport, autoplay and the word-size stepper); `SoundPanel`/`MixedPanel`/
  `WordPanel` render inside library and word sheets, and as full-screen phone
  screens. `BottomNav.tsx` owns the phone tabs (Practice/Sounds/Words),
  `CategoryTabs.tsx` is shared by the header and the Sounds screen, and
  `Icon.tsx` is the only icon set. `web/src/lib/` holds data loading, IPA highlighting, search, review
  scheduling, Web Speech and MediaRecorder.
  `web/public/data/` is a generated copy of `data/*.json`; never edit it by
  hand, run `./scripts/sync-web-data.sh`.
- `web/public/og.png` is the 1200×630 share card, rendered from
  `web/tools/og.html` by `web/tools/render-og.mjs`; `web/index.html` carries the
  absolute Open Graph/Twitter URLs. Keep the meta dimensions in step with the
  image.
- `data/articulation.json` is exported from `Articulation.swift` by
  `tools/export_articulation.swift`; both clients read the same guides.
- `Sources/WordAndSoundCore/Articulation.swift` holds the 48 authored
  phoneme guides (steps, errors, anchors, mouth shape, glide, anchor word,
  contrast list and length label).
- `Sources/WordAndSound/Views/MouthDiagramView.swift` renders the labelled 2D
  sagittal diagram with a dashed rest tongue, movement arrow, contact zone,
  airflow and voicing; `VowelChartView` renders the vowel space and the
  spread/neutral/rounded lip comparison; `ArticulationCoachView` is the sheet
  for a tile.
- `Sources/WordAndSound` owns `AppModel`, `SpeechEngine` (AVSpeechSynthesizer),
  `Snapshot`, commands and the SwiftUI views. `AppModel` is the single owner of
  list selection, playback state, imported lists, favorites, trouble marks,
  review scheduling and local progress.
- `Sources/WordAndSoundCore/ReviewScheduler.swift` holds the pure 1/3/7/14/30
  day schedule; it is covered by XCTest.
- `PracticeView` drives the minimal-pair listen/quiz sheet. `RecordController`
  owns AVAudioRecorder/AVAudioPlayer; `RecordView` presents it. Both are
  local-only.
- `Search.swift` + `GlobalSearchView` provide ⌘K search over tiles, lists and
  words. `AppModel.ensureWordIndex()` builds a lazy 40k-word index and
  invalidates it when the list source or imported lists change.
- `lastPositions` in UserDefaults maps tile/mixed-list id to the last word; it
  is restored by `applyTile`/`applyMixed` and saved on every utterance.
- `scripts/make_app.sh` builds the SwiftPM binary, copies the generated
  `WordAndSound_WordAndSoundCore.bundle` into `Contents/Resources`, builds the
  icon, writes `Info.plist`, copies licenses, and ad-hoc signs.

## Decisions and constraints

- **The web app is a static PWA, not a second backend.** Speech is the browser
  Web Speech API; recordings use MediaRecorder and stay in memory; progress,
  settings and imported lists live in `localStorage`. Do not add accounts,
  cloud TTS, uploads or analytics.
- **Web data is copied, not bundled through imports.** The JSON is fetched
  from `web/public/data/` at runtime so the macOS resources stay the single
  source. `scripts/sync-web-data.sh` is the only supported way to refresh it.
- **Pages deploy path is a subdirectory.** Vite `base: './'` and relative
  service-worker/manifest paths are deliberate; do not switch to absolute
  `/assets/...` paths or the project Pages URL breaks.
- **Both clients stay feature-consistent.** A new tile, list, pair or
  articulation guide must appear in the Swift and web clients; the web tests
  cover the parser, IPA matching, review schedule and search.
- **The web layout is focus-first.** One practice card is the screen; sounds,
  lists and the word index open as sheets on tablet/desktop and as full screens
  under the bottom navigation on phones. Do not reintroduce a permanent left
  rail or bottom player without a deliberate design decision.
- **Breakpoints are phone ≤700, tablet 701–1099, desktop ≥1100.** Short
  landscape (`max-height: 500px` up to 1000px wide) also uses the phone tier.
  The phone tier hides header tabs and shows `BottomNav`; 780–1099 px puts the
  practice card beside a persistent `WordPanel`; desktop keeps the single card.
  Keep the tiers in this order when adding layout rules, and put phone overrides
  after the base rules.
- **Phone playback controls live in Settings.** The accent/repeat/delay/IPA
  strip is hidden ≤700 px so the card fits without scrolling; the card links to
  Settings, which owns Repeat, Delay and IPA alongside Reading and Appearance.
  Do not re-add a dense select row to the phone card.
- **Desktop-site detection is advisory.** Android Chrome in Desktop site mode
  reports ~980 px and ignores the viewport meta; `App` shows a dismissible hint
  when `screen.width <= 600` but `innerWidth > 700`. A page cannot turn the
  browser setting off, so do not promise a scripted fix.
- **Web type is scalable by settings.** Base sizes are `rem`, `settings.textScale`
  drives the root font size (0.9–1.3), and `settings.wordScale` multiplies the
  hero via `--word-scale` (1–1.6). Keep new type in `rem` so the control keeps
  working; no fixed-px font sizes.
- **Themes are token-driven.** `settings.theme` (system/light/dark) sets
  `data-theme` and `settings.palette` sets `data-palette` on `<html>`; both are
  applied by an inline script in `index.html` before React so there is no flash.
  Use the semantic tokens (`--surface`, `--line`, `--soft`, `--track`,
  `--accent*`, `--tile-*`, `--diagram-*`) instead of hardcoded colours. Keep
  `theme-color` in step with the resolved theme.
- **Share metadata is static and absolute.** `og:image` and `og:url` must stay
  absolute under `https://somphol.github.io/word-and-sound/`; the crawler does
  not run the app. Regenerate `og.png` after branding or layout changes.

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
- **Progress and recordings are local.** `progress.json` and `recordings/`
  live in `~/Library/Application Support/WordAndSound/`. Never add cloud sync
  or upload without explicit consent.
- **No pronunciation scoring.** Record-and-compare is deliberately unscored;
  the quiz is the only objective feedback.
- **Articulation diagrams are 2D and stylised.** Do not replace them with an
  unvalidated 3D mouth or camera tongue tracking. Keep the text steps and
  physical checkpoints alongside the drawing; accuracy beats novelty.
- **Side-view labels are part of the contract.** Tongue tip, tongue body,
  ridge, lips and vocal folds are labelled; the dashed tongue is the rest
  position and the arrow points to the target. Do not remove the labels or the
  rest ghost to make the drawing look prettier.
- **Blends are component-based.** A cluster such as /str/ shows /s/, /t/, /r/
  in sequence; do not draw a fake single "cluster tongue" position.
- **Vowels are space + lips + length.** The vowel chart (`height` × `back`),
  spread/neutral/rounded lip comparison (`lipRound`), anchor word, contrast
  list and short/long/glide label are deliberate cues. Do not replace them with a
  single abstract diagram.
- **No automatic vowel scoring.** Formant analysis and pitch scoring are not
  shipped; the chart is a teaching map, not a measurement of the learner.
- **Microphone usage description** is in `scripts/make_app.sh`; recording
  refuses to start under `swift run` without the bundle key.

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
- Articulation guides cover 48 core phonemes (47 used by tiles); every tile resolves to one or
  more components. The diagrams are teaching aids, not medical anatomy.
- Vowel length is a cue, not a measured duration; formant analysis is not
  implemented.
- Minimal pairs are a curated set of 37, not generated from the IPA inventory.
- Global search indexes the first occurrence of a word; duplicate words jump to
  the first containing list. The index is lazy and rebuilt when the list
  source or imported lists change.
- Last positions live in UserDefaults (`lastPositions`) and are separate from
  practice progress reset.
- Recording is unscored and requires microphone permission; no audio leaves
  the Mac.
- Web speech depends on installed browser voices; headless Chrome exposes no
  English voice, and Safari/iOS voice lists differ.
- Web recordings are ephemeral and Safari MediaRecorder behaviour varies.
- The service worker serves cached assets first; a stale shell can survive a
  deployment until a hard reload.
- Social networks cache Open Graph data; refresh with Facebook's Sharing
  Debugger (or the equivalent) after deploying, or an old preview is shown.
- The iPad two-pane view is tuned at 810/1080; Sounds, Practice pairs and Coach
  still open as sheets rather than using a third pane.
- Phone landscape hides the context row and stacks the card into two columns;
  the playback strip is unavailable there until the Settings sheet is opened.
- Phone section history uses `pushState`; Android Back walks Practice → Sounds
  → Words rather than always returning to Practice.
- Desktop-site mode cannot be overridden from the page; the in-app hint is the
  only mitigation.
- Web import accepts the same `.txt`/`.csv` shapes as the Mac parser but is
  capped at 50,000 words per file.

## Continuity

Local project: `~/Projects/word-and-sound-mac` (the folder keeps the old
name; the repository is now `word-and-sound`).
GitHub: https://github.com/somphol/word-and-sound (public). The old
`word-and-sound-mac` repository URL redirects here.
Built app: `build/WordAndSound.app` (not committed).
Web app: https://somphol.github.io/word-and-sound/ (GitHub Pages, built
from `web/` by `.github/workflows/pages.yml`). Pages is enabled with
`build_type: workflow`; there is no `gh-pages` branch. The macOS app has no
hosted deployment; distribution is the GitHub source and release artifact.
The original `.aia` remains at `~/Downloads/WordAndSound.aia` and is not
committed.
