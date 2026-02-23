#!/bin/sh
set -e

# Increase file descriptor limit
ulimit -n 65535 2>/dev/null || true

# Ensure directory structure exists
mkdir -p /home/node/.openclaw
mkdir -p /home/node/.opencode

# 1. Initialize or Reset configuration
if [ ! -f /home/node/.openclaw/openclaw.json ] || [ "${OPENCLAW_OVERRIDE_CONFIG}" = "true" ]; then
    echo "Writing full OpenClaw configuration..."
    
    # We write the full JSON manually to bypass v2026 CLI hangs (142% CPU)
    # and to ensure a perfect meta-tagged config that satisfies the gateway.
    # The Antigravity extension is removed in the Dockerfile.
    
    cat <<EOF > /home/node/.openclaw/openclaw.json
{
  "meta": {
    "lastTouchedVersion": "2026.2.22-2",
    "lastTouchedAt": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"
  },
  "browser": {
    "cdpUrl": "${BROWSERLESS_BASE_URL}"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "${DEFAULT_MODEL_PROVIDER}": {
        "baseUrl": "${OPENAI_API_BASE}",
        "apiKey": "${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "${OPENAI_DEFAULT_MODEL}",
            "name": "${OPENAI_DEFAULT_MODEL} (Custom)",
            "contextWindow": ${OPENAI_DEFAULT_MODEL_CONTEXT_WINDOW:-262144},
            "maxTokens": ${OPENAI_DEFAULT_MODEL_MAX_TOKENS:-8192}
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}"
      },
      "models": {
        "${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}": {
          "alias": "primary-model"
        }
      },
      "workspace": "/home/node/.openclaw/workspace"
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": true,
    "ownerDisplay": "raw"
  },
  "gateway": {
    "port": ${OPENCLAW_GATEWAY_PORT},
    "mode": "local",
    "bind": "${OPENCLAW_GATEWAY_BIND}",
    "controlUi": {
      "allowInsecureAuth": ${OPENCLAW_GATEWAY_ALLOW_INSECURE_AUTH},
      "dangerouslyDisableDeviceAuth": ${OPENCLAW_GATEWAY_DANGEROUSLY_DISABLE_DEVICE_AUTH}
    },
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    }
  },
  "plugins": {
    "entries": {
      "google-antigravity-auth": {
        "enabled": false
      }
    }
  },
  "wizard": {
    "lastRunAt": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
    "lastRunVersion": "2026.2.22-2",
    "lastRunCommand": "onboard",
    "lastRunMode": "local"
  }
}
EOF
    echo "Configuration written manually with metadata."
else
    echo "Using existing OpenClaw configuration."
fi

# Ensure Opencode is also configured (fallback)
if [ ! -f /home/node/.env ]; then
    echo "Generating Opencode fallback .env..."
    cat <<EOF > /home/node/.env
OPENAI_API_KEY=${OPENAI_API_KEY}
OPENAI_API_BASE=${OPENAI_API_BASE}
OPENAI_MODEL=${OPENAI_DEFAULT_MODEL}
EOF
fi

echo "Starting OpenClaw gateway in non-interactive mode..."
export NO_ONBOARD=1
export OPENCLAW_NO_PROMPT=1
export CI=true

# Final safety: use redirection to close any zombie prompts
exec openclaw gateway run < /dev/null

