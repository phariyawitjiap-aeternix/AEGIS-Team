---
name: aegis-sprint
description: "Sprint management — plan, standup, review, retro, status, close. Full scrum lifecycle via Navi."
triggers:
  en: sprint, scrum, standup, sprint plan, sprint review, sprint retro, sprint status, sprint close
  th: สปรินต์, สครัม, สแตนอัพ, วางแผนสปรินต์
---

# /aegis-sprint

## Quick Reference

Full sprint lifecycle management. Navi (opus) orchestrates all ceremonies.

| Subcommand | Purpose |
|-----------|---------|
| `/aegis-sprint plan` | Start sprint planning: read backlog, calculate capacity, select stories, create sprint dir, init kanban |
| `/aegis-sprint standup` | Auto-generate daily standup from activity logs |
| `/aegis-sprint review` | Summarize completed work and demo links |
| `/aegis-sprint retro` | Sprint retrospective with action items (integrates with `/aegis-retro`) |
| `/aegis-sprint status` | Show burndown: points done vs remaining |
| `/aegis-sprint close` | Close sprint, calculate velocity, carry over incomplete tasks |

- **Sprint data**: `_aegis-brain/sprints/sprint-<N>/`
- **Orchestrator**: Navi (opus) — ceremony facilitator, single writer to kanban
- **Skill reference**: `skills/sprint-tracker.md` (full templates and rules)

---

## Full Instructions

### Routing

Parse the subcommand from the user's input. If no subcommand is given, show the
quick reference table above and ask which ceremony to run.

```
/aegis-sprint plan    → go to "Sprint Planning"
/aegis-sprint standup → go to "Daily Standup"
/aegis-sprint review  → go to "Sprint Review"
/aegis-sprint retro   → go to "Sprint Retrospective"
/aegis-sprint status  → go to "Sprint Status"
/aegis-sprint close   → go to "Sprint Close"
```

### Common: Determine Current Sprint Number

Before any subcommand, detect the current sprint number:

1. List directories in `_aegis-brain/sprints/` matching `sprint-*`.
2. Sort numerically. The highest number is the current (or most recent) sprint.
3. If no sprint directories exist, the next sprint is sprint-1.
4. Store this as `CURRENT_SPRINT` for the subcommand to use.

---

### Subcommand: Sprint Planning

**When**: Beginning of a new sprint.

#### Step 1: Determine Sprint Number
- If there is an open sprint (no `close.md` in the latest sprint dir), warn:
  "Sprint <N> is still open. Run `/aegis-sprint close` first, or pass `--force` to start a new one anyway."
- Otherwise, new sprint number = `CURRENT_SPRINT + 1`.

#### Step 2: Read Inputs
- Read `_aegis-brain/backlog.md` for the prioritized product backlog.
- Read `_aegis-brain/sprints/sprint-<N-1>/close.md` for previous velocity (if exists).
- Collect any carry-over tasks from the previous sprint's close report.

#### Step 3: Calculate Capacity
- Read rolling average velocity from the last 5 sprint close reports.
- If no history exists, use 20 points as default starting capacity.
- Recommended capacity = rolling average * 0.9 (10% buffer).

#### Step 4: Select Stories
- Read backlog sorted by priority (P0 highest).
- Carry-over tasks take priority over new backlog items.
- Select stories from the top until 85-95% of capacity is reached.
- Do not exceed 100% capacity.

#### Step 5: Assign to Agents
Map each task to the appropriate agent by type:
- Architecture / design → @sage
- Implementation / code → @bolt
- Code review / security → @vigil
- UI / content → @pixel or @muse
- Test planning → @sentinel
- Test execution → @probe
- Documentation → @scribe
- Research / adversarial → @havoc
- Data / analytics → @forge

#### Step 6: Create Sprint Directory and Files
- Create `_aegis-brain/sprints/sprint-<N>/` and `daily/` subdirectory.
- Write `plan.md` using the Sprint Plan Template from `skills/sprint-tracker.md`.
- Write `kanban.md` using the Initial Kanban Template with all tasks in TODO.

