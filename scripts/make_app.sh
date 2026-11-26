#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP="$ROOT/build/WordAndSound.app"
ICONSET="$ROOT/build/AppIcon.iconset"
ICON_SRC="$ROOT/data/AppIcon.png"

echo "Building release binary"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
BIN="$BIN_DIR/WordAndSound"
RES_BUNDLE="$BIN_DIR/WordAndSound_WordAndSoundCore.bundle"

if [[ ! -x "$BIN" ]]; then
  echo "error: missing $BIN" >&2
  exit 1
fi
if [[ ! -d "$RES_BUNDLE" ]]; then
  echo "error: missing resource bundle $RES_BUNDLE" >&2
  exit 1
fi

echo "Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/WordAndSound"
cp -R "$RES_BUNDLE" "$APP/Contents/Resources/"

if [[ -f "$ICON_SRC" ]]; then
  echo "Building icon"
  rm -rf "$ICONSET"
  mkdir -p "$ICONSET"
  while read -r size name; do
    sips -z "$size" "$size" "$ICON_SRC" --out "$ICONSET/$name.png" >/dev/null
  done <<'SIZES'
16 icon_16x16
32 icon_16x16@2x
32 icon_32x32
64 icon_32x32@2x
128 icon_128x128
256 icon_128x128@2x
256 icon_256x256
512 icon_256x256@2x
512 icon_512x512
1024 icon_512x512@2x
SIZES
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Word &amp; Sound</string>
    <key>CFBundleDisplayName</key>
    <string>Word &amp; Sound</string>
    <key>CFBundleIdentifier</key>
    <string>com.somphol.wordandsound</string>
    <key>CFBundleExecutable</key>
    <string>WordAndSound</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.4.1</string>
    <key>CFBundleVersion</key>
    <string>6</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.education</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Record your voice to compare with the model pronunciation. Recordings stay on this Mac.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Data CC BY-SA 4.0; code MIT.</string>
</dict>
</plist>
PLIST

cp "$ROOT/LICENSES.md" "$APP/Contents/Resources/LICENSES.md"
cp -R "$ROOT/licenses" "$APP/Contents/Resources/licenses"

plutil -lint "$APP/Contents/Info.plist" >/dev/null
codesign --force --deep --sign - "$APP" >/dev/null

echo "Built $APP"
echo "Open with: open \"$APP\""
