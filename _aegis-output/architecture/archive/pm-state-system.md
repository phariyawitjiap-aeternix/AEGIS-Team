# Architecture Specification: PM State System for AEGIS v7.0

**ID**: ADR-007
**Author**: Iron Man (System Architect)
**Date**: 2026-03-24
**Status**: PROPOSED (pending review by Black Panther or Loki)

---

## 1. Problem Statement

The current AEGIS PM system stores task state in flat markdown files (kanban.md, backlog.md) with ad-hoc ID schemes (TASK-NNN vs T-NNN vs US-NNN). This creates three problems:

1. No per-task history -- state transitions are lost once kanban.md is overwritten.
2. No unified ID counter -- IDs are derived by scanning directories, risking collisions under concurrent agent writes.
3. No structured metrics -- sprint velocity and burndown are computed ephemerally with no persistent record.

This spec defines a file-based PM state system using JSON for structured data and markdown for human-readable logs. No external database is required.

---

## 2. Design Principles

| Principle | Rationale |
|-----------|-----------|
| Single source of truth per entity | Each task has exactly one meta.json; no duplication across files |
| Append-only history | history.md is never edited, only appended -- provides full audit trail |
| Atomic counter file | counters.json is the sole authority for ID generation |
| Computed views, stored state | The kanban board and dashboard are computed from task meta.json files; they are views, not sources of truth |
| Backward compatibility | Existing kanban.md format is retained as a computed view; agents that read it continue to work |

---

## 3. Directory Structure

```
_aegis-brain/
  counters.json                          # Global sequential ID counter
  tasks/
    PROJ-T-001/
      meta.json                          # Structured task metadata
      history.md                         # Append-only state change log
      comments.md                        # Append-only discussion thread
    PROJ-T-002/
      meta.json
      history.md
      comments.md
    PROJ-E-001/
      meta.json
      history.md
      comments.md
    PROJ-US-001/
      meta.json
      history.md
      comments.md
    ...
  sprints/
    sprint-1/
      metrics.json                       # Sprint metrics (burndown, velocity)
      plan.md                            # Sprint plan (existing format)
      kanban.md                          # Computed board view (generated)
      daily/
        2026-03-24.md
      review.md
      retro.md
      close.md
    sprint-2/
      ...
    current -> sprint-N/                 # Symlink to active sprint

_aegis-output/
  iso-docs/
    SI-01-requirements-spec/
      v1.md
      v2.md
      current.md                         # Copy of latest version (not symlink)
      changelog.md
    PM-01-project-plan/
      v1.md
      current.md
      changelog.md
    doc-registry.json                    # Master document index
  breakdown/
    PROJ-US-001/                         # Breakdown output (updated ID format)
      summary.md
      journeys/
      epics/
      tasks.md
      tree.md
```

---

## 4. Sequential ID Counter

### 4.1 File: `_aegis-brain/counters.json`

```json
{
  "project_key": "PROJ",
  "counters": {
    "US": 0,
    "J": 0,
    "E": 0,
    "T": 0,
    "ST": 0,
    "DOC": 0
  },
  "last_updated": "2026-03-24T00:00:00"
}
```

### 4.2 ID Format

All IDs follow the pattern: `{project_key}-{type}-{NNN}`

Examples: `PROJ-T-001`, `PROJ-E-003`, `PROJ-US-012`, `PROJ-DOC-001`

Zero-padded to 3 digits. If a counter exceeds 999, extend to 4 digits automatically.

### 4.3 ID Generation Protocol

Every command that creates an entity MUST follow this exact sequence:

```
1. READ  _aegis-brain/counters.json
2. INCREMENT the relevant counter by 1
3. WRITE _aegis-brain/counters.json with updated counter and last_updated timestamp
4. USE the new ID for the entity being created
```

This is a read-modify-write cycle. Because AEGIS enforces single-writer (Captain America) for state mutations, there is no concurrent write risk. If a non-Captain America agent needs an ID, it MUST request it via a message to Captain America.

### 4.4 Counter Initialization

If `counters.json` does not exist when a command runs, create it with all counters at 0 and `project_key` set to `"PROJ"`. The project key can be changed by editing the file directly.

### 4.5 Migration from Legacy IDs

