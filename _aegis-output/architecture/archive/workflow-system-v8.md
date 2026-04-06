# Architecture Specification: AEGIS v8.0 Workflow System

**ID**: ADR-008
**Author**: Iron Man (System Architect)
**Date**: 2026-03-25
**Status**: PROPOSED (pending review by Black Panther or Loki)

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Thor Agent Definition](#2-thor-agent-definition)
3. [Master SDLC Pipeline](#3-master-sdlc-pipeline)
4. [Sub-team Workflows](#4-sub-team-workflows)
5. [Handoff Protocol](#5-handoff-protocol)
6. [Feedback Loop](#6-feedback-loop)
7. [Gate Summary Matrix](#7-gate-summary-matrix)
8. [Implementation Guidance for Spider-Man](#8-implementation-guidance-for-spider-man)

---

## 1. Problem Statement

AEGIS v7.0 has 12 agents, a 3-gate quality system, and sprint/kanban mechanics. However,
the system lacks:

1. **No DevOps agent** -- builds, deploys, health checks, and rollbacks are manual or
   handled ad-hoc by Spider-Man. There is no agent responsible for infrastructure.
2. **No end-to-end SDLC pipeline** -- agents operate in teams (build, review, QA) but
   the full lifecycle from idea to production monitoring is not defined as a single
   connected flow. Handoffs between teams are implicit.
3. **No formal handoff protocol** -- when the build team finishes, how does the QA team
   know? The meta.json status field changes, but there is no structured handoff envelope
   with artifacts, gate results, and routing metadata.
4. **No feedback loop** -- production issues do not flow back into the sprint backlog
   automatically. There is no defined path from monitor to hotfix to backlog.

This specification addresses all four gaps by defining: a new Thor agent, a master SDLC
pipeline connecting all stages, five sub-team workflows with explicit contracts, a
standardized handoff protocol, and a production feedback loop.

### Design Principles

| Principle | Rationale |
|-----------|-----------|
| One pipeline, many teams | A single linear SDLC flow prevents orphaned work |
| Explicit gates, not implicit trust | Every team transition passes through a gate |
| Handoff envelopes, not status flags | Structured JSON handoffs carry context forward |
| Feedback closes the loop | Production signals re-enter the backlog automatically |
| Thor is an agent, not a script | DevOps decisions require reasoning, not just execution |

---

## 2. Thor Agent Definition

### Agent Card

| Field | Value |
|-------|-------|
| Number | 13 |
| Name | Thor |
| Model | claude-sonnet |
| Role | DevOps -- builds, deploys, monitors, rollbacks |
| Tier | sonnet (execution-heavy, needs bash access) |

### Tools

- Read, Write, Edit, Bash, Glob, Grep

### Blast Radius

- **Read**: All project files, _aegis-output/*, _aegis-brain/*, deploy configs
- **Write**: deploy/, ci/, docker/, infra/, .github/workflows/, _aegis-output/deploys/, _aegis-brain/logs/
- **Forbidden**: src/ (application code -- delegates fixes to Spider-Man), CLAUDE*.md

### Message Types

- **Sends**: StatusUpdate (deploy progress), FindingReport (health check results, error spikes), EscalationAlert (deploy failure, rollback triggered)
- **Receives**: TaskAssignment from Captain America, HandoffEnvelope from Compliance team

### Behavioral Rules

1. NEVER deploys without all three gates (Code, QA, Compliance) passing.
2. ALWAYS runs a pre-deploy build verification (clean build from branch HEAD).
3. ALWAYS runs post-deploy health checks within 60 seconds of deploy.
4. If health check fails, triggers automatic rollback before any other action.
5. Generates a deployment report after every deploy attempt (success or failure).
6. Monitors error rates for 5 minutes post-deploy; if error rate exceeds 2x baseline, triggers rollback.
7. Creates Correction Register entries (PM.3) for any deploy failure or rollback.
8. For hotfix scenarios, coordinates with Spider-Man: Thor identifies the issue, Spider-Man writes the fix, Thor redeploys.

### Agent File Location

`.claude/agents/thor.md`

### Thor Capabilities Detail

```
BUILD:
  - Detect project type (package.json -> npm, go.mod -> go, Cargo.toml -> cargo, etc.)
  - Run: clean -> install -> build -> verify artifacts exist
  - Output: build log to _aegis-output/deploys/build-<timestamp>.log

DEPLOY:
  - Read deploy config from deploy/config.yaml (environment, target, strategy)
  - Strategies: rolling, blue-green, canary (configurable per environment)
  - Execute deploy script or command sequence
  - Output: deploy log to _aegis-output/deploys/deploy-<timestamp>.log

HEALTH CHECK:
  - HTTP endpoint check (configurable URL, expected status, timeout)
  - Process check (expected processes running)
  - Log check (no FATAL/PANIC in last 60s of logs)
  - Custom checks (defined in deploy/health-checks.yaml)

ROLLBACK:
  - Revert to previous known-good deployment
  - Re-run health checks to confirm rollback success
  - If rollback also fails: CRITICAL alert to Captain America + human

MONITOR:
  - Watch error rate for 5 minutes post-deploy
  - Compare against baseline error rate (from previous deploy report)
  - If error_rate > 2x baseline: auto-rollback
  - If error_rate > 1.5x baseline: WARNING alert, continue monitoring
  - Output: monitor report to _aegis-output/deploys/monitor-<timestamp>.log
```

---

## 3. Master SDLC Pipeline

### Pipeline Overview (ASCII)

```
IDEA
  |
  v
BREAKDOWN -----> Coulson: SI.01 (Requirements Spec)
  |
  v
SPRINT_PLAN ---> Coulson: PM.01 (Project Plan), PM.04 (Meeting Record)
  |
  v
[FOR EACH TASK IN SPRINT:]
  |
  +---> SPEC ----------> Coulson: SI.02 (Design Doc)
  |       |
  |       v
  |     DESIGN ---------> Coulson: SI.03 (Traceability Matrix update)
  |       |
  |       v
  |     BUILD ----------> Coulson: SI.04 (Test Cases)
  |       |
  |       v
  |     TEST (unit) ----> [inline with BUILD]
  |       |
  |       v
  |     REVIEW ---------> Gate 1 verdict
  |       |
  |       +--- FAIL ---> back to BUILD
  |       |
  |       v (PASS)
  |     QA -------------> Coulson: SI.05 (Test Report)
  |       |
  |       +--- FAIL ---> back to BUILD
  |       |
  |       v (PASS)
  |     COMPLY ----------> Gate 3 (ISO docs current)
  |       |
  |       +--- FAIL ---> block (Coulson generates missing docs)
  |       |
  |       v (PASS)
  |     TASK DONE
  |
  v
SPRINT_CLOSE ---> Coulson: PM.04 (Meeting Record), SI.06 (Acceptance Record)
  |
  v
RELEASE
  |
  v
DEPLOY ----------> Coulson: SI.07 (Software Configuration)
  |
  v
MONITOR
  |
  +--- ERROR SPIKE ---> FEEDBACK ---> BACKLOG (hotfix task)
  |
  v
STABLE (done)
```

### Stage Definitions

#### Stage: IDEA

| Field | Value |
|-------|-------|
| WHO | Human or Nick Fury (P8/P10 detection) |
| INPUT | User request, feature idea, or Nick Fury scan finding |
| OUTPUT | Raw idea description (free text or structured) |
| HANDOFF | Saved to `_aegis-brain/ideas/` or passed directly to BREAKDOWN |
| GATE | None -- ideas are ungated |
| ISO DOC | None |

#### Stage: BREAKDOWN

| Field | Value |
|-------|-------|
| WHO | Iron Man (architecture decomposition) |
| INPUT | Idea description or spec file |
| OUTPUT | User stories, epics, tasks with story points in `_aegis-brain/tasks/` |
| HANDOFF | Tasks created as meta.json files with status=BACKLOG |
| GATE | Breakdown review -- Loki challenges completeness (optional for < 8 pts total) |
| ISO DOC | Coulson generates SI.01 (Requirements Specification) |

#### Stage: SPRINT_PLAN

| Field | Value |
|-------|-------|
| WHO | Captain America (orchestrator) via /aegis-sprint plan |
| INPUT | Backlog tasks (meta.json with status=BACKLOG), velocity history |
| OUTPUT | Sprint directory with plan.md, metrics.json, kanban.md |
| HANDOFF | Tasks updated: status=TODO, sprint=sprint-N |
| GATE | Capacity check -- committed points must not exceed 100% capacity |
| ISO DOC | Coulson generates PM.01 (Project Plan update), PM.04 (Meeting Record) |

#### Stage: SPEC

| Field | Value |
|-------|-------|
| WHO | Iron Man (architect) |
| INPUT | Task from kanban (meta.json with status=TODO) |
| OUTPUT | Technical specification in `_aegis-output/specs/` |
| HANDOFF | Spec file path recorded; task stays TODO until Spider-Man picks it up |
| GATE | Spec must contain: problem statement, solution, file list, acceptance criteria |
| ISO DOC | Coulson generates SI.02 (Design Document) |

#### Stage: DESIGN

| Field | Value |
|-------|-------|
| WHO | Iron Man (architect), Wasp (if UI task) |
| INPUT | Spec file from SPEC stage |
| OUTPUT | Detailed design: data models, API contracts, component structure |
| HANDOFF | Design appended to spec or written as separate design doc |
| GATE | Design review by Loki for tasks >= 5 story points |
| ISO DOC | Coulson updates SI.03 (Traceability Matrix -- REQ to Design link) |

#### Stage: BUILD

| Field | Value |
|-------|-------|
| WHO | Spider-Man (implementer), Wasp (if frontend) |
| INPUT | Spec + design doc from Iron Man |
| OUTPUT | Source code + unit tests in src/, tests/ |
| HANDOFF | Task status moves to IN_PROGRESS during build, then IN_REVIEW when done |
| GATE | Pre-review checks: code compiles, lint passes, unit tests pass |
| ISO DOC | Coulson generates SI.04 (Test Cases -- unit test mapping) |

#### Stage: REVIEW (Gate 1)

| Field | Value |
|-------|-------|
| WHO | Black Panther (reviewer) |
| INPUT | Code diff from BUILD stage |
| OUTPUT | Review report in `_aegis-output/reviews/` |
| HANDOFF | If PASS: task status -> QA. If FAIL: task status -> IN_PROGRESS with findings. |
| GATE | Gate 1 criteria: correctness, security, performance, style, test coverage |
| ISO DOC | None (review report is internal artifact) |

#### Stage: QA (Gate 2)

| Field | Value |
|-------|-------|
| WHO | War Machine (QA lead) + Vision (executor) |
| INPUT | Code + review report (Gate 1 PASS) |
| OUTPUT | Test plan, raw results, QA report, verdict in `_aegis-output/qa/` |
| HANDOFF | If PASS: task status -> DONE. If FAIL: task status -> IN_PROGRESS. |
| GATE | Gate 2 criteria: P0 tests 100%, overall >= 95%, 0 regressions |
| ISO DOC | Coulson generates SI.05 (Test Report) |

#### Stage: COMPLY (Gate 3)

| Field | Value |
|-------|-------|
| WHO | Coulson (compliance doc generator) |
| INPUT | All artifacts from BUILD + QA stages |
| OUTPUT | ISO 29110 documents updated in `_aegis-output/iso-docs/` |
| HANDOFF | If all docs current: task is deploy-ready. If incomplete: block. |
| GATE | Gate 3 criteria: all required ISO docs exist, are current version, traceability matrix complete |
| ISO DOC | All applicable docs verified/generated |

#### Stage: SPRINT_CLOSE

| Field | Value |
|-------|-------|
| WHO | Captain America via /aegis-sprint close |
| INPUT | All tasks in sprint, metrics.json |
| OUTPUT | close.md, updated metrics, carry-over handling |
| HANDOFF | Incomplete tasks -> BACKLOG. Sprint marked closed. |
| GATE | ISO doc check -- sprint close blocked if required docs missing/stale |
| ISO DOC | Coulson generates PM.04 (Meeting Record for close), SI.06 (Acceptance Record) |

#### Stage: RELEASE

| Field | Value |
|-------|-------|
| WHO | Captain America (creates release tag/branch) + Thor (builds release artifact) |
| INPUT | All sprint tasks DONE, all gates passed, sprint closed |
| OUTPUT | Release tag, release notes, build artifact |
| HANDOFF | HandoffEnvelope from Captain America to Thor with release metadata |
| GATE | All 3 gates passed for every task in release scope |
| ISO DOC | Coulson generates SI.07 (Software Configuration) |

#### Stage: DEPLOY

| Field | Value |
|-------|-------|
| WHO | Thor (DevOps agent) |
| INPUT | Release artifact + deploy config |
| OUTPUT | Deployment report in `_aegis-output/deploys/` |
| HANDOFF | If healthy: enter MONITOR. If unhealthy: rollback + notify. |
| GATE | Health check pass within 60 seconds |
| ISO DOC | Coulson updates SI.07 (deployment record appended) |

#### Stage: MONITOR

| Field | Value |
|-------|-------|
| WHO | Thor (monitors for 5 minutes post-deploy) |
| INPUT | Health check endpoints, error rate baseline |
| OUTPUT | Monitor report in `_aegis-output/deploys/` |
| HANDOFF | If stable: pipeline complete. If error spike: trigger FEEDBACK. |
| GATE | Error rate must stay below 2x baseline for 5 minutes |
| ISO DOC | None (operational artifact) |

#### Stage: FEEDBACK

| Field | Value |
|-------|-------|
| WHO | Thor (creates issue) -> Captain America (routes to backlog) |
| INPUT | Error spike detection from MONITOR |
| OUTPUT | Hotfix task in backlog, Correction Register entry |
| HANDOFF | Hotfix task auto-added to current sprint with CRITICAL priority |
| GATE | None -- feedback is immediate |
| ISO DOC | Coulson generates PM.03 (Correction Register entry) |

---

## 4. Sub-team Workflows

### 4.1 Build Team (Iron Man -> Spider-Man -> Black Panther)

```
                   +----------+
                   |  KANBAN   |  task with status=TODO
                   |  (input)  |
                   +-----+----+
                         |
                         v
                   +----------+
                   |   IRON MAN   |  Read task meta.json + acceptance criteria
                   | (spec)   |  Write: _aegis-output/specs/{TASK-ID}-spec.md
                   +-----+----+
                         |
                   [spec ready]
                         |
                         v
                   +----------+
                   |   SPIDER-MAN   |  Read spec, implement code + unit tests
                   | (build)  |  Write: src/, tests/
                   +-----+----+  Run: lint, build, test
                         |
                   [build done]
                         |
                         v
                   +----------+
                   |  BLACK PANTHER   |  4-pass review: correctness, security,
                   | (review) |  performance, maintainability
                   +-----+----+  Write: _aegis-output/reviews/{TASK-ID}-review.md
                         |
                   +------+------+
                   |             |
                 PASS          FAIL
                   |             |
                   v             v
             [Gate 1 PASS]  [Back to SPIDER-MAN with findings]
```

#### Input Contract

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

#### Phase: Iron Man

- **Reads**: task meta.json, parent story meta.json (if exists), any existing spec
- **Produces**: `_aegis-output/specs/{TASK-ID}-spec.md` containing problem statement, proposed solution, file list, data models (if applicable), acceptance criteria mapping
- **ISO trigger**: Coulson generates SI.02 (Design Document) and updates SI.03 (Traceability Matrix)
- **Duration budget**: 2-5 minutes depending on task complexity
- **Skip condition**: If a spec already exists and task is <= 2 story points, Iron Man validates rather than rewrites

#### Phase: Spider-Man

- **Reads**: Iron Man's spec file
- **Produces**: Source code in src/, unit tests in tests/
- **Validation**: Runs `lint + build + test` before reporting done
- **Status updates**: Moves task to IN_PROGRESS in meta.json at start; sends StatusUpdate to Black Panther when done
- **ISO trigger**: Coulson generates SI.04 (Test Cases)
- **Escalation**: If spec has ambiguity, sends EscalationAlert to Iron Man (does not guess)

#### Phase: Black Panther

- **Reads**: Spider-Man's code diff (`git diff`), Iron Man's spec (for compliance check)
- **Produces**: `_aegis-output/reviews/{TASK-ID}-review.md` with verdict: PASS, CONDITIONAL, or FAIL
- **Gate 1 checklist**:
  - Correctness: code matches spec requirements
  - Security: no injection, no hardcoded secrets, proper auth checks
  - Performance: no O(n^2) in hot paths, no unbounded queries
  - Style: follows project conventions, proper naming
  - Test coverage: new code has corresponding tests
- **On PASS**: Moves task status to QA in meta.json. Writes Gate 1 result to task history.md. Emits HandoffEnvelope to QA team.
- **On FAIL**: Moves task status back to IN_PROGRESS. Appends findings to task comments.md. Spider-Man receives findings and iterates.

#### Output Contract

```json
{
  "from_team": "build",
  "to_team": "qa",
  "task_id": "PROJ-T-042",
  "status": "READY_FOR_QA",
  "artifacts": {
    "spec": "_aegis-output/specs/PROJ-T-042-spec.md",
    "code_files": ["src/auth/middleware.ts", "src/auth/middleware.test.ts"],
    "review": "_aegis-output/reviews/PROJ-T-042-review.md"
  },
  "gate_results": {
    "gate_1": "PASS",
    "gate_1_reviewer": "black-panther",
    "gate_1_timestamp": "2026-03-25T14:30:00Z"
  },
  "notes": "Rate limit added per Black Panther finding F-003"
}
```

---

### 4.2 Review Team (Beast -> Loki -> Black Panther)

```
                   +---------------+
                   | CODE / PR     |  code from Build team or external PR
                   | (input)       |
                   +-------+-------+
                           |
                           v
                   +---------------+
                   |    BEAST      |  Scan: complexity, deps, security signatures
                   |  (scanner)    |  Write: _aegis-brain/logs/scan-{TASK-ID}.md
                   +-------+-------+
                           |
                   [scan data ready]
                           |
                           v
                   +---------------+
                   |    LOKI      |  Challenge: assumptions, edge cases, threats
                   |  (adversary)  |  Write: _aegis-output/adversarial/{TASK-ID}.md
                   +-------+-------+
                           |
                   [challenges documented]
                           |
                           v
                   +---------------+
                   |    BLACK PANTHER      |  Deep review with Beast data + Loki challenges
                   |  (reviewer)   |  Write: _aegis-output/reviews/{TASK-ID}-deep-review.md
                   +-------+-------+
                           |
                   +-------+-------+
                   |               |
                 PASS            FAIL
                   |               |
                   v               v
             [-> QA team]    [-> Build team with findings]
```

#### Input Contract

```json
{
  "team": "review",
  "trigger": "manual request OR task.points >= 8 OR task.labels includes 'security'",
  "required_inputs": {
    "code_diff": "git diff for the task branch or PR",
    "spec": "_aegis-output/specs/{TASK-ID}-spec.md",
    "task_meta": "_aegis-brain/tasks/{TASK-ID}/meta.json"
  }
}
```

#### Phase: Beast

- **Reads**: All changed files, dependency tree, git history
- **Produces**: `_aegis-brain/logs/scan-{TASK-ID}.md` with metrics: cyclomatic complexity, dependency count, file size, known CVE matches, code duplication percentage
- **Duration budget**: < 30 seconds (haiku tier, parallel scans)

#### Phase: Loki

- **Reads**: Beast's scan data, spec file, code diff
- **Produces**: `_aegis-output/adversarial/{TASK-ID}.md` with threat model: assumption challenges, edge cases, failure modes, suggested mitigations
- **Duration budget**: 2-3 minutes (opus tier, deep reasoning)
- **Required output**: At least 3 challenges with constructive alternatives

#### Phase: Black Panther

- **Reads**: Code diff, Beast scan, Loki challenges, spec
- **Produces**: `_aegis-output/reviews/{TASK-ID}-deep-review.md` -- enhanced review incorporating scan data and adversarial findings
- **Verdict**: PASS (proceed to QA), FAIL (return to Build with consolidated findings)

#### Output Contract

```json
{
  "from_team": "review",
  "to_team": "build OR qa",
  "task_id": "PROJ-T-042",
  "status": "REVIEW_PASS OR REVIEW_FAIL",
  "artifacts": {
    "scan": "_aegis-brain/logs/scan-PROJ-T-042.md",
    "adversarial": "_aegis-output/adversarial/PROJ-T-042.md",
    "deep_review": "_aegis-output/reviews/PROJ-T-042-deep-review.md"
  },
  "findings_summary": {
    "critical": 0,
    "high": 1,
    "medium": 3,
    "low": 2
  },
  "verdict": "PASS",
  "notes": "Loki identified race condition in concurrent access; Spider-Man must add mutex"
}
```

#### When Review Team Is Triggered

The Review Team is not part of the default pipeline for every task. It activates when:

1. Task story points >= 8 (complex work needs deeper scrutiny)
2. Task labels include "security", "architecture", or "critical-path"
3. Manual request from Captain America or human
4. Black Panther's standard Gate 1 review flags a CONDITIONAL verdict with >= 2 high-severity findings

When the Review Team runs, its deep review verdict replaces the standard Gate 1 verdict.

---

### 4.3 QA Team (War Machine -> Vision -> War Machine)

```
                   +------------------+
                   | HANDOFF FROM     |  code + review report
                   | BUILD / REVIEW   |  (Gate 1 PASS)
                   +--------+---------+
                            |
                            v
                   +------------------+
                   |   WAR MACHINE       |  Read spec + code; write test plan
                   |   (plan)         |  Write: _aegis-output/qa/sprint-N/
                   +--------+---------+       test-plan-{TASK-ID}.md
                            |
                   [test plan ready]
                            |
                            v
                   +------------------+
                   |   VISION          |  Execute test cases from plan
                   |   (execute)      |  Write: _aegis-output/qa/sprint-N/
                   +--------+---------+       raw-results-{TASK-ID}.md
                            |
                   [results collected]
                            |
                            v
                   +------------------+
                   |   WAR MACHINE       |  Analyze results, issue verdict
                   |   (verdict)      |  Write: _aegis-output/qa/sprint-N/
                   +--------+---------+       qa-report-{TASK-ID}.md
                            |
                   +--------+--------+
                   |                 |
                 PASS              FAIL
                   |                 |
                   v                 v
             [Gate 2 PASS]    [Back to BUILD with QA findings]
             [-> Compliance]  [task status -> IN_PROGRESS]
```

#### Input Contract

```json
{
  "team": "qa",
  "trigger": "task_status == QA (set by Gate 1 PASS)",
  "required_inputs": {
    "task_meta": "_aegis-brain/tasks/{TASK-ID}/meta.json",
    "spec": "_aegis-output/specs/{TASK-ID}-spec.md",
    "code_files": "list from handoff envelope artifacts",
    "review_report": "_aegis-output/reviews/{TASK-ID}-review.md",
    "gate_1_result": "PASS (from handoff envelope)"
  }
}
```

#### Phase: War Machine (Plan)

- **Reads**: Spec (acceptance criteria), code files (to understand implementation), review report (to check flagged areas)
- **Produces**: `_aegis-output/qa/sprint-N/test-plan-{TASK-ID}.md`
  - Functional tests mapped to acceptance criteria
  - Integration tests for cross-component interactions
  - Regression tests for related modules
  - Edge case tests from spec boundary conditions
- **Each test case includes**: ID, description, preconditions, steps, expected result, priority (P0-P3)

#### Phase: Vision (Execute)

- **Reads**: Test plan from War Machine
- **Executes**: Test cases via shell commands (test runners), manual verification steps
- **Produces**: `_aegis-output/qa/sprint-N/raw-results-{TASK-ID}.md`
  - Per-test: ID, status (PASS/FAIL/SKIP/ERROR), actual result, duration, evidence
- **Parallelism**: Multiple Vision instances can run independent test batches concurrently

#### Phase: War Machine (Verdict)

- **Reads**: Raw results from Vision, original test plan
- **Produces**: `_aegis-output/qa/sprint-N/qa-report-{TASK-ID}.md`
  - Verdict: PASS, CONDITIONAL, or FAIL
  - Metrics: pass rate, coverage delta, regression count
  - Failure analysis: root cause category for each failure
- **Gate 2 criteria**:

| Criterion | PASS | CONDITIONAL | FAIL |
|-----------|------|-------------|------|
| P0 Tests | 100% pass | 100% pass | Any fail |
| P1 Tests | 100% pass | >= 90% pass | < 90% pass |
| Overall Pass Rate | >= 95% | >= 90% | < 90% |
| Regressions | 0 | 0 | Any |
| Coverage Delta | >= 0% | >= -1% | < -1% |

- **On PASS**: Updates task meta.json status to DONE. Writes GATE_PASS to history.md. Emits HandoffEnvelope to Compliance.
- **On FAIL**: Updates task meta.json status to IN_PROGRESS. Writes GATE_FAIL to history.md. Appends QA findings to comments.md. Emits HandoffEnvelope back to Build team.

#### Output Contract

```json
{
  "from_team": "qa",
  "to_team": "compliance OR build",
  "task_id": "PROJ-T-042",
  "status": "QA_PASS OR QA_FAIL",
  "artifacts": {
    "test_plan": "_aegis-output/qa/sprint-1/test-plan-PROJ-T-042.md",
    "raw_results": "_aegis-output/qa/sprint-1/raw-results-PROJ-T-042.md",
    "qa_report": "_aegis-output/qa/sprint-1/qa-report-PROJ-T-042.md"
  },
  "gate_results": {
    "gate_2": "PASS",
    "gate_2_reviewer": "war-machine",
    "gate_2_timestamp": "2026-03-25T15:00:00Z",
    "pass_rate": "97%",
    "regressions": 0
  },
  "notes": "All P0/P1 tests pass. 1 P3 test skipped (env dependency)."
}
```

#### Skip Condition

Tasks under 3 story points skip the QA team entirely. Black Panther's Gate 1 code review serves
as the sole quality gate. This is the existing "small task exception" from v7.0, preserved.

---

### 4.4 Compliance Team (Coulson solo)

```
                   +------------------+
                   | ALL ARTIFACTS    |  from Build + QA stages
                   | (input)          |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   |    COULSON        |  Check: which ISO docs need update?
                   |   (audit)        |  Read: _aegis-output/iso-docs/*/current.md
                   +--------+---------+  Read: _aegis-output/specs/, qa/, reviews/
                            |
                   [gap analysis done]
                            |
                            v
                   +------------------+
                   |    COULSON        |  Generate/update ISO docs from artifacts
                   |   (generate)     |  Write: _aegis-output/iso-docs/
                   +--------+---------+
                            |
                   +--------+--------+
                   |                 |
              ALL CURRENT       GAPS REMAIN
                   |                 |
                   v                 v
             [Gate 3 PASS]    [Block -- report which docs missing]
             [deploy ready]   [Coulson retries after source data provided]
```

#### Input Contract

```json
{
  "team": "compliance",
  "trigger": "task_status == DONE (after Gate 2 PASS) OR sprint_close OR release",
  "required_inputs": {
    "task_meta": "_aegis-brain/tasks/{TASK-ID}/meta.json",
    "spec": "_aegis-output/specs/{TASK-ID}-spec.md",
    "review": "_aegis-output/reviews/{TASK-ID}-review.md",
    "qa_report": "_aegis-output/qa/sprint-N/qa-report-{TASK-ID}.md",
    "existing_iso_docs": "_aegis-output/iso-docs/*/current.md"
  }
}
```

#### Coulson Workflow

1. **Audit**: Read all existing ISO docs. Compare against what the current task/sprint requires.
2. **Gap analysis**: Identify which documents are missing or stale (version < latest artifact version).
3. **Generate**: For each gap, produce the ISO 29110 document from existing agent artifacts:

| ISO Document | Source Artifacts |
|-------------|-----------------|
| PM.01 Project Plan | Sprint plan.md, metrics.json |
| PM.02 Progress Status | Daily standup files |
| PM.03 Correction Register | Black Panther FAIL findings, Thor rollback reports, bug reports |
| PM.04 Meeting Record | Sprint plan, review, retro, close ceremonies |
| SI.01 Requirements Spec | Breakdown output (user stories, acceptance criteria) |
| SI.02 Design Document | Iron Man spec files |
| SI.03 Traceability Matrix | REQ -> Design -> Code -> Test mapping |
| SI.04 Test Cases | War Machine test plans |
| SI.05 Test Report | War Machine QA reports |
| SI.06 Acceptance Record | Sprint close with QA verdicts |
| SI.07 Software Configuration | Release tag, file manifest, deploy config |

4. **Stamp**: Each document gets version, date, status (Draft/Review/Approved/Baselined), author.
5. **Verify**: Confirm traceability matrix is complete (every requirement has design, code, test links).

#### Gate 3 Criteria

- All required ISO docs for the task/sprint scope exist
- All docs are current version (not stale relative to latest code/test changes)
- Traceability matrix has no broken links
- Document status is at least "Review" (Draft is insufficient for gate passage)

#### Output Contract

```json
{
  "from_team": "compliance",
  "to_team": "devops OR captain-america",
  "task_id": "PROJ-T-042",
  "status": "COMPLIANT OR NON_COMPLIANT",
  "artifacts": {
    "updated_docs": [
      "_aegis-output/iso-docs/SI-02-design-doc/v3.md",
      "_aegis-output/iso-docs/SI-05-test-report/v2.md"
    ],
    "traceability": "_aegis-output/iso-docs/SI-03-traceability/current.md"
  },
  "gate_results": {
    "gate_3": "PASS",
    "gate_3_reviewer": "coulson",
    "gate_3_timestamp": "2026-03-25T15:15:00Z",
    "docs_checked": 7,
    "docs_updated": 2,
    "docs_missing": 0
  },
  "notes": "SI.02 and SI.05 updated to reflect PROJ-T-042 changes."
}
```

---

### 4.5 DevOps Team (Thor + Spider-Man)

```
                   +------------------+
                   | GATE 1+2+3 PASS  |  all gates passed for release scope
                   | (input)          |
                   +--------+---------+
                            |
                            v
                   +------------------+
                   |      THOR         |  Pre-deploy: clean build from HEAD
                   |    (build)       |  Verify: artifacts exist, checksums match
                   +--------+---------+
                            |
                   [build verified]
                            |
                            v
                   +------------------+
                   |      THOR         |  Deploy to target environment
                   |    (deploy)      |  Strategy: rolling/blue-green/canary
                   +--------+---------+
                            |
                   [deploy executed]
                            |
                            v
                   +------------------+
                   |      THOR         |  Health check: HTTP, process, log scan
                   |   (health)       |  Timeout: 60 seconds
                   +--------+---------+
                            |
                   +--------+---------+
                   |                  |
                HEALTHY          UNHEALTHY
                   |                  |
                   v                  v
          +--------+------+   +------+--------+
          |      THOR      |   |     THOR       |  Rollback to previous version
          |   (monitor)   |   |  (rollback)   |  Re-check health
          | 5 min watch   |   +------+--------+
          +--------+------+          |
                   |          +------+--------+
            +------+------+   |               |
            |             |   ROLLBACK OK   ROLLBACK FAIL
         STABLE      ERROR    |               |
            |        SPIKE    v               v
            v          |   [notify Captain America]   [CRITICAL alert
         [DONE]        v                    to human]
                +------+------+
                |    SPIDER-MAN     |  Write hotfix code
                |  (hotfix)   |
                +------+------+
                       |
                       v
                [Thor redeploys hotfix]
```

#### Input Contract

```json
{
  "team": "devops",
  "trigger": "release approved (all gates PASS) OR hotfix request",
  "required_inputs": {
    "release_scope": "list of task IDs included in release",
    "gate_results": {
      "gate_1": "PASS for all tasks",
      "gate_2": "PASS for all tasks >= 3pts",
      "gate_3": "PASS (ISO docs current)"
    },
    "deploy_config": "deploy/config.yaml",
    "health_checks": "deploy/health-checks.yaml"
  }
}
```

#### Phase: Thor (Build)

- **Reads**: Project source, build configuration
- **Executes**: Clean build from branch HEAD
- **Produces**: `_aegis-output/deploys/build-{timestamp}.log`
- **Validation**: Build artifacts exist, size is non-zero, checksums recorded

#### Phase: Thor (Deploy)

- **Reads**: Build artifacts, deploy/config.yaml
- **Executes**: Deploy command sequence per configured strategy
- **Produces**: `_aegis-output/deploys/deploy-{timestamp}.log`
- **Strategies supported**:
  - `rolling`: Gradual replacement of instances
  - `blue-green`: Deploy to inactive environment, swap traffic
  - `canary`: Deploy to small percentage, monitor, then full rollout

#### Phase: Thor (Health Check)

- **Executes within 60 seconds of deploy**:
  - HTTP endpoint check (GET /health, expect 200)
  - Process check (expected services running)
  - Log scan (no FATAL, PANIC, or unhandled exception in last 60s)
  - Custom checks from deploy/health-checks.yaml
- **On healthy**: Proceed to monitor phase
- **On unhealthy**: Immediate rollback (no human approval needed)

#### Phase: Thor (Monitor)

- **Duration**: 5 minutes post-deploy
- **Checks every 30 seconds**: Error rate from logs or metrics endpoint
- **Baseline**: Error rate from previous deploy's monitor report
- **Thresholds**:
  - error_rate <= 1.5x baseline: STABLE
  - error_rate > 1.5x baseline: WARNING (alert Captain America, continue monitoring)
  - error_rate > 2x baseline: AUTO-ROLLBACK (trigger rollback phase)

#### Phase: Spider-Man (Hotfix -- conditional)

- **Triggered only when**: Thor detects error spike and identifies a code-level root cause
- **Reads**: Error logs, stack traces, affected code
- **Produces**: Minimal fix (smallest possible change to resolve the issue)
- **Constraint**: Hotfix goes through expedited Gate 1 (Black Panther review) before redeploy. Gate 2 (QA) is deferred to next sprint but a regression test is added immediately.

#### Output Contract

```json
{
  "from_team": "devops",
  "to_team": "captain-america",
  "task_id": "RELEASE-001",
  "status": "DEPLOYED_STABLE OR DEPLOYED_ROLLED_BACK OR DEPLOY_FAILED",
  "artifacts": {
    "build_log": "_aegis-output/deploys/build-20260325-1500.log",
    "deploy_log": "_aegis-output/deploys/deploy-20260325-1505.log",
    "health_report": "_aegis-output/deploys/health-20260325-1506.log",
    "monitor_report": "_aegis-output/deploys/monitor-20260325-1511.log"
  },
  "deploy_result": {
    "environment": "production",
    "strategy": "rolling",
    "health_check": "PASS",
    "monitor_5min": "STABLE",
    "error_rate": "0.02%",
    "baseline_error_rate": "0.015%",
    "rollback_triggered": false
  },
  "notes": "Deployed v1.3.0. All health checks pass. Error rate within baseline."
}
```

---

## 5. Handoff Protocol

### HandoffEnvelope Schema

Every team-to-team transition uses this standardized envelope format. The envelope is
written as a JSON file to `_aegis-brain/handoffs/` and referenced in the task's history.md.

```json
{
  "envelope_id": "HO-20260325-001",
  "timestamp": "2026-03-25T14:30:00Z",
  "from_team": "build",
  "to_team": "qa",
  "task_id": "PROJ-T-042",
  "sprint": "sprint-1",
  "status": "READY_FOR_QA",
  "artifacts": {
    "spec": "_aegis-output/specs/PROJ-T-042-spec.md",
    "code_files": [
      "src/auth/middleware.ts",
      "src/auth/middleware.test.ts"
    ],
    "review": "_aegis-output/reviews/PROJ-T-042-review.md"
  },
  "gate_results": {
    "gate_1": {
      "verdict": "PASS",
      "reviewer": "black-panther",
      "timestamp": "2026-03-25T14:28:00Z",
      "report": "_aegis-output/reviews/PROJ-T-042-review.md"
    },
    "gate_2": null,
    "gate_3": null
  },
  "notes": "Rate limit added per Black Panther finding F-003. Ready for QA.",
  "priority": "high",
  "blocking": false
}
```

### Handoff Storage

```
_aegis-brain/
  handoffs/
    HO-20260325-001.json
    HO-20260325-002.json
    ...
```

### Handoff Lifecycle

```
1. Sending team completes its work
2. Sending team writes HandoffEnvelope to _aegis-brain/handoffs/
3. Sending team updates task meta.json (status change)
4. Sending team appends HANDOFF row to task history.md:
   | 2026-03-25 14:30 | black-panther | HANDOFF | IN_REVIEW | QA | HO-20260325-001 |
5. Receiving team reads the handoff envelope
6. Receiving team validates all required artifacts exist (file checks)
7. If validation fails: receiving team rejects handoff, sets status back, notifies sender
8. If validation passes: receiving team begins its workflow
```

### Handoff Routing Table

| From Team | To Team | Trigger Condition | Status Transition |
|-----------|---------|-------------------|-------------------|
| build | qa | Gate 1 PASS | IN_REVIEW -> QA |
| build | build | Gate 1 FAIL | IN_REVIEW -> IN_PROGRESS |
| review | qa | Deep review PASS | IN_REVIEW -> QA |
| review | build | Deep review FAIL | IN_REVIEW -> IN_PROGRESS |
| qa | compliance | Gate 2 PASS | QA -> DONE |
| qa | build | Gate 2 FAIL | QA -> IN_PROGRESS |
| compliance | devops | Gate 3 PASS | DONE -> DEPLOY_READY |
| compliance | compliance | Gate 3 FAIL | DONE (blocked) |
| devops | captain-america | Deploy stable | DEPLOY_READY -> RELEASED |
| devops | build | Hotfix needed | Creates new CRITICAL task |
| feedback | captain-america | Error spike | Creates new CRITICAL task |

### Handoff Validation Rules

The receiving team MUST validate before starting work:

1. All artifact file paths in the envelope exist on disk.
2. The task's meta.json status matches the expected incoming status.
3. All prerequisite gate results are present (e.g., QA team requires gate_1 PASS).
4. The task's sprint matches the active sprint (or is a hotfix with CRITICAL priority).

If any validation fails, the receiving team writes a rejection:

```json
{
  "envelope_id": "HO-20260325-001",
  "rejected": true,
  "rejected_by": "war-machine",
  "reason": "Artifact missing: _aegis-output/reviews/PROJ-T-042-review.md not found",
  "action": "Returned to build team for re-review"
}
```

### Handoff ID Generation

Handoff IDs follow the pattern: `HO-{YYYYMMDD}-{NNN}` where NNN is a daily sequential
counter stored in `_aegis-brain/counters.json` under the key `handoff_daily_{date}`.

---

## 6. Feedback Loop

### Production Issue Detection Flow

```
MONITOR (Thor watching post-deploy)
  |
  +--- Error rate > 2x baseline
  |    |
  |    v
  |  AUTO-ROLLBACK (Thor)
  |    |
  |    v
  |  CREATE CORRECTION REGISTER (Thor -> Coulson: PM.03)
  |    |
  |    v
  |  CREATE HOTFIX TASK (Thor -> Captain America)
  |    |
  |    +---> CRITICAL priority
  |    +---> Auto-added to current sprint backlog
  |    +---> If Spider-Man is free: immediate assignment
  |    +---> If Spider-Man is busy: preempts current task (CRITICAL > all)
  |    |
  |    v
  |  HOTFIX CYCLE:
  |    Spider-Man writes fix -> Black Panther expedited review (Gate 1 only)
  |    -> Thor redeploys -> Monitor again
  |    -> If stable: hotfix task DONE
  |    -> If unstable: escalate to human
  |
  +--- Error rate 1.5x-2x baseline (WARNING)
  |    |
  |    v
  |  ALERT to Captain America (StatusUpdate with severity=high)
  |    |
  |    v
  |  Captain America decides: wait (may stabilize) OR create investigation task (medium priority)
  |
  +--- Error rate <= 1.5x baseline
       |
       v
     STABLE -- no action needed
```

### Hotfix Task Creation (by Thor)

When Thor detects a production issue requiring a code fix:

```json
{
  "action": "CREATE_HOTFIX_TASK",
  "created_by": "thor",
  "task": {
    "id": "auto-generated via counters.json",
    "title": "HOTFIX: {error description}",
    "type": "task",
    "task_type": "hotfix",
    "parent": null,
    "status": "TODO",
    "assignee": "spider-man",
    "points": 1,
    "priority": "critical",
    "labels": ["hotfix", "production", "auto-created"],
    "sprint": "current active sprint",
    "dependencies": { "blocks": [], "blocked_by": [] }
  },
  "context": {
    "error_signature": "TypeError: Cannot read property 'id' of undefined",
    "affected_endpoint": "/api/users/:id",
    "error_rate": "4.2%",
    "baseline_rate": "0.015%",
    "deploy_id": "deploy-20260325-1505",
    "rollback_performed": true,
    "stack_trace": "_aegis-output/deploys/error-20260325-1520.log"
  }
}
```

### Correction Register Entry (PM.03)

Coulson generates a Correction Register entry for every production issue:

```
| Date | ID | Source | Description | Severity | Status | Resolution | Resolved |
|------|----|--------|-------------|----------|--------|------------|----------|
| 2026-03-25 | CR-005 | Production monitor | TypeError in /api/users/:id after v1.3.0 deploy | CRITICAL | OPEN | Rollback + hotfix PROJ-T-099 | pending |
```

### Priority Escalation Rules

| Error Rate vs Baseline | Severity | Auto-Action |
|----------------------|----------|-------------|
| <= 1.5x | LOW | Log only, no task created |
| 1.5x - 2x | HIGH | Alert Captain America, investigation task (medium priority) |
| > 2x | CRITICAL | Auto-rollback + hotfix task (critical priority, immediate assign to Spider-Man) |
| > 5x | EMERGENCY | Auto-rollback + human notification + all agents paused |

### Feedback Data Flow

```
Production Error
  |
  v
_aegis-output/deploys/error-{timestamp}.log     (Thor writes)
  |
  v
_aegis-output/iso-docs/PM-03-correction/        (Coulson writes)
  current.md (appended)
  |
  v
_aegis-brain/tasks/PROJ-T-{NNN}/                (Thor creates via counters.json)
  meta.json   (status=TODO, priority=critical)
  history.md  (CREATED row)
  |
  v
_aegis-brain/sprints/sprint-N/                   (Captain America updates)
  kanban.md   (regenerated with hotfix task in TODO)
  metrics.json (committed_pts increased)
  |
  v
BUILD TEAM picks up hotfix task
  |
  v
Expedited pipeline: BUILD -> GATE 1 -> DEPLOY (skip Gate 2 + Gate 3)
  |
  v
Post-hotfix: regression test added to SI.04, Gate 2 deferred to next sprint
```

---

## 7. Gate Summary Matrix

### All Gates at a Glance

| Gate | Name | Owner | Applies To | Criteria | On FAIL |
|------|------|-------|-----------|----------|---------|
| 1 | Code Quality | Black Panther | All tasks | Correctness, security, performance, style, tests | -> IN_PROGRESS |
| 1+ | Deep Review | Black Panther + Loki + Beast | Tasks >= 8pts or security-labeled | Enhanced review with scan data and adversarial analysis | -> IN_PROGRESS |
| 2 | Product Quality | War Machine + Vision | Tasks >= 3pts | P0 100%, overall >= 95%, 0 regressions | -> IN_PROGRESS |
| 3 | Compliance | Coulson | Sprint close / release | All ISO docs current, traceability complete | Block sprint close |
| 4 | Deploy Health | Thor | Every deployment | HTTP 200, process alive, no FATAL logs, 60s timeout | Auto-rollback |
| 5 | Post-Deploy Monitor | Thor | Every deployment | Error rate < 2x baseline for 5 minutes | Auto-rollback + hotfix |

### Gate Skip Rules

| Condition | Gates Applied |
|-----------|--------------|
| Task < 3 story points | Gate 1 only |
| Task 3-7 story points | Gates 1, 2, 3 |
| Task >= 8 story points | Gates 1+, 2, 3 |
| Hotfix (critical) | Gate 1 (expedited) + Gate 4 + Gate 5 |
| Release | Gates 1-5 (all) |

---

## 8. Implementation Guidance for Spider-Man

This section lists the concrete files Spider-Man must create or modify to implement this spec.

### New Files to Create

| File | Description |
|------|-------------|
| `.claude/agents/thor.md` | Thor agent persona (Section 2 of this spec) |
| `deploy/config.yaml.template` | Deploy configuration template with environment, strategy, target |
| `deploy/health-checks.yaml.template` | Health check definitions template |
| `_aegis-brain/handoffs/.gitkeep` | Handoff envelope storage directory |
| `.claude/commands/aegis-deploy.md` | Deploy command: build, deploy, health check, monitor |
| `.claude/commands/aegis-release.md` | Release command: tag, notes, trigger deploy pipeline |
| `skills/devops-pipeline.md` | DevOps skill definition for skill catalog |

### Files to Modify

| File | Changes |
|------|---------|
| `CLAUDE_agents.md` | Add Thor agent (entry 13) to roster, model routing table, spawning section |
| `CLAUDE_skills.md` | Add devops-pipeline skill (entry 28) |
| `.claude/agents/nick-fury.md` | Add deploy/release to decision matrix, add Gate 4+5, add feedback loop |
| `.claude/commands/aegis-team-build.md` | Add handoff envelope generation after Black Panther review |
| `.claude/commands/aegis-qa.md` | Add handoff envelope consumption and generation |
| `.claude/commands/aegis-sprint.md` | Add release/deploy stages to sprint close flow |
| `.claude/commands/aegis-compliance.md` | Add Gate 3 handoff envelope generation |

### Handoff Envelope Implementation

Add to `_aegis-brain/counters.json`:

```json
{
  "handoff_sequence": 0
}
```

Handoff ID generation: read counters.json, increment `handoff_sequence`, write back,
format as `HO-{YYYYMMDD}-{sequence padded to 3 digits}`.

### Meta.json Status Extension

The task status enum gains two new values:

```
BACKLOG -> TODO -> IN_PROGRESS -> IN_REVIEW -> QA -> DONE -> DEPLOY_READY -> RELEASED
```

New statuses:
- `DEPLOY_READY`: All 3 gates passed, awaiting deployment
- `RELEASED`: Deployed to production and stable

These are optional -- tasks that do not go through deploy (e.g., docs, config) skip directly
from DONE to the sprint close flow.

### Deploy Config Schema

```yaml
# deploy/config.yaml
environments:
  staging:
    target: "staging.example.com"
    strategy: "rolling"
    health_endpoint: "https://staging.example.com/health"
    health_timeout_seconds: 60
    monitor_duration_seconds: 300
    error_rate_baseline: 0.02

  production:
    target: "prod.example.com"
    strategy: "blue-green"
    health_endpoint: "https://prod.example.com/health"
    health_timeout_seconds: 60
    monitor_duration_seconds: 300
    error_rate_baseline: 0.015
    requires_approval: true

rollback:
  automatic: true
  max_attempts: 2
```

### Health Check Schema

```yaml
# deploy/health-checks.yaml
checks:
  - name: "HTTP Health"
    type: "http"
    url: "${HEALTH_ENDPOINT}"
    expected_status: 200
    timeout_ms: 5000
    retries: 3

  - name: "Process Check"
    type: "process"
    process_name: "node"
    expected_count: 1

  - name: "Log Scan"
    type: "log"
    path: "/var/log/app/error.log"
    forbidden_patterns: ["FATAL", "PANIC", "Unhandled"]
    window_seconds: 60
```

---

## Trade-offs and Alternatives Considered

### Trade-off 1: Thor as Separate Agent vs. Extending Spider-Man

**Chosen**: Separate Thor agent.
**Rationale**: Spider-Man's blast radius is application source code. Deploy and infrastructure
require different permissions (write to deploy/, ci/, docker/ but NOT src/). Mixing these
responsibilities violates the principle of least privilege. A separate agent also allows
Thor to run concurrently with Spider-Man on different tasks.
**Risk**: One more agent increases context cost. Mitigated by: Thor is sonnet tier (moderate
cost) and only spawns when deploy/release is needed, not for every task.

### Trade-off 2: Handoff Envelopes vs. Status-Only Transitions

**Chosen**: Full handoff envelopes with artifact references.
**Rationale**: Status flags (meta.json status change) tell you WHAT happened but not WHERE
the artifacts are or WHAT the gate result was. Handoff envelopes carry forward all context
the receiving team needs, preventing re-scanning and reducing context waste.
**Risk**: More files in _aegis-brain/handoffs/. Mitigated by: envelopes are small JSON files
and can be pruned after sprint close.

### Trade-off 3: 5 Gates vs. 3 Gates

**Chosen**: 5 gates (extending v7.0's 3-gate system with Deploy Health and Post-Deploy Monitor).
**Rationale**: The existing 3 gates cover code quality, product quality, and compliance, but
they all operate pre-deploy. Adding gates 4 and 5 extends quality assurance into production,
closing the gap between "tests pass" and "actually works in production."
**Risk**: More ceremony per release. Mitigated by: Gates 4 and 5 are fully automated (Thor
handles them without human input) and add only ~6 minutes to the deploy cycle.

---

**End of Specification**

**Next Steps**:
1. Loki or Black Panther reviews this spec for gaps, edge cases, and overlooked failure modes.
2. After review PASS, Spider-Man implements the files listed in Section 8.
3. Nick Fury's decision matrix is updated to include the new pipeline stages.
