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

_Last updated: 2026-05-04 · by: Nick Fury (sprint-v11-03 close · aegis-issue-thread shipped)_

| Sprint | Points Selected | Points Done | Stretch Done | Status |
|--------|-----------------|-------------|--------------|--------|
| sprint-v9-01 (foundation) | 13 | 13 | 0 | CLOSED |
| sprint-v9-02 (follow-ups) | 11 | 11 | 0 | CLOSED |
| sprint-v9-03 (visual layer) | 11 | 11 | 0 | CLOSED |
| sprint-v9-04 (design gen + cleanup) | 10 | 14 | 0 | CLOSED (140%) |
| sprint-v9-05 (FINAL-PUSH) | 13 | 13 | 0 | CLOSED (100%) |
| sprint-v9-06 (operational debt) | 11 | 11 | 0 | CLOSED (100%) |
| **v9 in-repo total** | **69** | **73** | **0** | **100%** |
| sprint-v10-01 (traceability wiki) | 13 | 13 | 0 | CLOSED (100%) |
| sprint-v10-02 (RTK readiness) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v10-03 (RTK adoption decision = DEFER) | 2 | 2 | 0 | CLOSED (100%) |
| sprint-v10-04 (MBP soft-ask detection) | 3 | 3 | 0 | CLOSED (100%) |
| sprint-v10-05 (honest cleanup) | 8 | 8 | 0 | CLOSED (100%) |
| sprint-v10-06 (searchable brain · Hermes L1) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v10-09 (per-agent allow lists · v9 personas) | 3 | 3 | 0 | CLOSED (100%) |
| **v10 in-repo total** | **39** | **39** | **0** | **100%** |
| sprint-v11-01 (aegis-live-tail · always-on terminal stream) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v11-02 (aegis-activity-logger · JSONL audit) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v11-03 (aegis-issue-thread · YAML tickets) | 5 | 5 | 0 | **CLOSED (100%)** |
| sprint-v11-04 (aegis-parallel-dispatch · Agent fan-out skill) | 3 | – | 0 | planned |
| **v11 Phase-1 (in flight)** | **18** | **15** | **0** | 83% |
| sprint-v11-05 (aegis-approval-gate · PreToolUse blocker) | 8 | – | 0 | deferred — pending P1 pilot |
| sprint-v11-06 (aegis-router · model-tier picker) | 8 | – | 0 | deferred |
| sprint-v11-07 (aegis-run-logger · Stop hook archive) | 8 | – | 0 | deferred |
| sprint-v11-08 (aegis-trace-export · PII redaction) | 8 | – | 0 | deferred |
| **v11 Phase-2 (deferred)** | **32** | – | – | gated by P1 pilot outcome |

## v11 Plan Reference

Source: `~/Documents/AEGIS-PLUS-MEGA-PLAN.md` v1.1 (2026-05-02). Adopted into roadmap on
2026-05-04 after pre-flight verification (tmux 3.6a, node v25.8.2, kam-tong-ham pilot dir
exists, settings.json backup taken). Phase 1 = 4 skills / 18pt / 1–2 sessions per skill.
Phase 2 = 4 skills / 32pt / gated on Phase 1 pilot outcome per plan §10 Step 3.
Phase 3 (resume, multi-tenant) = on-demand only — no roadmap entry until concrete trigger.

## Why delivered > denominator this sprint

sprint-v9-04 absorbed 4 stretch points (S3-06 came in at 5pt instead of
the planned-backlog 2pt, carrying forward mid-sprint as accepted scope).
sprint-v9-05 delivered exactly its 13pt budget.

Net position: all identified in-repo work shipped, with no silent aging
items. The 4pt "overrun" reflects scope realism — v9-04 expanded
its intake rather than deferring Wasp Revival to v9-05.

## v9-06 delivered (post-100% operational sprint)

All 5 items shipped in sprint-v9-06 (2026-04-24):

