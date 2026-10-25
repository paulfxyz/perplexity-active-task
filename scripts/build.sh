#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Build on macOS with Xcode Command Line Tools installed." >&2
  exit 1
fi
OUT="$PWD/build"
APP="$OUT/Active Task.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OUT/AppIcon.iconset"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
for ARCH in arm64 x86_64; do
  # Swift requires top-level application statements in a file called main.swift.
  cp Sources/App.swift "$OUT/main.swift"
  xcrun swiftc -swift-version 5 -O -sdk "$SDK" -target "$ARCH-apple-macos13.0" \
    -framework AppKit -framework WebKit Sources/Behavior.swift "$OUT/main.swift" \
    -o "$OUT/ActiveTask-$ARCH"
done
lipo -create "$OUT/ActiveTask-arm64" "$OUT/ActiveTask-x86_64" -output "$APP/Contents/MacOS/ActiveTask"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Sources/Sidebar.js "$APP/Contents/Resources/Sidebar.js"
xcrun swift scripts/icon.swift "$OUT/icon-1024.png"
for SIZE in 16 32 128 256 512; do
  sips -z "$SIZE" "$SIZE" "$OUT/icon-1024.png" --out "$OUT/AppIcon.iconset/icon_${SIZE}x${SIZE}.png" >/dev/null
  DOUBLE=$((SIZE * 2))
  sips -z "$DOUBLE" "$DOUBLE" "$OUT/icon-1024.png" --out "$OUT/AppIcon.iconset/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$OUT/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
plutil -lint "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/Active-Task-macOS-universal.zip"
(cd "$OUT" && shasum -a 256 Active-Task-macOS-universal.zip > SHA256SUMS.txt)
echo "Built $APP"
