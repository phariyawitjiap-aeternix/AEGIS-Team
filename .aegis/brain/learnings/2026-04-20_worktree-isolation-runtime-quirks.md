---
date: 2026-04-20
category: tooling
confidence: high
---
# v9-05 Worktree Isolation -- Runtime Quirks Discovered by Real Use

## Context

First real exercise of `Agent({isolation: "worktree"})` on a small implementation task (adding Scenario H to `tools/aegis-brain-adversarial-test.sh` via Spider-Man). The isolation feature worked end-to-end — sandbox held, agent produced a clean commit, merge script detected conflicts and aborted safely — but two concrete quirks surfaced that the spec (`.claude/references/worktree-isolation.md`) did not predict.

## Finding 1: Worktrees Spawn From Stale Ancestor, Not Current HEAD

When `Agent({isolation: "worktree"})` spawns, the worktree's base commit is NOT the caller's current HEAD. In this session, main was at `64c8810` when Spider-Man was spawned, but the worktree branch (`worktree-agent-a03cfd69`) was rooted at `1d5da1d` — roughly 8 commits behind. This means:

- Every worktree-originated commit needs to merge (not fast-forward) back into the parent branch.
- Any file touched by BOTH the intervening commits AND the worktree commit will conflict — even if the changes don't logically overlap (phantom add/add).
- The v9-05 spec assumed worktrees would be clean fast-forward merges; in practice they are always full merges.

In this run the phantom conflict was trivial (whitespace/marker around a section break) and took ~2 minutes to resolve by keeping the worktree's content. On a busy file with real intervening changes, this would be a real conflict requiring judgment.

**Why:** Likely Claude Code's isolation implementation snapshots from the branch tip at session start (or some earlier checkpoint), not at the spawn moment. Needs confirmation but the empirical evidence is clear.

## Finding 2: Worktree Directory Stays Locked After Agent Returns

After the spawned agent completed and returned its result, the worktree directory at `.claude/worktrees/agent-a03cfd69` remained locked by `claude agent agent-a03cfd69 (pid 13845)`. `git worktree remove --force` (single `-f`) was rejected with `fatal: cannot remove a locked working tree`. Only `git worktree remove -f -f` (double-force) succeeded.

**Why:** The underlying agent process holds the git worktree lock past the tool-call return boundary. Lifecycle mismatch between "agent result returned" and "agent process released."

## Lessons

1. **Post-merge step for aegis-merge-worktree.sh**: after successful merge, attempt `git worktree remove -f -f` (not `-f`) before falling back to manual intervention. Document that the extra `-f` is NOT a force-push-equivalent risk — it's just "unlock-and-remove," targeted at this lifecycle issue.
2. **Stage the merge as non-ff by default**: `aegis-merge-worktree.sh` should assume non-ff and pre-check for conflicts with `git merge-tree` before touching the working tree, so failures surface before a dirty state is created.
3. **Spec correction in v9-05**: add a "Known Quirks" section listing these two findings and their workarounds. Remove the assumption that worktree merges are fast-forward.
4. **Per-file conflict size budget**: for busy files (adversarial-test.sh, settings.json, any agent definition), consider either (a) routing worktree-originated changes through a rebase-onto-HEAD step before merge, or (b) explicitly NOT using worktree isolation for these files. The former is cleaner but requires re-testing the rebased commit.

## Application

- When spawning `Agent({isolation: "worktree"})`: expect a merge (not ff) back. Budget ~5 min for conflict handling on any file touched in-session.
- Prefer worktree isolation for tasks that touch files NOT being edited by the main agent or other subagents concurrently.
- After merge, use `git worktree remove -f -f` unconditionally (it's not dangerous, it's lifecycle-correct).
- Propose v9-05 follow-up sprint: (a) investigate whether Claude Code exposes a "spawn from current HEAD" option, (b) if not, add a `git rebase --onto HEAD base worktree-branch` step to `aegis-merge-worktree.sh` before the merge attempt.
- Add both findings to `.claude/references/worktree-isolation.md` as a "Known Quirks" section in a follow-up PR (not this one — scope creep).