Existing `TASK-NNN` and `US-NNN` IDs in older breakdown outputs and kanban boards are not retroactively renamed. New entities use the `PROJ-{type}-NNN` format. Commands that read legacy IDs treat `TASK-NNN` as equivalent to `PROJ-T-NNN` for lookup purposes.

---

## 5. Per-Task Directory with History

### 5.1 Task Creation

When any command creates a task (or epic, story, subtask), it MUST:

1. Generate an ID via the counter protocol (Section 4.3).
2. Create directory: `_aegis-brain/tasks/{ID}/`
3. Write `meta.json` with initial state.
4. Write `history.md` with the CREATED entry.
5. Write an empty `comments.md` with the header row.

### 5.2 meta.json Schema

```json
{
  "id": "PROJ-T-001",
  "title": "Implement login API",
  "type": "task",
  "task_type": "impl",
  "parent": "PROJ-E-001",
  "children": [],
  "status": "BACKLOG",
  "assignee": "unassigned",
  "points": 5,
  "priority": "high",
  "labels": ["backend", "auth"],
  "dependencies": {
    "blocks": ["PROJ-T-003"],
    "blocked_by": []
  },
  "created": "2026-03-24T10:00:00",
  "updated": "2026-03-24T10:00:00",
  "sprint": null,
  "time_tracking": {
    "estimated_hours": null,
    "logged_hours": 0
  }
}
```

**Field definitions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | yes | Unique ID from counter |
| title | string | yes | Human-readable title |
| type | enum | yes | One of: `user_story`, `journey`, `epic`, `task`, `subtask`, `doc` |
| task_type | enum | if type=task | One of: `arch`, `impl`, `test`, `review`, `ui`, `doc`, `research`, `data` |
| parent | string or null | no | Parent entity ID |
| children | string[] | no | Child entity IDs |
| status | enum | yes | See Section 5.3 |
| assignee | string | yes | Agent name or `"unassigned"` |
| points | integer | yes | Story points (Fibonacci: 1, 2, 3, 5, 8, 13) |
| priority | enum | yes | One of: `critical`, `high`, `medium`, `low` |
| labels | string[] | no | Freeform tags |
| dependencies.blocks | string[] | no | IDs this task blocks |
| dependencies.blocked_by | string[] | no | IDs blocking this task |
| created | ISO 8601 | yes | Creation timestamp |
| updated | ISO 8601 | yes | Last modification timestamp |
| sprint | string or null | no | Sprint identifier (e.g., `"sprint-1"`) |
| time_tracking.estimated_hours | number or null | no | Estimated hours |
| time_tracking.logged_hours | number | no | Accumulated logged hours |

### 5.3 Status Values and Transitions

Valid statuses:

```
BACKLOG -> TODO -> IN_PROGRESS -> IN_REVIEW -> QA -> DONE
                        ^              |        |
                        |              v        |
                        +----- REJECTED --------+
                        |
                   BLOCKED (from any active status)
                   CANCELLED (from any status)
```

| Status | Description |
|--------|-------------|
| BACKLOG | Created but not yet scheduled |
| TODO | Committed to a sprint, not yet started |
| IN_PROGRESS | Agent actively working |
| IN_REVIEW | Code review by Black Panther |
| QA | Quality assurance by War Machine/Vision |
| DONE | Completed and accepted |
| BLOCKED | Waiting on external dependency |
| CANCELLED | Abandoned (terminal state) |

Transition rules carry forward from the existing kanban-board skill (Section 2 of `skills/kanban-board.md`), with two additions:

- Any active status can transition to BLOCKED with a reason.
- Any status can transition to CANCELLED with a reason.

### 5.4 history.md Format

```markdown
## {ID} History

| Timestamp | Agent | Action | From | To | Note |
|-----------|-------|--------|------|----|------|
| 2026-03-24 10:00 | captain-america | CREATED | - | BACKLOG | Created from breakdown |
```

**Action types:**

| Action | Description |
|--------|-------------|
| CREATED | Entity created |
| MOVED | Status changed |
| ASSIGNED | Assignee changed |
| COMMENT | Comment added |
| POINTS_CHANGED | Story points modified |
| PRIORITY_CHANGED | Priority modified |
| DEPENDENCY_ADDED | Dependency link created |
| DEPENDENCY_REMOVED | Dependency link removed |
| SPRINT_ASSIGNED | Added to a sprint |
| GATE_PASS | Quality gate passed (Gate 1 = review, Gate 2 = QA) |
| GATE_FAIL | Quality gate failed |
| TIME_LOGGED | Hours logged |
| LABEL_CHANGED | Labels modified |

