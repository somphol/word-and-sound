# Changelog

## 1.5.0 — 2026-11-26

- Rebuild the web layout around a single practice card with a phone bottom
  navigation, full-screen Sounds/Words, and an iPad card + word list in
  landscape.
- Add Auto/Light/Dark themes and blue, teal, violet and amber accents, plus
  adjustable UI text and hero-word sizes.
- Add a prominent autoplay toggle, a Practice-screen Review shortcut, a
  legibility/touch-target pass, modal focus handling and touch-only hint rules.
- Add Open Graph/Twitter metadata and a 1200×630 share card.

## 1.4.2 — 2026-11-25

- Add a full-parity React + TypeScript PWA in `web/`, deployed to GitHub
  Pages. It shares `data/*.json`, adds SVG coach diagrams, search, minimal
  pairs, review, import, recording and offline caching.
- Replace the web layout with a focus-first practice card; sounds, lists and
  the word index open in sheets, and the bottom player bar is gone.
- Add adjustable UI text size (90–130%) and hero word size (100–160%), both
  persisted locally and applied before first paint.
- Add Open Graph/Twitter metadata and a 1200×630 share card for social feeds.
- Replace unicode glyphs with an inline SVG icon set; align spacing, type and
  controls across desktop and mobile.
- Add a phone bottom navigation with full-screen Sounds and Words, a Review
  jump, 48 px rows, 44 px touch targets, safe-area insets and larger form
  controls that avoid mobile zoom-on-focus.
- Add a dismissible hint when an Android browser is using Desktop site mode,
  and move the desktop breakpoint to ≥1100 px so tablet widths stay readable.
- Add Auto/Light/Dark themes and blue, teal, violet and amber accent palettes;
  apply them before first paint and keep the articulation diagrams theme-aware.
- Raise readable text to a 12 px floor, improve faint-text contrast, grow touch
  targets to 44 px and stop iOS zoom with 16 px inputs on phones and tablets.
- Keep the bottom navigation on landscape phones with a two-column card, give
  the iPad a two-pane card + word list in landscape only (portrait keeps the
  single card), and surface Review from Practice.
- Move phone playback options into Settings so the default card fits without
  scrolling; add modal focus trapping, inert backgrounds and live toast
  announcements.
- Hide the keyboard shortcut hint on touch-only devices (iPad, Android); the
  shortcuts still work with a physical keyboard.
- Export the 48 articulation guides to `data/articulation.json` so the web
  client reads the same coach content as the Mac app.
- Show the bundle version in the header, window title, Settings and Credits.
- Read version/build from `Info.plist`; `swift run` shows “dev build”.

## 1.4.1 — 2026-11-25

- Replace the single front-lip drawing with a clear spread / neutral /
  rounded comparison and a highlighted target.
- Label the tongue tip, tongue body, alveolar ridge, lips and vocal folds.
- Add a dashed rest tongue and a movement arrow to the side view.
- Clarify the legend: solid tongue = target, dashed = rest.

## 1.4.0 — 2026-11-25

- Add a vowel space chart with target and contrast vowels.
- Add a spread / neutral / rounded lip comparison with the target highlighted.
- Add labelled tongue tip/body, ridge, lips and vocal folds; dashed rest
  tongue and movement arrow.
- Add anchor words, contrast playback and a short/long/glide meter.
- Add whole-blend sequences with component diagrams and blend-specific errors.
- Add sample words from the current tile to every coach.
- Add a default common-error line for every guide.

## 1.3.0 — 2026-11-25

- Add an animated articulation coach with 47 phoneme guides.
- Add side-view tongue, lip, contact, airflow and voicing diagrams.
- Add detailed /r/ and /s/ guidance, common-error fixes and physical anchors.
- Show blends as their component sounds with selectable diagrams.
- Add “How to make this sound” from the tile card and player.

## 1.2.0 — 2026-11-25

- Add ⌘K global search across tiles, lists, words and IPA.
- Add search filters for favorites, trouble words and due review items.
- Resume the last word per sound/list across launches.
- Add a search snapshot command and documentation.

## 1.1.0 — 2026-11-25

- Highlight the target IPA segment and add articulatory tips.
- Add 37 minimal pairs with listen and quiz modes.
- Add favorites, trouble words, per-list progress and a local 1/3/7/14/30-day
  review queue.
- Add record-and-compare with microphone permission; recordings stay local.
- Add Irish English voice and a slow replay button.
- Add Practice and review UI, plus snapshot commands for QA.

## 1.0.0 — 2026-11-25

- Native SwiftUI macOS app derived from the MIT App Inventor project.
- 134 sound tiles: 58 starting (23 single, 35 blends), 53 ending (20 single,
  33 blends), and 23 vowels.
- US and UK IPA, four TTS accents, autoplay with repeat and delay, rate and
  pitch controls.
- Curated author lists plus pattern-built lists selected from open IPA data.
- Four mixed vocabulary lists and local word-list import.
- MIT code, CC BY-SA 4.0 data, provenance manifest and in-app credits.
- Headless self-test, XCTest coverage, snapshot rendering and CI workflow.
