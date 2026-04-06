---
document: SI.04
title: Test Plan — AEGIS v7.1
version: 1
status: Approved
created: 2026-03-24
author: Coulson (AEGIS v7.1)
project: AEGIS — AI Agent Team Framework
---

# SI.04 Test Plan

## 1. Purpose and Scope

This test plan defines the strategy, test cases, and acceptance criteria for AEGIS v7.1. Testing covers installation, skill command execution, agent behavior, quality gates, PM state, and ISO documentation completeness.

**Testing approach**: Functional verification via manual execution in Claude Code session. No automated test harness exists in v7.1 (planned for v7.2).

**Test executor**: Vision (QA Executor, haiku tier)
**Test approver**: War Machine (QA Lead, sonnet tier)

## 2. Test Environment

| Item | Specification |
|------|--------------|
| Host | macOS (Darwin 25.3.0) |
| Claude Code version | Latest stable |
| Model access | claude-opus, claude-sonnet, claude-haiku |
| tmux | Optional (tests run in in-process mode) |
| Repository | /Users/phariyawit.jiap/Documents/AEGIS-Team/ |
| Branch | main |

## 3. Test Cases

### Installation and Setup Tests

**TC-01: Agent roster completeness**
- Procedure: Open CLAUDE_agents.md; count agent definitions
- Expected: Exactly 12 agents defined, each with name, model, role, blast radius, message types, behavioral rules
- Pass criteria: All 12 present with all required fields

**TC-02: Skill command completeness**
- Procedure: Open CLAUDE_skills.md; count slash commands
- Expected: At least 27 skills documented
- Pass criteria: 27+ skills, each with purpose, inputs, outputs, agent assignment

**TC-03: Brain directory structure**
- Procedure: List _aegis-brain/ contents
- Expected: pm-state.json, counters.json, and 8 other JSON files present
- Pass criteria: All 10 brain files exist and are valid JSON

**TC-04: ISO doc directory structure**
- Procedure: List _aegis-output/iso-docs/ contents
- Expected: 11 subdirectories (PM-01 through PM-04, SI-01 through SI-07)
- Pass criteria: Each directory contains v1.md, current.md, changelog.md

### Session Lifecycle Tests

**TC-05: /aegis-start execution**
- Procedure: Invoke /aegis-start in a new Claude Code session
- Expected: Reads CLAUDE.md, reads pm-state.json, produces status report with current phase
- Pass criteria: Status report generated without error; pm-state.json phase displayed

**TC-06: /aegis-retro execution**
- Procedure: Invoke /aegis-retro at session end
- Expected: Retro document written to _aegis-output/retros/, lessons appended to lessons.json, pm-state.json updated
- Pass criteria: Retro file exists with session date; lessons.json has new entry

**TC-07: /aegis-status execution**
- Procedure: Invoke /aegis-status mid-session
- Expected: Report shows active agents, current phase, open tasks, recent decisions
- Pass criteria: Report generated; data reflects actual pm-state.json

### PM State Tests

**TC-08: Phase transition**
- Procedure: Invoke /aegis-pm-cycle from planning phase
- Expected: pm-state.json phase changes from "planning" to "in-process"
- Pass criteria: pm-state.json updated; /aegis-pm-status reflects new phase

**TC-09: State persistence across sessions**
- Procedure: Set phase to "review", end session, start new session, check pm-state.json
- Expected: Phase remains "review" in new session
- Pass criteria: pm-state.json not reset by /aegis-start unless explicitly requested

### Quality Gate Tests

**TC-10: Black Panther gate invocation**
- Procedure: Submit a code change to Black Panther via /aegis-review
- Expected: Black Panther produces written verdict (Pass/Fail) with specific comments
- Pass criteria: Verdict document generated in _aegis-output/; includes specific line-level feedback

**TC-11: War Machine QA gate**
- Procedure: After Black Panther Pass, invoke /aegis-qa-gate
- Expected: War Machine produces QA report with test coverage assessment
- Pass criteria: QA report generated; includes Pass/Fail verdict

**TC-12: Loki challenge gate**
- Procedure: After War Machine Pass, Loki reviews assumptions
- Expected: Loki produces challenge report; either Accept or Escalate
- Pass criteria: Challenge report generated; specific risks identified or explicitly cleared

### ISO Documentation Tests

**TC-13: Document registry completeness**
- Procedure: Read doc-registry.json
- Expected: 11 entries, one per ISO work product
- Pass criteria: All 11 documents listed with correct IDs, titles, paths, status

**TC-14: Document header conformance**
- Procedure: Read v1.md for each of 11 documents
- Expected: Each has YAML front matter with document, title, version, status, created, author, project
- Pass criteria: All 11 headers present and complete

**TC-15: Counter accuracy**
- Procedure: Read _aegis-brain/counters.json
- Expected: DOC counter equals 11
- Pass criteria: DOC=11; other counters non-negative integers

### Non-Functional Tests

**TC-16: In-process mode (no tmux)**
- Procedure: Remove tmux from PATH; invoke /aegis-start
- Expected: Framework detects tmux absence; switches to in-process mode; no error
- Pass criteria: /aegis-start completes; in-process mode confirmed in output

**TC-17: File portability**
- Procedure: Copy entire AEGIS-Team directory to a new machine with Claude Code installed
- Expected: /aegis-start works without any setup beyond `claude` command
- Pass criteria: Session starts successfully on clean machine

## 4. Test Schedule

| Phase | Tests | Executor | Target Date |
|-------|-------|---------|------------|
| v7.1 doc completion | TC-13, TC-14, TC-15 | Vision | 2026-03-24 |
| v7.1 smoke | TC-01–TC-09 | Vision | 2026-03-24 |
| Full regression | TC-01–TC-17 | Vision + War Machine | v7.2 cycle |

## 5. Exit Criteria

v7.1 release requires:
- TC-01, TC-02, TC-03, TC-04 Pass (structural integrity)
- TC-13, TC-14, TC-15 Pass (ISO compliance)
- No P0 blockers open

Full regression (v7.2) requires:
- TC-01 through TC-17 Pass
- Zero known P0 or P1 open issues
