# Release checklist

## 1. Verify

```bash
make check
swift run WordAndSound --selftest
```

Expect `PASS` and 134 tiles / 134 pattern lists.

## 2. Bump the version

Edit `scripts/make_app.sh`:

- `CFBundleShortVersionString` — user-facing version, for example `1.1.0`
- `CFBundleVersion` — monotonically increasing build number

Update `CHANGELOG.md`.

## 3. Build

```bash
make app
open build/WordAndSound.app
```

Check the Starting, Vowel, Ending and Mixed tabs, the Curated/Built switch,
autoplay, minimal-pair quiz, review queue, microphone prompt, and one imported
list.

## 4. Package

```bash
ditto -c -k --keepParent build/WordAndSound.app build/WordAndSound.app.zip
shasum -a 256 build/WordAndSound.app.zip
```

The app is ad-hoc signed, not notarized. On another Mac, the first launch
requires right-click → Open. Do not describe it as notarized.

## 5. Publish

```bash
gh release create v1.0.0 build/WordAndSound.app.zip \
  --title "Word & Sound 1.0.0" \
  --notes-file CHANGELOG.md
```

Attach the zip, keep the source archive GitHub generates, and link the release
from the README if it becomes the primary download.

## 6. Data obligations

The bundled data is CC BY-SA 4.0. Keep `LICENSES.md`,
`licenses/DATA-NOTICES.md`, the provenance JSON, and the in-app Credits screen
in every distributed build. The data must remain extractable from the app; do
not add DRM around it.
