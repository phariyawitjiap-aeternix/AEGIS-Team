# BLOCK 0 Lite Mode (S2-03)

> **Purpose**: Make BLOCK 0 (Coulson pre-work gate) proportional to task size.
> Address Loki Critical #5: "BLOCK 0 forced on every task -- 31,481 tokens/story-point"

## Problem

Current BLOCK 0 (full mode) requires for EVERY task regardless of size:
1. Coulson generates SI.01 spec
2. Coulson generates SI.02 design
3. Iron Man writes Epic/Task/Sub-task structure
4. Kanban entry created
5. Pre-implementation review

For a 1pt typo fix, this consumes ~10x the tokens of the actual fix.

## Solution: Proportional BLOCK 0

Three modes triggered by task complexity:

| Mode | Trigger | Required Artifacts | Skipped |
|------|---------|-------------------|---------|
| **lite** | task ≤ 1pt OR tag in {chore, typo, docs-fix, hotfix} | meta.json only | SI.01, SI.02, Epic, Sub-task |
| **standard** | task 2-5pt | meta.json + brief SI.01 | SI.02, Sub-task |
| **full** | task ≥6pt OR tag in {feature, refactor, security, breaking} | All artifacts | None |

## Mode Detection (Nick Fury Decision)

When Nick Fury receives a new task:

```python
def determine_block0_mode(task):
    # Tag-based override (highest priority)
    if any(tag in task.tags for tag in ['chore', 'typo', 'docs-fix', 'hotfix']):
        return 'lite'
    if any(tag in task.tags for tag in ['feature', 'refactor', 'security', 'breaking']):
        return 'full'

    # Size-based default
    if task.story_points <= 1:
        return 'lite'
    elif task.story_points <= 5:
        return 'standard'
    else:
        return 'full'
```

## Lite Mode Workflow

```
Task created (size ≤1pt or chore tag)
     │
     ▼
Coulson:
  - Create .aegis/brain/tasks/<TASK-ID>/meta.json (id, title, points, mode=lite, owner)
  - SKIP: SI.01, SI.02, Epic, Sub-task
     │
     ▼
Spider-Man / Spider-Man Direct:
  - Implement
  - Update meta.json status: in_progress → done
     │
     ▼
Black Panther:
  - Quick review (no formal gate, just visual diff check)
     │
     ▼
DONE
```

**Token estimate**: ~500 tokens overhead vs ~5000 in full mode (10x reduction)

## Standard Mode Workflow

```
Task (2-5pt)
     │
     ▼
Coulson: meta.json + brief SI.01 (≤200 lines, just goals + acceptance criteria)
     │
     ▼
Iron Man: brief design comment in SI.01 (no separate SI.02)
     │
     ▼
Spider-Man: implement
     │
     ▼
Black Panther: gate G1 (code review)
     │
     ▼
War Machine: gate G2 (QA)
     │
     ▼
DONE
```

## Full Mode Workflow (unchanged from v8.x)

Existing 6-gate pipeline. Unchanged for tasks ≥6pt or tagged as feature/refactor/security/breaking.

## Implementation Markers

For each mode, `meta.json` includes:

```json
{
  "id": "PROJ-T-042",
  "title": "Fix typo in README",
  "story_points": 1,
  "tags": ["docs-fix"],
  "block0_mode": "lite",
  "block0_artifacts": {
    "meta": true,
    "si01": false,
    "si02": false,
    "epic": false,
    "subtask": false
  }
}
```

## Migration Path

For existing v8.x tasks (no `block0_mode` field):
- Default behavior: assume `full` mode (v8.x compatible)
- New tasks: Nick Fury sets mode at creation

## Auditability

All modes log to `.aegis/brain/logs/block0-decisions.log`:

```
[2026-04-20T10:30:00Z] PROJ-T-042 mode=lite trigger=tag:docs-fix size=1pt
[2026-04-20T11:15:00Z] PROJ-T-043 mode=standard trigger=size:3pt size=3pt
[2026-04-20T14:00:00Z] PROJ-T-044 mode=full trigger=tag:security size=8pt
```

## Acceptance Criteria (S2-03 + S2-04)

- [ ] Reference doc explains 3 modes (this file)
- [ ] Decision logic documented (Python pseudocode above)
- [ ] meta.json schema includes `block0_mode` field
- [ ] Nick Fury agent updated to call `determine_block0_mode()` on task creation
- [ ] Coulson agent updated to skip artifacts based on mode
- [ ] Audit log appends per task
- [ ] Tested: 1pt typo fix uses lite mode (no SI.01)
- [ ] Tested: 8pt feature uses full mode (all artifacts)

## Loki Counter to Lite Mode

> "Lite mode could be abused -- agent tags everything as 'chore' to skip docs"

Mitigation:
- Nick Fury validates tag legitimacy on task creation
- Quarterly audit of mode distribution (alert if >40% lite)
- Tags require Iron Man approval if task size >3pt (prevents bypass)

## Trade-off Accepted

Lite mode reduces traceability for small tasks. Acceptable because:
- Small tasks have small blast radius
- Git history still tracks the change
- Time saved (~30 min/task) compounds significantly across sprint
