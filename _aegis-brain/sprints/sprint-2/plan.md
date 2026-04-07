# Sprint 2 Plan

## Sprint Goal
Make AEGIS self-sustaining: multi-cycle sessions, cross-session continuity, real QA pipeline, and live dashboard metrics.

## Sprint Info
- **Sprint**: sprint-2
- **Start**: 2026-03-30
- **End**: 2026-04-11 (12 days)
- **Capacity**: 24 pts (based on sprint-1 velocity 27 * 0.9)
- **Committed**: 23 pts (96% load)
- **Carry-over**: 0 tasks from sprint-1

## Selected Tasks

| # | ID | Title | Pts | Assignee | Priority | Type |
|---|-----|-------|:---:|----------|----------|------|
| 1 | PROJ-T-005 | Multi-cycle within session (context budget aware) | 8 | @bolt | high | impl |
| 2 | PROJ-T-006 | Cross-session continuity via handoff | 5 | @bolt | high | impl |
| 3 | PROJ-T-008 | Sentinel+Probe QA pipeline produces real reports | 5 | @sentinel | high | test |
| 4 | PROJ-T-012 | Dashboard shows real computed metrics | 5 | @bolt | medium | impl |

## Remaining Backlog (not selected)

| ID | Title | Pts | Priority | Reason |
|----|-------|:---:|----------|--------|
| PROJ-T-009 | Scribe generates versioned ISO docs automatically | 5 | medium | Exceeds capacity (23+5=28 > 24) |

## Definition of Done (per task)
1. Code/docs written and working
2. Gate 1 (Vigil code review) PASS
3. Tests pass (if applicable)
4. Task meta.json status = DONE

## Risks
- T-005 (8pts) is the largest task — may need decomposition mid-sprint
- T-008 depends on Sentinel+Probe agent coordination
- Dashboard metrics (T-012) depends on sprint data being populated
