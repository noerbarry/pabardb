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



📦 Python SDK

PABAR DB dapat digunakan dari Python melalui SDK (PyPI) atau wrapper CLI.
Pastikan CLI pabardb dan library sudah terpasang (lihat bagian Quick Start OS).

1) Instal via PyPI (disarankan)
python3 -m pip install -U pabardb


Verifikasi:
python3 - <<'PY'
import pabardb
print("pabardb OK:", pabardb)
PY


Catatan macOS: jika Python tidak menemukan libpabardb.dylib, pastikan:
export DYLD_LIBRARY_PATH=/usr/local/lib:$DYLD_LIBRARY_PATH

2) Contoh CRUD di Python (SDK)

Catatan: Contoh ini mengasumsikan SDK mengekspos client tingkat tinggi (mis. Client).
Jika API SDK kamu berbeda, lihat opsi “Wrapper CLI” di bawah (pasti bekerja).

# file: example_sdk.py
from pabardb import Client  # sesuaikan jika nama class berbeda

db = "mydb.pbr"
c = Client(db)

# CREATE / UPSERT
c.put("record", "R-1", {"name": "Barri", "age": 46, "gender": "M"})
print("PUT OK")

# READ
doc = c.get("record", "R-1")
print("GET:", doc)

# UPDATE
c.put("record", "R-1", {"name": "Barri", "age": 47, "gender": "M"})
print("UPDATE OK")

doc2 = c.get("record", "R-1")
print("GET2:", doc2)

# DELETE (jika tersedia)
# c.delete("record", "R-1")

# LIST / FIND (jika tersedia)
# print(c.list("record"))
# print(c.find("record", {"age": {"$gte": 30}}))


Python via CLI Wrapper (Portable & Pasti Jalan)

Jika SDK Python kamu masih tipis atau kamu ingin cara yang paling kompatibel di semua OS, gunakan wrapper CLI berikut. Ini memanggil binary pabardb dari Python.

1) Buat wrapper

# file: pabardb_cli_client.py
import json
import subprocess

class PabarDbCLI:
    def __init__(self, db_path: str, binary: str = "pabardb"):
        self.db = db_path
        self.bin = binary

    def _run(self, cmd: str) -> str:
        p = subprocess.run([self.bin, self.db, cmd], capture_output=True, text=True)
        if p.returncode != 0:
            raise RuntimeError(p.stderr.strip() or p.stdout.strip())
        return p.stdout.strip()

    def recover(self):
        return self._run("RECOVER")

    def put(self, typ: str, id_: str, obj: dict):
        payload = json.dumps(obj, separators=(",", ":"))
        return self._run(f"PUT {typ} {id_} '{payload}'")

    def get(self, typ: str, id_: str):
        out = self._run(f"GET {typ} {id_}")
        return json.loads(out)

    # Opsional (jika CLI mendukung)
    def delete(self, typ: str, id_: str):
        return self._run(f"DEL {typ} {id_}")

    def list(self, typ: str):
        out = self._run(f"LIST {typ}")
        return json.loads(out)

    def find(self, typ: str, filter_obj: dict):
        filt = json.dumps(filter_obj, separators=(",", ":"))
        out = self._run(f"FIND {typ} '{filt}'")
        return json.loads(out)


2) Contoh CRUD + Query

# file: example_cli.py
from pabardb_cli_client import PabarDbCLI

db = PabarDbCLI("mydb.pbr")

# OPEN / RECOVER
print(db.recover())

# CREATE
db.put("record", "R-1", {"name": "Barri", "age": 46, "gender": "M"})
print("PUT OK")

# READ
print("GET:", db.get("record", "R-1"))

# UPDATE
db.put("record", "R-1", {"name": "Barri", "age": 47, "gender": "M"})
print("UPDATE OK")
print("GET2:", db.get("record", "R-1"))

# DELETE (jika tersedia)
# db.delete("record", "R-1")

# LIST / FIND (jika tersedia)
# print("LIST:", db.list("record"))
# print("FIND:", db.find("record", {"age": {"$gte": 30}}))


Instal SDK dari Source (untuk Developer)
Jika anda ingin mengembangkan SDK dari repo:

cd python-package
python3 -m pip install -U pip build
python3 -m pip install -e .


Catatan Teknis
PABAR DB adalah embedded, local-first (tanpa daemon).
Python dapat berinteraksi:
langsung via C API (jika SDK mengekspos binding), atau
via CLI (wrapper di atas; paling kompatibel).
Pastikan library dapat ditemukan OS:

macOS: /usr/local/lib/libpabardb.dylib
Linux: /usr/local/lib/libpabardb.so
