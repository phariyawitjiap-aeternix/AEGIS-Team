# Spec: PROJ-T-008 -- Sentinel+Probe QA pipeline produces real reports

## Summary
The QA pipeline (Sentinel plans, Probe executes) must produce real test reports
in _aegis-output/qa/. Currently the agents exist but have never been run, the
output directory does not exist, and agent tool permissions need adjustment to
allow writing QA reports.

## Current State
- sentinel.md agent exists, well-defined, but has `disallowedTools: [Write, Agent]`
- probe.md agent exists, well-defined, but has `disallowedTools: [Write, Edit, Agent]`
- aegis-qa.md command exists with full subcommand structure
- _aegis-output/qa/ directory does NOT exist
- No QA reports have ever been generated
- Sentinel says "Write: _aegis-output/qa/ only" in blast radius but Write is disallowed
- Probe says "Write: _aegis-output/qa/results/ only" but Write is disallowed

## Problem Analysis
The agents need Write access to produce their outputs. Two approaches:
1. Remove Write from disallowedTools (allow scoped writing)
2. Have agents use Bash tool to write files (workaround)

Approach 1 is cleaner. Sentinel and Probe both have scoped blast radius already
defined. Adding Write to their tools (removing from disallowed) is the correct fix.

## Acceptance Criteria
1. Sentinel agent can write to _aegis-output/qa/ (Write tool enabled)
2. Probe agent can write to _aegis-output/qa/results/ (Write tool enabled)
3. _aegis-output/qa/ directory structure exists
4. aegis-qa.md references are consistent with agent capabilities
5. A sample QA output structure is documented (what files get created where)

## Implementation Plan

### A. Fix Sentinel agent -- enable Write tool
- Remove Write from disallowedTools
- Add Write to tools list
- Blast radius already correctly scoped to _aegis-output/qa/

### B. Fix Probe agent -- enable Write tool
- Remove Write and Edit from disallowedTools
- Add Write to tools list
- Blast radius already correctly scoped to _aegis-output/qa/results/

### C. Create QA output directory structure
- mkdir -p _aegis-output/qa/
- Add .gitkeep

### D. Enhance aegis-qa.md -- add initialization step
- Before running any QA subcommand, ensure _aegis-output/qa/sprint-N/ exists
- Auto-create directory if missing

## Out of Scope
- Running actual tests (no src/ code to test in this framework-only repo)
- Changing test runner configuration
