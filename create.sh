#!/usr/bin/env bash
# ============================================================
# PABAR DB™ — ONE-FILE BASH ORCHESTRATOR (Enterprise)
# Engine: C++ | Policy: Rust | API: Go | UI: React
# Format: *.pbr | WAL + Recovery | Export/Integrasi | UI Super
# ============================================================

set -euo pipefail

# -----------------------
# GLOBAL CONFIG
# -----------------------
PABAR_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PABAR_DATA="$PABAR_HOME/data"
PABAR_LOGS="$PABAR_HOME/logs"
PABAR_DB_NAME="${PABAR_DB_NAME:-simrs_intramedika.pbr}"
PABAR_API_PORT="${PABAR_API_PORT:-8080}"
PABAR_UI_PORT="${PABAR_UI_PORT:-5173}"
PABAR_GRPC_PORT="${PABAR_GRPC_PORT:-50051}"
PABAR_POLICY_PORT="${PABAR_POLICY_PORT:-7001}"
PABAR_METRICS_PORT="${PABAR_METRICS_PORT:-9100}"

ENGINE_BIN="$PABAR_HOME/engine/build/pabardb"
POLICY_BIN="$PABAR_HOME/policy/target/release/policy"
API_BIN="$PABAR_HOME/api/api"

mkdir -p "$PABAR_DATA" "$PABAR_LOGS"

log(){ echo -e "[PABAR] $*"; }

usage(){
cat <<'EOF'
Usage: ./pabardb.sh <command> [args]

Commands:
  install                Install all dependencies (C++, Rust, Go, Node, Docker)
  build                  Build Engine (C++), Policy (Rust), API (Go), UI (React)
  create-db              Create database (*.pbr)
  start                  Start Engine + Policy + API + UI
  stop                   Stop all services
  status                 Show status
  backup                 Backup database (*.pbr)
  restore <file>         Restore from backup
  recover                Force WAL recovery
  export-csv [out]       Export WAL to CSV
  export-json [out]      Export WAL to JSON
  stream-wal <url>       Stream WAL lines to HTTP endpoint
  rotate-wal             Rotate WAL file
  health                 Healthcheck (API + DB)
  metrics                Fetch metrics
  package-deb            Build .deb installer
  install-service        Install as systemd service (auto-start)
  all                    install + build + create-db + start

Environment variables:
  PABAR_DB_NAME, PABAR_API_PORT, PABAR_UI_PORT, PABAR_GRPC_PORT, PABAR_POLICY_PORT

Examples:
  ./pabardb.sh all
  ./pabardb.sh export-csv /tmp/out.csv
  ./pabardb.sh stream-wal http://example.com/ingest
EOF
}

# -----------------------
# INSTALL
# -----------------------
install(){
  log "Installing dependencies..."
  sudo apt-get update
  sudo apt-get install -y build-essential cmake libssl-dev \
                          golang nodejs npm curl jq docker.io docker-compose \
                          protobuf-compiler
  if ! command -v cargo >/dev/null 2>&1; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
  fi
  log "Dependencies installed"
}

# -----------------------
# BUILD
# -----------------------
build(){
  log "Building C++ Engine..."
  (cd "$PABAR_HOME/engine" && cmake -S . -B build && cmake --build build)

  log "Building Rust Policy..."
  (cd "$PABAR_HOME/policy" && cargo build --release)

  log "Building Go API..."
  (cd "$PABAR_HOME/api" && go build -o api)

  log "Building UI..."
  (cd "$PABAR_HOME/ui" && npm install && npm run build)

  log "Build complete"
}

# -----------------------
# CREATE DB
# -----------------------
create_db(){
  local DB_PATH="$PABAR_DATA/$PABAR_DB_NAME"
  if [ -d "$DB_PATH" ]; then
    log "DB already exists: $DB_PATH"; return 0
  fi
  log "Creating DB: $DB_PATH"
  "$ENGINE_BIN" create "$DB_PATH"
  log "DB created"
}

# -----------------------
# START / STOP / STATUS
# -----------------------
start(){
  log "Starting Engine (gRPC:$PABAR_GRPC_PORT)..."
  nohup "$ENGINE_BIN" open "$PABAR_DATA/$PABAR_DB_NAME" --grpc "$PABAR_GRPC_PORT" \
    > "$PABAR_LOGS/engine.log" 2>&1 & echo $! > "$PABAR_LOGS/engine.pid"
  sleep 1

  log "Starting Policy (:$PABAR_POLICY_PORT)..."
  nohup "$POLICY_BIN" --port "$PABAR_POLICY_PORT" \
    > "$PABAR_LOGS/policy.log" 2>&1 & echo $! > "$PABAR_LOGS/policy.pid"
  sleep 1

  log "Starting API (:$PABAR_API_PORT)..."
  nohup "$API_BIN" --grpc "127.0.0.1:$PABAR_GRPC_PORT" --policy "127.0.0.1:$PABAR_POLICY_PORT" --port "$PABAR_API_PORT" \
    > "$PABAR_LOGS/api.log" 2>&1 & echo $! > "$PABAR_LOGS/api.pid"
  sleep 1

  log "Starting UI (:$PABAR_UI_PORT)..."
  (cd "$PABAR_HOME/ui" && nohup npm run preview -- --port "$PABAR_UI_PORT" \
    > "$PABAR_LOGS/ui.log" 2>&1 & echo $! > "$PABAR_LOGS/ui.pid")

  log "All services started"
}

stop(){
  for svc in ui api policy engine; do
    local f="$PABAR_LOGS/$svc.pid"
    if [ -f "$f" ]; then
      log "Stopping $svc ($(cat "$f"))"
      kill "$(cat "$f")" || true
      rm -f "$f"
    fi
  done
  log "All services stopped"
}