**Append protocol:** Every write to history.md MUST append a new row at the bottom of the table. The file is never truncated or rewritten. This ensures a complete audit trail.

### 5.5 comments.md Format

```markdown
## {ID} Comments

---
**2026-03-24 14:00** | @black-panther
Missing input validation on email field. See review PROJ-T-001-review.md.

---
**2026-03-24 14:35** | @spider-man
Fixed. Added Zod schema validation for all input fields.

---
```

Comments are appended using the separator format above. Never edit or delete existing comments.

---

## 6. Document Versioning

### 6.1 Directory Structure per Document

Each ISO 29110 document lives in its own directory under `_aegis-output/iso-docs/`:

```
_aegis-output/iso-docs/{doc-type-slug}/
  v1.md              # Version 1
  v2.md              # Version 2
  current.md         # Copy of the latest version content
  changelog.md       # Version-by-version change summary
```

Note: `current.md` is a file copy, not a symlink. This avoids portability issues across platforms and ensures `current.md` is always readable without resolving links.

### 6.2 doc-registry.json

```json
{
  "documents": [
    {
      "id": "PROJ-DOC-001",
      "type": "SI.01",
      "title": "Requirements Specification",
      "current_version": 2,
      "status": "Approved",
      "author": "coulson",
      "reviewer": "black-panther",
      "created": "2026-03-24",
      "last_updated": "2026-03-24",
      "path": "_aegis-output/iso-docs/SI-01-requirements-spec/"
    }
  ]
}
```

### 6.3 Versioning Protocol

When a command generates or updates a document:

1. READ `doc-registry.json`. If it does not exist, create it with an empty `documents` array.
2. Look up the document by `type` field.
3. If the document does not exist:
   a. Generate a new `PROJ-DOC-NNN` ID via the counter protocol.
   b. Write the content to `v1.md`.
   c. Copy `v1.md` to `current.md`.
   d. Create `changelog.md` with the initial entry.
   e. Add the document entry to `doc-registry.json`.
4. If the document exists:
   a. Increment `current_version`.
   b. Write the content to `v{N}.md`.
   c. Overwrite `current.md` with the new content.
   d. Append a change summary to `changelog.md`.
   e. Update `last_updated` and `current_version` in `doc-registry.json`.

### 6.4 changelog.md Format

```markdown
# Changelog: {document title}

## v2 (2026-03-24)
- Updated requirements after sprint-1 feedback
- Added non-functional requirement NFR-003 (performance)
- Reviewed by: black-panther

## v1 (2026-03-24)
- Initial version created from breakdown PROJ-US-001
- Reviewed by: black-panther
```

---

## 7. Sprint Metrics

### 7.1 File: `_aegis-brain/sprints/sprint-N/metrics.json`

```json
{
  "sprint": "sprint-1",
  "started": "2026-03-24",
  "planned_end": "2026-03-31",
  "actual_end": null,
  "goal": "Core payment processing",
  "capacity_pts": 28,
  "committed_pts": 26,
  "completed_pts": 19,
  "daily_burndown": [
    { "date": "2026-03-24", "day": 1, "remaining": 26, "completed": 0 },
    { "date": "2026-03-25", "day": 2, "remaining": 21, "completed": 5 },
    { "date": "2026-03-26", "day": 3, "remaining": 13, "completed": 13 }
  ],
  "velocity_history": [24, 30, 26],
  "tasks": {
    "total": 8,
    "done": 5,
    "in_progress": 1,
    "in_review": 0,
    "qa": 1,
    "todo": 1,
    "blocked": 0,
    "cancelled": 0
  },
  "carry_over": {
    "count": 2,
    "points": 7,
    "task_ids": ["PROJ-T-006", "PROJ-T-008"]
  }
}
```

### 7.2 Metrics Update Protocol

Metrics are recomputed whenever a task status changes during a sprint:

1. READ all `meta.json` files where `sprint` matches the current sprint.
2. COUNT tasks by status.
3. SUM completed points (status = DONE).
4. SUM remaining points (all non-DONE, non-CANCELLED statuses).
5. APPEND a daily_burndown entry if the date changed since the last entry.
6. WRITE metrics.json.

