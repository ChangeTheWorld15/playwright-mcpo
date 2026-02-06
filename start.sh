#!/usr/bin/env sh
set -u

export DISPLAY=${DISPLAY:-:99}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime}
mkdir -p "$XDG_RUNTIME_DIR"

# Start X + WM
Xvfb "$DISPLAY" -screen 0 1920x1080x24 -ac +extension RANDR +render -noreset >/tmp/xvfb.log 2>&1 &
fluxbox >/tmp/fluxbox.log 2>&1 &

# Start VNC
x11vnc -display "$DISPLAY" -forever -shared -nopw -rfbport 5900 >/tmp/x11vnc.log 2>&1 &

# Start noVNC (try common launchers)
if command -v novnc >/dev/null 2>&1; then
  novnc --listen 6080 --vnc 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &
elif command -v novnc_proxy >/dev/null 2>&1; then
  novnc_proxy --listen 6080 --vnc 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &
elif command -v websockify >/dev/null 2>&1; then
  websockify --web=/usr/share/novnc/ 0.0.0.0:6080 127.0.0.1:5900 >/tmp/novnc.log 2>&1 &
else
  echo "No noVNC launcher found. Install novnc/websockify." >&2
fi

echo "noVNC: http://<host>:6080/vnc.html"

# Start MCPO -> Playwright MCP (IMPORTANT: use --headed, not --headless=false)
exec /opt/venv/bin/mcpo --host 0.0.0.0 --port 8000 --api-key "${MCPO_API_KEY}" -- \
  npx -y @playwright/mcp@0.0.63 --browser firefox --headed --user-data-dir /data/profile