#### Step 7: Log
Append to `_aegis-brain/logs/activity.log`:
```
[YYYY-MM-DD HH:MM] SPRINT_START | sprint=<N> | capacity=<pts> | stories=<count> | load=<pct>%
```

#### Step 8: Display Summary
```
Sprint <N> Planning Complete

  Sprint Goal:  <goal>
  Capacity:     <committed>/<total> pts (<pct>% load)
  Stories:      <count> tasks across <agent-count> agents
  Carry-over:   <count> tasks from sprint <N-1>
  Duration:     <start> to <end>

  Sprint dir:   _aegis-brain/sprints/sprint-<N>/
  Kanban:       _aegis-brain/sprints/sprint-<N>/kanban.md
```

---

### Subcommand: Daily Standup

**When**: Any time during an active sprint. Generates automatically from logs.

#### Step 1: Read Activity Logs
- Read `_aegis-brain/logs/activity.log` — filter entries from the last 24 hours.
- Read `_aegis-brain/sprints/sprint-<N>/kanban.md` for current task states.
- Check for kanban column transitions since the last standup file in `daily/`.

#### Step 2: Identify Blockers
- Scan log entries for BLOCKED, FAILURE, ERROR, or STALLED markers.
- Flag tasks in IN_PROGRESS for more than 1 day without a log entry.

#### Step 3: Calculate Burndown
- Points completed = sum of points in DONE column.
- Points remaining = sum of points in TODO + IN_PROGRESS + IN_REVIEW + QA.
- Read sprint duration from `plan.md` to compute ideal remaining.
- Determine status: ON_TRACK / AT_RISK / OFF_TRACK (see thresholds in skill).

#### Step 4: Write Standup
- Write to `_aegis-brain/sprints/sprint-<N>/daily/YYYY-MM-DD.md` using the
  Daily Standup Template from `skills/sprint-tracker.md`.

#### Step 5: Display Summary
```
Daily Standup: <YYYY-MM-DD> (Sprint <N>, Day <D>/<total>)

  Completed:  <pts> / <total> pts
  Remaining:  <pts> pts
  Status:     ON_TRACK / AT_RISK / OFF_TRACK
  Blockers:   <count>

  Full report: _aegis-brain/sprints/sprint-<N>/daily/<YYYY-MM-DD>.md
```

---

### Subcommand: Sprint Review

**When**: Last day of the sprint, before retrospective.

#### Step 1: Collect Completed Work
- Read `kanban.md` — list all tasks in DONE with their output paths.
- For each DONE task, locate its deliverable in `_aegis-output/` or `src/`.

#### Step 2: Collect Incomplete Work
- List all tasks NOT in DONE — these are carry-over candidates.
- Note each task's current column and reason for incompletion.

#### Step 3: Assess Sprint Goal
- Re-read sprint goal from `plan.md`.
- Determine: YES / PARTIAL / NO — was the goal achieved?

#### Step 4: Write Review
- Write to `_aegis-brain/sprints/sprint-<N>/review.md` using the Sprint Review
  Template from `skills/sprint-tracker.md`.
- Log to `_aegis-brain/logs/activity.log`:
  ```
  [YYYY-MM-DD HH:MM] SPRINT_REVIEW | sprint=<N> | completed=<pts>/<total> | goal=ACHIEVED/PARTIAL/NOT_ACHIEVED
  ```

#### Step 5: Display Summary
```
Sprint <N> Review

  Goal:       <sprint goal>
  Achieved:   YES / PARTIAL / NO
  Completed:  <pts> / <total> pts (<count> tasks)
  Incomplete: <pts> pts (<count> tasks — carry-over candidates)
  Outputs:    <count> deliverables produced

  Full report: _aegis-brain/sprints/sprint-<N>/review.md
```

---

### Subcommand: Sprint Retrospective

**When**: Last day of the sprint, after review. Integrates with `/aegis-retro`.

#### Step 1: Read Context
- Read `_aegis-brain/sprints/sprint-<N>/review.md`.
- Read `_aegis-brain/logs/activity.log` filtered to this sprint's date range.
- Read any blocker entries from daily standups.