This recomputation happens inside the kanban move command (Section 9.2).

### 7.3 Velocity History

The `velocity_history` array stores completed points from the last 5 closed sprints. It is populated by `/aegis-sprint close` and read by `/aegis-sprint plan` for capacity calculation.

---

## 8. Dashboard Command

### 8.1 New Command: `/aegis-dashboard`

**File**: `.claude/commands/aegis-dashboard.md`

**Behavior**: Read-only. Computes a comprehensive view from all JSON state files. Writes nothing.

### 8.2 Data Sources

| Data | Source File |
|------|-------------|
| Current sprint info | `_aegis-brain/sprints/sprint-N/metrics.json` |
| Task details | `_aegis-brain/tasks/*/meta.json` |
| Recent activity | `_aegis-brain/tasks/*/history.md` (last 10 entries across all tasks) |
| Document status | `_aegis-output/iso-docs/doc-registry.json` |
| ID counters | `_aegis-brain/counters.json` |

### 8.3 Display Format

```
AEGIS DASHBOARD -- Sprint 1 (Day 3 of 7)
================================================================

BURNDOWN
  Committed: 26 pts | Completed: 19 pts | Remaining: 7 pts
  Progress:  [===================>-------] 73%
  Status:    ON_TRACK

  Day  Ideal  Actual
   1    22.3   26.0
   2    18.6   21.0
   3    14.9   13.0  <-- ahead

TASK DISTRIBUTION
  BACKLOG:      0    TODO:         1    IN_PROGRESS:  1
  IN_REVIEW:    0    QA:           1    DONE:         5
  BLOCKED:      0    CANCELLED:    0

AGENT WORKLOAD
  @spider-man      3 tasks (13 pts) | 2 done, 1 in_progress
  @black-panther     2 tasks ( 6 pts) | 2 done
  @iron-man      1 task  ( 5 pts) | 1 done
  @war-machine  2 tasks ( 5 pts) | 1 qa, 1 todo

BLOCKED TASKS
  (none)

UPCOMING (next to finish)
  PROJ-T-006  "Add payment webhook"  IN_PROGRESS  @spider-man  [5pts]
  PROJ-T-008  "Write integration tests" TODO  @war-machine  [3pts]

RECENT ACTIVITY
  2026-03-26 15:05  PROJ-T-005  MOVED  IN_REVIEW -> DONE  @captain-america
  2026-03-26 15:00  PROJ-T-005  GATE_PASS  Gate 2  @war-machine
  2026-03-26 14:30  PROJ-T-003  MOVED  QA -> DONE  @captain-america
  ...

DOCUMENTS (ISO 29110)
  PROJ-DOC-001  SI.01  Requirements Spec   v2  Approved
  PROJ-DOC-002  PM.01  Project Plan        v1  Draft
================================================================
```

### 8.4 Burndown Calculation

```
ideal_remaining(day) = committed_pts * (1 - day / total_days)
actual_remaining(day) = committed_pts - completed_pts_as_of(day)
status:
  if actual <= ideal: ON_TRACK
  if actual <= ideal * 1.15: AT_RISK
  else: OFF_TRACK
```

---

## 9. Command Modifications

This section specifies exactly which files each command reads and writes after the migration.

### 9.1 `/aegis-breakdown`

**Current behavior**: Creates `_aegis-output/breakdown/US-NNN/` with summary.md, journeys/, epics/, tasks.md, tree.md. IDs generated by scanning directories.

**New behavior**:

READS:
- `_aegis-brain/counters.json`

