# Sprint v9-02 Plan

**Goal**: Ship remaining in-repo v9 follow-ups + clear knowledge debt
**Capacity**: ~15pt (1 agent-week equivalent)
**Status**: PLANNED (awaiting /aegis-start to activate)

## Backlog (prioritized)

| ID | Story | Points | Source | Notes |
|----|-------|--------|--------|-------|
| S2-02 | Retro-summary wiring: Nick Fury logs decisions at runtime, /aegis-retro reads decision-audit.log | 3 | v9-follow-ups | Unblocked now that Nick Fury spawn path works |
| S2-03 | BLOCK 0 lite-mode: wire aegis-block0-mode.sh into Nick Fury gate checks | 3 | v9-follow-ups | Gate logic exists; skip-switching not wired |
| S2-04 | BLOCK 0 lite-mode: tag-override validation (Loki counter) | 2 | v9-follow-ups | Pairs with S2-03 |
| DIST-01 | Run /aegis-distill: process 28-session learning backlog | 3 | maintenance | Overdue by 28 sessions (threshold=3) |
| S6-06 | Command consolidation 29->12 | 5 | v9-follow-ups | Deferred — include only if capacity allows |

**Total selected**: 11pt (S2-02 + S2-03 + S2-04 + DIST-01)
**Stretch**: S6-06 (+5pt) if velocity exceeds estimate

## Acceptance Criteria
- S2-02: decision-audit.log populated during live session; /aegis-retro summary section reads it
- S2-03: lite/standard/full mode auto-determined; lite tasks skip SI.01/SI.02
- S2-04: chore-tagged task touching auth paths overridden to full; logged
- DIST-01: learnings/raw/ backlog < 3 sessions; skill-cache updated

## Blocked
- S4-02 (Nick Fury proxy dispatch loop): blocked on memory_20250818 tool availability — not in this sprint

## Dependencies
- S2-03 depends on S2-02 (decision logging must work before lite-mode can log skips)
- DIST-01 is independent, can run in parallel
