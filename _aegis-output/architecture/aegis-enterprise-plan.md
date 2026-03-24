# AEGIS v7.0 Enterprise Project Management Plan

**Author**: Sage (Architect)
**Date**: 2026-03-24
**Status**: DRAFT -- Requires peer review from Vigil or Havoc
**Scope**: Add sprint/scrum framework, kanban board, ISO 29110 document management, work breakdown structure, and QA sub-team to AEGIS.

---

## Executive Summary

This plan upgrades AEGIS from a development-focused agent framework to one that also handles project management, quality assurance, and standards compliance. The design targets ISO/IEC 29110 Basic profile (for organizations of up to 25 people) and uses two processes defined by that standard: Project Management (PM) and Software Implementation (SI). All artifacts remain markdown-based, require no external tooling, and work within Claude Code's capabilities.

---

## A. New Agents

### A.1 Agent Roster Addition

| # | Name | Model | Role | Rationale |
|---|------|-------|------|-----------|
| 9 | Sentinel | sonnet | QA Lead | Plans test strategy, writes test plans, reviews test results, gates releases |
| 10 | Probe | haiku | QA Executor | Runs test cases, collects results, generates test reports at volume |
| 11 | Scribe | haiku | Compliance Doc Generator | Produces ISO 29110 work products from agent outputs, maintains traceability matrix |

**Why three agents, not one**: QA planning (Sentinel) requires reasoning about risk and coverage -- sonnet tier. Test execution (Probe) is repetitive and high-volume -- haiku tier. Document generation (Scribe) is templated output from structured data -- haiku tier. Combining these into one agent would either overpay for bulk work or under-power the planning step.

**Why not promote Vigil**: Vigil reviews code quality. Sentinel reviews product quality against requirements. These are distinct concerns. Vigil answers "is this code well-written?" while Sentinel answers "does this code satisfy the acceptance criteria and pass the test plan?" Keeping them separate prevents role overload and keeps blast radii clean.

### A.2 Agent Definitions

#### Sentinel -- QA Lead

- **Model**: claude-sonnet
- **Role**: Quality assurance planning and verdict. Writes test plans, defines test cases from requirements, reviews Probe's test results, and issues QA verdicts (PASS/FAIL/CONDITIONAL).
- **Blast Radius**:
  - Read: All project files, _aegis-output/specs/, _aegis-output/architecture/
  - Write: _aegis-output/qa/, _aegis-output/iso-docs/test-plan/, _aegis-output/iso-docs/test-report/
  - Forbidden: src/, CLAUDE*.md, _aegis-brain/ (except logs)
- **Message Types**:
  - Sends: FindingReport (QA verdict), PlanProposal (test strategy)
  - Receives: TaskAssignment from Navi, PlanProposal from Sage (requirements to test against)

#### Probe -- QA Executor

- **Model**: claude-haiku
- **Role**: Executes test cases, runs test suites, collects pass/fail results, reports raw findings. Does not interpret or decide -- just executes and reports.
- **Blast Radius**:
  - Read: All project files, _aegis-output/qa/
  - Write: _aegis-output/qa/results/, _aegis-brain/logs/
  - Forbidden: src/ (write), CLAUDE*.md, docs/
- **Message Types**:
  - Sends: StatusUpdate (test progress), FindingReport (raw test results)
  - Receives: TaskAssignment from Sentinel

#### Scribe -- Compliance Document Generator

- **Model**: claude-haiku
- **Role**: Generates ISO 29110 compliant documents from structured agent outputs. Maintains the traceability matrix. Does not make decisions -- transforms data into compliant document format.
- **Blast Radius**:
  - Read: All _aegis-output/ files, _aegis-brain/sprints/
  - Write: _aegis-output/iso-docs/
  - Forbidden: src/, CLAUDE*.md, _aegis-brain/ (except reading)
- **Message Types**:
  - Sends: StatusUpdate (document generation progress)
  - Receives: TaskAssignment from Navi

### A.3 Updated Model Routing

