---
name: github-augment
description: >
  GitHub CLI patterns for Augment repos — issue management, PR workflows, merge
  tiers, and review automation via gh CLI. Use when working with GitHub issues,
  pull requests, or repository operations for Augment projects.
---

# GitHub Augment

GitHub operations for Augment repos using the `gh` CLI. No MCP servers — CLI only.

## Repos

| Repo | Purpose |
|------|---------|
| `minzique/ops-agent` | Ops-agent monorepo (Paperclip + agents) |

## Issue Management

```bash
# List open issues
gh issue list --repo minzique/ops-agent

# List with filters
gh issue list --repo minzique/ops-agent --label bug --state open
gh issue list --repo minzique/ops-agent --assignee @me

# View issue details
gh issue view 42 --repo minzique/ops-agent

# Create issue
gh issue create --repo minzique/ops-agent \
  --title "type(scope): summary" \
  --body "Description" \
  --label "bug,backend"

# Close issue
gh issue close 42 --repo minzique/ops-agent --comment "Resolved in #43"

# Add comment
gh issue comment 42 --repo minzique/ops-agent --body "Update: working on fix"
```

## Pull Request Workflow

### Creating PRs

```bash
# Standard PR creation
gh pr create --repo minzique/ops-agent \
  --title "type(scope): summary (#issue)" \
  --body "$(cat <<'EOF'
## Summary
- What changed and why

## Issue
Closes #42

## Testing
- [ ] Typecheck passes
- [ ] Build passes
- [ ] Tests pass
EOF
)"

# Draft PR
gh pr create --draft --title "wip: feature name"
```

### PR Title Format

```
type(scope): summary (#issue)
```

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructure, no behavior change |
| `chore` | Deps, config, tooling |
| `docs` | Documentation only |
| `test` | Test additions/fixes |

### Branch Naming

```
feat/AUG-123-short-slug
fix/AUG-456-bug-description
chore/AUG-789-dependency-update
```

### Reviewing PRs

```bash
# List open PRs
gh pr list --repo minzique/ops-agent

# View PR details
gh pr view 43 --repo minzique/ops-agent

# View PR diff
gh pr diff 43 --repo minzique/ops-agent
gh pr diff 43 --repo minzique/ops-agent --stat    # Summary only

# Watch CI checks
gh pr checks 43 --repo minzique/ops-agent --watch --fail-level all

# Read reviews
gh api repos/minzique/ops-agent/pulls/43/reviews
gh api repos/minzique/ops-agent/pulls/43/comments
```

### Merging PRs

```bash
# Squash merge (preferred)
gh pr merge 43 --repo minzique/ops-agent --squash \
  --subject "feat(scope): summary (AUG-XXX) (#43)"

# Merge commit (for large feature branches)
gh pr merge 43 --repo minzique/ops-agent --merge

# Delete branch after merge (usually automatic)
gh pr merge 43 --repo minzique/ops-agent --squash --delete-branch
```

## Merge Tiers

### Tier 1 — Auto-merge (agent merges, no human needed)

- Config/prompt text changes
- Chores/cleanup (dead code removal, comment fixes, formatting)
- Single-service bug fixes following established patterns
- Test/eval additions or fixes
- Docs-only changes
- Review verdict is COMMENT (no change requests)

### Tier 2 — Auto-merge if pattern-matched

- Service logic changes following existing patterns (adding a field, extending a handler)
- Must: diff <= 300 lines, CI green, review is COMMENT

### Tier 3 — Human approval required

- Schema/migration changes
- Route/API contract changes
- Infrastructure changes (CI, Docker, deployment configs)
- Cross-stack changes (multiple services in one PR)
- New dependencies added
- Review is REQUEST_CHANGES (even after fixes)
- Anything the agent is uncertain about

### Pre-merge Checklist

```bash
# 1. All CI checks pass
gh pr checks <pr-number> --watch --fail-level all

# 2. Check diff scope
gh pr diff <pr-number> --stat

# 3. Ensure branch is up to date
git fetch origin main && git rebase origin/main && git push --force-with-lease

# 4. Merge
gh pr merge <pr-number> --squash --subject "type(scope): summary (#pr)"
```

## Raw API Access

For operations not covered by `gh` subcommands:

```bash
# GraphQL query
gh api graphql -f query='{ viewer { login } }'

# REST API
gh api repos/minzique/ops-agent/pulls/43
gh api repos/minzique/ops-agent/issues/42/comments

# POST request
gh api repos/minzique/ops-agent/issues/42/comments \
  -f body="Automated comment from agent"

# Pagination
gh api repos/minzique/ops-agent/issues --paginate --jq '.[].title'
```

## Repository Operations

```bash
# Clone
gh repo clone minzique/ops-agent

# List repos in org
gh repo list minzique --limit 50

# View repo info
gh repo view minzique/ops-agent

# Create release
gh release create v1.0.0 --repo minzique/ops-agent \
  --title "v1.0.0" --notes "Release notes"
```

## CI/CD Workflow Runs

```bash
# List recent workflow runs
gh run list --repo minzique/ops-agent --limit 10

# View specific run
gh run view <run-id> --repo minzique/ops-agent

# Watch a running workflow
gh run watch <run-id> --repo minzique/ops-agent

# Re-run failed jobs
gh run rerun <run-id> --repo minzique/ops-agent --failed
```

## Conventions

- Always use `--repo` flag unless already inside the cloned repo
- Squash merge is the default merge strategy
- Branch names include the Linear issue key when applicable
- PR titles follow conventional commits format
- Delete branches after merge
