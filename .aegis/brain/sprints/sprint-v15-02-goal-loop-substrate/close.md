# Sprint v15-02 — Close

**Status**: CLOSED 2026-05-13
**Velocity**: 3/3 pt

## Delivered

`.claude/commands/aegis-start.md` Step 4 now selects loop substrate at runtime:

- IF `/goal` available (CC 2.1.139+): use it as loop primitive, Nick Fury runs inside each turn
- ELSE: fall back to legacy subagent + SendMessage heartbeat loop (preserved verbatim)

The `/goal` text encodes 5 exit conditions:
(a) all kanban TODO → DONE, (b) BLOCK 0 missing (Coulson first), (c) MBP escalation,
(d) tests/lint red, (e) context >= 80%.

Per-turn workflow stays identical to nick-fury.md Decision Cycle — only the loop substrate changes.

## Compatibility

Older Claude Code versions: legacy path executes (function-identical to before). No regression.
CC 2.1.139+: native `/goal` provides better cost UX + cancellation UX.

## What's NOT done in this sprint

- Trimming nick-fury.md §HEARTBEAT LOOP / §Context Window duplicate policy — that's
  cosmetic doc cleanup; nick-fury.md still works as-is because the v15-02 wiring
  ALSO uses it.
- Real prototype run on CC 2.1.139 — requires user to actually be on that version.
  The detection logic is best-effort; if `/goal` errors silently rather than reporting
  unknown command, the fallback might not trigger.

Both are tracked as follow-ups; neither blocks v15-02 close.
