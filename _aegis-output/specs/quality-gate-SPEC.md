# Spec: Quality Gate Agent (aegis-quality-gate)

> ทุกชิ้นงานที่ team สร้าง ต้องถูกตรวจสอบก่อน mark DONE — ไม่มีข้อยกเว้น

**Version:** 1.0.0
**Date:** 2026-05-28
**Status:** BUILD-READY

---

## 1. Problem

Nick Fury มี gate flow ในเอกสาร (line 791-798 nick-fury.md):
```
Build → IN_REVIEW → Black Panther (Gate 1) → QA → War Machine (Gate 2) → DONE
```

แต่ **ไม่มี implementation** — ไม่มี script/hook ที่ enforce chain นี้ ผลคือ agents mark DONE โดยไม่ผ่าน review/test จริง เป็น "policy-without-test" bug class ที่เคยบันทึกไว้ใน memory

## 2. Solution

สร้าง `tools/aegis-quality-gate.sh` — single script ที่ Nick Fury/Captain America เรียกก่อน mark task DONE:

```
aegis-quality-gate.sh check <branch-or-diff>
  → Gate 1: Black Panther code review (spawn agent)
  → Gate 2: War Machine test run (spawn agent or run tests directly)
  → Gate 3: Spec compliance (diff vs acceptance criteria)
  → Verdict: PASS / FAIL + evidence file
```

## 3. Design

### Trigger Points

| When | Who calls | How |
|------|----------|-----|
| Task moves to IN_REVIEW | Nick Fury / Captain America | `bash tools/aegis-quality-gate.sh check` |
| PR created | PostToolUse hook on `gh pr create` | Auto-trigger |
| Sprint close | `aegis-sprint-close-gate.sh` chains to this | Existing gate |
| Manual | Any agent or human | `bash tools/aegis-quality-gate.sh check --branch feat/xxx` |

### Gate Sequence

```
Input: branch name or git diff scope

Gate 1 — CODE REVIEW (Black Panther)
  ├── git diff main..HEAD
  ├── Multi-pass: correctness → security → performance → maintainability
  ├── Output: findings[] with severity (critical/high/medium/low)
  └── FAIL if: any critical finding

Gate 2 — TEST RUN (direct, no agent needed)
  ├── Detect test runner: jest/vitest/pytest/bash tests/
  ├── Run test suite
  ├── Output: pass/fail count, coverage %
  └── FAIL if: any test fails OR coverage drops

Gate 3 — SPEC COMPLIANCE
  ├── Find related PBI/story (from branch name or kanban)
  ├── Read acceptance criteria
  ├── Check each AC against actual changes
  ├── Output: AC checklist with ✅/❌
  └── FAIL if: any AC not met

Verdict:
  ├── ALL PASS → write verdict file, return 0
  ├── ANY FAIL → write verdict file with findings, return 1
  └── Verdict file: .aegis/brain/state/quality-gate-<task>.json
```

### Verdict File Format

```json
{
  "task": "PBI-042",
  "branch": "feat/overdue-command",
  "timestamp": "2026-05-28T10:00:00Z",
  "verdict": "PASS",
  "gates": {
    "code_review": {
      "status": "PASS",
      "findings": 2,
      "critical": 0,
      "high": 1,
      "reviewer": "black-panther"
    },
    "tests": {
      "status": "PASS",
      "passed": 342,
      "failed": 0,
      "coverage": "87%",
      "runner": "jest"
    },
    "spec_compliance": {
      "status": "PASS",
      "ac_total": 5,
      "ac_met": 5,
      "ac_unmet": 0
    }
  },
  "evidence": ".aegis/brain/logs/quality-gate-PBI-042.log"
}
```

### CLI Interface

```
Usage: aegis-quality-gate.sh <command> [options]

Commands:
  check [--branch <name>] [--task <id>]    Run all gates
  review [--branch <name>]                  Gate 1 only (code review)
  test                                      Gate 2 only (run tests)
  spec [--task <id>]                        Gate 3 only (spec compliance)
  status [--task <id>]                      Show last verdict

Options:
  --skip-review    Skip Gate 1 (for test-only runs)
  --skip-tests     Skip Gate 2 (for review-only runs)
  --skip-spec      Skip Gate 3 (when no spec available)
  --fix            Auto-fix findings where possible (Black Panther Edit)
  --json           Output verdict as JSON
  --quiet          Only print verdict line
```

