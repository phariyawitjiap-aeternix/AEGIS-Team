---
document: SI.01
title: Requirements Specification — AEGIS AI Agent Team Framework
version: 1
status: Approved
created: 2026-03-24
author: Coulson (AEGIS v7.1)
project: AEGIS — AI Agent Team Framework
---

# SI.01 Requirements Specification

## 1. Purpose

This document specifies the functional and non-functional requirements for AEGIS v7.1. Requirements are derived from operator needs, retrospective findings, and ISO 29110 Basic Profile process obligations.

## 2. Stakeholders

| Stakeholder | Role | Primary Concern |
|-------------|------|----------------|
| Human Operator | Primary user | Productive, low-friction AI-assisted development |
| Claude Code | Execution host | CLAUDE.md instruction compliance |
| Anthropic API | Infrastructure | Token efficiency, model routing |

## 3. Functional Requirements

### FR-01: Agent Roster and Routing
The system shall define 12 agent personas, each with: name, model tier (opus/sonnet/haiku), primary role, tool permissions, blast radius (read/write/forbidden), message types sent/received, and behavioral rules.

**Acceptance**: CLAUDE_agents.md contains all 12 agents with all required fields. Any agent invoked by name routes to correct model tier.

### FR-02: Skill Command System
The system shall provide at minimum 27 slash commands (skills) accessible in Claude Code via `/skill-name`. Each skill shall have a defined purpose, inputs, outputs, and agent assignments.

**Acceptance**: CLAUDE_skills.md documents all 27 skills. Each skill executes without error when invoked with valid inputs.

### FR-03: Session Lifecycle
The system shall support a defined session lifecycle:
1. `/aegis-start` — initializes session, restores PM state, scans project
2. Active work — agents execute tasks per PM cycle
3. `/aegis-retro` — captures retrospective, updates brain, closes session

**Acceptance**: `/aegis-start` produces a status report. `/aegis-retro` writes a retro document to `_aegis-output/retros/`.

### FR-04: Persistent Memory (Brain Directory)
The system shall maintain a `_aegis-brain/` directory with JSON files persisting cross-session state: PM state, counters, lessons learned, current plan, agent assignments.

**Acceptance**: After a session ends and a new session begins, `_aegis-brain/pm-state.json` reflects the last known phase and cycle count.

### FR-05: Three-Gate Quality System
The system shall enforce a three-gate quality pipeline for all significant changes:
- Gate 1: Black Panther (code quality, security, style)
- Gate 2: War Machine (test coverage, QA verdict)
- Gate 3: Loki (assumptions, strategic risks)

**Acceptance**: No change reaches "Done" status without passing all three gates. Each gate produces a written verdict artifact.

### FR-06: PM State Machine
The system shall maintain a PM state machine with four phases: `planning` → `in-process` → `review` → `retro`. Phase transitions shall be explicit (via `/aegis-pm-cycle`) and recorded in `pm-state.json`.

**Acceptance**: `pm-state.json` always reflects current phase. `/aegis-pm-status` displays human-readable phase summary.

### FR-07: ISO 29110 Compliance Documentation
The system shall generate and maintain all 11 ISO 29110 Basic Profile work products (PM.01–PM.04, SI.01–SI.07) for the AEGIS project itself (dogfooding).

**Acceptance**: All 11 documents exist in `_aegis-output/iso-docs/` with `v1.md`, `current.md`, and `changelog.md` per document. `doc-registry.json` lists all 11.

### FR-08: Autonomy Levels
The system shall support three autonomy levels:
- L1 (Guided): Human approves every agent action
- L2 (Supervised): Human approves major decisions, agents handle details
- L3 (Autonomous): Nick Fury decides and executes; human can interrupt

**Acceptance**: `/aegis-mode --autonomy L1/L2/L3` switches mode. Current mode reflected in pm-state.json.

### FR-09: Nick Fury Orchestration
Nick Fury shall, on activation, scan project state (git log, brain files, open tasks), construct a Decision Matrix (P0–P10 priority), and spawn the appropriate agent team without human prompting.

**Acceptance**: `/aegis-start` in L3 mode produces a plan and begins execution without operator input beyond the initial command.

### FR-10: tmux Optional / In-Process Fallback
The system shall function in two modes: tmux mode (parallel agents in separate windows) and in-process mode (sequential agents in one session). All quality gates shall function in both modes.

**Acceptance**: Running `/aegis-start` without tmux installed completes without error and defaults to in-process mode.

## 4. Non-Functional Requirements

### NFR-01: Zero External Runtime Dependencies
AEGIS shall require no packages, libraries, or external services beyond Claude Code and the Anthropic API.

### NFR-02: Token Efficiency
High-frequency, low-reasoning tasks (research, doc generation, test execution) shall route to haiku-tier agents. Reasoning-heavy tasks shall route to opus. The system shall not use opus for tasks a haiku can handle.

### NFR-03: Portability
AEGIS shall run on any machine where Claude Code is installed. Framework state is in plain markdown and JSON files — no database, no binary dependencies.

### NFR-04: Graceful Degradation
If an agent is unavailable or a skill fails, the system shall produce an error report and continue with available agents rather than halting the entire session.

### NFR-05: Audit Trail
All agent decisions, gate verdicts, and PM state transitions shall be recorded in `_aegis-brain/` or `_aegis-output/`. The operator shall be able to reconstruct any decision from artifacts.

### NFR-06: Bilingual Operator Interface
Agent outputs targeting the human operator may be produced in English and/or Thai based on operator preference. Technical artifacts (code, commits, ISO docs) shall be English-only.

### NFR-07: Version Compatibility
CLAUDE.md and related files shall include a version header. Changes that break backward compatibility shall increment the major version number.
