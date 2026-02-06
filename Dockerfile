FROM mcr.microsoft.com/playwright:v1.58.1-noble

# Install Python + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install MCPO into a venv (avoids PEP 668 issues)
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir mcpo

ENV PORT=8000
WORKDIR /app

# Install Playwright JS library locally so Node can import it (for scripts/tools)
RUN npm init -y \
  && npm install --omit=dev playwright

# noVNC + minimal desktop for one-time interactive SSO login
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb fluxbox x11vnc novnc websockify \
  && rm -rf /var/lib/apt/lists/*

# --- Keep your cookie files in repo for now (won't be used in noVNC login phase) ---
# If you still want it available, keep this; otherwise you can remove later.
COPY import-cookies.mjs /app/import-cookies.mjs

# Start script that launches Xvfb + noVNC + MCPO->Playwright MCP
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8000 6080 5900

CMD ["/app/start.sh"]