| Model Tier | Existing Agents | New Agents |
|-----------|-----------------|------------|
| opus | Navi, Sage, Havoc | (none) |
| sonnet | Bolt, Vigil, Pixel | Sentinel |
| haiku | Forge, Muse | Probe, Scribe |

Total agent count: 8 existing + 3 new = 11 agents.

### A.4 Team Compositions

| Team | Agents | Purpose |
|------|--------|---------|
| Build Team | Sage, Bolt, Vigil | Design + implement + review (unchanged) |
| QA Team | Sentinel, Probe | Test planning + execution |
| Compliance Team | Scribe, (Muse assist) | ISO 29110 document generation |
| Full Pipeline | All relevant agents | End-to-end: design through QA and docs |

---

## B. New Skills

### B.1 Skill Summary

| # | Skill Name | Profile | Description |
|---|-----------|---------|-------------|
| 22 | sprint-manager | standard | Full scrum ceremony management (replaces/upgrades sprint-tracker) |
| 23 | kanban-board | standard | Markdown-based kanban with column transitions |
| 24 | iso-29110-docs | full | ISO 29110 Basic profile document generator |
| 25 | work-breakdown | standard | Story to journey to epic to task to subtask decomposition |
| 26 | qa-pipeline | full | QA test planning, execution, and reporting pipeline |

### B.2 Skill: sprint-manager (upgrades existing sprint-tracker)

```
Profile: standard
Triggers EN: "sprint", "scrum", "ceremony", "standup", "sprint planning", "sprint review", "sprint retro"
Triggers TH: "สปรินต์", "สครัม", "พิธี", "สแตนอัพ"
```

**Extends sprint-tracker with**:
- Sprint Planning ceremony: Navi facilitates, pulls from prioritized backlog, assigns to agents
- Daily Standup: Auto-generated from agent StatusUpdate messages in the last 24h
- Sprint Review: Summarizes completed work, demos (links to outputs)
- Sprint Retrospective: What went well, what to improve, action items (integrates with existing /aegis-retro)
- Sprint backlog management with carry-over tracking

**Ceremony schedule within a sprint**:
1. Sprint Planning (Day 1) -- select stories, estimate, assign
2. Daily Standup (every day) -- auto-generated from agent activity
3. Sprint Review (last day) -- demo completed work
4. Sprint Retrospective (last day, after review) -- process improvement

**Output**: `_aegis-brain/sprints/sprint-<N>/`

### B.3 Skill: kanban-board

```
Profile: standard
Triggers EN: "kanban", "board", "task board", "move task", "task status"
Triggers TH: "คันบัง", "บอร์ด", "สถานะงาน"
```

**Columns**: BACKLOG | TODO | IN_PROGRESS | IN_REVIEW | QA | DONE

**Implementation**: A single markdown file per sprint that represents the board state. Agents update it by moving task IDs between columns. The file is the source of truth.

**Board file format** (`_aegis-brain/sprints/sprint-<N>/kanban.md`):
```markdown
# Kanban Board: Sprint <N>
Last updated: <timestamp>

## BACKLOG
- [ ] TASK-005: <description> [3pts] @unassigned

## TODO
- [ ] TASK-004: <description> [2pts] @bolt

## IN_PROGRESS
- [~] TASK-003: <description> [5pts] @bolt

## IN_REVIEW
- [~] TASK-002: <description> [3pts] @vigil

## QA
- [~] TASK-001: <description> [5pts] @sentinel

## DONE
- [x] TASK-000: <description> [2pts] @bolt
```

**Transition rules**:
- BACKLOG to TODO: Sprint planning assigns it
- TODO to IN_PROGRESS: Agent picks it up
- IN_PROGRESS to IN_REVIEW: Agent completes implementation
- IN_REVIEW to QA: Vigil approves code review (or back to IN_PROGRESS if rejected)
- QA to DONE: Sentinel approves QA (or back to IN_PROGRESS if failed)
- Any column can go back to TODO if blocked

**WIP Limits**: IN_PROGRESS max 3 items, IN_REVIEW max 2 items (configurable).

