# Contributing

Thanks for helping improve Word & Sound. The project is a native macOS app
with a deliberately narrow data policy.

## Before opening a pull request

```bash
make check      # XCTest + headless self-test
make app        # release bundle, ad-hoc signed
```

Include the macOS version, the affected sound tile, and whether the issue is
in the UI, speech, or data.

## Code changes

- Keep the app offline at runtime. Do not add analytics, telemetry, remote
  fonts, or network calls.
- Keep `AppModel` as the single owner of selection and playback state.
- Keep the pure sequencer and parser in `WordAndSoundCore` so they stay
  testable without a window.
- Add or update a test when changing the sequencer, parser, or data loader.
- Follow the existing SwiftUI style; no third-party dependencies.

## Data changes

- Do not add Oxford 5000, GRE, EF, TOEFL, SVL, or other restricted/branded
  lists. They are intentionally excluded.
- Do not add `ipa-dict en_UK` (GPL-3.0-derived) or `wordfreq` extracted data.
- Keep the code MIT and the bundled data CC BY-SA 4.0.
- Rebuilding data requires the original `.aia` and the Kaikki dump:

```bash
python3 tools/fetch_corpus.py --kaikki
make data
```

Commit the regenerated `data/*.json`, the matching
`Sources/WordAndSoundCore/Resources/*.json`, `provenance.json`, and the
screenshot. Do not commit `data/sources/` or the Kaikki dump.

## Licensing of contributions

Code contributions are accepted under the MIT license. Data contributions are
accepted under CC BY-SA 4.0. By opening a pull request you confirm you have the
right to submit the material under those terms.
