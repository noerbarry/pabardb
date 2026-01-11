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


## Quick Start (macOS / Linux)

### Build
```bash
chmod +x build.sh install.sh
./build.sh





**20) Catatan Akhir**
PABAR DB adalah storage engine: cepat, lokal, crash-safe.

Login, role, dan UI dikelola oleh aplikasi.

Cocok untuk on-prem, offline, edge, dan aplikasi yang butuh audit & durability.