### B.4 Skill: iso-29110-docs

```
Profile: full
Triggers EN: "ISO", "29110", "compliance", "audit docs", "work products"
Triggers TH: "ไอเอสโอ", "เอกสารมาตรฐาน", "ตรวจสอบ"
```

**Generates the ISO 29110 Basic profile work products** (see Section F for full mapping).

**Approach**: Scribe agent collects structured outputs from other agents and transforms them into ISO 29110 compliant document templates. Documents are generated incrementally -- not all at once at the end, but as each process activity completes.

**Document generation triggers**:
- Project Plan: Generated at sprint planning, updated each sprint
- Requirements Specification: Generated when work-breakdown completes
- Design Document: Generated when Sage completes architecture spec
- Test Plan: Generated when Sentinel completes test planning
- Test Report: Generated when Probe completes test execution
- Traceability Matrix: Updated whenever any of the above changes

### B.5 Skill: work-breakdown

```
Profile: standard
Triggers EN: "breakdown", "user story", "epic", "decompose", "hierarchy", "user journey"
Triggers TH: "แตกงาน", "ยูสเซอร์สตอรี่", "เอพิค", "แยกย่อย"
```

**Hierarchy**:
```
User Story (what the user wants)
  -> User Journey (how the user experiences it, step by step)
    -> Epic (large body of work to enable the journey)
      -> Task (implementable unit, 1-8 story points)
        -> Subtask (atomic action, 1-2 story points max)
```

**Process**:
1. User provides a user story in natural language
2. Sage decomposes into user journeys (interaction flows)
3. Each journey maps to one or more epics
4. Each epic breaks into tasks (estimable, assignable)
5. Complex tasks (8+ points) further break into subtasks
6. Output: structured breakdown in `_aegis-output/breakdown/`

**Breakdown file format**:
```markdown
# Work Breakdown: <User Story Title>

## User Story
As a <role>, I want <capability>, so that <benefit>.

## User Journeys
### J-001: <Journey Name>
1. User does X
2. System responds with Y
3. User sees Z

## Epics
### E-001: <Epic Name> (from J-001)
**Scope**: <what this epic covers>
**Estimated size**: <total points>

#### Tasks
| ID | Task | Points | Dependencies | Assignee |
|----|------|--------|-------------|----------|
| T-001 | <task> | 3 | none | @bolt |
| T-002 | <task> | 5 | T-001 | @bolt |

#### Subtasks (for T-002)
| ID | Subtask | Points | Parent |
|----|---------|--------|--------|
| ST-001 | <subtask> | 2 | T-002 |
| ST-002 | <subtask> | 2 | T-002 |
| ST-003 | <subtask> | 1 | T-002 |
```

### B.6 Skill: qa-pipeline

```
Profile: full
Triggers EN: "QA", "quality assurance", "test pipeline", "acceptance test"
Triggers TH: "คิวเอ", "ทดสอบคุณภาพ", "ตรวจสอบคุณภาพ"
```

**Pipeline stages**:
1. Sentinel reads requirements spec and design doc
2. Sentinel produces test plan (test cases, test data, pass criteria)
3. Probe executes test cases against implementation
4. Probe reports raw results
5. Sentinel evaluates results and issues verdict
6. Scribe generates ISO 29110 Test Report from verdict

**Test types** (Sentinel selects appropriate ones per task):
- Functional testing (does it do what the spec says)
- Integration testing (do components work together)
- Regression testing (did we break anything)
- Acceptance testing (does it meet user story criteria)

---

## C. New Commands

### C.1 Command Summary

| Command | Purpose | Primary Agent |
|---------|---------|---------------|
| /aegis-sprint | Sprint ceremony management | Navi |
| /aegis-kanban | View and update kanban board | Navi (view), Any (update) |
| /aegis-breakdown | Decompose user stories into task hierarchy | Sage |
| /aegis-qa | Run QA pipeline on completed work | Sentinel |
| /aegis-compliance | Generate/update ISO 29110 documents | Scribe |

### C.2 Command: /aegis-sprint

