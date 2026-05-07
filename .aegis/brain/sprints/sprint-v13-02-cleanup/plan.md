# Sprint v13-02-cleanup — v13-01 retro action items

**Status**: OPEN
**Date opened**: 2026-05-07
**Predecessor**: sprint-v13-01-refactor (CLOSED 24/24)
**Total points**: 6pt across 6 stories (1pt each)

## Goal

Close the 6 action items mined from the [v13-01 retro](../../../retrospectives/2026-05/07/21.15_sprint-v13-01-close-retro.md). Each item small enough to ship as its own PR or chunked together.

## Stories (one PR each — small, sequential)

| ID | Story | Pt | Owner | PR |
|----|-------|----|-------|-----|
| **AI-1** | Add Rule 6 to SPRINT_RULES — "Graduate-by-running, not graduate-by-reading" | 1 | Captain America | (in flight) |
| **AI-2** | Sweep tools/ + tests/ for `set -e` + `&&` short-circuit footgun; document findings | 1 | War Machine | TBD |
| **AI-3** | Audit branch-protection rules; consider blocking on red CI matrix; document recommendation | 1 | Thor | TBD |
| **AI-4** | Codify `${CI:-}=true` graceful-fallback pattern in `.claude/references/` | 1 | Coulson | TBD |
| **AI-5** | Decide test-suite runtime budget (current 74s vs DoD §5 30s) — tighten suite OR update DoD | 1 | War Machine + Thor | TBD |
| **AI-6** | Add a "validate against empty-cache runner" checklist for future CI sprints | 1 | Thor | TBD |

## Acceptance criteria

- All 6 AIs closed (shipped, deferred-with-rationale, or merged into another item)
- Suite stays 44/44 GREEN throughout (no regressions)
- Each PR's CI matrix passes both macOS + Ubuntu
- Final close.md mining any new lessons that emerge

## Sequencing

Per Rule 2 (impact-per-point): AI-1 first (most cited from v13-01), then AI-2 (highest discovery value), then AI-4 (codifies a pattern that's already in use). AI-3 / AI-5 / AI-6 are administrative — can ship together as a single PR if AI-2 / AI-4 surface no new bugs.

## References

- v13-01 final close: [`../sprint-v13-01-refactor/close.md`](../sprint-v13-01-refactor/close.md)
- v13-01 retro: [`../../retrospectives/2026-05/07/21.15_sprint-v13-01-close-retro.md`](../../retrospectives/2026-05/07/21.15_sprint-v13-01-close-retro.md)
- SPRINT_RULES (target for AI-1): [`../../../../SPRINT_RULES.md`](../../../../SPRINT_RULES.md)