| ID | Title | Points | Status |
|----|-------|--------|--------|
| BP-LOW-02 | aegis-log-decision.sh counter flock atomicity | 1 | DONE |
| F1-04-UX | test-harness-template intentional-FAIL exit-code UX | 1 | DONE |
| S2-07 | Nick Fury real-loop validation harness | 3 | DONE |
| S2-10 | Policy-without-test audit tool (automated scan) | 3 | DONE |
| S2-11 | Hook-governance ADR (merge deferred cluster D) | 3 | DONE |

## Deferred (explicit — not counted in denominator)

- v9-07 through v9-15 — SDK/infra/calendar-dependent (see AEGIS_v9_UPGRADE_PLAN.md historical)
- S4-02 — Nick Fury proxy dispatch loop — blocked on `memory_20250818` tool availability (external SDK feature)

## Grand Total Math

```
Denominator = selected points across open/closed v9 sprints
Numerator   = delivered points (DONE across closed sprints)
Remaining   = denominator − numerator

Current:
  Denominator = 13 + 11 + 11 + 10 + 13 + 11 = 69 pt
  Numerator   = 13 + 11 + 11 + 14 + 13 + 11 = 73 pt (incl. 4pt stretch in v9-04)
  Effective   = min(73, 69) = 69 / 69 = 100%

  Grand total = 100% (v9 in-repo scope, 6 sprints closed)
```

> Computed live by `tools/aegis-progress.sh` — this table is a human-readable
> reflection. If the two disagree, the script is authoritative (re-run it).

## v10 -- Framework Application (next phase)

v9 is the terminal in-repo sprint series for AEGIS framework development.
v10 marks the transition from "building the framework" to "applying the
framework to real projects."

**v10 scope** (tracked separately from v9 denominator):
- Application Playbook published (`docs/AEGIS_APPLICATION_PLAYBOOK.md`) -- DONE
- ADR-006 memory integration plan documented -- DONE
- SDK readiness checker (`tools/aegis-sdk-readiness-check.sh`) -- DONE
- Project-wide traceability wiki (sprint-v10-01, 13pt) -- DONE
- **Hermes adoption (v10-06/07/08)**: 3-sprint roadmap to adopt Nous Research Hermes Agent's compounding-intelligence pattern (observed-only, no LLM-generated skills, ISO 29110 audit trail preserved)
  - L1 — Searchable brain (FTS5 over `.aegis/brain/`) — sprint-v10-06 — **DONE 2026-05-02**
  - L2 — Pattern miner over `decision-audit.log` — sprint-v10-07 — DEFERRED (planned)
  - L3 — Instinct refinement loop — sprint-v10-08 — DEFERRED (needs L2 measurement first)
- Real-project application sprints (first AEGIS-powered project delivery)
- Feedback loop: lessons from real usage feed back into framework improvements

**v10 is open-ended**: unlike v9's fixed 69pt denominator, v10 sprints are
demand-driven. Each real project that adopts AEGIS generates its own sprint
series. The AEGIS-Team meta-repo tracks framework-level improvements only.

**SDK-dependent items** (v9-07 through v9-15) activate when their SDK
dependencies land. They become v10 sprint candidates at that point.

## Policies

- **No silent aging**: if an item sits in TODO > 2 sprints, move to deferred WITH rationale, or escalate to Nick Fury for re-prioritization. Don't let it rot.
- **Stretch honesty**: stretch items count in the denominator of the sprint they were selected for ONLY if actually delivered. Otherwise they carry forward at their original point value.
- **Backlog cap**: no more than ~20pt in "planned backlog" at any time — if it grows, either plan another sprint or move tail items to deferred.
- **Every close updates this file**: sprint-close PR must touch this document.
- **Post-100% operational debt** (v9-06+): tracked as follow-on scope, not
  counted against the sprint that surfaced it unless it's a merge blocker
  for that sprint. Keeps the grand total honest.