```
/aegis-sprint plan              -- Start sprint planning ceremony
/aegis-sprint standup           -- Generate daily standup from agent activity
/aegis-sprint review            -- Run sprint review (end of sprint)
/aegis-sprint retro             -- Run sprint retrospective
/aegis-sprint status            -- Show current sprint progress
/aegis-sprint close             -- Close sprint, calculate velocity, carry over
```

**Flow for `/aegis-sprint plan`**:
1. Read backlog from `_aegis-brain/backlog.md`
2. Calculate capacity from velocity history
3. Navi selects stories that fit capacity, ordered by priority
4. Create sprint plan at `_aegis-brain/sprints/sprint-<N>/plan.md`
5. Initialize kanban board at `_aegis-brain/sprints/sprint-<N>/kanban.md`
6. Trigger Scribe to update Project Plan document

### C.3 Command: /aegis-kanban

```
/aegis-kanban                   -- Show current board
/aegis-kanban move <TASK-ID> <COLUMN>  -- Move task to column
/aegis-kanban add <description> [points]  -- Add task to BACKLOG
/aegis-kanban wip               -- Show WIP limit status
```

### C.4 Command: /aegis-breakdown

```
/aegis-breakdown "<user story text>"    -- Full decomposition
/aegis-breakdown --from-file <path>     -- Read stories from file
/aegis-breakdown --epic <EPIC-ID>       -- Break down a specific epic further
```

**Flow**:
1. Sage receives user story
2. Sage produces user journeys
3. Sage decomposes journeys into epics, tasks, subtasks
4. Output written to `_aegis-output/breakdown/<story-id>/`
5. Tasks auto-added to `_aegis-brain/backlog.md`
6. Scribe generates/updates Requirements Specification

### C.5 Command: /aegis-qa

```
/aegis-qa plan                  -- Sentinel creates test plan for current sprint work
/aegis-qa run                   -- Probe executes test plan
/aegis-qa report                -- Generate QA report
/aegis-qa full                  -- Plan + run + report in sequence
/aegis-qa gate                  -- QA quality gate check (pass/fail verdict)
```

### C.6 Command: /aegis-compliance

```
/aegis-compliance generate      -- Generate all missing ISO 29110 docs from current state
/aegis-compliance check         -- Audit which documents are missing or outdated
/aegis-compliance matrix        -- Show/update traceability matrix
```

---

## D. File Structure

```
_aegis-brain/
  backlog.md                          # Product backlog (all stories, prioritized)
  sprints/
    sprint-<N>/
      plan.md                         # Sprint plan (goal, stories, capacity)
      kanban.md                       # Kanban board state
      daily/
        YYYY-MM-DD.md                 # Daily standup records
      review.md                       # Sprint review summary
      retro.md                        # Sprint retrospective
      close.md                        # Sprint close report + velocity

_aegis-output/
  breakdown/
    <story-id>/
      breakdown.md                    # Full hierarchy: journeys, epics, tasks
  qa/
    sprint-<N>/
      test-plan.md                    # Test plan for the sprint
      test-cases/
        TC-<NNN>.md                   # Individual test case definitions
      results/
        YYYY-MM-DD-run.md             # Test execution results
      verdict.md                      # QA verdict (PASS/FAIL/CONDITIONAL)
  iso-docs/
    project-plan.md                   # PM.01 - Project Plan
    progress-status.md                # PM.02 - Progress Status Record
    requirements-spec.md              # SI.01 - Requirements Specification
    design-doc.md                     # SI.02 - Software Design Document
    traceability-matrix.md            # SI.03 - Traceability Record
    test-plan.md                      # SI.04 - Test Plan (master, not per-sprint)
    test-report.md                    # SI.05 - Test Report (cumulative)
    change-requests.md                # PM.03 - Change Request log
    meeting-minutes/
      YYYY-MM-DD-<type>.md            # PM.04 - Meeting Records
    acceptance-record.md              # SI.06 - Acceptance Record
    release/
      release-<version>.md            # SI.07 - Software Configuration
```

