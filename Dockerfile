FROM mcr.microsoft.com/playwright:v1.50.0-noble

# Install Python + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install MCPO into a venv (avoids "externally managed environment" issues)
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir mcpo

ENV PORT=8000
WORKDIR /app
EXPOSE 8000

# MCPO wraps Playwright MCP (pinned version for stability)
CMD ["sh","-lc","/opt/venv/bin/mcpo --port 8000 --api-key \"$MCPO_API_KEY\" -- npx -y @playwright/mcp@0.0.63"]
