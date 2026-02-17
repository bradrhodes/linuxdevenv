FROM ubuntu:24.04

# Install Node.js 20+ and deps (Codex requires Node 18+)
RUN apt-get update && \
    apt-get install -y curl gnupg git && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @openai/codex && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /workspace
CMD ["codex"]

