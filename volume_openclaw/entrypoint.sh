#!/bin/sh
set -e

# Increase file descriptor limit
ulimit -n 65535 2>/dev/null || true

# Ensure directory structure exists
mkdir -p /home/node/.openclaw
mkdir -p /home/node/.opencode

# Helper function to set config values
set_config() {
    path="$1"
    value="$2"
    echo "Setting config $path to $value..."
    openclaw config set "$path" "$value" || echo "Failed to set $path"
}

# 1. Bootstrap openclaw.json using official CLI
if [ ! -f /home/node/.openclaw/openclaw.json ] || [ "${OPENCLAW_OVERRIDE_CONFIG}" = "true" ]; then
    echo "Bootstrapping OpenClaw configuration via CLI..."
    
    # Run a minimal non-interactive onboarding to generate a valid config with metadata
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice custom-api-key \
      --custom-compatibility openai \
      --custom-base-url "${OPENAI_API_BASE}" \
      --custom-api-key "${OPENAI_API_KEY}" \
      --custom-model-id "${OPENAI_DEFAULT_MODEL}" \
      --gateway-port ${OPENCLAW_GATEWAY_PORT} \
      --gateway-bind ${OPENCLAW_GATEWAY_BIND} \
      --workspace "/home/node/.openclaw/workspace" \
      --skip-skills \
      --accept-risk || echo "Onboarding finished (gateway connection warning ignored)."

    # 2. Fine-tune configuration with granular overrides
    echo "Applying fine-tuned overrides..."
    
    # Gateway settings
    set_config "gateway.auth.token" "${OPENCLAW_GATEWAY_TOKEN}"
    set_config "gateway.auth.mode" "token"
    set_config "gateway.controlUi.allowInsecureAuth" "${OPENCLAW_GATEWAY_ALLOW_INSECURE_AUTH}"
    set_config "gateway.controlUi.dangerouslyDisableDeviceAuth" "${OPENCLAW_GATEWAY_DANGEROUSLY_DISABLE_DEVICE_AUTH}"
    
    # Model configuration (Merge mode)
    set_config "models.mode" "merge"
    
    # Custom model provider setup
    openclaw config set "models.providers.${DEFAULT_MODEL_PROVIDER}" "{
        \"baseUrl\": \"${OPENAI_API_BASE}\",
        \"apiKey\": \"${OPENAI_API_KEY}\",
        \"api\": \"openai-completions\",
        \"models\": [{
            \"id\": \"${OPENAI_DEFAULT_MODEL}\",
            \"name\": \"${OPENAI_DEFAULT_MODEL} (Custom)\",
            \"contextWindow\": ${OPENAI_DEFAULT_MODEL_CONTEXT_WINDOW:-262144},
            \"maxTokens\": ${OPENAI_DEFAULT_MODEL_MAX_TOKENS:-8192}
        }]
    }"

    # Set agents primary model
    set_config "agents.defaults.model.primary" "${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}"
    set_config "agents.defaults.models.${DEFAULT_MODEL_PROVIDER}/${OPENAI_DEFAULT_MODEL}" "{\"alias\":\"primary-model\"}"
    
    # Browser control
    set_config "browser.cdpUrl" "${BROWSERLESS_BASE_URL}"
    
    # 3. FORCE BYPASS Skills Onboarding
    set_config "skills.setupCompleted" "true"
    set_config "onboarded" "true"

    echo "Configuration generated and meta-tagged."
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

# Final sanity check: if gateway still prompts, /dev/null will close it
exec openclaw gateway run < /dev/null
