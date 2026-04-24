---
document: SI.03
title: Design Document — AEGIS Architecture
version: 2
status: Approved
created: 2026-03-24
updated: 2026-04-24
author: Coulson (AEGIS v7.1), updated by Nick Fury (sprint-v10-01)
project: AEGIS — AI Agent Team Framework
---

# SI.03 Design Document

## 1. Architecture Overview

AEGIS is a layered framework built entirely on Claude Code's CLAUDE.md instruction system. There is no runtime process — the "system" is the set of markdown instruction files that shape Claude's behavior in every session.

```
Layer 7: Documentation          docs/ (Application Playbook, guides)
Layer 6: ISO Compliance         _aegis-output/iso-docs/ (12 docs: PM.01-PM.06, SI.01-SI.06)
Layer 5: Output Artifacts       _aegis-output/retros/, qa-reports/, specs/
Layer 4: Agent Memory           .aegis/brain/ (brain directory, migrated from _aegis-brain/ in v9-01)
Layer 3: Quality Gates          5-gate pipeline (Gate 0-5: Pre-Work, Code, QA, Compliance, Deploy, Monitor)
Layer 2: Commands               /aegis-* (30 canonical commands in .claude/commands/)
Layer 1: Agent Personas         11 agents defined in .claude/agents/
Layer 0: Framework Core         CLAUDE.md, CLAUDE_safety.md, CLAUDE_lessons.md
Hook Layer: Enforcement         .claude/hooks/ (11 hooks: guard-bash, guard-write, guard-ui-edit, etc.)
Tool Layer: Operations          tools/ (61 bash scripts: audit, test, build, deploy helpers)
Reference Layer: Knowledge      .claude/references/ (28 reference documents)
```

## 2. Layer Descriptions

### Layer 0: Framework Core
**Files**: CLAUDE.md, CLAUDE_safety.md, CLAUDE_lessons.md

CLAUDE.md is the root instruction file read at every session start. It defines:
- Navigation table (which files to read, when, priority)
- Golden Rules (absolute constraints, never overridden)
- Nick Fury behavior and default autonomy level
- Quick command reference

CLAUDE_safety.md defines the permission model:
- Blast radius per agent (what each agent can read/write/delete)
- Forbidden operations (force push, commit --amend, direct main push)
- Escalation protocol when an agent wants to exceed its blast radius

CLAUDE_lessons.md accumulates learnings from retrospectives:
- Format: `[DATE] [AGENT] Lesson: {what went wrong/right} → {future behavior}`
- Read before major decisions; written at every `/aegis-retro`

### Layer 1: Agent Personas
**Directory**: `.claude/agents/`

11 agents (consolidated from 13 in v9-03: Songbird merged into language rules, Vision merged into War Machine QA), each defined in its own `.md` file with: role, tool permissions, blast radius, behavioral rules.

| Agent | Tier | Primary Role |
|-------|------|-------------|
| Nick Fury | opus | Orchestration, Decision Matrix, Master Brain |
| Iron Man | opus | Architecture, spec authoring |
| Captain America | opus | Debate facilitation, judgment fallback |
| Loki | opus | Adversarial review, spec challenge |
| Spider-Man | sonnet | Implementation, build execution |
| Black Panther | sonnet | Code review (Gate 1) |
| War Machine | sonnet | QA planning (Gate 2) |
| Wasp | sonnet | Visual design, DESIGN.md authoring |
| Thor | sonnet | DevOps, deployment (Gates 4-5) |
| Beast | haiku | Research, scanning |
| Coulson | haiku | ISO docs, compliance (Gate 3) |

### Layer 2: Commands
**Directory**: `.claude/commands/`

30 canonical slash commands (consolidated from 27 skills + legacy aliases in v9-06). Each command is a standalone `.md` file in `.claude/commands/`.

