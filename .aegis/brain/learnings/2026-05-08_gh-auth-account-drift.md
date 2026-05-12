---
date: 2026-05-08
category: workflow
confidence: high
---
# `gh auth` active-account drifts to non-collaborator → 404 false negatives

## Context

Hit `404 Not Found` from `gh api -X DELETE /repos/.../git/refs/heads/<branch>` on branches that demonstrably exist on the remote (verified via `git ls-remote`). GitHub returns 404 instead of 403 for security reasons when the token lacks access — masquerading as "branch doesn't exist."

Root cause: `gh auth status` had two accounts logged in (`mr-phariyawit` + `phariyawitjiap-aeternix`). The repo is owned by `phariyawitjiap-aeternix` but the active account silently drifted to `mr-phariyawit` between command invocations during the session — possibly across worktree-create/delete or the implicit reset on session boundary.

Hit this **3 times** in the same session (PR #152 cleanup, PR #153 cleanup, romantic-tharp cleanup). Each time spent ~30s to recognize the symptom and re-switch.

## Lesson

When two `gh` accounts are configured and only one has access to the target repo, the active account can drift silently. Symptoms:
- `gh api` write/delete returns 404 on resources that visibly exist
- `gh pr list` works (read access) but writes fail
- `gh auth status` shows the wrong account as active

The 404 is a security feature (don't leak existence to unauthorized callers) but reads like "doesn't exist."

## Application

**Defensive pattern** — prefix gh API calls that depend on repo-owner identity:

```bash
# Before any write/delete API call:
gh auth switch -u phariyawitjiap-aeternix 2>/dev/null
gh api -X DELETE /repos/...
```

**Detection check** — when an `gh api` returns 404 on something you know exists:

```bash
ACTIVE=$(gh auth status 2>&1 | grep -B1 "Active account: true" | head -1 | awk '{print $NF}')
echo "active: $ACTIVE"  # if not the repo-owner, switch
```

**Long-term fix** — wrap gh in a session-pinned identity:

```bash
# In .claude/settings.local.json or project bootstrap:
export GH_REPO=phariyawitjiap-aeternix/AEGIS-Team
# Then use: gh api ... --hostname github.com (forces consistent identity resolution)
```

Future tool: `tools/aegis-gh-pin-identity.sh` that runs `gh auth switch -u <repo-owner>` at session start, idempotent.
