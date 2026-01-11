#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/dist"
[ -d "$SRC" ] || { echo "Run ./build.sh first"; exit 1; }

PREFIX="${PREFIX:-/usr/local}"
sudo mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include"

# CLI
sudo cp "$SRC/pabardb" "$PREFIX/bin/pabardb"
sudo chmod +x "$PREFIX/bin/pabardb"

# Library + header
sudo cp "$SRC/"libpabardb* "$PREFIX/lib/" 2>/dev/null || true
sudo cp "$SRC/pabardb.h" "$PREFIX/include/pabardb.h"

echo "Installed:"
echo "  CLI : $PREFIX/bin/pabardb"
echo "  LIB : $PREFIX/lib/libpabardb*"
echo "  HDR : $PREFIX/include/pabardb.h"