WRITES:
- `_aegis-brain/counters.json` (increment US, J, E, T, ST counters)
- `_aegis-brain/tasks/{PROJ-US-NNN}/meta.json` (type: user_story)
- `_aegis-brain/tasks/{PROJ-US-NNN}/history.md` (CREATED entry)
- `_aegis-brain/tasks/{PROJ-US-NNN}/comments.md` (empty)
- `_aegis-brain/tasks/{PROJ-J-NNN}/meta.json` (type: journey, parent: US ID)
- `_aegis-brain/tasks/{PROJ-J-NNN}/history.md`
- `_aegis-brain/tasks/{PROJ-J-NNN}/comments.md`
- `_aegis-brain/tasks/{PROJ-E-NNN}/meta.json` (type: epic, parent: J ID)
- `_aegis-brain/tasks/{PROJ-E-NNN}/history.md`
- `_aegis-brain/tasks/{PROJ-E-NNN}/comments.md`
- `_aegis-brain/tasks/{PROJ-T-NNN}/meta.json` (type: task, parent: E ID)
- `_aegis-brain/tasks/{PROJ-T-NNN}/history.md`
- `_aegis-brain/tasks/{PROJ-T-NNN}/comments.md`
- `_aegis-brain/tasks/{PROJ-ST-NNN}/meta.json` (type: subtask, parent: T ID)
- `_aegis-brain/tasks/{PROJ-ST-NNN}/history.md`
- `_aegis-brain/tasks/{PROJ-ST-NNN}/comments.md`
- `_aegis-output/breakdown/{PROJ-US-NNN}/` (existing output structure, unchanged)
- `_aegis-brain/logs/activity.log` (append)

**Key change**: Every entity in the breakdown hierarchy gets its own task directory with meta.json and history.md. The parent field links the hierarchy. The children array on the parent is also populated.

**meta.json initial values for breakdown-created tasks:**

```
status: "BACKLOG"
assignee: "unassigned"
sprint: null
priority: inferred from position in hierarchy (P2 for first journey tasks, P3 default)
```

### 9.2 `/aegis-kanban move TASK-ID COLUMN`

**Current behavior**: Reads kanban.md, validates transition and WIP, rewrites kanban.md, logs to activity.log.

**New behavior**:

READS:
- `_aegis-brain/tasks/{TASK-ID}/meta.json`
- `_aegis-brain/sprints/sprint-N/metrics.json` (for WIP counts)
- All `meta.json` files in current sprint (for WIP limit check)

WRITES:
- `_aegis-brain/tasks/{TASK-ID}/meta.json` (update status, updated timestamp)
- `_aegis-brain/tasks/{TASK-ID}/history.md` (append MOVED row)
- `_aegis-brain/sprints/sprint-N/metrics.json` (recompute task counts and burndown)
- `_aegis-brain/sprints/sprint-N/kanban.md` (regenerate from all task meta.json files)
- `_aegis-brain/logs/activity.log` (append)

**Kanban.md regeneration protocol**:

After every state change, the kanban board is regenerated by:
1. Reading all `meta.json` files where `sprint` equals the current sprint.
2. Grouping tasks by status.
3. Writing the kanban.md using the existing visual format from `skills/kanban-board.md`.

This makes kanban.md a derived view, not a source of truth. If kanban.md is lost or corrupted, it can be regenerated from meta.json files at any time.

**WIP limit check**: Count tasks in the target status from meta.json files, not from kanban.md.

**Gate enforcement**: Unchanged from current implementation. Gate results are additionally written to history.md.

### 9.3 `/aegis-kanban add "description" [pts]`

**Current behavior**: Scans kanban for highest TASK-ID, creates entry in kanban.md BACKLOG.

**New behavior**:

READS:
- `_aegis-brain/counters.json`

WRITES:
- `_aegis-brain/counters.json` (increment T counter)
- `_aegis-brain/tasks/{PROJ-T-NNN}/meta.json` (new task, status: BACKLOG)
- `_aegis-brain/tasks/{PROJ-T-NNN}/history.md` (CREATED entry)
- `_aegis-brain/tasks/{PROJ-T-NNN}/comments.md` (empty)
- `_aegis-brain/sprints/sprint-N/kanban.md` (regenerate if task is in active sprint)
- `_aegis-brain/logs/activity.log` (append)

### 9.4 `/aegis-sprint plan`

**Current behavior**: Reads backlog.md, calculates capacity from previous close.md, creates sprint dir with plan.md and kanban.md.

**New behavior**:

READS:
- `_aegis-brain/tasks/*/meta.json` (where status = BACKLOG, sprint = null)
- `_aegis-brain/sprints/sprint-{N-1}/metrics.json` (for velocity_history)
- `_aegis-brain/counters.json`

WRITES:
- `_aegis-brain/sprints/sprint-N/` (create directory)
- `_aegis-brain/sprints/sprint-N/metrics.json` (initial metrics with committed tasks)
- `_aegis-brain/sprints/sprint-N/plan.md` (existing format)
- `_aegis-brain/sprints/sprint-N/kanban.md` (generated from selected task meta.json files)
- `_aegis-brain/sprints/current` (update symlink to sprint-N)
- For each selected task: `_aegis-brain/tasks/{ID}/meta.json` (set sprint = "sprint-N", status = TODO)
- For each selected task: `_aegis-brain/tasks/{ID}/history.md` (append SPRINT_ASSIGNED and MOVED rows)
- `_aegis-brain/logs/activity.log` (append)

