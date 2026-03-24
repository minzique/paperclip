# Messaging Bridge

Send notifications and query Slack/WhatsApp via the unified messaging bridge.

## Security Model

- **WhatsApp**: owner-only sends, enforced server-side
- **Slack /send**: only channels with active conversation threads
- **All endpoints require** `BRIDGE_API_TOKEN` bearer auth (except `/health`)

## Environment

```bash
export BRIDGE_URL="${BRIDGE_API_URL:-http://messaging-bridge:3200}"
export BRIDGE_TOKEN="${BRIDGE_API_TOKEN}"
AUTH="-H 'Authorization: Bearer $BRIDGE_TOKEN'"
```

## Notify Owner

```bash
curl -s -X POST "$BRIDGE_URL/notify" $AUTH \
  -H "Content-Type: application/json" \
  -d '{"text": "Your message here", "priority": "normal"}'
```

`"priority": "urgent"` sends to ALL channels (Slack + WhatsApp).

## Query Slack

### List channels the bot is in

```bash
curl -s "$BRIDGE_URL/slack/channels" $AUTH
```

### Get channel history (last N messages)

```bash
curl -s "$BRIDGE_URL/slack/channels/CHANNEL_ID/history?limit=20" $AUTH
# Pagination: &latest=TIMESTAMP or &oldest=TIMESTAMP
```

### Get a thread

```bash
curl -s "$BRIDGE_URL/slack/channels/CHANNEL_ID/threads/THREAD_TS?limit=50" $AUTH
```

All query responses return `[{ ts, time, sender, text, ... }]`.

## Send to Active Slack Thread

```bash
curl -s -X POST "$BRIDGE_URL/send" $AUTH \
  -H "Content-Type: application/json" \
  -d '{"platform": "slack", "to": "CHANNEL_ID", "text": "Message"}'
```

Only works for channels with active conversation threads.

## Send to Owner via WhatsApp

```bash
curl -s -X POST "$BRIDGE_URL/send" $AUTH \
  -H "Content-Type: application/json" \
  -d '{"platform": "whatsapp", "text": "Message"}'
```

`to` field is ignored — always routes to owner.

## List Active Conversations

```bash
curl -s "$BRIDGE_URL/conversations" $AUTH
```

## Read Conversation Messages

```bash
curl -s "$BRIDGE_URL/conversations/ENCODED_KEY/messages" $AUTH
```

## When to Use

- **Need context**: query channel history or search messages before answering
- **Task completed**: notify owner
- **Approval needed**: notify with context
- **Error/blocker**: urgent notify
- **Read Slack**: search or browse channel history for information
