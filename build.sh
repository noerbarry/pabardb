#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$ROOT/dist"
cd "$ROOT/engine"

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Collect artifacts
cp build/pabardb_cli "$ROOT/dist/pabardb" 2>/dev/null || true
cp build/libpabardb* "$ROOT/dist/" 2>/dev/null || true
cp include/pabardb.h "$ROOT/dist/"

echo "Built artifacts in ./dist"
ls -la "$ROOT/dist"

