#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

STATE_DIR=".launcher"
LOG_FILE="$STATE_DIR/mandel.log"
PID_FILE="$STATE_DIR/mandel.pid"
URL_FILE="$STATE_DIR/url.txt"
mkdir -p "$STATE_DIR"

HOST="127.0.0.1"
DEFAULT_PORT="3000"
PORT="$DEFAULT_PORT"

pick_port() {
  python - "$1" <<'PY'
import socket, sys
port = int(sys.argv[1])
while True:
    sock = socket.socket()
    try:
        sock.bind(('127.0.0.1', port))
        sock.close()
        print(port)
        break
    except OSError:
        port += 1
PY
}

wait_for_url() {
  python - "$1" <<'PY'
import sys, time, urllib.request
url = sys.argv[1]
for _ in range(120):
    try:
        with urllib.request.urlopen(url, timeout=2):
            print(url)
            sys.exit(0)
    except Exception:
        time.sleep(2)
sys.exit(1)
PY
}

echo

echo "=== MANDEL // SIGNAL AQUARIUM ==="
echo

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Mandel already looks alive."
  if [[ -f "$URL_FILE" ]]; then
    URL="$(cat "$URL_FILE")"
    if command -v open >/dev/null 2>&1; then open "$URL"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL"; fi
  fi
  exit 0
fi

if [[ -f package.json && ( -f vite.config.ts || -f vite.config.js || -f vite.config.mts || -f vite.config.mjs ) ]]; then
  command -v node >/dev/null 2>&1 || { echo "Node.js is required."; exit 1; }
  command -v npm >/dev/null 2>&1 || { echo "npm is required."; exit 1; }
  PORT="$(pick_port "$DEFAULT_PORT")"
  URL="http://$HOST:$PORT"
  echo "$URL" > "$URL_FILE"
  if [[ ! -d node_modules ]]; then
    if [[ -f package-lock.json ]]; then npm ci; else npm install; fi
  fi
  echo "Starting Mandel at $URL"
  WM_HOST="$HOST" WM_PORT="$PORT" WM_AUTO_OPEN_BROWSER=false BROWSER=none npm run dev > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  if wait_for_url "$URL" >/dev/null; then
    if command -v open >/dev/null 2>&1; then open "$URL"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL"; fi
    echo "Mandel is ready at $URL"
    exit 0
  fi
  echo "Mandel did not answer in time. See $LOG_FILE"
  exit 1
fi

echo "This launcher could not find a safe startup path for this folder."
exit 1
