# PABAR DB (Embedded, Local-First)

PABAR DB is a local-first embedded database engine written in C++.
It ships as:
- `pabardb` CLI
- `libpabardb` shared library + `pabardb.h` (C API)
- local DB format: `<name>.pbr/` (folder-based, WAL-backed)

## Quick start (macOS/Linux)

### Build
```bash
chmod +x build.sh install.sh
./build.sh

