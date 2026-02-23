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

# 2. Install Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
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

# 5. [DEPRECATED] Aggressive Memory Optimization: Removed as per user request
# Extensions are now preserved.

# 6. Install uv (with explicit path)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 7. Install Opencode
RUN curl -fsSL https://opencode.ai/install | bash

# 8. Setup user and environment
RUN mkdir -p /home/node/.openclaw
ENV HOME=/home/node
ENV NO_ONBOARD=1
ENV OPENCLAW_NO_PROMPT=1
ENV CI=true
ENV TERM=xterm-256color
# Add all possible OpenClaw/uv/opencode paths to PATH
ENV PATH=$PATH:/root/.openclaw/bin:/home/node/.openclaw/bin:/root/.opencode/bin:/root/.cargo/bin:/root/.local/bin

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /home/node
EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
