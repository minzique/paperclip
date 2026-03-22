---
name: exa-search
description: >
  Exa web search API for structured web research. Use when you need to search
  the web, research companies, find news, or gather structured information from
  the internet. Provides a CLI wrapper with rate limiting.
---

# Exa Search

Web search via the Exa API. Returns clean, structured content from search results — no scraping needed.

## CLI Usage

```bash
# Basic web search
EXA_API_KEY=... bun run scripts/search.ts "query"

# With options
EXA_API_KEY=... bun run scripts/search.ts "query" --type web --limit 5
EXA_API_KEY=... bun run scripts/search.ts "query" --type news --limit 10
```

### Search Types

| Type | Use Case |
|------|----------|
| `web` | General web search (default) |
| `news` | Recent news articles |

### Arguments

| Flag | Default | Description |
|------|---------|-------------|
| `--type` | `web` | Search type: `web`, `news` |
| `--limit` | `5` | Number of results to return |

## Rate Limits

**Hard limit: 5 requests per second.** Never exceed this.

- Space requests at least 200ms apart in batch operations
- For bulk research, collect all queries first, then execute sequentially with delays
- If rate-limited (429), back off exponentially starting at 1 second

## Output Format

Results are JSON with this structure:

```json
{
  "results": [
    {
      "title": "Page Title",
      "url": "https://example.com/page",
      "text": "Extracted page content...",
      "publishedDate": "2026-03-15",
      "author": "Author Name"
    }
  ]
}
```

## Use Cases

### Web Research

```bash
bun run scripts/search.ts "Paperclip AI agent orchestration platform"
```

### Company Research

```bash
bun run scripts/search.ts "company: Linear app project management features" --limit 10
```

### News Monitoring

```bash
bun run scripts/search.ts "AI agent frameworks news 2026" --type news --limit 10
```

### Competitive Analysis

```bash
bun run scripts/search.ts "AI ops agent platforms comparison" --limit 8
```

## Constraints

- Always format results as structured output (JSON or markdown tables)
- Never exceed 5 req/sec rate limit
- Prefer targeted queries over broad ones — Exa returns better results with specific queries
- Include date qualifiers for time-sensitive searches
- `EXA_API_KEY` must be set in environment — never hardcode or expose it

## Environment

| Variable | Required | Description |
|----------|----------|-------------|
| `EXA_API_KEY` | Yes | Exa API key for authentication |
