# Sprint v10-02 Plan -- RTK Readiness

> Opened: 2026-04-25
> Budget: 5pt
> Theme: Measurement + governance infrastructure for RTK adoption decision

## Stories

| ID | Title | Points | Owner | Status |
|----|-------|--------|-------|--------|
| v10-02-A | Bash vs Read/Grep/Glob token accounting | 2 | Spider-Man + War Machine | TODO |
| v10-02-B | Upstream issue #427 watcher | 1 | Beast | TODO |
| v10-02-C | ADR-007 draft (shell output compression governance) | 1 | Iron Man + Coulson | TODO |
| v10-02-D | Canary test scaffold | 1 | War Machine | TODO |

## Context

Team voted on RTK (Rust Token Killer) adoption:
- 2 ADOPT, 2 DEFER, 2 CONDITIONAL, 1 REJECT
- No majority to ship
- Consensus: measure first, answer Loki's killshot question, wait for upstream #427, draft ADR-007

This sprint builds the infrastructure so v10-03 CAN make a data-driven decision.

## Key Principles

1. NOT adopting RTK in this sprint -- building measurement capability
2. Story A is load-bearing -- answers "What % of AEGIS tokens is Bash vs Read/Grep/Glob?"
3. Story D (canary) is dormant -- skips cleanly when RTK not installed
4. Story C (ADR-007) codifies the vote for future sessions

## Success Criteria

- tools/aegis-token-profile.sh + test passing
- tools/aegis-rtk-upstream-check.sh operational (non-blocking)
- ADR-007 recorded in architecture-decisions.md
- tools/aegis-rtk-canary-test.sh skips cleanly without RTK
- All 5pt delivered, sprint closed
