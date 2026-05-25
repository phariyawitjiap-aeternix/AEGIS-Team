---
name: aegis-cross-session-awareness
description: "When deciding to dispatch parallel work, run a long Beast research pass, or write to .aegis/brain/, FIRST consult cross-session state via tools/aegis-claude-agents.sh. Race-risk and idle-session detection wraps v15-22's claude agents CLI integration into a persona-discoverable decision habit."
profile: standard|full
triggers:
  en: ["cross-session", "another session", "is anyone else running", "race risk", "before dispatch", "parallel sessions", "session conflict"]
  th: ["session อื่น", "ก่อน dispatch", "session ขนาน", "race risk", "session ชนกัน"]
reads: []
writes: []
wires:
  - "tools/aegis-claude-agents.sh"
  - "tools/aegis-multi-tenant/mt.mjs"
tests:
  - "tests/aegis-claude-agents-test.sh"
  - "tests/aegis-mt-sessions-test.sh"
supersedes: []
---

## Why this skill exists

v15-22 wired `claude agents --json` into AEGIS via the
`tools/aegis-claude-agents.sh` wrapper + `mt sessions` subcommand. The
command-level integration (`/aegis-start` Step 2.7, `/aegis-status` Step 5.5)
covers the OBSERVABILITY surface — surface cross-session state when the user
asks.

This skill covers the DECISION surface — when a persona (Nick Fury,
Captain America, Spider-Man) is about to take an action that could collide
with another live session, consult cross-session state FIRST.

Without this skill, the behavioral rule lives only in command files —
personas don't see it as part of their toolkit.

## When to consult cross-session state

Always check `claude agents --json` (via the wrapper) BEFORE:

| Trigger | Why |
|---|---|
| Dispatching parallel work via `Task` tool | Other session might already be working the same area |
| Writing to `.aegis/brain/` | Brain writes race if two sessions edit the same file |
| Spawning a background Beast research run | Another session may be running the same research |
| Pushing to a branch | Another session may have unpushed commits on the same branch |
| Long-running operations (full test suite, brain index rebuild) | Avoid double-runs that waste compute |

## How to invoke

### Quick check (one-liner)

```bash
bash tools/aegis-claude-agents.sh list --json | jq --arg self "$CLAUDE_SESSION_ID" '[.[] | select(.sessionId != $self)] | length'
```

Returns the count of OTHER live CC sessions (excluding self).

### Filtered by cwd (race-risk check)

```bash
bash tools/aegis-claude-agents.sh filter --cwd "$(pwd)"
```

Returns sessions in the same project directory. If count > 1 (one is self),
treat as **race-risk** — defer brain writes, warn the user.

### Merged registry view (when planning cross-project work)

```bash
node tools/aegis-multi-tenant/mt.mjs sessions
```

Shows registered projects × live session state in one table. Use when
deciding which project to switch into.

## Decision rules (for personas to apply)

### Rule 1 — Race-risk: another session on the SAME cwd

```text
Detected:  another session at the SAME project path
Verdict:   DO NOT write to .aegis/brain/ without coordination
Action:    Use queue-human or post to .aegis/brain/team-chat — let the
           other session see it. If user is in both sessions, ask which
           one should own the write.
```

### Rule 2 — Idle handoff candidate: > 1h idle elsewhere

```text
Detected:  session in OTHER project idle > 60 min
Verdict:   the user probably forgot /aegis-handoff there
Action:    surface it as informational (not blocking). The cross-session
           warning at /aegis-start Step 2.7 already does this — don't
           repeat unless the user re-asks.
```

### Rule 3 — Self-only: no other sessions

```text
Detected:  count of OTHER sessions == 0
Verdict:   safe to proceed with dispatch / brain write / etc.
Action:    proceed normally. No further check needed for this turn.
```

### Rule 4 — `claude` binary missing (CI / older install)

```text
Detected:  wrapper returns [] because `claude` is not on PATH
Verdict:   no cross-session info available; treat as Rule 3 (proceed)
           but log the gap to .aegis/brain/logs/activity.log for retro.
Action:    proceed with the action; mention in close.md that the check
           was unavailable in this environment.
```

## What this skill does NOT do (deferred to v15-23+ when active dispatch lands)

- **Spawn** a background `claude agents` session (active dispatch — needs
  PID tracking, lifecycle capture, cleanup)
- **Send** a message to another live session (inter-session messaging)
- **Auto-handoff** an idle session (move state without human input)
- **Lock** brain files when same-cwd race detected (hard gate — currently soft warning only)

All four are v15-28+ candidates once dispatch lands.

## Where this skill is invoked from

| Caller | When |
|---|---|
| `/aegis-start` Step 2.7 | Every session start — applies Rules 1+2 |
| `/aegis-status` Step 5.5 | User-initiated inventory — applies Rule 3 |
| Nick Fury (persona) | Before dispatching parallel `Task` agents on the same project — should apply Rule 1 |
| Spider-Man (persona) | Before writing to `.aegis/brain/` — should apply Rule 1 |
| Beast (persona) | Before long research dispatch — should apply Rule 1 + 2 |
| Any agent considering brain write | Apply Rule 1 |

## Linked

- [[aegis-multi-tenant]] — registry layer that pairs with live session data
- [[aegis-coverage-contract]] — same family: cross-cutting awareness skill
- v15-22 sprint plan + kanban — origin of the wrapper + mt-sessions wiring
- `docs/AEGIS_VS_NATIVE_CC.md` — the strategic positioning that puts cross-session awareness on AEGIS's keep-and-invest list
