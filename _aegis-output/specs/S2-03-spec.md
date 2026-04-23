# S2-03 Spec: BLOCK 0 Lite-Mode Gate Switching

> A surgical wiring task. The `aegis-block0-mode.sh` helper already exists and
> passes 26/26 assertions. The agent prompts already document the mode table.
> What's missing is the **runtime behavior**: when Nick Fury actually runs a
> BLOCK 0 check during `/aegis-start` or task pickup, it must call the helper,
> read the mode, and conditionally skip checks 0A/0B/0E based on the result.
> Coulson must similarly branch. The goal is proportional overhead -- a 1pt typo
> should not burn 5,000 tokens on SI.01/SI.02 generation.

## 1. Problem Statement

BLOCK 0 currently runs all five checks (0A-0E) for every task regardless of
size or tags. The helper `tools/aegis-block0-mode.sh` computes the correct
mode (`lite`/`standard`/`full`) but nothing in the runtime pipeline actually
invokes it or branches on the result. This is the "policy without enforcement"
bug class identified in AEGIS lesson `2026-04-22_policy-without-test-bug-class.md`.

## 2. Scope

| In Scope | Out of Scope |
|----------|-------------|
| Wire helper call into Nick Fury's BLOCK 0 check path | Writing the helper (already done) |
| Branch 0A/0B/0E enforcement by mode | Loki counter tag validation (S2-04) |
| Log skips to activity.log | Behavioral end-to-end test harness |
| Write mode to task meta.json on first determination | UI/dashboard changes |
| Coulson conditional generation based on mode | New ISO doc templates |

## 3. Architecture

### Layer / Responsibility / Interface

| Layer | Responsibility | Interface |
|-------|----------------|-----------|
| Helper | Compute mode from points+tags or meta.json | `tools/aegis-block0-mode.sh` (stdout: lite/standard/full) |
| Nick Fury Runtime | Call helper, branch BLOCK 0 checks, log skips | `.claude/agents/nick-fury.md` BLOCK 0 section (agent prompt) |
| Coulson Runtime | Read mode from meta.json, skip doc generation | `.claude/agents/coulson.md` BLOCK 0 section (agent prompt) |
| Activity Log | Audit trail for skipped checks | `.aegis/brain/logs/activity.log` |
| Task Meta | Persist mode for re-dispatch stability | `.aegis/brain/tasks/<ID>/meta.json` |

### Mode / Checks Enforced / Checks Skipped

| Mode | 0A (PM.01) | 0B (SI.01) | 0C (tasks) | 0D (kanban) | 0E (SI.02) |
|------|-----------|-----------|-----------|-----------|-----------|
| `lite` | skip | skip | require | require | skip |
| `standard` | require | require | require | require | skip |
| `full` | require | require | require | require | require |

## 4. Implementation Plan

### 4a. Nick Fury Agent Prompt Changes (`nick-fury.md`)

**Current state**: The BLOCK 0 section at lines 253-344 already documents the
mode table and helper usage. However, there is no executable pseudocode showing
the branching logic Nick Fury must follow at runtime.

**Required change**: Add a concrete decision procedure between the mode table
(line 279) and the individual check definitions (line 301). This procedure is
what Nick Fury's runtime actually follows:

```
BLOCK_0_PROCEDURE(task):
  1. Determine mode:
     IF task has meta.json with block0_mode field:
       MODE = meta.json.block0_mode
     ELIF task has meta.json with points/tags:
       MODE = $(tools/aegis-block0-mode.sh --task-id <TASK-ID>)
       Write MODE to meta.json.block0_mode
     ELSE:
       # Nick Fury infers points+tags from task title + PR description.
       # Points: /aegis-breakdown conventions (1=chore, 3=feat, 5+=epic).
       # Tags: from commit-footer or PR labels.
       # If inference is ambiguous, default to `full` mode.
       MODE = $(tools/aegis-block0-mode.sh --points <inferred-N> --tags <inferred-tags>)

  2. Log mode determination:
     Append to activity.log: "[HOOK:block0] task=<ID> mode=<MODE> determined"

  3. Run checks per mode:
     FOR each check in [0A, 0B, 0C, 0D, 0E]:
       IF mode_table[MODE][check] == "skip":
         Log: "[HOOK:block0] task=<ID> mode=<MODE> skipped=<check>"
         CONTINUE
       ELSE:
         Run standard check (existing logic)
         IF FAIL: dispatch Coulson to fix, block until resolved

  4. Emit BLOCK 0 result:
     "BLOCK 0: PASS (mode=<MODE>, skipped=[list])"
```

### 4b. Coulson Agent Prompt Changes (`coulson.md`)

**Current state**: Lines 30-54 already have the mode-aware generation table and
skip logging format. This section is ALREADY correctly wired from a previous
session's prompt edit.

**Required change**: Verify the existing wiring is complete. If Coulson's BLOCK 0
checklist (lines 56-65) still shows all 5 docs unconditionally, add a guard:

