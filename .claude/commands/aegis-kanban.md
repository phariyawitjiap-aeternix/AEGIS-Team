---
name: aegis-kanban
description: "View and manage the kanban board — show board, move tasks, add tasks, check WIP limits"
triggers:
  en: kanban, board
  th: คันบัง, บอร์ด
---

# /aegis-kanban

## Quick Reference
Interact with the sprint kanban board. Default action shows the board. Subcommands let you
move tasks, add new ones, and check WIP status.

- **Board file**: `_aegis-brain/sprints/current/kanban.md`
- **Skill**: `kanban-board` (see `skills/kanban-board.md` for full rules)
- **Single writer**: Only Navi writes to `kanban.md`

**Usage**:
```
/aegis-kanban                          # Show board (default)
/aegis-kanban move TASK-NNN COLUMN     # Move task to column
/aegis-kanban add "description" [pts]  # Add task to BACKLOG
/aegis-kanban wip                      # Show WIP limit status
```

## Full Instructions

### Subcommand: (default) — Show Board

**When**: `/aegis-kanban` with no arguments.

1. Read `_aegis-brain/sprints/current/kanban.md`.
2. If file does not exist, report: `No kanban board found. Run sprint planning first or use /aegis-kanban add to seed the backlog.`
3. Display the board using the compact visual format defined in `skills/kanban-board.md`:

```
KANBAN — Sprint <N> | Updated: <timestamp>

BACKLOG (2)        TODO (1)           IN_PROGRESS (1/3)  IN_REVIEW (0/2)    QA (1)             DONE (1)
─────────────────  ─────────────────  ─────────────────  ─────────────────  ─────────────────  ─────────────────
TASK-005 [3pts]    TASK-004 [2pts]    TASK-003 [5pts]                       TASK-001 [5pts]    TASK-000 [2pts]
@unassigned        @bolt              @bolt                                  @sentinel          @bolt
```

4. Below the board, show summary stats:
```
Total: <N> tasks | <pts> points | Done: <pts>/<total> (<pct>%)
```

---

### Subcommand: move TASK-ID COLUMN

**When**: `/aegis-kanban move TASK-003 IN_REVIEW`

1. Read current board from `_aegis-brain/sprints/current/kanban.md`.
2. Find `TASK-ID` in the board. If not found, error: `Task TASK-NNN not found on board.`
3. Validate the transition using the transition rules from `skills/kanban-board.md`:
   - Check the move is an allowed transition (no skipping columns).
   - Check WIP limits for the target column.
4. If validation fails, report the specific reason:
   - `[BLOCKED] Cannot move TASK-NNN to IN_PROGRESS: WIP limit reached (3/3)`
   - `[INVALID] Cannot move TASK-NNN from TODO to QA: skipping columns not allowed`
5. If validation passes:
   - Move the task entry to the target column section.
   - Update the checkbox: `[ ]` for BACKLOG/TODO, `[~]` for IN_PROGRESS/IN_REVIEW/QA, `[x]` for DONE.
   - Update `Last updated` timestamp.
   - Write the file.
6. Display the updated board.
7. Log to `_aegis-brain/logs/activity.log`:
   ```
   [YYYY-MM-DD HH:MM] KANBAN_MOVE | task=TASK-NNN | from=<old_col> | to=<new_col>
   ```

---

### Subcommand: add "description" [pts]

**When**: `/aegis-kanban add "Implement auth middleware" 5`

1. Read current board. If no board exists, initialize one (see Board Initialization in `skills/kanban-board.md`).
2. Determine the next available TASK-ID by scanning for the highest existing ID and incrementing.
3. Default points to 3 if not specified.
4. Add the new task to the BACKLOG column:
   ```
   - [ ] TASK-NNN: <description> [<pts>pts] @unassigned
   ```
5. Update `Last updated` timestamp.
6. Write the file.
7. Display confirmation:
   ```
   Added TASK-NNN: <description> [<pts>pts] to BACKLOG
   ```
8. Log to `_aegis-brain/logs/activity.log`:
   ```
   [YYYY-MM-DD HH:MM] KANBAN_ADD | task=TASK-NNN | points=<pts> | column=BACKLOG
   ```

---

### Subcommand: wip

**When**: `/aegis-kanban wip`

1. Read current board.
2. Count tasks in each WIP-limited column.
3. Display WIP status:

```
WIP Status:
  IN_PROGRESS: 2/3 (1 slot available)
  IN_REVIEW:   2/2 (FULL — no moves allowed)
```

4. If any column is at limit, list the tasks occupying it so the user can decide what to unblock.

---

### Error Handling

- **No board file**: Prompt to run sprint planning or use `add` subcommand.
- **Invalid TASK-ID format**: Report expected format `TASK-NNN`.
- **Invalid COLUMN name**: Report valid columns: `BACKLOG, TODO, IN_PROGRESS, IN_REVIEW, QA, DONE`.
- **Concurrent write conflict**: If file changed between read and write, re-read and retry once.