**Design decisions**:
- Sprint operational data lives in `_aegis-brain/` (working memory, mutable)
- Outputs and reports live in `_aegis-output/` (deliverables, append-mostly)
- ISO docs live in `_aegis-output/iso-docs/` (formal artifacts, versioned)
- Breakdown outputs are per-story, not per-sprint (stories may span sprints)

---

## E. Workflow Integration

### E.1 Updated Mother Brain Decision Flow

```
Mother Brain activates
  |
  v
Scan project state (existing)
  |
  v
[NEW] Check: Is there an active sprint?
  |-- No  --> Prompt: /aegis-sprint plan (or work from backlog)
  |-- Yes --> Check kanban board for next TODO item
        |
        v
      Pick highest-priority TODO task
        |
        v
      [NEW] Check: Does task have a breakdown?
        |-- No  --> /aegis-breakdown (Sage decomposes)
        |-- Yes --> Proceed
              |
              v
            Move task to IN_PROGRESS on kanban
              |
              v
            Spawn Build Team (Sage + Bolt + Vigil) -- existing flow
              |
              v
            Build Team completes --> Move to IN_REVIEW
              |
              v
            Vigil code review --> PASS: Move to QA
              |                   FAIL: Move back to IN_PROGRESS
              v
            [NEW] Spawn QA Team (Sentinel + Probe)
              |
              v
            QA verdict --> PASS: Move to DONE
              |            FAIL: Move back to IN_PROGRESS with findings
              v
            [NEW] Scribe generates/updates ISO 29110 docs
              |
              v
            Task complete. Pick next TODO.
```

### E.2 Quality Gate Enhancement

The existing quality gate (Vigil code review) becomes a two-stage gate:

| Gate | Agent | Checks | Blocks |
|------|-------|--------|--------|
| Gate 1: Code Quality | Vigil | Code review, lint, standards, security | Merge to branch |
| Gate 2: Product Quality | Sentinel | Functional tests, acceptance criteria, regression | Move to DONE |
| Gate 3: Compliance | Scribe | All required ISO docs exist and are current | Sprint close |

A task is only DONE when all three gates pass.

### E.3 Sprint Lifecycle Integration

```
/aegis-sprint plan
  --> Navi selects from backlog
  --> Kanban initialized
  --> Scribe updates Project Plan

For each task in sprint:
  --> /aegis-breakdown (if needed)
  --> Build Team works
  --> QA Team validates
  --> Scribe generates docs
  --> Kanban updated

/aegis-sprint review
  --> Navi summarizes completed work
  --> Scribe updates Progress Status Record

/aegis-sprint retro
  --> Navi runs retrospective (existing /aegis-retro, enhanced)
  --> Scribe records Meeting Minutes

/aegis-sprint close
  --> Velocity calculated
  --> Incomplete tasks carried over
  --> Scribe updates all ISO docs to current state
```

---

## F. ISO 29110 Basic Profile Document Mapping

ISO/IEC 29110 Basic profile defines two processes: Project Management (PM) and Software Implementation (SI). Below are the required work products mapped to the AEGIS agent responsible for producing them.

### F.1 Project Management Process Work Products

| ID | Work Product | AEGIS Producer | When Generated | File Location |
|----|-------------|----------------|----------------|---------------|
| PM.01 | Project Plan | Navi + Scribe | Sprint planning | iso-docs/project-plan.md |
| PM.02 | Progress Status Record | Navi + Scribe | Daily standups, sprint reviews | iso-docs/progress-status.md |
| PM.03 | Change Request Log | Navi + Scribe | When scope changes occur | iso-docs/change-requests.md |
| PM.04 | Meeting Records | Scribe | Each ceremony (planning, standup, review, retro) | iso-docs/meeting-minutes/ |

