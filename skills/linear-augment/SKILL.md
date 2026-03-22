---
name: linear-augment
description: >
  Augment Linear workspace context — team, projects, states, queries, and agent
  workflow patterns. Pair with CLI scripts (query.ts, linear-ops.ts) for all
  Linear operations. Use when creating/querying issues in the Augment team.
---

# Augment Linear Workspace

Project-specific Linear context for ops-agent agents. Provides workspace IDs, ready-to-use queries, mutation patterns, and the autonomous agent workflow.

**CLI tools**: `bun run scripts/query.ts` (GraphQL), `bun run scripts/linear-ops.ts` (high-level ops)

## Workspace

| Field | Value |
|-------|-------|
| Team | **Augment** |
| Key | `<QUERY: bun run scripts/query.ts 'query { teams { nodes { id key name } } }'>` |
| Team ID | `<QUERY: bun run scripts/query.ts 'query { teams { nodes { id key name } } }'>` |

> **First run**: Execute the query above once to populate the actual team key and ID. Cache the result — it won't change.

## CLI Tooling

### Ad-hoc GraphQL Queries

```bash
# Requires LINEAR_API_KEY in environment
bun run scripts/query.ts 'query { viewer { id name } }'

# With variables
bun run scripts/query.ts 'query($id: String!) { issue(id: $id) { title } }' '{"id": "ISSUE_UUID"}'
```

### High-Level Operations

```bash
bun run scripts/linear-ops.ts help                              # Show all commands

# Issue management
bun run scripts/linear-ops.ts create-issue "Project" "Title" "Description"
bun run scripts/linear-ops.ts create-sub-issue AUG-100 "Sub-task" "Details"
bun run scripts/linear-ops.ts status Done AUG-123 AUG-124
bun run scripts/linear-ops.ts done AUG-123                      # Shortcut for status Done
bun run scripts/linear-ops.ts wip AUG-123                       # Shortcut for status "In Progress"

# Project management
bun run scripts/linear-ops.ts create-project "Phase X: Name" "Initiative"
bun run scripts/linear-ops.ts project-status "Phase X" in-progress
bun run scripts/linear-ops.ts project-status "Phase X" completed

# Initiative management
bun run scripts/linear-ops.ts create-initiative "Q1 Goals" "Description"
bun run scripts/linear-ops.ts link-initiative "Phase X" "Q1 Goals"
bun run scripts/linear-ops.ts list-initiatives
bun run scripts/linear-ops.ts list-projects

# Labels
bun run scripts/linear-ops.ts labels taxonomy
bun run scripts/linear-ops.ts labels validate "feature,backend"
bun run scripts/linear-ops.ts labels suggest "Fix authentication bug"
bun run scripts/linear-ops.ts labels set AUG-123 feature,backend

# Identity
bun run scripts/linear-ops.ts whoami
```

## Common Agent Queries

Replace `TEAM_KEY` with the actual team key (run the workspace query above to discover it).

### Agent Queue (To Do, priority desc)

```bash
bun run scripts/query.ts 'query {
  issues(filter: {
    team: { key: { eq: "TEAM_KEY" } },
    state: { name: { eq: "To Do" } }
  }, first: 10, orderBy: updatedAt) {
    nodes { id identifier title description priority project { name } labels { nodes { name } } }
  }
}'
```

### Triage Items

```bash
bun run scripts/query.ts 'query {
  issues(filter: {
    team: { key: { eq: "TEAM_KEY" } },
    state: { type: { eq: "triage" } }
  }, first: 20) {
    nodes { identifier title createdAt creator { name } }
  }
}'
```

### In-Flight Work

```bash
bun run scripts/query.ts 'query {
  issues(filter: {
    team: { key: { eq: "TEAM_KEY" } },
    state: { type: { eq: "started" } }
  }, first: 30) {
    nodes { identifier title state { name } assignee { name } project { name } }
  }
}'
```

### Issues by Label

```bash
bun run scripts/query.ts 'query {
  issues(filter: {
    team: { key: { eq: "TEAM_KEY" } },
    labels: { name: { eq: "backend" } },
    state: { type: { nin: ["completed", "canceled"] } }
  }, first: 30) {
    nodes { identifier title state { name } priority }
  }
}'
```

### Active Projects Overview

```bash
bun run scripts/query.ts 'query {
  teams(filter: { key: { eq: "TEAM_KEY" } }) {
    nodes {
      projects(filter: { state: { in: ["started", "planned"] } }, first: 10) {
        nodes { name state issues { nodes { identifier title state { name } } } }
      }
    }
  }
}'
```

### Sprint / Cycle Status

```bash
bun run scripts/query.ts 'query {
  teams(filter: { key: { eq: "TEAM_KEY" } }) {
    nodes {
      activeCycle {
        name number startsAt endsAt
        issues { nodes { identifier title state { name } priority } }
      }
    }
  }
}'
```

## Mutation Patterns

### Create Issue

