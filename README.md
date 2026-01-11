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


🧑‍💻 INSTALL PABARDB DARI GITHUB (MODE USER – macOS)


user@Users-MBP ~ % cd ~
git clone https://github.com/noerbarry/pabardb.git
cd pabardb

Cloning into 'pabardb'...
remote: Enumerating objects: 90, done.
remote: Counting objects: 100% (90/90), done.
remote: Compressing objects: 100% (72/72), done.
remote: Total 90 (delta 35), reused 48 (delta 7), pack-reused 0 (from 0)
Receiving objects: 100% (90/90), 564.67 KiB | 118.00 KiB/s, done.
Resolving deltas: 100% (35/35), done.
user@Users-MBP pabardb % ls
LICENSE		assets		create.sh	engine		installer
README.md	build.sh	docs		install.sh	pabardb.sh
user@Users-MBP pabardb % chmod +x build.sh install.sh
./build.sh

-- The C compiler identification is AppleClang 15.0.0.15000309
-- The CXX compiler identification is AppleClang 15.0.0.15000309
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /usr/bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /usr/bin/c++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring done (2.3s)
-- Generating done (0.0s)
-- Build files have been written to: /Users/user/pabardb/engine/build
[ 16%] Building CXX object CMakeFiles/pabardb.dir/core/engine.cpp.o
[ 33%] Building CXX object CMakeFiles/pabardb.dir/storage/wal.cpp.o
[ 50%] Building CXX object CMakeFiles/pabardb.dir/c_api/pabardb_c.cpp.o
[ 66%] Linking CXX shared library libpabardb.dylib
[ 66%] Built target pabardb
[ 83%] Building CXX object CMakeFiles/pabardb_cli.dir/cli/main.cpp.o
[100%] Linking CXX executable pabardb_cli
[100%] Built target pabardb_cli
Built artifacts in ./dist
total 136
drwxr-xr-x   5 user  staff    160 Jan 11 19:14 .
drwxr-xr-x  16 user  staff    512 Jan 11 19:13 ..
-rwxr-xr-x   1 user  staff  41312 Jan 11 19:14 libpabardb.dylib
-rwxr-xr-x   1 user  staff  20472 Jan 11 19:14 pabardb
-rw-r--r--   1 user  staff    678 Jan 11 19:14 pabardb.h
user@Users-MBP pabardb % ./install.sh

Password:
Installed:
  CLI : /usr/local/bin/pabardb
  LIB : /usr/local/lib/libpabardb*
  HDR : /usr/local/include/pabardb.h
user@Users-MBP pabardb % pabardb mydb.pbr "RECOVER"

OK
user@Users-MBP pabardb % pabardb mydb.pbr "PUT record R-1 '{\"name\":\"Barri\",\"age\":46,\"gender\":\"M\"}'"

OK
user@Users-MBP pabardb % pabardb mydb.pbr "GET record R-1"

{"name":"Barri","age":46,"gender":"M"}
user@Users-MBP pabardb % pabardb mydb.pbr "PUT record R-1 '{\"name\":\"Barri\",\"age\":47,\"gender\":\"M\"}'"

OK
user@Users-MBP pabardb % pabardb mydb.pbr "RECOVER"
pabardb mydb.pbr "GET record R-1"

OK
{"name":"Barri","age":47,"gender":"M"}
user@Users-MBP pabardb % 

