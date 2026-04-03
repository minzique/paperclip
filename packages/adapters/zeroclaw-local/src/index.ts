export const type = "zeroclaw_local";
export const label = "ZeroClaw (local)";

export const models = [
  { id: "claude-sonnet-4-5", label: "Claude Sonnet 4.5" },
  { id: "claude-opus-4-6", label: "Claude Opus 4.6" },
  { id: "claude-sonnet-4-6", label: "Claude Sonnet 4.6" },
  { id: "claude-haiku-4-6", label: "Claude Haiku 4.6" },
];

export const agentConfigurationDoc = `# zeroclaw_local agent configuration

Adapter: zeroclaw_local

Core fields:
- command (string, optional): defaults to "zeroclaw"
- cwd (string, optional): default absolute working directory for the agent process (created if missing)
- provider (string, optional): LLM provider name passed via --provider (default "anthropic")
- model (string, optional): model id passed via --model
- promptTemplate (string, optional): run prompt template
- env (object, optional): KEY=VALUE environment variables

Operational fields:
- timeoutSec (number, optional): run timeout in seconds (default 300)
- graceSec (number, optional): SIGTERM grace period in seconds (default 20)

Notes:
- ZeroClaw manages its own sessions internally.
- Set ANTHROPIC_API_KEY in env for Anthropic provider auth.
- Paperclip injects PAPERCLIP_* env vars automatically.
`;
