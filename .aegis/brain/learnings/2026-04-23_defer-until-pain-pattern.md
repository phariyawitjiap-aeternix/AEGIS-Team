---
date: 2026-04-23
category: workflow
confidence: medium
source_sprint: sprint-v9-05
related_decisions: D-051
---

# Defer-Until-Pain Scope Management

## Context

S6-06 (29 → 12 command consolidation) was first proposed in sprint-v9-02 and deferred. Deferred again in v9-03 and v9-04. Every retro asked "should we still do this?" and every answer was "the pain signal isn't strong enough yet." In sprint-v9-05, the consolidation shipped in 4 points (F2-01) and took less than 2 hours of Spider-Man time. The specs, shims, and Modes tables were all obvious at that point because the users of the framework (we) had hit each duplicate-flag confusion enough times that the right consolidation was self-evident.

Had we forced the work in v9-02, the design would have been wrong — we didn't yet know that `/aegis-doctor` wanted to be `/aegis-verify --doctor` vs `/aegis-pipeline --doctor`. That knowledge was earned through 3 sprints of usage.

## Lesson

**Refactors forced before the pain signal produce worse designs.** When a proposed refactor sits deferred for 2+ sprints and each retro's answer is "not yet", that's data — not procrastination. Wait for:

- Multiple independent sessions hitting the same friction
- The correct shape of the refactor becoming obvious rather than debatable
- A "meta-clue" surfacing — a test failure, a user complaint, a reviewer finding that makes the need concrete

When the signal arrives, the refactor ships fast because the design is no longer speculative.

## Application

**Use when**:
- A cleanup/refactor has been proposed but specifics are debatable
- Multiple "right answers" exist and which is best depends on usage patterns
- Deferral cost is bounded (no active breakage, just aesthetic debt)

**Don't use when**:
- Active breakage is happening (defer-until-pain becomes ship-it-broken)
- Security or correctness is at stake (those don't wait)
- The item is blocking other work (dependency-forced urgency)

**Policy lever**: roadmap.md's "Backlog cap: no more than ~20pt in planned backlog" — items that sit past 2 sprints either ship or move to deferred with rationale. This keeps the pattern from degenerating into hoarding.

**Meta-observation**: the same pattern applies to instinct promotion. Instincts in `pending/` with `observations: 1` shouldn't be forced to `active/` — they promote themselves through reinforcement when the pattern is real.

**Canonical example**: S6-06 (command consolidation), proposed sprint-v9-02 retro, shipped sprint-v9-05 (3-sprint defer, clean delivery).
