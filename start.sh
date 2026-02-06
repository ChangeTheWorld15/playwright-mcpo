#!/usr/bin/env sh
set -eu

# Display settings
export DISPLAY=${DISPLAY:-:99}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime}
mkdir -p "$XDG_RUNTIME_DIR"

# Start virtual X server
Xvfb "$DISPLAY" -screen 0 1920x1080x24 -ac +extension RANDR +render -noreset &
XVFB_PID=$!

# Minimal window manager
fluxbox >/tmp/fluxbox.log 2>&1 &
FLUX_PID=$!

# VNC server (passwordless on localhost; noVNC provides web access)
x11vnc -display "$DISPLAY" -forever -shared -nopw -rfbport 5900 >/tmp/x11vnc.log 2>&1 &
VNC_PID=$!

# noVNC web proxy
# Serves web client on :6080
websockify --web=/usr/share/novnc/ 0.0.0.0:6080 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &
NOVNC_PID=$!

echo "noVNC running on :6080 (DISPLAY=$DISPLAY)"

# Start MCPO -> Playwright MCP
exec /opt/venv/bin/mcpo --port 8000 --api-key "${MCPO_API_KEY}" -- \
  npx -y @playwright/mcp@0.0.63 --browser firefox --headless=false --user-data-dir /data/profile
