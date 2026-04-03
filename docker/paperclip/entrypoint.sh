#!/bin/sh
# Bootstrap pi config and runtime dirs, then drop to node user.
set -e

# Fix ownership of volume dirs that may have been created as root
chown -R node:node /paperclip/.pi 2>/dev/null || true
chown -R node:node /home/node/.pi 2>/dev/null || true

# Create dirs and seed config
for base in /paperclip/.pi /home/node/.pi; do
  mkdir -p "$base/agent/sessions" "$base/agent/skills" "$base/paperclips"
  # Seed settings.json if missing or empty
  if [ ! -s "$base/agent/settings.json" ]; then
    cp /app/config/pi/settings.json "$base/agent/settings.json"
  fi
  chown -R node:node "$base"
done

# Opencode dirs (legacy)
mkdir -p /home/node/.local/share/opencode/log \
         /home/node/.local/state \
         /home/node/.config/opencode \
         /home/node/.claude \
         /home/node/.cache/opencode
chown -R node:node /home/node/.local /home/node/.config /home/node/.claude /home/node/.cache 2>/dev/null || true

# Source Claude OAuth token if available (written by token-refresh sidecar)
if [ -f /run/claude-token/env ]; then
  export $(cat /run/claude-token/env | xargs)
  echo "[entrypoint] Loaded ANTHROPIC_OAUTH_TOKEN from token-refresh sidecar"
fi

# Drop to node and exec
exec gosu node "$@"
