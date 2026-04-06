---
document: PM.03
title: Change Requests Log — AEGIS v7.1
version: 1
status: Approved
created: 2026-03-24
author: Coulson (AEGIS v7.1)
project: AEGIS — AI Agent Team Framework
---

# PM.03 Change Requests Log

## 1. Overview

This document records all formal change requests raised against AEGIS from v6.0 through v7.1. Each CR captures the trigger, decision, and impact on the framework.

## 2. Change Request Register

---

### CR-001: Make tmux Optional

**ID**: CR-001
**Date Raised**: 2026-Q1
**Raised By**: Iron Man (Architect)
**Status**: Approved and Implemented (v7.0)

**Problem Statement**:
tmux was a hard dependency for multi-agent orchestration. New operators on macOS without tmux pre-installed received errors on first run of `/aegis-team-build`. This blocked onboarding and created an unnecessary barrier for single-agent use cases.

**Proposed Change**:
- Mark tmux as optional in CLAUDE.md and CLAUDE_agents.md
- Implement in-process fallback mode where agents run sequentially in the same Claude Code session
- Add tmux availability check at `/aegis-start`
- Update GETTING_STARTED.md to document both modes

**Decision**: Approved by Captain America (Lead). Risk accepted: in-process mode sacrifices true parallelism but preserves all quality gates.

**Impact**:
- CLAUDE.md: Added in-process mode documentation
- CLAUDE_agents.md: Added in-process execution notes per agent
- GETTING_STARTED.md: Added "Without tmux" section
- No agents removed or renamed

---

### CR-002: Rename "Loop" to "Cycle"

**ID**: CR-002
**Date Raised**: 2026-Q1
**Raised By**: Loki (Devil's Advocate)
**Status**: Approved and Implemented (v7.0)

**Problem Statement**:
The term "loop" in agent communication (e.g., "build loop", "review loop") caused confusion. Operators with programming backgrounds interpreted "loop" as an infinite or iterative control structure, not a single pass of an activity. This led to misunderstanding of the PM state machine.

**Proposed Change**:
- Rename all occurrences of "loop" to "cycle" in CLAUDE.md, CLAUDE_agents.md, CLAUDE_skills.md
- Update PM state transitions: planning → in-process → review → retro (one cycle)
- Update skill command descriptions accordingly

**Decision**: Approved. Terminology change only — no behavioral changes to agents or PM state machine.

**Impact**:
- CLAUDE.md: "cycle" replaces "loop" in PM state descriptions
- CLAUDE_agents.md: Agent behavioral rules updated
- CLAUDE_skills.md: Skill descriptions updated
- CLAUDE_lessons.md: Lesson added — "terminology precision prevents agent confusion"

---

### CR-003: Enforce Planning Gate Before Build

**ID**: CR-003
**Date Raised**: 2026-Q1
**Raised By**: Black Panther (Reviewer)
**Status**: Approved and Implemented (v7.0)

**Problem Statement**:
In v6.0, agents (primarily Spider-Man) would begin implementation immediately upon receiving a task, before Iron Man had confirmed the architecture. This led to rework when Black Panther's review revealed design flaws that should have been caught at the planning stage.

**Proposed Change**:
- Add mandatory planning gate: Iron Man must produce a design summary before Spider-Man begins
- Add gate check to `/aegis-build` skill: aborts if no plan artifact exists in `_aegis-brain/current-plan.json`
- Update Nick Fury decision matrix: planning phase must complete before in-process phase begins

**Decision**: Approved by Captain America. Loki challenged whether the gate adds latency; Captain America accepted the latency trade-off in favor of rework reduction.

**Impact**:
- CLAUDE_agents.md: Spider-Man behavioral rule added — "Never start implementation without confirmed plan"
- CLAUDE_skills.md: `/aegis-build` updated with gate check logic
- _aegis-brain/: `current-plan.json` schema defined
- Estimated rework reduction: 40% based on v6.0 retrospective data

---

### CR-004: Add PM State Persistence System

**ID**: CR-004
**Date Raised**: 2026-Q1
**Raised By**: Nick Fury
**Status**: Approved and Implemented (v7.0)

**Problem Statement**:
AEGIS sessions had no memory of their PM state between Claude Code restarts. Each new session required the operator to manually re-establish context (current sprint, blockers, last decision). This violated the "Context is King, Memory is Soul" principle.

**Proposed Change**:
- Add `_aegis-brain/pm-state.json` with fields: current_phase, current_cycle, active_agents, blockers, last_decision, session_count
- Add `/aegis-pm-start` skill to initialize/restore PM state at session start
- Add `/aegis-pm-cycle` skill to advance phase (planning → in-process → review → retro)
- Add `/aegis-pm-status` skill to display current state as formatted report
- Nick Fury reads pm-state.json as first action in `/aegis-start`

**Decision**: Approved. This was identified as the highest-leverage architectural change for v7.0.

**Impact**:
- _aegis-brain/pm-state.json: New file, always present
- CLAUDE_skills.md: 3 new PM skills
- CLAUDE_agents.md: Nick Fury updated to read pm-state on startup
- CLAUDE.md: PM state section added to overview
