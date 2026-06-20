#!/bin/sh
# Bootstrap Pi runtime dirs/config, support Paperclip UID/GID remapping, then exec.
set -e

PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

seed_pi_config() {
  for base in /paperclip/.pi /home/node/.pi; do
    mkdir -p "$base/agent/sessions" "$base/agent/skills" "$base/paperclips"
    if [ ! -s "$base/agent/settings.json" ]; then
      cp /app/config/pi/settings.json "$base/agent/settings.json"
    fi
  done

  mkdir -p /home/node/.local/share/opencode/log \
           /home/node/.local/state \
           /home/node/.config/opencode \
           /home/node/.claude \
           /home/node/.cache/opencode
}

if [ "$(id -u)" -ne 0 ]; then
  if [ "$(id -u)" -ne "$PUID" ] || [ "$(id -g)" -ne "$PGID" ]; then
    echo "entrypoint.sh: running unprivileged as $(id -u):$(id -g); cannot remap to requested ${PUID}:${PGID}" >&2
  fi
  seed_pi_config 2>/dev/null || true
  exec "$@"
fi

changed=0
if [ "$(id -u node)" -ne "$PUID" ]; then
  echo "Updating node UID to $PUID"
  usermod -o -u "$PUID" node
  changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
  echo "Updating node GID to $PGID"
  groupmod -o -g "$PGID" node
  usermod -g "$PGID" node
  changed=1
fi

seed_pi_config

# Ensure runtime volume and known tool homes are writable by the node user.
if [ "$changed" = "1" ]; then
  chown -R node:node /paperclip
else
  chown -R node:node /paperclip/.pi /home/node/.pi 2>/dev/null || true
fi
chown -R node:node /home/node/.local /home/node/.config /home/node/.claude /home/node/.cache 2>/dev/null || true

if [ -f /run/claude-token/env ]; then
  # shellcheck disable=SC2046
  export $(cat /run/claude-token/env | xargs)
  echo "[entrypoint] Loaded ANTHROPIC_OAUTH_TOKEN from token-refresh sidecar"
fi

exec gosu node "$@"
