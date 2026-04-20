---
date: 2026-04-20
category: tooling
confidence: high
---
# Claude Code Agent worktrees spawn from session-start HEAD, not current HEAD

## Context

Sprint v9-05 shipped `tools/aegis-merge-worktree.sh` with a "rebase worktree
branch onto main HEAD before merge" step, mitigating the phantom add/add
conflicts observed when spawning worktrees after several mid-session commits.
The rebase was added as a defensive workaround; the open question was whether
Claude Code's Agent tool might expose a spawn-from-current-HEAD option that
would make the workaround unnecessary.

Investigation closed 2026-04-20: no such option exists.

## Lesson

`Agent({isolation: "worktree"})` snapshots the worktree base from the
**session-start HEAD**, not the caller's current HEAD at spawn time. There is
no user-visible parameter to change this.

Empirical probe:
- Main HEAD at spawn: `f940591` (20th commit of the session)
- Spawned worktree agent reported: `HEAD=1d5da1d` (the 0th commit, i.e. the
  commit present when the Claude Code session was opened)
- `git log 1d5da1d..f940591` = 20 commits delta

Schema check confirms this is intrinsic to the SDK, not a configuration:
- `Agent` tool: `isolation` is `enum: ["worktree"]` -- single value, no sibling
  parameter for base/ref selection.
- `EnterWorktree` tool: accepts `name` (create new, based on HEAD) or `path`
  (enter an existing worktree registered in `git worktree list`). No base-ref
  param.

## Application

**When writing worktree merge tooling**: always assume the worktree branch is
potentially many commits behind the current HEAD. Rebase onto HEAD before
merging. Don't treat the rebase as a "rare-edge-case workaround" -- it's the
standard flow.

**When estimating sprint velocity**: worktree spawns after several commits
will ALWAYS require a rebase step. Price that into merge costs, not as a
one-off tax.

**If Anthropic later adds a base-ref parameter**: remove the rebase step in
`aegis-merge-worktree.sh`. Until then, keep it.

**When writing specs that assume Agent tool capabilities**: verify with a
minimal empirical probe. The system-prompt tool descriptions are concise
(the isolation param has a one-sentence description); details like "which
HEAD" are not documented. A 60-second probe beats a week of speculation.