Major categories:
- **Session** (4): aegis-start, aegis-retro, aegis-status, aegis-mode
- **Pipeline** (5): aegis-pipeline, aegis-verify, aegis-qa, aegis-flow, aegis-deploy
- **Team** (4): aegis-team, aegis-team-build, aegis-team-review, aegis-team-debate
- **Memory** (5): aegis-memory, aegis-distill, aegis-evolve, aegis-ingest, aegis-instinct
- **Sprint** (3): aegis-sprint, aegis-kanban, aegis-breakdown
- **Docs** (3): aegis-compliance, aegis-adr, aegis-handoff
- **Infra** (6): aegis-doctor, aegis-lint, aegis-context, aegis-launch, aegis-reengineer, aegis-dashboard

Each command specifies: purpose, inputs, outputs, agent assignments, gate requirements.

### Layer 3: Three-Gate Quality System

```
Change Proposed
      │
      ▼
 [Gate 1: Black Panther]
 Code quality, security, style
 Output: Black Panther verdict (Pass/Fail + comments)
      │
      ▼ (on Pass)
 [Gate 2: War Machine]
 Test coverage, QA verdict, regression check
 Output: War Machine QA report
      │
      ▼ (on Pass)
 [Gate 3: Loki]
 Assumptions, strategic risks, "what breaks at scale"
 Output: Loki challenge report (Accept/Escalate)
      │
      ▼ (on Accept)
   DONE
```

Gate failures trigger either fix-and-resubmit (Black Panther, War Machine) or architecture review (Loki escalation to Captain America).

### Layer 4: Agent Memory (Brain)
**Directory**: `.aegis/brain/` (migrated from `_aegis-brain/` in v9-01)

| Subdirectory | Purpose |
|-------------|---------|
| `instincts/` | Promoted, active, pending instincts (learning system) |
| `learnings/` | Raw + distilled session learnings |
| `logs/` | Activity, heartbeat, decision-audit, team-chat logs |
| `metrics/` | Judgment counter, skill stats |
| `resonance/` | Project identity, evolved patterns, anti-patterns |
| `retrospectives/` | Sprint and session retros |
| `sprints/` | Sprint plans, kanbans, roadmap, close docs |
| `tasks/` | PROJ-E/J/T/US task directories with meta.json |
| `handoffs/` | Session handoff briefs |
| `human-queue.md` | Items requiring human input (MBP escalation) |
| `index.md` | LLM-wiki brain index (Karpathy pattern) |

### Layer 5: Output Artifacts
**Directory**: `_aegis-output/`

- `retros/` — Retrospective documents (one per session)
- `qa-reports/` — War Machine QA reports and Vision test results
- `iso-docs/` — ISO 29110 work products (this document lives here)
- `debate-logs/` — Loki challenge + team debate transcripts

### Layer 6: ISO Compliance
**Directory**: `_aegis-output/iso-docs/`

12 work products following ISO 29110 Basic Profile:
- PM process: PM.01-PM.06 (Project Plan, Progress Status, Change Requests, Meeting Records, Correction Register, Acceptance Record)
- SI process: SI.01-SI.06 (Requirements Spec, Traceability Matrix, Design Doc, Test Cases, Test Report, Delivery)

Note: SI.07 was removed -- does not exist in ISO 29110 standard. Delivery is SI.06.

Each document: `v{n}.md` (versioned), `current.md` (latest), `changelog.md` (history).
Tracked in `doc-registry.json`.

## 3. PM State Machine

```
         ┌─────────────────────────────────────┐
         │            PM State Machine          │
         │                                     │
  START  │  planning ──► in-process ──► review │
    ─────►                                ──►  │
         │              retro ◄────────────────┘
         │                │                    │
         └────────────────▼────────────────────┘
                      next cycle
```

State transitions triggered by `/aegis-pm-cycle`. Nick Fury reads state at session start and resumes from last known phase.

## 4. Decision Matrix (Nick Fury)

