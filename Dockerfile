FROM mcr.microsoft.com/playwright:v1.50.0-noble

# --- System deps for python/venv + tools ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# --- Install MCPO in a venv (avoids PEP 668 issues) ---
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir mcpo

# --- Install the *matching* Playwright version for @playwright/mcp@0.0.63 ---
# 1) Ask npm what playwright version MCP depends on
# 2) Install that playwright version
# 3) Install Firefox browser binaries into /ms-playwright
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN set -eux; \
    PW_VER="$(npm view @playwright/mcp@0.0.63 dependencies.playwright)"; \
    echo "MCP expects playwright version: ${PW_VER}"; \
    npm -g install "playwright@${PW_VER}"; \
    playwright install firefox

ENV PORT=8000
WORKDIR /app
EXPOSE 8000

# Run MCPO and launch Playwright MCP (pinned)
CMD ["sh","-lc","/opt/venv/bin/mcpo --port 8000 --api-key \"$MCPO_API_KEY\" -- npx -y @playwright/mcp@0.0.63"]
