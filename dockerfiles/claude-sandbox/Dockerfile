FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y curl gnupg git ripgrep && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm config set prefix /usr/local && \
    npm install -g @anthropic-ai/claude-code && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV CLAUDE_CONFIG_DIR=/root/.claude
WORKDIR /workspace
CMD ["claude"]

