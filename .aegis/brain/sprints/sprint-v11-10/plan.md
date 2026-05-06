# Sprint v11-10 Plan: aegis-resume (Phase-3 §8.1)

**Points**: 8pt · **Branch**: `feat/v11-10-aegis-resume`
**Phase-3 gate**: explicitly overridden by user ("ship it") — trigger ≥2 crash-loss incidents was NOT yet met; build proceeds anyway per user direction.

## Goal

Persistent run state so a session can be resumed after a Claude Code crash, machine restart, or branch swap. Closes Mega Plan §8.1.

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | `checkpoint.mjs` — capture {ts, session_id, branch, persona, task, last_commit, dirty_files} → `.aegis/brain/state/<session>.yaml` | 2 |
| B | `resume.mjs` CLI — list / show / clear interruptable checkpoints + integrate with v11-07 archived `runs/` | 2 |
| C | SessionStart hook integration — surface unresolved checkpoints on session start | 2 |
| D | SKILL.md + 14+ assertion regression test | 2 |

## Storage

- `.aegis/brain/state/<SESSION>.yaml` — one file per active session, overwritten on each checkpoint
  ```yaml
  session_id: abc123
  ts: 2026-05-05T20:00:00Z
  branch: feat/sprint-2-cache
  persona: spider-man
  task: "fix wordPool dedup race"
  last_commit: abc1234
  dirty_files:
    - src/wordPool.ts
    - tests/wordPool.test.ts
  ```
- A checkpoint is "stale" once a Stop hook has fired for its session (handled by v11-07 archiving the run); operator clears via `resume clear <session>` or `resume clear --all-stopped`.

## Acceptance criteria (Mega Plan §8.1)

- [ ] `checkpoint` invocation writes a YAML snapshot with the required fields
- [ ] `resume list` shows currently-interruptable checkpoints (excludes ones whose session was cleanly archived)
- [ ] `resume show <session>` prints a paste-ready resume brief
- [ ] `resume clear` deletes one or all
- [ ] SessionStart hook prints "Resume X interrupted run(s)?" if any active checkpoints exist
- [ ] Hook is non-blocking (exit 0 even on internal error)
- [ ] Integration with v11-07: `resume list` cross-references `.aegis/brain/runs/` to show "archived" vs "interrupted"
