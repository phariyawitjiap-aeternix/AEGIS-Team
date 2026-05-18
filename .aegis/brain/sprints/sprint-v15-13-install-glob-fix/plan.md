# Sprint v15-13 — install-remote.sh glob+pipefail silent-exit bug

> Fix the silent-exit class in install-remote.sh + install.sh where
> `ls glob 2>/dev/null | wc -l | tr -d ' '` aborts the script under
> `set -e` + `pipefail` when the glob doesn't match.

## Sprint metadata

- **ID**: sprint-v15-13-install-glob-fix
- **Points**: 2
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-13-install-glob-fix`
- **Driver**: User reproduction — Contra-Thai install died silently after
  "Core docs + VERSION file installed". Trace via `bash -x` showed exit
  right after `ARCHIVED_COUNT=0` assignment.

## Root cause

```bash
ARCHIVED_COUNT=$(ls "${TARGET_DIR}/.claude/agents/_archived/"*.md 2>/dev/null | wc -l | tr -d ' ')
```

When `_archived/` doesn't exist (which is normal for fresh installs):
1. Glob doesn't expand (no nullglob), stays literal
2. `ls 'literal-path/*.md'` errors "no such file"; exits 1
3. `2>/dev/null` suppresses stderr but exit code propagates
4. `wc -l | tr -d ' '` succeeds (returns 0)
5. **Pipefail** makes the pipeline exit non-zero (matches leftmost failure)
6. `$(...)` captures empty stdout, exit code propagates to assignment
7. **`set -e`** aborts the script — silently, because stderr was muted

User saw the install banner + dependency checks + "Core docs installed" then nothing. No error, no doctor, no completion message. Script just exited.

## Stories

| Story | Points | Description |
|-------|--------|-------------|
| A — Patch 5 patterns in install-remote.sh | 1 | AGENT_COUNT, ARCHIVED_COUNT, HOOK_COUNT, TOOL_COUNT, SKILL_COUNT — add `|| echo 0` fallback |
| B — Patch 1 pattern in install.sh | 0.5 | `skill_count` line (same bug class) |
| C — Smoke test from clean dir | 0.5 | Validate fixed installer completes end-to-end in fresh temp dir |

## The fix

```bash
# Before:
ARCHIVED_COUNT=$(ls "...*.md" 2>/dev/null | wc -l | tr -d ' ')

# After:
ARCHIVED_COUNT=$(ls "...*.md" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
```

`|| echo 0` makes the pipeline always exit 0 (and produces `0` as
output if all upstream commands failed). Variable gets a valid number
either way; no set-e abort.

## Acceptance criteria

1. All 5 patterns in install-remote.sh have `|| echo 0` fallback
2. install.sh's skill_count line same fix
3. `bash install-remote.sh --profile minimal` from fresh temp dir completes through Summary block (no silent exit)
4. Variable values still correct when files DO exist (no regression)

## Out of scope

- Other glob patterns in the codebase (only count-pipelines have this bug class)
- nullglob setup (would require shopt; more invasive)
- Wider audit of `set -e` + `pipefail` interactions across all tools (deferred)

## Verification plan

1. `grep -n "ls.*2>/dev/null | wc -l" install-remote.sh install.sh` — all 6 results show `|| echo 0`
2. Smoke install in temp dir → completes through `Installation Complete!` block
3. Suite still 58/58 PASS
