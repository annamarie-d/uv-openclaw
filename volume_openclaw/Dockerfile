FROM debian:bookworm-slim

# 1. Install core system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    procps \
    build-essential \
    gnupg \
    ca-certificates \
    jq \
    vim \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. Install GH CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 4. Install OpenClaw
# We allow it to fail the TTY check at the end but ensure the install completes
RUN export NO_ONBOARD=1 && \
    export OPENCLAW_NO_PROMPT=1 && \
    (curl -fsSL https://openclaw.ai/install.sh | bash || true)

# 5. Aggressive Memory Optimization: Remove bulky/unused extensions after install
RUN rm -rf /usr/lib/node_modules/openclaw/extensions/memory-lancedb && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/discord && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/slack && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/telegram && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/whatsapp && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/signal && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/msteams && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/matrix && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/feishu && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/googlechat && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/line && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/mattermost && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/nextcloud-talk && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/nostr && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/synology-chat && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/twitch && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/zalo && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/zalouser && \
    rm -rf /usr/lib/node_modules/openclaw/extensions/tlon

# 6. Install uv (with explicit path)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 7. Install Opencode
RUN curl -fsSL https://opencode.ai/install | bash

# 8. Setup user and environment
RUN mkdir -p /home/node/.openclaw
ENV HOME=/home/node
ENV NO_ONBOARD=1
ENV OPENCLAW_NO_PROMPT=1
ENV TERM=xterm-256color
# Add all possible OpenClaw/uv/opencode paths to PATH
ENV PATH=$PATH:/root/.openclaw/bin:/home/node/.openclaw/bin:/root/.opencode/bin:/root/.cargo/bin:/root/.local/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /home/node
EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
