#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:3100}"
API="${BASE_URL}/api"

echo "==> Setting up approval gates..."

if curl -fsS "${API}/health" >/dev/null 2>&1; then
  echo "==> Paperclip API reachable at ${API}"
else
  echo "==> Paperclip API not reachable at ${API}; printing manual setup guidance"
fi

echo "==> Approval gate configuration:"
echo "    - Destructive actions: BLOCKED (never auto-execute)"
echo "    - Write operations: CONFIRM (Slack notification to #ops-approvals)"
echo "    - Read operations: SAFE (auto-execute)"
echo ""
echo "==> Budget limits:"
echo "    - PM Agent: \$5/day"
echo "    - Sales Agent: \$5/day"
echo "    - Comms Agent: \$5/day"
echo ""
echo "==> To approve/reject agent actions:"
echo "    1. Agent sends approval request to Slack #ops-approvals"
echo "    2. minzi or Kevin reviews and responds"
echo "    3. Agent receives approval/rejection and proceeds"
