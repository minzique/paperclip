#!/usr/bin/env bash
# seed-company.sh — Create "Augment" company with CEO + 3 ZeroClaw agents in Paperclip.
# Run after Paperclip is healthy: ./scripts/seed-company.sh [base_url]
#
# Org chart: CEO (minzi) → PM Agent, Sales Agent, Comms Agent
# All 3 agents use zeroclaw_local adapter with $5/day budget and 5-min heartbeat.
#
# Idempotent: creates missing entities, updates existing ones.
set -euo pipefail

BASE_URL="${1:-http://localhost:3100}"
API="${BASE_URL}/api"

# --- Budget & heartbeat config ---
# $5/day ≈ $150/month = 15000 cents
BUDGET_MONTHLY_CENTS=15000
HEARTBEAT_INTERVAL_SEC=300  # 5 minutes

# --- Helpers ---
json_field() {
  python3 -c "import sys, json; print(json.load(sys.stdin)$1)"
}

find_agent_by_name() {
  local company_id="$1" name="$2"
  curl -sf "${API}/companies/${company_id}/agents" | python3 -c "
import sys, json
agents = json.load(sys.stdin)
for a in agents:
    if a['name'] == '$name':
        print(a['id'])
        break
" 2>/dev/null || true
}

create_or_update_agent() {
  local company_id="$1" payload="$2" agent_name="$3"
  local existing_id
  existing_id=$(find_agent_by_name "$company_id" "$agent_name")

  if [ -n "$existing_id" ]; then
    echo "    Agent '${agent_name}' exists (${existing_id}), updating..."
    curl -sf -X PATCH "${API}/companies/${company_id}/agents/${existing_id}" \
      -H "Content-Type: application/json" \
      -d "$payload" | json_field "['id']"
  else
    echo "    Creating agent '${agent_name}'..."
    curl -sf -X POST "${API}/companies/${company_id}/agents" \
      -H "Content-Type: application/json" \
      -d "$payload" | json_field "['id']"
  fi
}

# --- 1. Wait for health ---
echo "==> Waiting for Paperclip health..."
for i in $(seq 1 30); do
  if curl -sf "${API}/health" > /dev/null 2>&1; then
    echo "    Paperclip is healthy."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "ERROR: Paperclip did not become healthy within 30s" >&2
    exit 1
  fi
  sleep 1
done

# --- 2. Get or create company ---
COMPANY_ID=$(curl -sf "${API}/companies" | python3 -c "
import sys, json
companies = json.load(sys.stdin)
for c in companies:
    if c['name'] == 'Augment':
        print(c['id'])
        break
" 2>/dev/null || true)

if [ -n "$COMPANY_ID" ]; then
  echo "==> Company 'Augment' already exists: ${COMPANY_ID}"
else
  echo "==> Creating company 'Augment'..."
  COMPANY_ID=$(curl -sf -X POST "${API}/companies" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Augment",
      "description": "Build and operate AI-powered hospitality and analytics products"
    }' | json_field "['id']")
  echo "    Company ID: ${COMPANY_ID}"
fi

# --- 3. Create or update CEO agent (minzi) ---
echo "==> Seeding CEO agent (minzi)..."
CEO_ID=$(create_or_update_agent "$COMPANY_ID" '{
  "name": "minzi",
  "role": "ceo",
  "title": "CEO",
  "adapterType": "process",
  "adapterConfig": {},
  "runtimeConfig": {},
  "capabilities": "Strategic direction, hiring, budget allocation, final approvals",
  "budgetMonthlyCents": 0
}' "minzi")
echo "    CEO ID: ${CEO_ID}"

# --- 4. Create or update PM Agent ---
echo "==> Seeding PM Agent..."
PM_ID=$(create_or_update_agent "$COMPANY_ID" "$(cat <<PAYLOAD
{
  "name": "PM Agent",
  "role": "pm",
  "title": "Product Manager",
  "reportsTo": "${CEO_ID}",
  "adapterType": "zeroclaw_local",
  "adapterConfig": {
    "command": "zeroclaw",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5",
    "timeoutSec": 600,
    "promptTemplate": "You are the PM Agent for Augment. {{context.wakeReason}}"
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": true,
      "intervalSec": ${HEARTBEAT_INTERVAL_SEC},
      "cooldownSec": 10,
      "wakeOnDemand": true,
      "wakeOnAssignment": true,
      "maxConcurrentRuns": 1
    }
  },
  "capabilities": "Product planning, issue triage, sprint management, stakeholder communication",
  "budgetMonthlyCents": ${BUDGET_MONTHLY_CENTS}
}
PAYLOAD
)" "PM Agent")
echo "    PM Agent ID: ${PM_ID}"

# --- 5. Create or update Sales Agent ---
echo "==> Seeding Sales Agent..."
SALES_ID=$(create_or_update_agent "$COMPANY_ID" "$(cat <<PAYLOAD
{
  "name": "Sales Agent",
  "role": "general",
  "title": "Sales Representative",
  "reportsTo": "${CEO_ID}",
  "adapterType": "zeroclaw_local",
  "adapterConfig": {
    "command": "zeroclaw",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5",
    "timeoutSec": 300,
    "promptTemplate": "You are the Sales Agent for Augment. {{context.wakeReason}}"
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": true,
      "intervalSec": ${HEARTBEAT_INTERVAL_SEC},
      "cooldownSec": 10,
      "wakeOnDemand": true,
      "wakeOnAssignment": true,
      "maxConcurrentRuns": 1
    }
  },
  "capabilities": "Lead qualification, outreach, pipeline management, proposal generation",
  "budgetMonthlyCents": ${BUDGET_MONTHLY_CENTS}
}
PAYLOAD
)" "Sales Agent")
echo "    Sales Agent ID: ${SALES_ID}"

# --- 6. Create or update Comms Agent ---
echo "==> Seeding Comms Agent..."
COMMS_ID=$(create_or_update_agent "$COMPANY_ID" "$(cat <<PAYLOAD
{
  "name": "Comms Agent",
  "role": "general",
  "title": "Communications Manager",
  "reportsTo": "${CEO_ID}",
  "adapterType": "zeroclaw_local",
  "adapterConfig": {
    "command": "zeroclaw",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5",
    "timeoutSec": 300,
    "promptTemplate": "You are the Comms Agent for Augment. {{context.wakeReason}}"
  },
  "runtimeConfig": {
    "heartbeat": {
      "enabled": true,
      "intervalSec": ${HEARTBEAT_INTERVAL_SEC},
      "cooldownSec": 10,
      "wakeOnDemand": true,
      "wakeOnAssignment": true,
      "maxConcurrentRuns": 1
    }
  },
  "capabilities": "Internal comms, status reports, Slack updates, stakeholder briefings",
  "budgetMonthlyCents": ${BUDGET_MONTHLY_CENTS}
}
PAYLOAD
)" "Comms Agent")
echo "    Comms Agent ID: ${COMMS_ID}"

# --- 7. Summary ---
echo ""
echo "==> Seed complete."
echo "    Company:  Augment (${COMPANY_ID})"
echo "    Org chart: CEO (minzi: ${CEO_ID})"
echo "               ├── PM Agent     (${PM_ID})"
echo "               ├── Sales Agent  (${SALES_ID})"
echo "               └── Comms Agent  (${COMMS_ID})"
echo "    Adapter:   zeroclaw_local"
echo "    Budget:    \$5/day (${BUDGET_MONTHLY_CENTS} cents/month per agent)"
echo "    Heartbeat: ${HEARTBEAT_INTERVAL_SEC}s (5 minutes)"
echo "    Dashboard: ${BASE_URL}"
