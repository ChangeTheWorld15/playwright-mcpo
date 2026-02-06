#!/usr/bin/env sh
set -eu

export DISPLAY=${DISPLAY:-:99}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime}
mkdir -p "$XDG_RUNTIME_DIR"

Xvfb "$DISPLAY" -screen 0 1920x1080x24 -ac +extension RANDR +render -noreset >/tmp/xvfb.log 2>&1 &
fluxbox >/tmp/fluxbox.log 2>&1 &

x11vnc -display "$DISPLAY" -forever -shared -nopw -rfbport 5900 >/tmp/x11vnc.log 2>&1 &

# Use the novnc launcher (sets the correct websocket endpoint for vnc.html)
(/usr/bin/novnc --listen 6080 --vnc 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &) || true

echo "noVNC should be available at http://<host>:6080/vnc.html"

exec /opt/venv/bin/mcpo --port 8000 --api-key "${MCPO_API_KEY}" -- \
  npx -y @playwright/mcp@0.0.63 --browser firefox --headless=false --user-data-dir /data/profile
