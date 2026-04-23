# AEGIS Roadmap — Grand Total Tracker

> Single source of truth for "how close are we to 100% done".
> Updated when sprints open, close, or rescope.

## Scope

"100% done" = every work item currently known is either DONE or explicitly
declared out-of-scope (deferred with rationale). No ambiguous
in-progress / untriaged / silently-aging items.

This tracker covers **in-repo work only**. SDK-side items (v9-07 through
v9-15 per AEGIS_v9_UPGRADE_PLAN.md) are tracked separately — they are not
counted against this roadmap's denominator because they require
external dependencies (new SDK features, infra, migration calendar).

## Tally (update on every sprint close)

_Last updated: 2026-04-23 · by: main agent (sprint-v9-05 close · GENUINE 100%)_

| Sprint | Points Selected | Points Done | Stretch Done | Status |
|--------|-----------------|-------------|--------------|--------|
| sprint-v9-01 (foundation) | 13 | 13 | 0 | CLOSED |
| sprint-v9-02 (follow-ups) | 11 | 11 | 0 | CLOSED |
| sprint-v9-03 (visual layer) | 11 | 11 | 0 | CLOSED |
| sprint-v9-04 (design gen + cleanup) | 10 | 14 | 0 | CLOSED (140%) |
| sprint-v9-05 (FINAL-PUSH) | 13 | 13 | 0 | **CLOSED (100%)** |
| **v9 in-repo total** | **58** | **62** | **0** | **GENUINE 100%** |

## Why delivered > denominator this sprint

sprint-v9-04 absorbed 4 stretch points (S3-06 came in at 5pt instead of
the planned-backlog 2pt, carrying forward mid-sprint as accepted scope).
sprint-v9-05 delivered exactly its 13pt budget.

Net position: all identified in-repo work shipped, with no silent aging
items. The 4pt "overrun" reflects scope realism — v9-04 expanded
its intake rather than deferring Wasp Revival to v9-05.

## Planned next (v9-06 — post-100% operational sprint)

| ID | Title | Points | Source |
|----|-------|--------|--------|
| BP-LOW-02 | aegis-log-decision.sh counter `flock` atomicity | 1 | v9-05 BP advisory |
| F1-04-UX | test-harness-template intentional-FAIL exit-code UX | 1 | v9-05 retro |
| S2-07 | Nick Fury real-loop validation harness | 3 | roadmap carry |
| S2-10 | Policy-without-test audit tool (automated scan) | 3 | user-feedback-driven |
| S2-11 | Hook-governance ADR (merge deferred cluster D) | 3 | DIST-01 deferred |

v9-06 denominator: 11pt. Status: BACKLOG — not yet opened. These items do
NOT count against the v9 100% number because they are post-100%
operational debt (stability, not features) and follow-on scope surfaced
during v9-05 reviews.

## Deferred (explicit — not counted in denominator)

- v9-07 through v9-15 — SDK/infra/calendar-dependent (see AEGIS_v9_UPGRADE_PLAN.md historical)
- S4-02 — Nick Fury proxy dispatch loop — blocked on `memory_20250818` tool availability (external SDK feature)

## Grand Total Math

```
Denominator = selected points across open/closed v9 sprints
Numerator   = delivered points (DONE across closed sprints)
Remaining   = denominator − numerator

Current:
  Denominator = 13 + 11 + 11 + 10 + 13 = 58 pt
  Numerator   = 13 + 11 + 11 + 14 + 13 = 62 pt (incl. 4pt stretch in v9-04)
  Effective   = min(62, 58) = 58 / 58 = 100%

  Grand total = 100% (genuine, v9 in-repo scope)
```

> Computed live by `tools/aegis-progress.sh` — this table is a human-readable
> reflection. If the two disagree, the script is authoritative (re-run it).

## Policies

- **No silent aging**: if an item sits in TODO > 2 sprints, move to deferred WITH rationale, or escalate to Nick Fury for re-prioritization. Don't let it rot.
- **Stretch honesty**: stretch items count in the denominator of the sprint they were selected for ONLY if actually delivered. Otherwise they carry forward at their original point value.
- **Backlog cap**: no more than ~20pt in "planned backlog" at any time — if it grows, either plan another sprint or move tail items to deferred.
- **Every close updates this file**: sprint-close PR must touch this document.
- **Post-100% operational debt** (v9-06+): tracked as follow-on scope, not
  counted against the sprint that surfaced it unless it's a merge blocker
  for that sprint. Keeps the grand total honest.
