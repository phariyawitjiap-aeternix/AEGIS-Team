---
name: aegis-build
description: "Spec-to-implementation build team with explicit input/output contracts"
lead: bolt
members: [sage, vigil]
mode: in-process
requires: agent-teams
---

## Team Purpose
End-to-end build pipeline: Sage designs -> Bolt implements -> Vigil reviews.

## Input Contract

```json
{
  "team": "build",
  "trigger": "task_status == TODO && task.sprint == active_sprint",
  "required_inputs": {
    "task_meta": "_aegis-brain/tasks/{TASK-ID}/meta.json",
    "acceptance_criteria": "from meta.json or parent user story",
    "existing_spec": "optional -- _aegis-output/specs/{TASK-ID}-spec.md"
  }
}
```

## Task Breakdown

### 1. Sage (opus): Write/refine technical spec
- Reads: task meta.json, parent story, any existing spec
- Produces: `_aegis-output/specs/{TASK-ID}-spec.md`
- ISO trigger: Scribe generates SI.02 (Design Document) and updates SI.03 (Traceability Matrix)
- Skip condition: If spec exists and task <= 2 story points, Sage validates rather than rewrites

### 2. Bolt (sonnet): Implement based on spec
- Reads: Sage's spec file
- Produces: Source code in src/, unit tests in tests/
- Validation: Runs `lint + build + test` before reporting done
- ISO trigger: Scribe generates SI.04 (Test Cases)
- Escalation: If spec has ambiguity, sends EscalationAlert to Sage (does not guess)

### 3. Vigil (sonnet): Review implementation against spec
- Reads: Bolt's code diff, Sage's spec
- Produces: `_aegis-output/reviews/{TASK-ID}-review.md`
- Gate 1 checklist: correctness, security, performance, style, test coverage
- On PASS: task status -> QA, emit HandoffEnvelope to aegis-qa
- On FAIL: task status -> IN_PROGRESS, findings appended to task comments

## Communication Flow
Sage -> PlanProposal -> Bolt
Bolt -> StatusUpdate -> Vigil
Vigil -> FindingReport -> Bolt (iterate if needed)
Bolt -> CompletionReport -> Lead

## Pipeline
Sage spec -> GATE -> Bolt implement -> GATE -> Vigil review -> GATE -> Done

## Output Contract

```json
{
  "from_team": "build",
  "to_team": "qa",
  "task_id": "PROJ-T-XXX",
  "status": "READY_FOR_QA",
  "artifacts": {
    "spec": "_aegis-output/specs/{TASK-ID}-spec.md",
    "code_files": ["list of changed files"],
    "review": "_aegis-output/reviews/{TASK-ID}-review.md"
  },
  "gate_results": {
    "gate_1": "PASS",
    "gate_1_reviewer": "vigil",
    "gate_1_timestamp": "ISO timestamp"
  }
}
```

## Handoff Rules
- **PASS** -> aegis-qa team receives HandoffEnvelope with all artifacts
- **FAIL** -> self-fix cycle: Vigil findings go to Bolt, Bolt iterates, Vigil re-reviews

## ISO Triggers
- **SI.02** (Design Document): Generated during Sage phase from spec output
- **SI.04** (Test Cases): Generated during Bolt phase from unit test mapping

## Output
_aegis-output/builds/YYYY-MM-DD_build.md
