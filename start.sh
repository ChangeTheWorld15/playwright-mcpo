#!/usr/bin/env sh
set -eu

export DISPLAY=${DISPLAY:-:99}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime}
mkdir -p "$XDG_RUNTIME_DIR"

# Start virtual X server
Xvfb "$DISPLAY" -screen 0 1920x1080x24 -ac +extension RANDR +render -noreset &
# Minimal window manager
fluxbox >/tmp/fluxbox.log 2>&1 &
# VNC server
x11vnc -display "$DISPLAY" -forever -shared -nopw -rfbport 5900 >/tmp/x11vnc.log 2>&1 &
# noVNC web proxy
websockify --web=/usr/share/novnc/ 0.0.0.0:6080 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &

echo "noVNC running on :6080 (DISPLAY=$DISPLAY)"

# Launch MCPO -> Playwright MCP (headful for interactive login)
exec /opt/venv/bin/mcpo --port 8000 --api-key "${MCPO_API_KEY}" -- \
  npx -y @playwright/mcp@0.0.63 --browser firefox --headless=false --user-data-dir /data/profile
