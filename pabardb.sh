#!/usr/bin/env bash
set -euo pipefail

PABAR_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PABAR_DATA="$PABAR_HOME/data"
PABAR_LOGS="$PABAR_HOME/logs"
PABAR_DB_NAME="${PABAR_DB_NAME:-simrs_intramedika.pbr}"
PABAR_API_PORT="${PABAR_API_PORT:-8080}"
PABAR_UI_PORT="${PABAR_UI_PORT:-5173}"
PABAR_GRPC_PORT="${PABAR_GRPC_PORT:-50051}"
PABAR_POLICY_PORT="${PABAR_POLICY_PORT:-7001}"

ENGINE_BIN="$PABAR_HOME/engine/build/pabardb"
POLICY_BIN="$PABAR_HOME/policy/target/release/policy"
API_BIN="$PABAR_HOME/api/api"

mkdir -p "$PABAR_DATA" "$PABAR_LOGS"

log(){ echo "[PABAR] $*"; }

usage(){
  cat <<'EOF'
Usage: ./pabardb.sh <command>

DEV:
  dev-install
  dev-build
  dev-create-db
  dev-start
  dev-stop
  dev-status
  dev-health
EOF
}

dev_install(){
  log "Installing dependencies (auto-detect OS)..."
  OS="$(uname -s)"

  if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew not found. Install Homebrew first."
      exit 1
    fi
    brew update
    brew install cmake openssl@3 go node jq protobuf rust
    echo "macOS dependencies installed."
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y build-essential cmake libssl-dev \
      golang nodejs npm curl jq docker.io docker-compose protobuf-compiler
    if ! command -v cargo >/dev/null 2>&1; then
      curl https://sh.rustup.rs -sSf | sh -s -- -y
      source "$HOME/.cargo/env"
    fi
    echo "Linux dependencies installed."
    return 0
  fi

  echo "Unsupported OS. Install manually: cmake, openssl, go, node, rust, protobuf."
  exit 1
}

dev_build(){
  log "Building C++ engine..."
  (cd "$PABAR_HOME/engine" && cmake -S . -B build && cmake --build build)

  log "Building Rust policy..."
  (cd "$PABAR_HOME/policy" && cargo build --release)

  log "Building Go API..."
  (cd "$PABAR_HOME/api" && go build -o api)

  log "Building UI..."
  (cd "$PABAR_HOME/ui" && npm install && npm run build)

  log "Build complete"
}

dev_create_db(){
  local DB_PATH="$PABAR_DATA/$PABAR_DB_NAME"
  if [ -d "$DB_PATH" ]; then
    log "DB already exists: $DB_PATH"
    return 0
  fi
  log "Creating DB: $DB_PATH"
  "$ENGINE_BIN" create "$DB_PATH"
  log "DB created"
}

dev_start(){
  log "Starting Engine..."
  nohup "$ENGINE_BIN" open "$PABAR_DATA/$PABAR_DB_NAME" --grpc "$PABAR_GRPC_PORT" \
    > "$PABAR_LOGS/engine.log" 2>&1 & echo $! > "$PABAR_LOGS/engine.pid"

  log "Starting Policy..."
  nohup "$POLICY_BIN" --port "$PABAR_POLICY_PORT" \
    > "$PABAR_LOGS/policy.log" 2>&1 & echo $! > "$PABAR_LOGS/policy.pid"

  log "Starting API..."
  nohup "$API_BIN" --grpc "127.0.0.1:$PABAR_GRPC_PORT" --policy "127.0.0.1:$PABAR_POLICY_PORT" --port "$PABAR_API_PORT" \
    > "$PABAR_LOGS/api.log" 2>&1 & echo $! > "$PABAR_LOGS/api.pid"

  log "Starting UI..."
  (cd "$PABAR_HOME/ui" && nohup npm run preview -- --port "$PABAR_UI_PORT" \
    > "$PABAR_LOGS/ui.log" 2>&1 & echo $! > "$PABAR_LOGS/ui.pid")

  log "All services started"
}

dev_stop(){
  for svc in ui api policy engine; do
    f="$PABAR_LOGS/$svc.pid"
    if [ -f "$f" ]; then
      log "Stopping $svc"
      kill "$(cat "$f")" || true
      rm -f "$f"
    fi
  done
  log "Stopped"
}

dev_status(){
  for svc in engine policy api ui; do
    f="$PABAR_LOGS/$svc.pid"
    if [ -f "$f" ] && ps -p "$(cat "$f")" >/dev/null; then
      echo "[✓] $svc running"
    else
      echo "[✗] $svc down"
    fi
  done
}

dev_health(){
  curl -fsS "http://localhost:$PABAR_API_PORT/health" && echo "API OK" || echo "API DOWN"
  [ -f "$PABAR_DATA/$PABAR_DB_NAME/manifest.json" ] && echo "DB OK" || echo "DB MISSING"
}

cmd="${1:-}"
case "$cmd" in
  dev-install) dev_install ;;
  dev-build) dev_build ;;
  dev-create-db) dev_create_db ;;
  dev-start) dev_start ;;
  dev-stop) dev_stop ;;
  dev-status) dev_status ;;
  dev-health) dev_health ;;
  ""|-h|--help) usage ;;
  *) echo "Unknown command: $cmd"; usage; exit 1 ;;
esac

