<p align="center">
  <img src="assets/logo.png" alt="PABAR DB Logo" width="240"/>
</p>

# PABAR DB (Embedded, Local-First)

PABAR DB adalah database engine **embedded** (C++) yang berjalan **lokal** dan **tanpa service/daemon wajib**.  
Dirancang untuk aplikasi on-prem, offline, dan edge, dengan format data berbasis event + WAL (crash-safe).

**Deliverables:**
- `pabardb` — CLI tool
- `libpabardb` — shared library + `pabardb.h` (C API)
- Format database: `<name>.pbr/` (folder-based, WAL-backed)


## Quick Start (Binary Release)

PABAR DB didistribusikan sebagai **binary** via GitHub Releases.

### macOS
```bash
curl -L -o pabardb.tar.gz https://github.com/noerbarry/pabardb/releases/download/v1.0.0/pabardb-1.0.0-macos-universal.tar.gz
tar -xzf pabardb.tar.gz

sudo cp pabardb-1.0.0-macos/bin/pabardb /usr/local/bin/
sudo cp pabardb-1.0.0-macos/lib/libpabardb.dylib /usr/local/lib/
sudo cp pabardb-1.0.0-macos/include/pabardb.h /usr/local/include/ 2>/dev/null || true

pabardb --help


Linux (x86_64)

curl -L -o pabardb.tar.gz https://github.com/noerbarry/pabardb/releases/download/v1.0.0/pabardb-1.0.0-linux-x86_64.tar.gz
tar -xzf pabardb.tar.gz

sudo cp pabardb-1.0.0-linux/bin/pabardb /usr/local/bin/
sudo cp pabardb-1.0.0-linux/lib/libpabardb.so /usr/local/lib/
sudo cp pabardb-1.0.0-linux/include/pabardb.h /usr/local/include/ 2>/dev/null || true

sudo ldconfig 2>/dev/null || true
pabardb --help




