# Sprint Kanban — sprint-v9-02

**Goal**: Ship remaining in-repo v9 follow-ups + clear knowledge debt
**Capacity**: 11pt selected + 5pt stretch
**Status**: ACTIVE (BLOCK 0 cleared 2026-04-22)

## BACKLOG
- [ ] [S6-06] Command consolidation 29→12 (@unassigned) — 5pt, stretch if velocity allows

## TODO
- [ ] [DIST-01] Run /aegis-distill: process 28-session learning backlog (@unassigned) — 3pt, independent

## IN_PROGRESS
_(empty)_

## IN_REVIEW
- [ ] [S2-04] BLOCK 0 lite-mode: tag-override validation via Loki counter (@iron-man) — 2pt
      **Loki gate round 1** (D-011, adr:sprint-v9-02, conf 0.95): CONDITIONAL — 3 fixable
        1. `mv -n` not atomic on macOS HFS+/APFS → use flock
        2. `secret[^s]` regex misses bare `secret` file → change to `secret($|[^s])`
        3. Missing test cases for `.ssh/` and `tokens/` → add TC-13, TC-14
      **Iron Man v1.1** (D-013, adr:sprint-v9-02, conf 0.9): ALL 3 addressed.
        - flock -x lockfile pattern replacing mv -n swap (macOS fallback: last-writer-wins + warning)
        - regex anchor fix in all 3 locations (pattern table + pseudocode + path registry)
        - TC-13 (.ssh/id_rsa), TC-14 (tokens/api.json) added; total 14 test cases
        - v1.1 footer added
      **Next actor**: Loki re-review (should flip → APPROVE) → Spider-Man build → BP review → merge
      **Blockers**: none

## QA
_(empty)_

## DONE
- [x] [S2-02] Retro-summary wiring — Nick Fury logs decisions to decision-audit.log; /aegis-retro reads and summarizes (@nick-fury) — 3pt [PR #34 merged 2026-04-22]
- [x] [S2-03] BLOCK 0 lite-mode: wire aegis-block0-mode.sh into Nick Fury gate checks (@spider-man) — 3pt [PR #39 merged 2026-04-23]
      Full audit trail D-001 → D-010 in decision-audit.log. Autonomous cycle:
      Nick Fury pick → spec → Loki CONDITIONAL → Iron Man v1.1 → Loki APPROVE →
      Spider-Man impl → Black Panther CONDITIONAL → Spider-Man round-2 → BP PASS.
      Artifacts: nick-fury.md +45 (§BLOCK 0 Runtime Procedure),
      coulson.md +34 (§COULSON_BLOCK0), tools/aegis-block0-gate-test.sh
      (new, 240 LOC, 22/22 assertions pass).

## Blocked (not in sprint)
- [S4-02] Nick Fury proxy dispatch loop — blocked on `memory_20250818` tool availability (SDK-side, not in-repo)

## Dependencies
- S2-03 depends on S2-02 (decision logging must work before lite-mode can log skips)
- S2-04 pairs with S2-03 (same code path, parallel review)
- DIST-01 is independent — can run in parallel with S2-02
- S6-06 (stretch) is independent

## Next Action (from Nick Fury)
Per heartbeat cycle=1 decision log (2026-04-22T10:55:44Z): open with S2-02 (unblocks S2-03/04) + DIST-01 (parallel).
