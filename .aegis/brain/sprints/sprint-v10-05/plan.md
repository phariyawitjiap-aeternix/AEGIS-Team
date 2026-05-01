# Sprint v10-05 Plan: Honest Cleanup

**Sprint Goal**: Remove architectural fiction, dead code, and improve project organization.
**Points**: 8pt total (1+1+1+3+2)
**Duration**: 1 session (2026-05-01)

## Stories

| ID | Story | Pt | Type |
|----|-------|----|------|
| A | Cut 18 deprecated command shims | 1 | CUT |
| B | Cut archived agents + sprint-tracker skill | 1 | CUT |
| C | ADR-008 persona overlay + heartbeat removal | 1 | EVOLVE |
| D | Decompose on-stop.sh 376 -> 5 modules | 3 | EVOLVE |
| E | Tools triage (tests/ dir, migration scripts to scripts/) | 2 | EVOLVE |

## Capacity
- Single session, ~80% context budget pre-allocated
- All stories independently PR-able for clean rollback