### Integration with Nick Fury Flow

Update nick-fury.md BLOCK 5 to call quality-gate instead of manual agent dispatch:

```
Before moving task to DONE:
  result=$(bash tools/aegis-quality-gate.sh check --branch "$BRANCH" --task "$TASK_ID")
  if PASS → move to DONE
  if FAIL → move back to IN_PROGRESS with findings attached
```

## 4. PBIs

### PBI-001: Gate 2 — Test Runner Detection + Execution
**Priority:** P0 (most value, least risk)

**AC:**
1. Detect test runner from package.json (jest/vitest), pytest.ini/pyproject.toml (pytest), or tests/ dir (bash)
2. Run detected suite, capture stdout/stderr
3. Parse pass/fail counts from output
4. Return PASS if all tests pass, FAIL if any fail
5. Timeout after 5 minutes

**DEV Notes:**
- Parse `package.json` scripts for `test` command
- Fallback chain: `npm test` → `npx jest` → `npx vitest` → `pytest` → `bash tools/aegis-test-all.sh`
- Capture exit code + parse structured output

---

### PBI-002: Gate 1 — Code Review via Black Panther Agent
**Priority:** P0

**AC:**
1. Compute git diff (main..HEAD or staged changes)
2. Spawn Black Panther agent with diff as context
3. Receive structured findings: {severity, file, line, message}
4. FAIL if any critical finding
5. WARN on high findings (don't block)
6. Timeout after 3 minutes

**DEV Notes:**
- Use `Agent` tool to spawn black-panther with the diff
- Parse agent response for findings
- Alternative for headless: call `claude -p` with black-panther review prompt

---

### PBI-003: Verdict Writer + Status Command
**Priority:** P0

**AC:**
1. Write JSON verdict to `.aegis/brain/state/quality-gate-<task>.json`
2. Append to `.aegis/brain/logs/quality-gate.jsonl`
3. `status` command reads last verdict for a task
4. Exit code reflects verdict: 0=PASS, 1=FAIL

---

### PBI-004: Gate 3 — Spec Compliance Check
**Priority:** P1 (needs PBI/kanban parsing)

**AC:**
1. Find PBI from task ID or branch name (parse kanban YAML)
2. Extract acceptance criteria
3. For each AC, check if changes address it (semantic match via git diff)
4. Output checklist with ✅/❌
5. FAIL if any AC not met

**DEV Notes:**
- This is the hardest gate — needs LLM to evaluate AC vs changes
- Use `claude -p` with focused prompt: "Given these ACs and this diff, which ACs are met?"
- Fallback: skip if no PBI found (--skip-spec implied)

---

### PBI-005: Main Orchestrator + CLI Parser
**Priority:** P0

**AC:**
1. Parse CLI arguments (check/review/test/spec/status)
2. Run gates in sequence, short-circuit on FAIL (unless --continue)
3. Print human-readable summary + write verdict
4. Return correct exit code

---

### PBI-006: Nick Fury Integration
**Priority:** P1

**AC:**
1. Update nick-fury.md BLOCK 5 to reference quality-gate
2. Add quality-gate call in task-to-DONE transition
3. Add to installer delivery list

---

## 5. Implementation Order

1. PBI-005 (CLI skeleton)
2. PBI-001 (test runner — instant value)
3. PBI-003 (verdict writer)
4. PBI-002 (code review agent)
5. PBI-004 (spec compliance)
6. PBI-006 (Nick Fury wiring)

## 6. Open Questions

| # | Question | Decision |
|---|---------|----------|
| Q1 | Gate 1 ใช้ agent spawn หรือ claude -p? | claude -p สำหรับ headless/autopilot, agent spawn สำหรับ interactive |
| Q2 | Coverage drop threshold? | Default: any drop = WARN, >5% drop = FAIL |
| Q3 | ควร auto-fix findings มั้ย? | --fix flag opt-in, ไม่ default |