Nick Fury scores pending tasks P0–P10 based on:
- P0–P2: Blockers (broken build, security issue, data loss risk)
- P3–P5: High priority (unfinished cycle, failing gate, stale plan)
- P6–P8: Normal (feature work, doc updates, refactoring)
- P9–P10: Low (nice-to-have, cosmetic, future ideas)

Nick Fury always works from P0 down. Never skips a P0 to work on P5.

## 5. Data Flow

```
Operator input (/aegis-start)
    │
    ▼
Nick Fury reads pm-state.json + git log + brain files
    │
    ▼
Decision Matrix constructed (P0–P10)
    │
    ▼
Plan artifact written to current-plan.json
    │
    ▼
Agents assigned (agent-assignments.json)
    │
    ▼
Spider-Man/Wasp implement ─► Black Panther Gate 1 ─► War Machine Gate 2 ─► Loki Gate 3
    │
    ▼
Output artifacts written (_aegis-output/)
    │
    ▼
pm-state.json updated ─► /aegis-retro ─► lessons.json updated
```

## 6. Module Catalog (MOD-XX)

> Added: sprint-v10-01-B (2026-04-24)
> Purpose: Provide a stable, referenceable ID for each top-level module in the AEGIS framework.
> Each module groups related files under a single ownership and traceability scope.

### MOD-CORE -- Framework Core

| Field | Value |
|-------|-------|
| ID | MOD-CORE |
| Description | Root instruction files that define AEGIS identity, golden rules, navigation, and safety constraints. Read at every session start. The single source of truth for framework behavior. |
| Owner | Nick Fury |
| Primary Files | `CLAUDE.md`, `CLAUDE_safety.md`, `CLAUDE_lessons.md`, `CLAUDE_agents.md`, `CLAUDE_skills.md` |
| Dependencies | None (Layer 0 -- no upstream) |
| Requirements | FR-03, FR-08, FR-10, NFR-04, NFR-07 |
| Test Coverage | TC-03, TC-08, TC-10, TC-14, TC-17 |

### MOD-AGENTS -- Agent Personas

| Field | Value |
|-------|-------|
| ID | MOD-AGENTS |
| Description | 11 agent persona definition files. Each defines a role, tool permissions, blast radius, and behavioral rules. Agents are the primary actors in the AEGIS pipeline. |
| Owner | Nick Fury (roster), each agent owns its own file |
| Primary Files | `.claude/agents/beast.md`, `black-panther.md`, `captain-america.md`, `coulson.md`, `iron-man.md`, `loki.md`, `nick-fury.md`, `spider-man.md`, `thor.md`, `war-machine.md`, `wasp.md` |
| Dependencies | MOD-CORE (reads golden rules from CLAUDE.md) |
| Requirements | FR-01, FR-05, FR-09, FR-12, FR-16, FR-17, NFR-02 |
| Test Coverage | TC-01, TC-05, TC-09, aegis-nick-fury-loop-harness.sh |

### MOD-COMMANDS -- Slash Commands

| Field | Value |
|-------|-------|
| ID | MOD-COMMANDS |
| Description | 30 canonical `/aegis-*` slash commands implemented as markdown files in `.claude/commands/`. Each command defines purpose, inputs, outputs, and agent assignments. |
| Owner | Iron Man (spec), Spider-Man (implementation) |
| Primary Files | `.claude/commands/aegis-start.md`, `aegis-retro.md`, `aegis-sprint.md`, `aegis-pipeline.md`, and 26 others |
| Dependencies | MOD-CORE (command behavior constrained by golden rules), MOD-AGENTS (commands dispatch to agents) |
| Requirements | FR-02, FR-03, FR-06, FR-11, FR-18 |
| Test Coverage | TC-02, TC-03, TC-06, TC-001..TC-008, test-f2-01-command-shims.sh |

### MOD-HOOKS -- Enforcement Hooks

