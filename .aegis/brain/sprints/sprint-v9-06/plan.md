# Sprint v9-06 Plan -- Operational Debt

**Sprint**: v9-06
**Opened**: 2026-04-24
**Capacity**: 11pt
**Theme**: Post-100% operational hardening -- stability, auditability, governance
**Sprint type**: operational (not feature)

## Goal

Ship the 5 backlog items identified during sprint-v9-05 close and retro.
These are stability/governance improvements that strengthen the AEGIS
framework's operational reliability without adding new user-facing features.

## Backlog

| ID | Title | Points | Priority | Assignee | Status |
|----|-------|--------|----------|----------|--------|
| F1-04-UX | test-harness-template intentional-FAIL exit-code UX | 1 | P3 | spider-man | TODO |
| BP-LOW-02 | aegis-log-decision.sh counter flock atomicity | 1 | P3 | spider-man | TODO |
| S2-11 | Hook-governance ADR (merge deferred cluster D) | 3 | P2 | iron-man | TODO |
| S2-10 | Policy-without-test audit tool (automated scan) | 3 | P2 | spider-man | TODO |
| S2-07 | Nick Fury real-loop validation harness | 3 | P2 | spider-man | TODO |

## Build Order

1. F1-04-UX (1pt) -- warmup, unblocks CI consumers
2. BP-LOW-02 (1pt) -- small fix, unblocks nothing but low risk
3. S2-11 (3pt) -- ADR document, unblocks S2-10 conventions
4. S2-10 (3pt) -- audit tool, depends on S2-11 conventions
5. S2-07 (3pt) -- validation harness, stresses infra (last)

## Definition of Done

- All 5 items pass Gate 1 (Black Panther review)
- Items >= 3pt pass Gate 2 (QA via test harness)
- Sprint closed with retro + handoff
- roadmap.md updated with v9-06 row
