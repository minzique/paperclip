# Messaging Bridge

Send notifications and read conversations across Slack and WhatsApp via the unified messaging bridge.

## Security Model

- **WhatsApp is owner-only**: the bridge can ONLY send WhatsApp messages to the configured owner. It cannot message your contacts. This is enforced server-side — there is no bypass.
- **Slack**: can send to any channel the bot is in.
- **All endpoints require** `BRIDGE_API_TOKEN` bearer auth.

## Environment

The bridge runs at `BRIDGE_API_URL` (default: `http://messaging-bridge:3200` inside Docker).

```bash
export BRIDGE_URL="${BRIDGE_API_URL:-http://messaging-bridge:3200}"
export BRIDGE_TOKEN="${BRIDGE_API_TOKEN}"
```

## Send a Notification to Owner

Use this when you need to alert minzi about something — task completion, approval needed, errors, status updates.

```bash
curl -s -X POST "$BRIDGE_URL/notify" \
  -H "Authorization: Bearer $BRIDGE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "Your message here", "priority": "normal"}'
```

Priority `"urgent"` sends to ALL configured channels (Slack + WhatsApp).
Priority `"normal"` uses the configured default channel.

## Send to a Specific Slack Channel

```bash
curl -s -X POST "$BRIDGE_URL/send" \
  -H "Authorization: Bearer $BRIDGE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"platform": "slack", "to": "C09SLB47JG4", "text": "Message text"}'
```

## Send to Owner via WhatsApp

```bash
curl -s -X POST "$BRIDGE_URL/send" \
  -H "Authorization: Bearer $BRIDGE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"platform": "whatsapp", "text": "Message text"}'
```

Note: the `to` field is ignored for WhatsApp — it always sends to the owner.

## List Active Conversations

```bash
curl -s "$BRIDGE_URL/conversations" \
  -H "Authorization: Bearer $BRIDGE_TOKEN"
```

Returns an array of `{ key, platform, channelId, issueId, createdAt, commentCount }`.

## Read Conversation Messages

```bash
curl -s "$BRIDGE_URL/conversations/$(echo -n 'slack:C09SLB47JG4:1234567890' | jq -sRr @uri)/messages" \
  -H "Authorization: Bearer $BRIDGE_TOKEN"
```

Returns `{ platform, issueId, messages: [{ id, body, authorAgentId, createdAt }] }`.

## Check Bridge Health

```bash
curl -s "$BRIDGE_URL/health"
```

Returns `{ status, slack, whatsapp, activeThreads }`.

## When to Use

- **Task completed**: notify owner with summary
- **Approval needed**: notify with context + options
- **Error/blocker**: urgent notify
- **Status update**: post to Slack channel
- **Read context**: list conversations to understand what's being discussed