| Field | Value |
|-------|-------|
| ID | MOD-HOOKS |
| Description | 11 Claude Code hooks that enforce golden rules at the tool level. Guards prevent force-push, unauthorized writes, MBP violations. Runs automatically before/after tool calls. |
| Owner | Black Panther (review), Spider-Man (implementation) |
| Primary Files | `.claude/hooks/guard-bash.sh`, `guard-write.sh`, `guard-ui-edit.sh`, `guard-ask-user.sh`, `on-stop.sh`, `post-tool-use.sh`, `post-edit-accumulate.sh`, `run-with-flags.sh`, `session-start.sh`, `tinman-heartbeat.sh`, `aegis-version-check.sh` |
| Dependencies | MOD-CORE (enforces golden rules) |
| Requirements | FR-12, FR-13, FR-14 |
| Test Coverage | aegis-guard-write-test.sh, aegis-guard-ui-edit-test.sh, aegis-policy-audit.sh |

### MOD-BRAIN -- Agent Memory

| Field | Value |
|-------|-------|
| ID | MOD-BRAIN |
| Description | Persistent cross-session state in `.aegis/brain/`. Contains instincts (learning system), logs (activity, decisions, heartbeat), tasks (PROJ-E/J/T/US), sprints, resonance (project identity, patterns), and handoffs. The "soul" of AEGIS. |
| Owner | Nick Fury (writes), all agents (read) |
| Primary Files | `.aegis/brain/index.md`, `instincts/`, `learnings/`, `logs/`, `metrics/`, `resonance/`, `retrospectives/`, `sprints/`, `tasks/`, `handoffs/`, `human-queue.md` |
| Dependencies | MOD-TOOLS (brain-sync, brain-write helpers) |
| Requirements | FR-04, FR-06, FR-15, NFR-05 |
| Test Coverage | TC-04, TC-06, TC-15, aegis-brain-adversarial-test.sh |

### MOD-TOOLS -- Operational Scripts

| Field | Value |
|-------|-------|
| ID | MOD-TOOLS |
| Description | 61 bash scripts providing operational capabilities: testing, auditing, brain management, design system, migration, deployment helpers. The "hands" of AEGIS. |
| Owner | Spider-Man (implementation), Black Panther (review) |
| Primary Files | `tools/aegis-log-decision.sh`, `aegis-policy-audit.sh`, `aegis-block0-mode.sh`, `aegis-design-init.sh`, `aegis-design-lint.sh`, `aegis-test-all.sh`, `aegis-progress.sh`, `aegis-team-chat.sh`, and 53 others |
| Dependencies | MOD-BRAIN (reads/writes brain state), MOD-HOOKS (some tools are called by hooks) |
| Requirements | FR-13, FR-15, FR-17, FR-19, NFR-08 |
| Test Coverage | 15+ dedicated test scripts (test-f1-*, test-f2-*, test-f3-*, test-s2-*) |

### MOD-ISO -- ISO Compliance Documents

| Field | Value |
|-------|-------|
| ID | MOD-ISO |
| Description | 12 ISO 29110 Basic Profile work products (PM.01-PM.06, SI.01-SI.06). Each document has versioned snapshots (v1.md), current state (current.md), and changelog. Tracked by doc-registry.json. |
| Owner | Coulson |
| Primary Files | `_aegis-output/iso-docs/PM-01-project-plan/`, `PM-02-progress-status/`, `PM-03-change-requests/`, `PM-04-meeting-records/`, `PM-05-correction-register/`, `PM-06-acceptance-record/`, `SI-01-requirements-spec/`, `SI-02-traceability-matrix/`, `SI-03-design-doc/`, `SI-04-test-cases/`, `SI-05-test-report/`, `SI-06-delivery/`, `doc-registry.json` |
| Dependencies | MOD-BRAIN (reads task/sprint data), MOD-SPECS (traces to specs) |
| Requirements | FR-07 |
| Test Coverage | TC-07, aegis-trace-audit.sh |

