FROM mcr.microsoft.com/playwright:v1.50.0-noble

# Python + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Create a venv and install mcpo into it (avoids PEP 668 issues)
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir mcpo

ENV PORT=8000
WORKDIR /app
EXPOSE 8000

# Use the venv mcpo binary
CMD ["sh","-lc","/opt/venv/bin/mcpo --port 8000 --api-key \"$MCPO_API_KEY\" -- npx -y @playwright/mcp@latest --browser firefox"]