**PM.01 Project Plan** contains:
- Task descriptions with estimated effort (from work-breakdown)
- Schedule and milestones (from sprint plan)
- Resource assignments (from kanban board agent assignments)
- Risk identification (from Havoc's adversarial analysis)
- Version control strategy (from git-workflow skill)

**PM.02 Progress Status Record** contains:
- Actual vs planned progress (from kanban board + burndown)
- Identified problems and deviations (from blocker tracking)
- Corrective actions taken (from course-correction skill)

### F.2 Software Implementation Process Work Products

| ID | Work Product | AEGIS Producer | When Generated | File Location |
|----|-------------|----------------|----------------|---------------|
| SI.01 | Requirements Specification | Sage + Scribe | /aegis-breakdown completes | iso-docs/requirements-spec.md |
| SI.02 | Software Design Document | Sage + Scribe | Sage architecture spec completes | iso-docs/design-doc.md |
| SI.03 | Traceability Record | Scribe | Updated on every doc change | iso-docs/traceability-matrix.md |
| SI.04 | Test Plan | Sentinel + Scribe | /aegis-qa plan completes | iso-docs/test-plan.md |
| SI.05 | Test Report | Sentinel + Scribe | /aegis-qa run completes | iso-docs/test-report.md |
| SI.06 | Acceptance Record | Navi + Scribe | QA gate passes + human sign-off | iso-docs/acceptance-record.md |
| SI.07 | Software Configuration | Bolt + Scribe | Release preparation | iso-docs/release/ |

### F.3 Traceability Matrix Structure

The traceability matrix links every requirement to its design, implementation, and test:

```markdown
# Traceability Matrix

| Req ID | Requirement | Design Ref | Code Ref | Test Case | Test Result | Status |
|--------|------------|------------|----------|-----------|-------------|--------|
| REQ-001 | <requirement text> | design-doc#section-2 | src/auth.ts | TC-001 | PASS | Verified |
| REQ-002 | <requirement text> | design-doc#section-3 | src/api.ts | TC-002 | FAIL | Open |
```

Scribe auto-generates this by cross-referencing:
- Requirements from breakdown output
- Design sections from Sage's specs
- Code references from Bolt's implementation commits
- Test cases from Sentinel's test plan
- Test results from Probe's execution results

### F.4 Document Lifecycle

Every ISO 29110 document follows this lifecycle:
1. **Draft**: Generated by producing agent + Scribe
2. **Review**: Vigil checks document completeness and consistency
3. **Approved**: Navi approves (or escalates to human for formal sign-off)
4. **Baselined**: Version-tagged in git via commit

---

## G. Priority and Effort Matrix

### G.1 Implementation Phases

| Phase | Changes | Effort | Impact | Dependencies |
|-------|---------|--------|--------|-------------|
| **Phase 1** | Kanban board skill + command | Small (1 session) | High -- immediate visibility into work status | None |
| **Phase 2** | Work breakdown skill + command | Small (1 session) | High -- enables structured planning | None |
| **Phase 3** | Sprint manager skill (upgrade sprint-tracker) + command | Medium (1-2 sessions) | High -- full scrum ceremony support | Phases 1-2 |
| **Phase 4** | QA agents (Sentinel + Probe) + qa-pipeline skill + command | Medium (2 sessions) | High -- automated quality assurance | Phase 2 (needs requirements to test against) |
| **Phase 5** | Scribe agent + iso-29110-docs skill + compliance command | Medium (2 sessions) | Medium -- compliance documentation | Phases 2-4 (needs all outputs to document) |
| **Phase 6** | Mother Brain integration (updated decision flow) | Small (1 session) | High -- ties everything together | Phases 1-5 |

### G.2 Rationale for Ordering

1. **Kanban first**: Lowest effort, highest immediate value. Even without sprints or QA, a visual task board improves coordination. Unblocks all subsequent phases.

2. **Work breakdown second**: The decomposition hierarchy is the input to everything else -- sprint planning needs tasks, QA needs requirements, ISO docs need specs. Building this early means all downstream phases have structured data to work with.

3. **Sprint manager third**: Depends on kanban (board state) and breakdown (task pool). Once tasks exist and can be tracked, sprint ceremonies add process structure.

4. **QA agents fourth**: Depends on breakdown for requirements to test against. Adding QA before compliance means test results exist for Scribe to document.

5. **Scribe and ISO docs fifth**: This is the documentation layer. It needs all other outputs to exist before it can generate compliant documents. Putting it last means Scribe has maximum material to work with.

6. **Mother Brain integration last**: The orchestration update ties all pieces together. Doing it last means all components are tested individually before being wired into the autonomous flow.

### G.3 Effort Estimates

| Item | New Files | Modified Files | Estimated Tokens |
|------|-----------|---------------|-----------------|
| Kanban skill | 1 skill file, 1 command file | CLAUDE_skills.md | ~800 |
| Work breakdown skill | 1 skill file, 1 command file | CLAUDE_skills.md | ~1000 |
| Sprint manager upgrade | 1 skill file (replace), 1 command file | CLAUDE_skills.md, existing sprint-tracker.md | ~1200 |
| QA agents + skill | 2 agent persona files, 1 skill file, 1 command file | CLAUDE_agents.md, CLAUDE_skills.md | ~2000 |
| Scribe agent + ISO skill | 1 agent persona file, 1 skill file, 1 command file, ~10 template files | CLAUDE_agents.md, CLAUDE_skills.md | ~3000 |
| Mother Brain update | 0 new files | CLAUDE.md (decision flow section) | ~500 |
| **Total** | **~20 new files** | **~5 modified files** | **~8500** |

---

## H. Risks and Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| ISO docs become bureaucratic overhead | High | Templates are pre-filled by agents. Human only reviews, never writes from scratch. Documents auto-generate from existing outputs. |
| Context budget overrun (11 agents + ISO docs) | High | QA and compliance agents only spawn when needed (not for every trivial task). Threshold check from v6.1 plan applies here too. |
| Kanban board file conflicts (multiple agents writing) | Medium | Single-writer rule: only the active orchestrator (Navi) writes to kanban.md. Other agents send StatusUpdate messages, Navi updates the board. |
| Sprint ceremonies feel artificial for solo developers | Medium | Ceremonies are optional. /aegis-sprint standup auto-generates from activity -- zero human effort. Solo mode skips ceremonies entirely. |
| Traceability matrix grows stale | Medium | Scribe regenerates the matrix from source data on every /aegis-compliance generate call. It is computed, not manually maintained. |

---

## I. Open Questions for Peer Review

1. **Scribe vs Muse overlap**: Should Scribe be a new agent, or should Muse gain ISO 29110 templates as a skill? Argument for new agent: blast radius separation (Muse writes user-facing docs, Scribe writes compliance artifacts). Argument for Muse upgrade: fewer agents, simpler routing.

2. **Sprint duration**: Should AEGIS enforce a default sprint length (e.g., 1 week for AI-speed development), or leave it fully configurable? AI agents work faster than human teams -- traditional 2-week sprints may be too long.

3. **Backlog priority scheme**: The existing Decision Matrix uses P0-P10. Should the backlog use the same scale, or switch to MoSCoW (Must/Should/Could/Won't) for better alignment with ISO 29110 requirements prioritization?

4. **QA depth for small changes**: Should the threshold check (from v6.1 plan) also gate QA? A one-line typo fix should not trigger Sentinel + Probe + Scribe. Proposed rule: tasks under 3 story points skip QA team, Vigil's code review is sufficient.

5. **ISO 29110 Entry vs Basic**: The Entry profile requires fewer documents. Should AEGIS default to Entry (lighter) and optionally upgrade to Basic? This would reduce initial overhead.

---

## J. What This Plan Does NOT Cover

- CI/CD integration (AEGIS runs locally in Claude Code, not in a pipeline server)
- Multi-project portfolio management (one project at a time)
- Time tracking or billing (out of scope for an AI agent framework)
- Formal ISO certification process (this plan produces the documents; certification is an organizational decision)
- External tool integration (Jira, GitHub Projects, etc. -- everything stays in markdown)

---

*This plan requires review from Vigil (for process rigor) or Havoc (for adversarial challenge) before implementation proceeds.*
