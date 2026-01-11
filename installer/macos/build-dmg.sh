#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGING="$ROOT/installer/macos/dmg"
OUT="$ROOT/dist/PABARDB-Installer.dmg"

mkdir -p "$ROOT/dist"

# Build DMG from staging folder
hdiutil create -volname "PABARDB" -srcfolder "$STAGING" -ov -format UDZO "$OUT"

echo "DMG created: $OUT"

