FROM mcr.microsoft.com/playwright:v1.50.0-noble

# Install Python + pip (pip is not available by default in this base)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install MCPO
RUN pip3 install --no-cache-dir mcpo

ENV PORT=8000
WORKDIR /app
EXPOSE 8000

CMD ["sh","-lc","mcpo --port 8000 --api-key \"$MCPO_API_KEY\" -- npx -y @playwright/mcp@latest"]
