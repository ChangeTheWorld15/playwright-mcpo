# Use the official Playwright base image (includes browsers + deps)
FROM mcr.microsoft.com/playwright:v1.58.1-noble

# Install Python + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install MCPO into a venv (avoids system python packaging issues)
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir mcpo

WORKDIR /app
EXPOSE 8000

# Run MCPO and attach Playwright MCP over stdio
# Playwright MCP supports args like --headless --browser chromium and also documents docker usage with these flags.  [oai_citation:3‡GitHub](https://github.com/microsoft/playwright-mcp)
CMD ["sh","-lc", "\
  /opt/venv/bin/mcpo --host 0.0.0.0 --port 8000 --api-key \"$MCPO_API_KEY\" -- \
  npx -y @playwright/mcp@latest --browser firefox --headless --no-sandbox --user-data-dir /data/profile \
"]
