---
date: 2026-04-25
category: tooling
confidence: high
status: consolidated
merged_from:
  - 2026-04-20_worktree-isolation-runtime-quirks.md
  - 2026-04-20_worktree-base-is-session-start-HEAD.md
---

# Worktree Isolation Implementation Guide

## Context

Claude Code's `Agent({isolation: "worktree"})` provides per-agent git isolation.
Sprint v9-05 shipped `tools/aegis-merge-worktree.sh` and `.claude/references/worktree-isolation.md`
as the spec. Real usage in dogfooding sessions revealed two empirical quirks that
the spec did not predict, both confirmed by schema inspection.

## Known Quirk 1: Base Commit is Session-Start HEAD, Not Spawn-Time HEAD

When `Agent({isolation: "worktree"})` spawns, the worktree branch roots from the
**session-start HEAD** (commit 0 of the session), not the caller's current HEAD at
spawn time. There is no SDK parameter to change this.

**Empirical proof (2026-04-20)**:
- Main HEAD at spawn: `f940591` (20th commit of the session)
- Spawned worktree: `HEAD=1d5da1d` (0th commit)
- Delta: 20 commits behind

**Schema confirmation**: `Agent` tool's `isolation` field is `enum: ["worktree"]` with
no sibling parameter for base/ref selection. `EnterWorktree` tool accepts `name` or
`path` but no base-ref param.

**Implications**:
- Every worktree-originated commit requires a merge (not fast-forward) back to the parent branch
- Any file touched by BOTH intervening commits AND the worktree commit will conflict --
  even if changes don't logically overlap (phantom add/add)
- The rebase step in `aegis-merge-worktree.sh` is the **standard flow**, not a workaround

## Known Quirk 2: Worktree Directory Stays Locked After Agent Returns

After the spawned agent completes and returns its result, the worktree directory at
`.claude/worktrees/agent-<id>` remains locked by the agent process. The lifecycle
mismatch means "agent result returned" != "agent process released."

**Recovery**: `git worktree remove -f -f` (double-force) is required. Single `-f` is
rejected with `fatal: cannot remove a locked working tree`. The double-force is NOT a
force-push-equivalent risk -- it only unlocks the worktree entry.

## Application

### When Spawning Worktree Agents

1. **Expect a merge (not ff) back.** Budget ~5 min for conflict handling on files
   touched in-session.
2. **Prefer worktree isolation for tasks that touch files NOT being edited by the
   main agent** or other subagents concurrently.
3. **After merge, use `git worktree remove -f -f` unconditionally** (lifecycle-correct
   cleanup, not dangerous).

### When Writing Merge Tooling

1. **Always assume the worktree branch is potentially many commits behind current HEAD.**
   Rebase onto HEAD before merging. Don't treat the rebase as a "rare-edge-case workaround."
2. **Pre-check for conflicts** with `git merge-tree` before touching the working tree,
   so failures surface before a dirty state is created.
3. **Stage the merge as non-ff by default** in `aegis-merge-worktree.sh`.

### When Estimating Sprint Velocity

Worktree spawns after several commits will ALWAYS require a rebase step. Price that
into merge costs, not as a one-off tax.

### When Writing Specs

If Anthropic later adds a `base-ref` parameter to the Agent tool, remove the rebase
step. Until then, keep it. The same "verify primitives before speccing" discipline
(see `platform-capability-verification.md`) applies -- don't spec against capabilities
that don't exist yet.

### Per-File Conflict Budget

For busy files (adversarial-test.sh, settings.json, any agent definition), either:
- (a) Route worktree-originated changes through a rebase-onto-HEAD step before merge, OR
- (b) Explicitly NOT use worktree isolation for those files
The former is cleaner but requires re-testing the rebased commit.
