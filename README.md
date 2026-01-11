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

---

## Quick Start (macOS / Linux)

### Build
```bash
chmod +x build.sh install.sh
./build.sh



###PABAR DB — User Guide (CLI & Concepts)

Dokumen ini menjelaskan **cara penggunaan PABAR DB dari sudut pandang USER**: mulai dari
**create table (schema), login, insert, update, query, delete, list, index, dump/export, import, backup, restore, dan recovery**.
Semua contoh menggunakan CLI `pabardb`.**

> Catatan: PABAR DB adalah **embedded, local-first engine**. Autentikasi, role, dan UI berada di layer aplikasi.
> Engine fokus pada **storage, WAL, durability, dan auditability**.

 

**0) Konsep Dasar**

- **Database** = folder `<name>.pbr/`
- **Record key** = `<type>` + `<id>`
- **Payload** = JSON
- **Update** = tulis ulang key yang sama (event terbaru menang)
- **Durability** = WAL (Write-Ahead Log)
- **Recovery** = membangun ulang state dari WAL

Format umum:
 pabardb <db.pbr> "<COMMAND>"
**1) Membuat / Membuka Database**
 
pabardb mydb.pbr "RECOVER"
Jika mydb.pbr belum ada, engine akan membuat struktur awal.

Struktur minimal:

mydb.pbr/
├── manifest.json
└── wal/
    └── wal-active.log

**2) “Create Table” (Definisi Schema)**
PABAR DB tidak memakai tabel fisik seperti SQL. type bertindak sebagai logical table.
Namun kamu bisa mendefinisikan schema untuk validasi aplikasi.

Buat schema (logical table)
 
pabardb mydb.pbr "PUT _schema record '{
  \"primary_key\":\"id\",
  \"fields\":{
    \"name\":\"string\",
    \"age\":\"number\",
    \"gender\":\"string\"
  }
}'"
_schema adalah namespace khusus untuk metadata. Engine menyimpan; aplikasi bisa memvalidasi.

Lihat schema
 
pabardb mydb.pbr "GET _schema record"

**3) Login & Manajemen User**
Engine tidak mengatur autentikasi, tetapi data user disimpan di DB.

Buat user

pabardb mydb.pbr "PUT user admin '{\"username\":\"admin\",\"password\":\"12345\",\"role\":\"admin\"}'"
pabardb mydb.pbr "PUT user kasir '{\"username\":\"kasir\",\"password\":\"111\",\"role\":\"operator\"}'"
Login (aplikasi membaca & memverifikasi)
 

pabardb mydb.pbr "GET user admin"
Aplikasi:

cek password

baca role untuk hak akses

**4) Insert Data**
 
pabardb mydb.pbr "PUT record R-1 '{\"name\":\"Barri\",\"age\":46,\"gender\":\"M\"}'"
Output:

nginx

OK

**5) Query (Ambil Data)**
 
pabardb mydb.pbr "GET record R-1"
Output:
 
{"name":"Budi","age":30,"gender":"M"}

**6) Update Data**
Update = PUT ulang dengan ID yang sama

pabardb mydb.pbr "PUT record R-1 '{\"name\":\"Barri\",\"age\":3461,\"gender\":\"L\"}'"


**7) Delete Data (Soft Delete)**
pabardb mydb.pbr "DEL record R-1"
Data tidak dihapus fisik; dicatat sebagai event.

**8) List / Scan Data (per “table”)**
Untuk membaca banyak record berdasarkan type:

pabardb mydb.pbr "LIST record"
Contoh output:

 
[
  {"id":"R-1","name":"Barri","age":46,"gender":"M"},
  {"id":"R-2","name":"Ajrul","age":29,"gender":"M"},
  {"id":"R-3","name":"Deddy","age":29,"gender":"M"},
  {"id":"R-4","name":"Dhina","age":29,"gender":"F"}
  {"id":"R-5","name":"Jonathan","age":29,"gender":"M"}
  {"id":"R-6","name":"Wildan","age":29,"gender":"M"}
]

**9) Index (Metadata)**
Index bersifat metadata agar aplikasi tahu field mana yang sering dicari.

Buat index

pabardb mydb.pbr "PUT _index record '{\"fields\":[\"name\",\"age\"]}'"
Lihat index

pabardb mydb.pbr "GET _index record"
Engine menyimpan metadata; optimisasi eksekusi dapat ditambahkan di layer engine/app.

**10) Query dengan Filter (Konsep)**
CLI dasar membaca per key. Untuk filter:

 
pabardb mydb.pbr "FIND record '{\"age\":{\"$gte\":30}}'"
Contoh hasil:

 
[
  {"id":"R-1","name":"Ajrul","age":29,"gender":"M"}
]

**11) Transaction (Konsep)**
PABAR DB bersifat event-based. Untuk operasi berurutan:

 
pabardb mydb.pbr "BEGIN"
pabardb mydb.pbr "PUT order O-1 '{\"total\":10000}'"
pabardb mydb.pbr "PUT order_item OI-1 '{\"order_id\":\"O-1\",\"sku\":\"A1\",\"qty\":2}'"
pabardb mydb.pbr "COMMIT"
Jika terjadi error:

 
pabardb mydb.pbr "ROLLBACK"

**12) Dump / Export Data**
Dump seluruh DB ke JSON
 
pabardb mydb.pbr "DUMP JSON" > mydb_dump.json
Dump satu “table”
 

pabardb mydb.pbr "DUMP record JSON" > record.json
Export CSV
 

pabardb mydb.pbr "DUMP record CSV" > record.csv

**13) Import Data**
Import dari JSON
 

pabardb mydb.pbr "IMPORT JSON record record.json"
Import dari CSV

pabardb mydb.pbr "IMPORT CSV record record.csv"
14) Backup & Restore
Backup (snapshot folder)

tar -czf mydb-backup.tgz mydb.pbr

Restore
 
tar -xzf mydb-backup.tgz
pabardb mydb.pbr "RECOVER"

**15) Recovery (Crash / Power Loss)**

pabardb mydb.pbr "RECOVER"
Engine akan membaca WAL dan membangun ulang state terakhir.

16) Audit / History (Event Log)
Lihat event log

pabardb mydb.pbr "LOG record R-1"
Output:
[
  {"ts":"2026-01-11T10:00:00Z","op":"PUT","data":{"name":"Budi","age":30}},
  {"ts":"2026-01-11T12:00:00Z","op":"PUT","data":{"name":"Budi","age":31}}
]

**17) Role & Hak Akses (Contoh Kebijakan Aplikasi)**
Struktur user:

 
{"username":"admin","role":"admin"}
Kebijakan contoh:

admin: PUT, DEL, DUMP, IMPORT, RECOVER

operator: GET, LIST

viewer: GET

Penegakan dilakukan di aplikasi yang memanggil PABAR DB.

**18) Contoh Alur Lengkap**
(1) Buat schema
 

pabardb mydb.pbr "PUT _schema product '{\"primary_key\":\"id\",\"fields\":{\"name\":\"string\",\"price\":\"number\"}}'"
(2) Insert
 

pabardb mydb.pbr "PUT product PRD-1 '{\"name\":\"Kopi\",\"price\":15000}'"
(3) Update
 

pabardb mydb.pbr "PUT product PRD-1 '{\"name\":\"Kopi\",\"price\":16000}'"
(4) Query

pabardb mydb.pbr "GET product PRD-1"
(5) List
 
pabardb mydb.pbr "LIST product"
(6) Dump


pabardb mydb.pbr "DUMP product JSON" > product.json
(7) Backup

tar -czf mydb-backup.tgz mydb.pbr

(8) Restore + Recover

tar -xzf mydb-backup.tgz
pabardb mydb.pbr "RECOVER"

19) Ringkasan Perintah
Kategori	Perintah
Create/Open	RECOVER
Schema	PUT _schema <type> <json>
Insert	PUT <type> <id> <json>
Query	GET <type> <id>
List	LIST <type>
Update	PUT <type> <id> <json>
Delete	DEL <type> <id>
Index	PUT _index <type> <json>
Find	FIND <type> <filter-json>
Dump	`DUMP [<type>] JSON
Import	`IMPORT JSON
Backup	tar -czf <file> <db>.pbr
Restore	tar -xzf <file> + RECOVER
Audit/Log	LOG <type> <id>
Transaction	BEGIN / COMMIT / ROLLBACK

**20) Catatan Akhir**
PABAR DB adalah storage engine: cepat, lokal, crash-safe.

Login, role, dan UI dikelola oleh aplikasi.

Cocok untuk on-prem, offline, edge, dan aplikasi yang butuh audit & durability.
