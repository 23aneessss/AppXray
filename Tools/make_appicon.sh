#!/usr/bin/env bash
#
# make_appicon.sh — regenerate the macOS app icon from code.
# Renders a 1024×1024 master with generate_icon.swift, then slices it into every
# size the AppIcon.appiconset needs. Run from the repo root:
#
#   ./Tools/make_appicon.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SET="$ROOT/App/Sources/Assets.xcassets/AppIcon.appiconset"
MASTER="/tmp/appxray-icon-1024.png"

swift "$ROOT/Tools/generate_icon.swift"
mkdir -p "$SET"

# size:filename pairs for a macOS app icon
gen() { sips -z "$1" "$1" "$MASTER" --out "$SET/$2" >/dev/null; }
gen 16   icon_16x16.png
gen 32   icon_16x16@2x.png
gen 32   icon_32x32.png
gen 64   icon_32x32@2x.png
gen 128  icon_128x128.png
gen 256  icon_128x128@2x.png
gen 256  icon_256x256.png
gen 512  icon_256x256@2x.png
gen 512  icon_512x512.png
cp "$MASTER" "$SET/icon_512x512@2x.png"   # 1024

echo "Wrote icon set to $SET"