**Capacity calculation**: Uses `velocity_history` from the most recent metrics.json instead of parsing close.md files. Rolling average of last 5 values times 0.9.

### 9.5 `/aegis-sprint close`

**Current behavior**: Counts DONE points in kanban.md, computes rolling average from old close.md files, writes close.md, moves incomplete tasks to backlog.

**New behavior**:

READS:
- `_aegis-brain/sprints/sprint-N/metrics.json`
- All `meta.json` files in current sprint

WRITES:
- `_aegis-brain/sprints/sprint-N/metrics.json` (set actual_end, final task counts, update velocity_history)
- `_aegis-brain/sprints/sprint-N/close.md` (existing format)
- For each incomplete task: `_aegis-brain/tasks/{ID}/meta.json` (set sprint = null, status = BACKLOG)
- For each incomplete task: `_aegis-brain/tasks/{ID}/history.md` (append MOVED row with note "Carried over from sprint-N")
- `_aegis-brain/sprints/sprint-N/metrics.json` (populate carry_over object)
- `_aegis-brain/logs/activity.log` (append)

**Velocity history propagation**: The closing sprint's completed_pts is appended to velocity_history. Only the last 5 entries are kept.

### 9.6 `/aegis-sprint standup`

**Current behavior**: Reads activity.log and kanban.md, writes daily standup file.

**New behavior**:

READS:
- `_aegis-brain/sprints/sprint-N/metrics.json`
- All `meta.json` files in current sprint
- `_aegis-brain/tasks/*/history.md` (last 24 hours of entries)

WRITES:
- `_aegis-brain/sprints/sprint-N/daily/{YYYY-MM-DD}.md` (existing format)
- `_aegis-brain/sprints/sprint-N/metrics.json` (append daily_burndown entry if new day)

### 9.7 `/aegis-sprint status`

**Current behavior**: Read-only display from kanban.md.

**New behavior**: Read-only display from `metrics.json`. No files written. Unchanged in output format.

### 9.8 `/aegis-qa gate`

**Current behavior**: Runs QA checks, writes report to `_aegis-output/qa/`.

**New behavior (additional writes)**:

READS:
- `_aegis-brain/tasks/{TASK-ID}/meta.json`

WRITES (in addition to existing QA report output):
- `_aegis-brain/tasks/{TASK-ID}/history.md` (append GATE_PASS or GATE_FAIL row)
- `_aegis-brain/tasks/{TASK-ID}/comments.md` (append QA summary if findings exist)

The gate result is now recorded in two places: the existing `_aegis-output/qa/` report (for detailed findings) and the task history (for state tracking).

### 9.9 `/aegis-compliance generate`

**Current behavior**: Generates ISO 29110 documents to `_aegis-output/iso-docs/`.

**New behavior**:

READS:
- `_aegis-output/iso-docs/doc-registry.json`
- `_aegis-brain/counters.json`

WRITES:
- `_aegis-brain/counters.json` (increment DOC counter if new document)
- `_aegis-output/iso-docs/{doc-type-slug}/v{N}.md` (versioned document)
- `_aegis-output/iso-docs/{doc-type-slug}/current.md` (copy of latest)
- `_aegis-output/iso-docs/{doc-type-slug}/changelog.md` (append entry)
- `_aegis-output/iso-docs/doc-registry.json` (add or update entry)

---

## 10. Concurrency and Write Safety

### 10.1 Single-Writer Rule

The existing AEGIS rule holds: **only Captain America writes to state files**. Other agents send StatusUpdate messages to Captain America, who performs the actual file writes. This eliminates concurrent write conflicts.

### 10.2 Counter Atomicity

Because Captain America is the single writer, the read-increment-write cycle on `counters.json` is effectively atomic. If AEGIS ever moves to multi-writer, this file would need file locking or a compare-and-swap mechanism.

### 10.3 Append-Only Safety

`history.md` and `comments.md` are append-only. Even if a write is interrupted, the worst case is a partial last row, which is detectable and recoverable.

---

