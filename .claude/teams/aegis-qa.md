---
name: aegis-qa
description: "QA team: test planning, execution, and verdict"
lead: sentinel
members: [probe]
mode: in-process
requires: agent-teams
---

## Team Purpose
Quality assurance pipeline: Sentinel plans tests -> Probe executes -> Sentinel issues verdict.

## Input Contract

```json
{
  "team": "qa",
  "trigger": "task_status == QA (set by Gate 1 PASS from build team)",
  "required_inputs": {
    "task_meta": "_aegis-brain/tasks/{TASK-ID}/meta.json",
    "spec": "_aegis-output/specs/{TASK-ID}-spec.md",
    "code_files": "list from handoff envelope artifacts",
    "review_report": "_aegis-output/reviews/{TASK-ID}-review.md",
    "gate_1_result": "PASS (from handoff envelope)"
  }
}
```

## Task Breakdown

### 1. Sentinel (sonnet): Write test plan
- Reads: Spec (acceptance criteria), code files, review report
- Produces: `_aegis-output/qa/sprint-N/test-plan-{TASK-ID}.md`
- Each test case includes: ID, description, preconditions, steps, expected result, priority (P0-P3)

### 2. Probe (haiku): Execute test cases
- Reads: Test plan from Sentinel
- Executes: Test cases via shell commands, manual verification steps
- Produces: `_aegis-output/qa/sprint-N/raw-results-{TASK-ID}.md`
- Per-test: ID, status (PASS/FAIL/SKIP/ERROR), actual result, duration, evidence
- Parallelism: Multiple Probe instances can run independent test batches

### 3. Sentinel (sonnet): Analyze results and issue verdict
- Reads: Raw results from Probe, original test plan
- Produces: `_aegis-output/qa/sprint-N/qa-report-{TASK-ID}.md`
- Verdict: PASS, CONDITIONAL, or FAIL
- Gate 2 criteria: P0 tests 100%, overall >= 95%, 0 regressions

## Communication Flow
Sentinel -> test plan -> Probe
Probe -> raw results -> Sentinel
Sentinel -> QA verdict -> Navi / next team

## Output Contract

```json
{
  "from_team": "qa",
  "to_team": "compliance OR build",
  "task_id": "PROJ-T-XXX",
  "status": "QA_PASS OR QA_FAIL",
  "artifacts": {
    "test_plan": "_aegis-output/qa/sprint-N/test-plan-{TASK-ID}.md",
    "raw_results": "_aegis-output/qa/sprint-N/raw-results-{TASK-ID}.md",
    "qa_report": "_aegis-output/qa/sprint-N/qa-report-{TASK-ID}.md"
  },
  "gate_results": {
    "gate_2": "PASS or FAIL",
    "gate_2_reviewer": "sentinel",
    "gate_2_timestamp": "ISO timestamp",
    "pass_rate": "percentage",
    "regressions": 0
  }
}
```

## Handoff Rules
- **PASS** -> aegis-compliance team (Scribe verifies/generates ISO docs)
- **FAIL** -> back to aegis-build team with QA findings; task status -> IN_PROGRESS

## Skip Condition
Tasks under 3 story points skip QA team entirely. Vigil's Gate 1 code review is sufficient.

## ISO Triggers
- **SI.05** (Test Report): Scribe generates after Sentinel issues verdict

## Output
_aegis-output/qa/sprint-N/qa-report-{TASK-ID}.md
