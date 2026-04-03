import type {
  AdapterExecutionContext,
  AdapterExecutionResult,
} from "@paperclipai/adapter-utils";
import {
  asString,
  asNumber,
  buildPaperclipEnv,
  runChildProcess,
  ensureAbsoluteDirectory,
  ensureCommandResolvable,
  ensurePathInEnv,
  redactEnvForLogs,
  renderTemplate,
  parseObject,
} from "@paperclipai/adapter-utils/server-utils";

export async function execute(
  ctx: AdapterExecutionContext,
): Promise<AdapterExecutionResult> {
  const { runId, agent, config, context, onLog, onMeta, onSpawn, authToken } =
    ctx;

  const command = asString(config.command, "zeroclaw");
  const configuredCwd = asString(config.cwd, "");
  const cwd = configuredCwd || process.cwd();
  await ensureAbsoluteDirectory(cwd, { createIfMissing: true });

  const timeoutSec = asNumber(config.timeoutSec, 300);
  const graceSec = asNumber(config.graceSec, 20);
  const provider = asString(config.provider, "anthropic");
  const model = asString(config.model, "claude-sonnet-4-5");

  const envConfig = parseObject(config.env);
  const env: Record<string, string> = { ...buildPaperclipEnv(agent) };
  env.PAPERCLIP_RUN_ID = runId;

  const wakeTaskId =
    (typeof context.taskId === "string" &&
      context.taskId.trim().length > 0 &&
      context.taskId.trim()) ||
    (typeof context.issueId === "string" &&
      context.issueId.trim().length > 0 &&
      context.issueId.trim()) ||
    null;
  if (wakeTaskId) env.PAPERCLIP_TASK_ID = wakeTaskId;

  const wakeReason =
    typeof context.wakeReason === "string" &&
    context.wakeReason.trim().length > 0
      ? context.wakeReason.trim()
      : null;
  if (wakeReason) env.PAPERCLIP_WAKE_REASON = wakeReason;

  const wakeCommentId =
    (typeof context.wakeCommentId === "string" &&
      context.wakeCommentId.trim().length > 0 &&
      context.wakeCommentId.trim()) ||
    (typeof context.commentId === "string" &&
      context.commentId.trim().length > 0 &&
      context.commentId.trim()) ||
    null;
  if (wakeCommentId) env.PAPERCLIP_WAKE_COMMENT_ID = wakeCommentId;

  const approvalId =
    typeof context.approvalId === "string" &&
    context.approvalId.trim().length > 0
      ? context.approvalId.trim()
      : null;
  if (approvalId) env.PAPERCLIP_APPROVAL_ID = approvalId;

  const approvalStatus =
    typeof context.approvalStatus === "string" &&
    context.approvalStatus.trim().length > 0
      ? context.approvalStatus.trim()
      : null;
  if (approvalStatus) env.PAPERCLIP_APPROVAL_STATUS = approvalStatus;

  const linkedIssueIds = Array.isArray(context.issueIds)
    ? context.issueIds.filter(
        (value): value is string =>
          typeof value === "string" && value.trim().length > 0,
      )
    : [];
  if (linkedIssueIds.length > 0) {
    env.PAPERCLIP_LINKED_ISSUE_IDS = linkedIssueIds.join(",");
  }

  for (const [key, value] of Object.entries(envConfig)) {
    if (typeof value === "string") env[key] = value;
  }

  if (authToken && !env.PAPERCLIP_API_KEY) {
    env.PAPERCLIP_API_KEY = authToken;
  }

  const runtimeEnv = ensurePathInEnv({ ...process.env, ...env });
  await ensureCommandResolvable(command, cwd, runtimeEnv);

  const promptTemplate = asString(
    config.promptTemplate,
    "You are agent {{agent.id}} ({{agent.name}}). Continue your Paperclip work.",
  );
  const templateData = {
    agentId: agent.id,
    companyId: agent.companyId,
    runId,
    agent,
    run: { id: runId },
    context,
  };
  const prompt = renderTemplate(promptTemplate, templateData);

  const args = ["agent", "-m", prompt, "--provider", provider, "--model", model];

  if (onMeta) {
    await onMeta({
      adapterType: "zeroclaw_local",
      command,
      cwd,
      commandArgs: args,
      commandNotes: [],
      env: redactEnvForLogs(env),
      prompt,
      promptMetrics: { promptChars: prompt.length },
      context,
    });
  }

  const proc = await runChildProcess(runId, command, args, {
    cwd,
    env,
    timeoutSec,
    graceSec,
    onSpawn,
    onLog,
  });

  if (proc.timedOut) {
    return {
      exitCode: proc.exitCode,
      signal: proc.signal,
      timedOut: true,
      errorMessage: `Timed out after ${timeoutSec}s`,
      errorCode: "timeout",
    };
  }

  const exitCode = proc.exitCode ?? 0;
  const errorMessage =
    exitCode !== 0
      ? (proc.stderr
          .split(/\r?\n/)
          .map((l) => l.trim())
          .find(Boolean) ?? `zeroclaw exited with code ${exitCode}`)
      : null;

  return {
    exitCode,
    signal: proc.signal,
    timedOut: false,
    errorMessage,
    resultJson: { stdout: proc.stdout, stderr: proc.stderr },
    provider,
    biller: provider,
    model,
    billingType: "api",
    summary:
      proc.stdout
        .split(/\r?\n/)
        .filter(Boolean)
        .pop() ?? "",
  };
}