#### Step 2: Generate Retro Sections
- **What went well**: Tasks ahead of schedule, effective collaboration, clean gates.
- **What went wrong**: Blockers, context overruns, failed QA gates, carry-over causes.
- **Action items**: Specific, assignable changes for next sprint (not vague).

#### Step 3: Write Retrospective
- Write to `_aegis-brain/sprints/sprint-<N>/retro.md` using the Sprint
  Retrospective Template from `skills/sprint-tracker.md`.
- Feed "What went wrong" and "Action items" into `/aegis-retro` for long-term
  storage in `_aegis-brain/learnings/`.

#### Step 4: Log
```
[YYYY-MM-DD HH:MM] SPRINT_RETRO | sprint=<N> | action_items=<count>
```

#### Step 5: Display Summary
```
Sprint <N> Retrospective

  Went well:    <count> items
  Went wrong:   <count> items
  Action items: <count> (assigned for sprint <N+1>)

  Lessons saved to _aegis-brain/learnings/
  Full report:  _aegis-brain/sprints/sprint-<N>/retro.md
```

---

### Subcommand: Sprint Status

**When**: Any time during a sprint. Quick burndown check.

#### Step 1: Read Current State
- Read `kanban.md` for task column counts and point totals.
- Read `plan.md` for sprint duration and total committed points.
- Calculate day of sprint and ideal remaining.

#### Step 2: Display Burndown
```
Sprint <N> Status (Day <D> of <total>)

  DONE:         <count> tasks, <pts> pts
  IN_REVIEW:    <count> tasks, <pts> pts
  QA:           <count> tasks, <pts> pts
  IN_PROGRESS:  <count> tasks, <pts> pts
  TODO:         <count> tasks, <pts> pts

  Burndown:
    Completed:       <pts> / <total> pts (<pct>%)
    Remaining:       <pts> pts
    Ideal remaining: <pts> pts
    Delta:           <+/- pts>
    Status:          ON_TRACK / AT_RISK / OFF_TRACK

  Blockers: <count active blockers or "none">
```

No file is written for status — it is a read-only display.

---

### Subcommand: Sprint Close

**When**: After review and retro are complete.

#### Step 1: Calculate Velocity
- Count total points in DONE column of `kanban.md`. This is the sprint velocity.

#### Step 2: Calculate Rolling Average
- Read `close.md` from the last 5 sprints (or all available).
- Rolling average = sum of completed points / number of sprints.
- This becomes the recommended capacity for sprint N+1.

#### Step 3: Handle Carry-Over
- For each task NOT in DONE:
  - Add it back to `_aegis-brain/backlog.md` at the top of its priority tier.
  - Mark it with `[carried from sprint-<N>]`.
- Carry-over tasks must not be silently dropped.

#### Step 4: Write Close Report
- Write to `_aegis-brain/sprints/sprint-<N>/close.md` using the Sprint Close
  Template from `skills/sprint-tracker.md`.

#### Step 5: Log
```
[YYYY-MM-DD HH:MM] SPRINT_CLOSE | sprint=<N> | velocity=<pts> | rolling_avg=<pts> | carry_over=<count> tasks
```

#### Step 6: Display Summary
```
Sprint <N> Closed

  Velocity:         <pts> pts (<pct>% of committed)
  Rolling Average:  <pts> pts (last <N> sprints)
  Recommended Next: <rolling_avg * 0.9> pts capacity
  Carry-Over:       <count> tasks (<pts> pts) added back to backlog

  Close report: _aegis-brain/sprints/sprint-<N>/close.md

  Ready for: /aegis-sprint plan (to start sprint <N+1>)
```

---

### Error Handling

- **No backlog exists** (plan): Create `_aegis-brain/backlog.md` with a header and prompt the user to add stories.
- **No active sprint** (standup/status/review/retro/close): Report "No active sprint found. Run `/aegis-sprint plan` first."
- **Sprint already closed** (close): Report "Sprint <N> is already closed."
- **Missing brain directory**: Create `_aegis-brain/sprints/` and `_aegis-brain/logs/` automatically.
- **Kanban write conflict**: Only Navi writes to `kanban.md`. Other agents send StatusUpdate messages; Navi performs the column move.