status(){
  for svc in engine policy api ui; do
    local f="$PABAR_LOGS/$svc.pid"
    if [ -f "$f" ] && ps -p "$(cat "$f")" >/dev/null; then
      echo "[✓] $svc running"
    else
      echo "[✗] $svc down"
    fi
  done
}

# -----------------------
# BACKUP / RESTORE / RECOVER
# -----------------------
backup(){
  local DB="$PABAR_DATA/$PABAR_DB_NAME"
  local OUT="$PABAR_DATA/backup_${PABAR_DB_NAME}_$(date +%Y%m%d_%H%M%S).tar.gz"
  log "Backing up $DB -> $OUT"
  tar -czf "$OUT" -C "$PABAR_DATA" "$PABAR_DB_NAME"
  log "Backup done: $OUT"
}

restore(){
  local ARCHIVE="${1:-}"
  [ -z "$ARCHIVE" ] && { echo "Usage: restore <backup.tar.gz>"; exit 1; }
  log "Restoring from $ARCHIVE..."
  tar -xzf "$ARCHIVE" -C "$PABAR_DATA"
  log "Restore done (auto-recover on start)"
}

recover(){
  log "Forcing WAL recovery..."
  "$ENGINE_BIN" open "$PABAR_DATA/$PABAR_DB_NAME" --recover
  log "Recovery complete"
}

# -----------------------
# EXPORT / INTEGRATION
# -----------------------
export_csv(){
  local DB="$PABAR_DATA/$PABAR_DB_NAME"
  local OUT="${1:-$PABAR_DATA/export_$(date +%Y%m%d_%H%M%S).csv}"
  log "Exporting WAL -> CSV: $OUT"
  awk -F"|" '{print $1","$2","$3","$4","$5}' "$DB/wal/wal-active.log" > "$OUT"
  log "CSV exported: $OUT"
}

export_json(){
  local DB="$PABAR_DATA/$PABAR_DB_NAME"
  local OUT="${1:-$PABAR_DATA/export_$(date +%Y%m%d_%H%M%S).json}"
  log "Exporting WAL -> JSON: $OUT"
  echo "[" > "$OUT"
  sed 's/|/","/g; s/^/["/; s/$/"],/' "$DB/wal/wal-active.log" >> "$OUT"
  sed -i '$ s/,$//' "$OUT"
  echo "]" >> "$OUT"
  log "JSON exported: $OUT"
}

stream_wal(){
  local URL="${1:-}"
  [ -z "$URL" ] && { echo "Usage: stream-wal <http_endpoint>"; exit 1; }
  log "Streaming WAL to $URL (CTRL+C to stop)"
  tail -F "$PABAR_DATA/$PABAR_DB_NAME/wal/wal-active.log" | while read -r line; do
    curl -s -X POST "$URL" -H "Content-Type: text/plain" --data-binary "$line" >/dev/null
  done
}

rotate_wal(){
  local DB="$PABAR_DATA/$PABAR_DB_NAME"
  local TS="$(date +%Y%m%d_%H%M%S)"
  log "Rotating WAL..."
  mv "$DB/wal/wal-active.log" "$DB/wal/wal-$TS.log"
  touch "$DB/wal/wal-active.log"
  log "WAL rotated"
}

# -----------------------
# HEALTH / METRICS
# -----------------------
health(){
  curl -fsS "http://localhost:$PABAR_API_PORT/health" && echo " API OK" || echo " API DOWN"
  [ -f "$PABAR_DATA/$PABAR_DB_NAME/manifest.json" ] && echo " DB OK" || echo " DB MISSING"
}

metrics(){
  curl -fsS "http://localhost:$PABAR_API_PORT/metrics" || echo "metrics unavailable"
}

# -----------------------
# PACKAGING / SERVICE
# -----------------------
package_deb(){
  local PKG="$PABAR_HOME/dist/pabardb_1.0.0_amd64"
  mkdir -p "$PKG/DEBIAN" "$PKG/usr/local/pabardb"
  cp -r "$PABAR_HOME/engine/build" "$PABAR_HOME/api" "$PABAR_HOME/ui" "$PABAR_HOME/policy" "$PKG/usr/local/pabardb/"
  cat > "$PKG/DEBIAN/control" <<EOF
Package: pabardb
Version: 1.0.0
Architecture: amd64
Maintainer: PABAR
Description: PABAR DB - Policy-first AI-native Database
EOF
  dpkg-deb --build "$PKG"
  log "Built .deb in dist/"
}

install_service(){
  log "Installing systemd service..."
  sudo tee /etc/systemd/system/pabardb.service > /dev/null <<'EOF'
[Unit]
Description=PABAR DB
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/pabardb/pabardb.sh start
ExecStop=/usr/local/pabardb/pabardb.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable pabardb
  sudo systemctl start pabardb
  log "Service installed & started"
}

# -----------------------
# ALL-IN-ONE
# -----------------------
all(){
  install
  build
  create_db
  start
  status
}

# -----------------------
# DISPATCH
# -----------------------
cmd="${1:-}"
shift || true

case "$cmd" in
  install) install ;;
  build) build ;;
  create-db) create_db ;;
  start) start ;;
  stop) stop ;;
  status) status ;;
  backup) backup ;;
  restore) restore "$@" ;;
  recover) recover ;;
  export-csv) export_csv "$@" ;;
  export-json) export_json "$@" ;;
  stream-wal) stream_wal "$@" ;;
  rotate-wal) rotate_wal ;;
  health) health ;;
  metrics) metrics ;;
  package-deb) package_deb ;;
  install-service) install_service ;;
  all) all ;;
  ""|-h|--help) usage ;;
  *) echo "Unknown command: $cmd"; usage; exit 1 ;;
esac