### MOD-REFS -- Reference Documents

| Field | Value |
|-------|-------|
| ID | MOD-REFS |
| Description | 28 reference documents providing detailed protocol specifications, design decisions, and operational guides. Read by agents on-demand for specific protocol details. |
| Owner | Iron Man (authoring), Captain America (review) |
| Primary Files | `.claude/references/quality-protocol.md`, `context-rules.md`, `decision-audit-protocol.md`, `block-0-lite.md`, `captain-america-fallback.md`, `sdlc-pipeline.md`, and 22 others |
| Dependencies | MOD-CORE (referenced from CLAUDE.md navigation) |
| Requirements | FR-16, FR-20 |
| Test Coverage | aegis-policy-audit.sh (policy-without-test audit) |

### MOD-SPRINTS -- Sprint Planning

| Field | Value |
|-------|-------|
| ID | MOD-SPRINTS |
| Description | Sprint lifecycle artifacts: plans, kanbans, close documents, roadmap. The `current` symlink always points to the active sprint. Supports the AEGIS SDLC pipeline from planning through delivery. |
| Owner | Nick Fury (planning), Coulson (documentation) |
| Primary Files | `.aegis/brain/sprints/roadmap.md`, `sprint-v9-01/` through `sprint-v10-01/`, `current` (symlink) |
| Dependencies | MOD-BRAIN (sprints are subdirectory of brain) |
| Requirements | FR-18 |
| Test Coverage | Manual (sprint artifact presence verified at close) |

### MOD-SPECS -- Design Specifications

| Field | Value |
|-------|-------|
| ID | MOD-SPECS |
| Description | Task-level design specifications written by Iron Man, reviewed by Loki. Each spec covers a task or group of tasks with acceptance criteria, implementation approach, and test strategy. |
| Owner | Iron Man (author), Loki (review) |
| Primary Files | `_aegis-output/specs/PROJ-T-001-spec.md` through `PROJ-T-012-spec.md`, `FINAL-PUSH-spec.md`, `S-V9-04-REMAINING-spec.md`, etc. (15 specs total) |
| Dependencies | MOD-ISO (specs trace to SI.01 requirements) |
| Requirements | FR-05, FR-09 |
| Test Coverage | Spec-tracking test (aegis-spec-tracking-test.sh) |

### MOD-PLAYBOOK -- Framework Application Guide

| Field | Value |
|-------|-------|
| ID | MOD-PLAYBOOK |
| Description | Step-by-step guide for applying AEGIS to real projects. Covers brain seeding, persona assembly, CLAUDE.md tailoring, BLOCK 0 bootstrap, and includes a greenfield React app walkthrough. v10 deliverable. |
| Owner | Nick Fury |
| Primary Files | `docs/AEGIS_APPLICATION_PLAYBOOK.md` |
| Dependencies | MOD-CORE (references CLAUDE.md structure), MOD-BRAIN (references brain seeding) |
| Requirements | FR-21 |
| Test Coverage | Manual (walkthrough verification) |

### Module Dependency Graph

```
MOD-CORE (Layer 0, no upstream dependencies)
  |
  +-- MOD-AGENTS (Layer 1, reads golden rules)
  |     |
  |     +-- MOD-COMMANDS (Layer 2, dispatches to agents)
  |
  +-- MOD-HOOKS (enforcement, enforces golden rules)
  |
  +-- MOD-REFS (knowledge base, referenced from CLAUDE.md)
  |
  +-- MOD-PLAYBOOK (application guide)

MOD-BRAIN (Layer 4, central state)
  |
  +-- MOD-SPRINTS (subdirectory of brain)
  |
  +-- MOD-TOOLS (reads/writes brain state)
  |
  +-- MOD-ISO (reads task/sprint data)
       |
       +-- MOD-SPECS (traces to requirements)
```