```bash
bun run scripts/query.ts 'mutation {
  issueCreate(input: {
    teamId: "TEAM_UUID",
    title: "Issue title",
    description: "Description",
    stateId: "TODO_STATE_UUID",
    projectId: "PROJECT_UUID",
    labelIds: ["LABEL_UUID"],
    priority: 2
  }) { success issue { identifier url } }
}'
```

Or use the high-level CLI:

```bash
bun run scripts/linear-ops.ts create-issue "Project Name" "Title" "Description" --priority 2 --labels feature,backend
```

### Update Issue Status

```bash
# Via high-level CLI (preferred)
bun run scripts/linear-ops.ts status "In Progress" AUG-123

# Via GraphQL
bun run scripts/query.ts 'mutation {
  issueUpdate(id: "ISSUE_UUID", input: { stateId: "STATE_UUID" }) {
    success issue { identifier state { name } }
  }
}'
```

### Add Comment

```bash
bun run scripts/query.ts 'mutation {
  commentCreate(input: {
    issueId: "ISSUE_UUID",
    body: "Comment text in markdown"
  }) { success comment { id } }
}'
```

### Create PR Link (Attachment)

```bash
bun run scripts/query.ts 'mutation {
  attachmentCreate(input: {
    issueId: "ISSUE_UUID",
    url: "https://github.com/minzique/ops-agent/pull/42",
    title: "feat(paperclip): add skill injection (#42)"
  }) { success }
}'
```

## Agent Autonomous Workflow

### Phase 1: Pick Up & Implement

1. Query **Agent Queue** (To Do, priority desc)
2. Pick highest-priority issue matching your capability
3. Move to **In Progress**: `bun run scripts/linear-ops.ts wip AUG-XXX`
4. Create branch: `git checkout -b feat/AUG-XXX-slug`
5. Explore before coding — read relevant files, understand context
6. Implement
7. Commit locally

### Phase 2: PR Creation

8. Push branch: `git push -u origin feat/AUG-XXX-slug`
9. Create PR with structured body:
```bash
gh pr create --title "feat(scope): summary (AUG-XXX)" --body "$(cat <<'EOF'
## Summary
- What changed and why

## Linear Issue
Closes AUG-XXX

## Testing
- [ ] Typecheck passes
- [ ] Build passes
- [ ] Tests pass
EOF
)"
```
10. Move to **In Review**: `bun run scripts/linear-ops.ts status "In Review" AUG-XXX`

### Phase 3: CI & Review Fix Loop

11. Wait for CI + review:
```bash
gh pr checks <pr-number> --watch --fail-level all
```
12. Read review comments:
```bash
gh api repos/minzique/ops-agent/pulls/<pr-number>/reviews
gh api repos/minzique/ops-agent/pulls/<pr-number>/comments
```
13. Evaluate:
    - `REQUEST_CHANGES` -> fix inline comments, commit, push
    - `COMMENT` with suggestions -> apply easy wins, commit, push
    - `COMMENT` with no actionable items + all checks green -> Phase 4
    - CI failure in changed file -> fix, commit, push
    - CI failure in untouched file -> pre-existing, note in PR comment
14. Loop (max 3 iterations). If stuck after 3 -> mark blocked, comment on PR and Linear issue, stop.

### Phase 4: Merge Decision

All green. Classify the change:

**Tier 1 — Auto-merge (no human needed):**
- Config/prompt text changes
- Chores/cleanup (dead code, comments, formatting)
- Single-service bug fixes following existing patterns
- Test additions/fixes
- Docs-only changes

**Tier 2 — Auto-merge if pattern-matched:**
- Logic changes following existing patterns (adding a field, extending a handler)
- diff <= 300 lines, CI green, review is COMMENT

**Tier 3 — Human approval required:**
- Schema/migration changes
- Route/API contract changes
- Infrastructure changes (CI, Docker, deployment)
- Cross-stack changes
- New dependencies
- Review is REQUEST_CHANGES after fixes
- Anything uncertain

```bash
gh pr diff <pr-number> --stat
```

### Phase 5: Merge -> Done

17. If auto-merge safe:
```bash
gh pr merge <pr-number> --squash --subject "feat(scope): summary (AUG-XXX) (#<pr-number>)"
```
18. If NOT safe -> comment "Ready for human review — [reason]", stop.
19. After merge: `bun run scripts/linear-ops.ts done AUG-XXX`

## Conventions

- **Issue key prefix**: Use the team key discovered from the workspace query
- **Branch naming**: `feat/AUG-XXX-slug`, `fix/AUG-XXX-slug`, `chore/AUG-XXX-slug`
- **PR title format**: `type(scope): summary (AUG-XXX)`
- **Every issue needs**: project + priority + at least one label
- **Assigned to me**: state = "Todo". **Unassigned**: state = "Backlog"

## Security

- Never expose `LINEAR_API_KEY` in terminal output or agent context
- Never run `echo $LINEAR_API_KEY` or `printenv | grep LINEAR`
- Scripts read the key from environment automatically
