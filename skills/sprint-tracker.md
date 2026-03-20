---
name: sprint-tracker
description: "Sprint planning, story management, and progress tracking"
profile: standard
triggers:
  en: ["sprint", "sprint planning", "story points", "sprint tracker", "burndown"]
  th: ["วางแผน sprint", "sprint", "จัดการ sprint", "burndown"]
---

## Quick Reference
Sprint lifecycle management: planning, daily tracking, burndown, velocity.
- **Plan**: Define sprint goal, select stories, assign points
- **Track**: Daily status updates, blocker identification
- **Burndown**: Track remaining work vs ideal line
- **Velocity**: Calculate team velocity across sprints
- **Output**: `_aegis-output/sprints/`
- **Agent**: Navi (opus) — planning; Lumen (sonnet) — analytics

## Full Instructions

### Invocation

```
/sprint-tracker [plan|status|update|burndown|close] [sprint-id]
```
- `plan` — Create new sprint plan
- `status` — Show current sprint status
- `update` — Update story status
- `burndown` — Generate burndown chart data
- `close` — Close sprint, calculate velocity

### Sprint Planning

#### Sprint Plan Template

```markdown
# Sprint Plan: Sprint <N>
**Goal**: <one-line sprint goal>
**Duration**: <start-date> → <end-date> (<N> days)
**Capacity**: <total story points>

## Stories

| ID | Story | Points | Assignee | Priority | Status |
|----|-------|--------|----------|----------|--------|
| S-001 | <user story> | <pts> | <agent/person> | P0/P1/P2 | TODO |
| S-002 | <user story> | <pts> | <agent/person> | P0/P1/P2 | TODO |

## Sprint Backlog
Total Points: <sum>
Capacity: <available points based on velocity>
Load: <percentage>%

## Risks & Dependencies
| Risk | Impact | Mitigation |
|------|--------|------------|
| <risk> | <impact> | <plan> |

## Definition of Done
- [ ] Code complete and reviewed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No critical bugs
- [ ] Deployed to staging
```

### Story Point Scale

| Points | Complexity | Duration Estimate | Example |
|--------|-----------|-------------------|---------|
| 1 | Trivial | < 2 hours | Config change, copy update |
| 2 | Simple | 2-4 hours | Small bug fix, add field |
| 3 | Small | 4-8 hours | New endpoint, simple feature |
| 5 | Medium | 1-2 days | Feature with tests, integration |
| 8 | Large | 2-4 days | Complex feature, refactoring |
| 13 | Very Large | 4-7 days | Major feature, cross-module |
| 21 | Epic | 1-2 weeks | Should be broken down further |

### Daily Status Update

```markdown
## Daily Status: YYYY-MM-DD

### Progress
| Story | Yesterday | Today | Blockers |
|-------|-----------|-------|----------|
| S-001 | <what was done> | <plan for today> | <none/blocker> |

### Burndown
- Points Completed: <n> / <total>
- Points Remaining: <n>
- Days Remaining: <n>
- On Track: ✅ / ⚠️ / ❌

### Blockers
| Blocker | Story | Owner | Escalation |
|---------|-------|-------|------------|
| <description> | S-XXX | <who> | <action needed> |
```

### Burndown Tracking

Track daily:
```
Day | Ideal Remaining | Actual Remaining | Delta
1   | <points>        | <points>         | <+/->
2   | <points>        | <points>         | <+/->
...
```

**Status indicators:**
- ✅ On track: Actual ≤ Ideal + 10%
- ⚠️ At risk: Actual > Ideal + 10% but < 25%
- ❌ Off track: Actual > Ideal + 25%

### Sprint Velocity

Calculate after each sprint close:

```markdown
## Velocity Report

### Current Sprint
- Committed: <points>
- Completed: <points>
- Completion Rate: <percentage>%

### Velocity Trend (Last 5 Sprints)
| Sprint | Committed | Completed | Rate |
|--------|-----------|-----------|------|
| N | <pts> | <pts> | <pct>% |
| N-1 | <pts> | <pts> | <pct>% |

### Average Velocity: <average completed points>
### Recommended Next Sprint Capacity: <avg * 0.9> points
```

### Sprint Close

```markdown
## Sprint <N> Retrospective Summary
**Dates**: <start> → <end>
**Goal**: <goal> — Achieved: ✅/❌

### Completion
- Stories completed: <n>/<total>
- Points completed: <n>/<total>
- Velocity: <points>
- Carryover: <n> stories (<points> pts)

### Carried Over Stories
| Story | Points | Reason |
|-------|--------|--------|
| S-XXX | <pts> | <why not completed> |
```

### Output

```
_aegis-output/sprints/
  sprint-<N>/
    plan.md
    daily/
      YYYY-MM-DD.md
    burndown.md
    close.md
```
