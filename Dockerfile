FROM mcr.microsoft.com/playwright:v1.50.0-noble

# 1) Install Google Chrome (system browser for "chrome" channel)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg ca-certificates \
  && wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor \
     > /usr/share/keyrings/google-linux-signing-keyring.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
     > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
  && rm -rf /var/lib/apt/lists/*

# Playwright MCP error expects this exact path:
# /opt/google/chrome/chrome
RUN ln -sf /opt/google/chrome/google-chrome /opt/google/chrome/chrome

# 2) Install Python + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# 3) Install MCPO into a venv (avoids "externally managed environment" issues)
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir mcpo

ENV PORT=8000
WORKDIR /app
EXPOSE 8000

# 4) Run MCPO and launch Playwright MCP using the Chrome channel
CMD ["sh","-lc","export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright; export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1; /opt/venv/bin/mcpo --port 8000 --api-key \"$MCPO_API_KEY\" -- npx -y @playwright/mcp@latest --browser firefox --headless --timeout-navigation 180000 --timeout-action 30000"]