```
COULSON_BLOCK0(task):
  MODE = read task.meta.json.block0_mode (default: "full")
  FOR each doc in [PM.01, SI.01, tasks, kanban, SI.02]:
    IF mode_table[MODE][doc] == "skip":
      Log skip to activity.log
      SKIP generation
    ELSE:
      Generate if missing (existing logic)
```

### 4c. Meta.json Schema Extension

Tasks MAY include `block0_mode` field. On first BLOCK 0 check, Nick Fury writes
the computed mode to this field. Subsequent checks read from meta (no re-computation).

```json
{
  "block0_mode": "lite | standard | full"
}
```

### 4d. Activity Log Format

All mode determinations and skips logged as:
```
[2026-04-22T10:00:00Z] [HOOK:block0] task=S2-03 mode=standard determined
[2026-04-22T10:00:01Z] [HOOK:block0] task=S2-03 mode=standard skipped=0E
```

## 5. Severity / Handler / Escalation

| Severity | Condition | Handler |
|----------|-----------|---------|
| P0 | Mode helper returns non-zero exit | Fall back to `full` mode, log error |
| P1 | Task tagged `chore` but modifies `.claude/` paths | Override to `full` (Loki counter, S2-04) |
| P2 | meta.json missing block0_mode field | Compute + write on first check |

## 6. Acceptance Criteria

- [ ] Nick Fury calls `tools/aegis-block0-mode.sh` before running BLOCK 0 checks
- [ ] Mode result branches which checks run (lite skips 0A/0B/0E, standard skips 0E)
- [ ] Skipped checks logged to activity.log with `[HOOK:block0]` prefix
- [ ] Mode written to task meta.json on first determination
- [ ] Coulson skips doc generation for checks not required by mode
- [ ] Helper failure (exit != 0) falls back to `full` mode (safe default)
- [ ] No regression: `full` mode behavior identical to pre-change behavior
- [ ] A `lite`-mode task produces at least one activity.log line containing `skipped=0A` AND does NOT produce 0A/0B/0E output artifacts (PM.01, SI.01, SI.02). This criterion prevents the policy-without-test bug class.

## 7. Do's and Don'ts

**Do:**
- Always fall back to `full` if mode determination fails
- Always log skips -- auditability is the contract
- Read mode from meta.json on re-dispatch (don't re-compute)
- Test with `tools/aegis-block0-mode-test.sh` (26 assertions) after any helper change

**Don't:**
- Don't skip 0C (tasks) or 0D (kanban) in any mode -- traceability minimum
- Don't let agents self-tag to escape full mode (that's S2-04 Loki counter)
- Don't modify the helper's precedence logic -- it's tested and stable
- Don't add new modes without updating both nick-fury.md and coulson.md
- Don't trust a pinned `block0_mode` if the task tags have changed since the pin was written. If a task is re-tagged (e.g., `typo` to `security`) after the pin is set, the stale `lite` pin creates a BLOCK 0 bypass. S2-04 Loki counter mitigates but does not fully prevent -- treat pins as advisory, not authoritative.

## 8. Agent Prompt Guide (Handoff)

**Spider-Man: Wire BLOCK 0 procedure into nick-fury.md**
```
Read .claude/agents/nick-fury.md lines 253-344. Between the mode table (line 279)
and BLOCK 0A (line 301), insert the BLOCK_0_PROCEDURE pseudocode from section 4a.
Wrap it in a code block labeled "BLOCK 0 Runtime Procedure". Ensure it references
tools/aegis-block0-mode.sh by path.
```

**Spider-Man: Verify Coulson wiring**
```
Read .claude/agents/coulson.md lines 30-65. Verify the mode-aware generation table
(lines 41-47) is present. If the BLOCK 0 Checklist (lines 56-65) does not have a
mode guard, add the COULSON_BLOCK0 procedure from section 4b after line 54.
```

**Spider-Man: Add integration test**
```
Create tools/aegis-block0-gate-test.sh that:
1. Creates a temp task meta.json with points=1, tags=["typo"]
2. Runs aegis-block0-mode.sh --task-id on it, asserts output = "lite"
3. Verifies the mode table lookup for lite skips 0A, 0B, 0E
4. Creates a temp task with points=8, tags=["feature"]
5. Asserts output = "full", no skips
```

**Thor: Verify lite-mode skip enforcement (Condition 1 acceptance test)**
```
Simulate a lite-mode task (points=1, tags=["typo"]). After BLOCK 0 completes:
1. Assert activity.log contains at least one line matching "skipped=0A"
2. Assert NO PM.01, SI.01, or SI.02 output files exist for the task
3. Assert 0C (tasks) and 0D (kanban) outputs DO exist
If any assertion fails, the policy-without-test bug class has re-emerged.
```

---

*Spec author: Nick Fury (acting as Iron Man) | Task: S2-03 | Sprint: sprint-v9-02*
*Requires Loki Plan-Approval Gate review before Spider-Man implementation.*
*v1.1 -- Loki conditions addressed 2026-04-23 by Iron Man (cycle=5)*