## 11. Migration Path

### 11.1 Phase 1: Foundation (implement first)

1. Create `_aegis-brain/counters.json` with counters initialized to 0.
2. Create `_aegis-brain/tasks/` directory.
3. Update `/aegis-breakdown` to create task directories alongside existing breakdown output.
4. Update `/aegis-kanban add` to create task directories.

### 11.2 Phase 2: State Migration (implement second)

1. Update `/aegis-kanban move` to write meta.json + history.md and regenerate kanban.md.
2. Update `/aegis-sprint plan` to write metrics.json and update task meta.json sprint fields.
3. Update `/aegis-sprint close` to write final metrics and update velocity_history.

### 11.3 Phase 3: Reporting (implement third)

1. Create `/aegis-dashboard` command.
2. Update `/aegis-sprint standup` to read from metrics.json.
3. Update `/aegis-sprint status` to read from metrics.json.

### 11.4 Phase 4: Document Versioning (implement fourth)

1. Create `_aegis-output/iso-docs/doc-registry.json`.
2. Update `/aegis-compliance generate` to follow versioning protocol.

### 11.5 Backward Compatibility

During migration, commands that previously read `kanban.md` as source of truth will continue to work because kanban.md is still generated. The difference is that kanban.md is now a derived view, not the canonical state. If a command reads kanban.md and it is stale, the regeneration step corrects it.

---

## 12. Non-Functional Requirements

### 12.1 Performance

- Reading all meta.json files for a sprint (typical: 8-15 tasks) involves 8-15 small file reads. This is acceptable for a file-based system.
- The dashboard command performs the most reads (all tasks + metrics + doc-registry). For projects with fewer than 200 tasks, this completes in under 2 seconds.
- If task count exceeds 200, introduce a sprint-scoped index file (`sprint-N/task-index.json`) that caches task IDs and statuses to avoid scanning all directories.

### 12.2 Storage

- Each task directory uses approximately 1-3 KB (meta.json ~500B, history.md ~200B-2KB, comments.md ~0-5KB).
- A project with 500 tasks uses approximately 1.5 MB of state. This is negligible.

### 12.3 Recoverability

- If `counters.json` is lost, it can be reconstructed by scanning all task directories and finding the maximum ID for each prefix.
- If a `meta.json` is lost, the task still exists in history.md and can be partially reconstructed.
- If `kanban.md` is lost, it is regenerated from meta.json files on the next state change or by running `/aegis-kanban` (show board).
- If `metrics.json` is lost, it can be recomputed from task meta.json files and daily standup files.

### 12.4 Security

- No sensitive data is stored in task metadata by default. If credentials or secrets appear in comments, they are the responsibility of the commenting agent.
- File permissions follow OS defaults. No additional access control is implemented at the file level.

---

## 13. Trade-Off Analysis

| Decision | Alternative Considered | Rationale for Choice |
|----------|----------------------|---------------------|
| JSON meta.json per task | Single tasks.json with all tasks | Per-task files avoid merge conflicts when multiple tasks change in sequence; easier to inspect individually |
| Append-only history.md | JSON array in meta.json | Markdown is human-readable in git diffs; append-only is simpler and safer than array manipulation |
| Regenerated kanban.md | kanban.md as source of truth | Eliminates state drift between kanban and task metadata; kanban becomes a view |
| File copy for current.md | Symlink for current version | Symlinks cause issues on some platforms and in some git configurations; file copy is universally portable |
| Single counters.json | Per-type counter files | One file is simpler to manage; the single-writer rule prevents contention |
| No database | SQLite or similar | Markdown + JSON is readable by all agents without drivers, inspectable in any editor, and diffs cleanly in git |

---

## 14. Open Questions for Review

1. Should the `project_key` in counters.json be configurable per session, or fixed at project initialization?
2. Should CANCELLED tasks have their directories archived (moved to `_aegis-brain/tasks/.archive/`) or kept in place with a terminal status?
3. Should the dashboard command support filtering (e.g., `/aegis-dashboard --agent spider-man` or `/aegis-dashboard --sprint sprint-2`)?
4. What is the maximum sprint duration to enforce in metrics.json validation?

---

**Next steps**: This spec requires review by Black Panther (structural integrity) or Loki (adversarial testing of edge cases) before implementation begins. After approval, implementation should follow the phased migration path in Section 11.
