#!/usr/bin/env bash
set -e

if [ -f .env ]; then
  set -a; source .env; set +a
fi

MARKER="/app/.node_modules_installed"
if [ ! -f "$MARKER" ]; then
  echo "==> First run: cleaning host node_modules and reinstalling..."
  find /app -name "node_modules" -type d -maxdepth 3 -exec rm -rf {} + 2>/dev/null || true
  pnpm install
  touch "$MARKER"
else
  echo "==> Dependencies already installed, skipping..."
fi

# Ensure opencode + gh CLI are available for agents
if ! command -v opencode &>/dev/null; then
  echo "==> Installing opencode..."
  npm install -g opencode-ai
fi
if ! command -v gh &>/dev/null; then
  echo "==> Installing gh CLI..."
  apt-get update -qq && apt-get install -y -qq gh 2>/dev/null || echo "gh install skipped (not root)"
fi

# Ensure agent home dirs are writable
mkdir -p "$HOME/.claude/skills" 2>/dev/null || true

echo "==> Starting Paperclip on port ${PORT:-3100}..."
exec pnpm dev:once
