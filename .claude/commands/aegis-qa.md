---
name: aegis-qa
description: "QA command — plan tests, run tests, generate reports, gate releases"
triggers:
  en: QA, test, run tests, quality assurance, test plan
  th: คิวเอ, ทดสอบ, รันเทสต์
---

# /aegis-qa

## Quick Reference
QA command that plans test strategies, executes tests, reviews results, and gates
releases. Solo mode uses sub-agent Sentinel for single targets. Team mode spawns
a full QA team (Sentinel + Probe) via TeamCreate for multi-target work.

## Full Instructions

### Subcommands

```
/aegis-qa plan [target]     — Generate test plan for target scope
/aegis-qa run [target]      — Execute tests against target
/aegis-qa report [target]   — Generate QA report from existing results
/aegis-qa full [target]     — Full pipeline: plan -> run -> report -> gate
/aegis-qa gate [target]     — Release gate check (pass/conditional/fail)
```

### Mode Selection

**Solo Mode** (1 target, simple scope):
- Uses sub-agent Sentinel directly
- Sentinel plans, coordinates Probe internally, reviews, and gates
- Best for: single module, single feature, quick checks

**Team Mode** (2+ targets, complex scope):
- Spawns full QA team via TeamCreate in tmux
- Sentinel as QA Lead, Probe as parallel executor
- Best for: sprint-wide QA, multi-module changes, release candidates

Mode is auto-detected based on scope, or forced with `--mode solo|team`.

### Subcommand Details

#### `/aegis-qa plan [target]`

Generate a test plan without executing tests.

1. Analyze target scope:
   - If target is a branch: `git diff main...<branch>` to find changed files
   - If target is a path: scan files in that directory
   - If target is `--sprint`: analyze all changes since last sprint tag
2. Map changes to test categories (functional, integration, regression, acceptance)
3. Generate prioritized test plan
4. Output: `_aegis-output/qa/sprint-N/test-plan.md`

#### `/aegis-qa run [target]`

Execute tests for the target. Requires a test plan (auto-generates one if missing).

1. Load or generate test plan
2. Detect test runner and environment
3. Execute test cases via Probe
4. Capture raw results
5. Output: `_aegis-output/qa/sprint-N/raw-results.md`

#### `/aegis-qa report [target]`

Generate QA report from existing test results.

1. Load raw results from `_aegis-output/qa/sprint-N/raw-results.md`
2. Sentinel analyzes and interprets results
3. Calculate metrics: pass rate, regression count, coverage delta
4. Classify failures by severity and type
5. Output: `_aegis-output/qa/sprint-N/qa-report.md`

#### `/aegis-qa full [target]`

Run the complete pipeline end-to-end.

```
Plan --> Run --> Report --> Gate
```

1. Generate test plan (plan)
2. Execute all test cases (run)
3. Analyze results and generate report (report)
4. Issue release gate verdict (gate)
5. Output: all files in `_aegis-output/qa/sprint-N/`

#### `/aegis-qa gate [target]`

Release gate check — issues a verdict based on existing QA report.

1. Load QA report from `_aegis-output/qa/sprint-N/qa-report.md`
2. Evaluate against gate criteria:
   - **PASS** — All P0 tests pass, pass rate >= 95%, 0 regressions
   - **CONDITIONAL** — Minor failures only (P2+), pass rate >= 90%
   - **FAIL** — P0/P1 failures, regressions, or pass rate < 90%
3. Output verdict with justification

### Gate Criteria

| Criterion          | PASS       | CONDITIONAL | FAIL       |
|--------------------|------------|-------------|------------|
| P0 Tests           | 100% pass  | 100% pass   | Any fail   |
| P1 Tests           | 100% pass  | >= 90% pass | < 90% pass |
| Overall Pass Rate  | >= 95%     | >= 90%      | < 90%      |
| Regressions        | 0          | 0           | Any        |
| Coverage Delta     | >= 0%      | >= -1%      | < -1%      |

### Team Mode Details

When team mode is activated:

```
TeamCreate: aegis-qa-team
  Sentinel (sonnet) — QA Lead: plans, reviews, gates
  Probe (haiku)     — Executor: runs tests in parallel
```

- Sentinel breaks work into parallel test batches for Probe
- Probe instances run test batches concurrently
- Sentinel collects and merges results
- Human monitors via `tmux attach -t aegis-qa-team`

### Examples

```bash
# Plan tests for current branch
/aegis-qa plan

# Run tests for a specific module
/aegis-qa run src/auth/

# Full QA pipeline for the sprint
/aegis-qa full --sprint

# Check release gate
/aegis-qa gate

# Force team mode for complex scope
/aegis-qa full --mode team src/
```

### Output Structure

```
_aegis-output/qa/sprint-N/
  test-plan.md      # Test strategy and case list
  raw-results.md    # Probe's raw execution output
  qa-report.md      # Sentinel's analysis and verdict
  coverage/         # Coverage reports (if available)
```
