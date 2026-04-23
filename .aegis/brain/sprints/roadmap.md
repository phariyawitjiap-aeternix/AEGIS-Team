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

_Last updated: 2026-04-23 · by: main agent (sprint-v9-03 close)_

| Sprint | Points Selected | Points Done | Stretch Done | Status |
|--------|-----------------|-------------|--------------|--------|
| sprint-v9-01 (foundation) | 13 | 13 | 0 | CLOSED |
| sprint-v9-02 (follow-ups) | 11 | 11 | 0 | CLOSED |
| sprint-v9-03 (visual layer) | 11 | 11 | 0 | CLOSED |
| **sprint-v9-04** (next) | 10 | 0 | — | PLANNED |
| **backlog — planned** | 8 | 0 | — | PLANNED |
| **stretch — deferred** | 5 | 0 | — | BACKLOG |

## Planned next (sprint-v9-04 candidates, 10pt target)

| ID | Title | Points | Source |
|----|-------|--------|--------|
| S3-05 | EXCLUDE/INCLUDE pattern SSOT (single file for hooks + agents + tests) | 3 | v9-03 retro (BP F-03 finding) |
| S2-05 | Promote resonance → instinct lifecycle (pipeline gap) | 3 | v9-02 retro carry-forward |
| S2-06 | Track approved specs in git (fix `_aegis-output/` gitignore) | 2 | v9-02 retro carry-forward |
| S6-06 | Command consolidation 29→12 (stretch from v9-02, deferred again) | 5 | v9-follow-ups (can stretch v9-04 to 15pt) |
| S3-09 | realpath normalization in guard-ui-edit (BP F-02 LOW) | 1 | v9-03 retro carry-forward |
| BACKLOG-1 | --output path validation (design-fetch + design-init) | 1 | v9-03 round-1 LOW S-01 |
| BACKLOG-2 | --seed-all exit code semantics | 1 | v9-03 round-1 LOW C-02 |

## Planned backlog (post-v9-03)

| ID | Title | Points | Notes |
|----|-------|--------|-------|
| S2-07 | Nick Fury real-loop validation harness | 3 | monitor cross-session behavior |
| S2-08 | Capture meta-pattern: main-agent-as-router | 1 | when Nick Fury too heavy |
| S2-09 | Team chat + progress features | 2 | ← THIS SESSION is implementing, move to DONE on next close |
| S2-10 | Policy-without-test audit tool (automated scan) | 3 | per resonance/policy-enforcement-architecture.md §Infrastructure |
| S2-11 | Hook-governance ADR (merge deferred cluster D) | 3 | DIST-01 deferred |

## Deferred (explicit — not counted in denominator)

- v9-07 through v9-15 — SDK/infra/calendar-dependent (see AEGIS_v9_UPGRADE_PLAN.md historical)
- S4-02 — Nick Fury proxy dispatch loop — blocked on `memory_20250818` tool availability (external SDK feature)

## Grand Total Math

```
Denominator = selected points across open/planned sprints + planned backlog
Numerator   = delivered points (DONE across closed sprints)
Remaining   = denominator − numerator

Current:
  Denominator = 13 + 11 + 10 + 12 = 46 pt
  Numerator   = 13 + 11           = 24 pt
  Remaining   =                     22 pt
  Grand total = 24 / 46 = 52.2%
```

> Computed live by `tools/aegis-progress.sh` — this table is a human-readable
> reflection. If the two disagree, the script is authoritative (re-run it).

## Policies

- **No silent aging**: if an item sits in TODO > 2 sprints, move to deferred WITH rationale, or escalate to Nick Fury for re-prioritization. Don't let it rot.
- **Stretch honesty**: stretch items count in the denominator of the sprint they were selected for ONLY if actually delivered. Otherwise they carry forward at their original point value.
- **Backlog cap**: no more than ~20pt in "planned backlog" at any time — if it grows, either plan another sprint or move tail items to deferred.
- **Every close updates this file**: sprint-close PR must touch this document.
