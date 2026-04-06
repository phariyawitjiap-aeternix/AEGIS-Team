---
document: SI.02
title: Design Document — AEGIS Architecture
version: 1
status: Approved
created: 2026-03-24
author: Coulson (AEGIS v7.1)
project: AEGIS — AI Agent Team Framework
---

# SI.02 Design Document

## 1. Architecture Overview

AEGIS is a layered framework built entirely on Claude Code's CLAUDE.md instruction system. There is no runtime process — the "system" is the set of markdown instruction files that shape Claude's behavior in every session.

```
Layer 6: ISO Compliance         _aegis-output/iso-docs/
Layer 5: Output Artifacts       _aegis-output/retros/, qa-reports/
Layer 4: Agent Memory           _aegis-brain/ (10 JSON files)
Layer 3: Quality Gates          Black Panther → War Machine → Loki (3-gate pipeline)
Layer 2: Skill Commands         /aegis-* (27 slash commands in CLAUDE_skills.md)
Layer 1: Agent Personas         12 agents defined in CLAUDE_agents.md
Layer 0: Framework Core         CLAUDE.md, CLAUDE_safety.md, CLAUDE_lessons.md
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
**File**: CLAUDE_agents.md

12 agents, each defined with:
- Model tier: opus (reasoning), sonnet (implementation/review), haiku (speed/volume)
- Blast radius: read scope, write scope, forbidden scope
- Message types: what it sends, what it receives
- Behavioral rules: 3–5 invariant rules that define the agent's character

Model routing rationale:
- `opus`: Captain America, Iron Man, Loki, Nick Fury — tasks requiring deep reasoning, architecture, challenge
- `sonnet`: Spider-Man, Black Panther, Wasp, War Machine — tasks requiring solid implementation and review
- `haiku`: Beast, Songbird, Vision, Coulson — high-frequency, volume-oriented, cost-sensitive tasks

### Layer 2: Skill Commands
**File**: CLAUDE_skills.md

27 slash commands organized in 7 categories:
- **Session** (4): aegis-start, aegis-retro, aegis-status, aegis-mode
- **Pipeline** (6): aegis-pipeline, aegis-plan, aegis-build, aegis-review, aegis-qa, aegis-retro-deep
- **Team** (3): aegis-team-build, aegis-team-review, aegis-team-debate
- **Brain** (3): aegis-brain-scan, aegis-brain-update, aegis-brain-reset
- **PM** (3): aegis-pm-start, aegis-pm-cycle, aegis-pm-status
- **QA** (3): aegis-qa-plan, aegis-qa-run, aegis-qa-gate
- **Docs** (2): aegis-doc-gen, aegis-doc-update
- **Util** (3): aegis-diff, aegis-checkpoint, aegis-help

Each skill specifies: purpose, inputs, outputs, agents involved, gate requirements.

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

### Layer 4: Agent Memory
**Directory**: `_aegis-brain/`

| File | Purpose |
|------|---------|
| pm-state.json | Current phase, cycle, active agents, blockers |
| counters.json | Auto-increment IDs: US, J, E, T, ST, DOC |
| lessons.json | Structured lessons from retros |
| current-plan.json | Active plan artifact (required before build) |
| agent-assignments.json | Who is doing what this cycle |
| decisions.json | Decision log with rationale |
| tech-debt.json | Known debt items with priority |
| retrospectives-index.json | Index of all retro files |
| project-context.json | Project metadata, repo info, operator prefs |
| skills-registry.json | Skill execution log, last-run timestamps |

### Layer 5: Output Artifacts
**Directory**: `_aegis-output/`

- `retros/` — Retrospective documents (one per session)
- `qa-reports/` — War Machine QA reports and Vision test results
- `iso-docs/` — ISO 29110 work products (this document lives here)
- `debate-logs/` — Loki challenge + team debate transcripts

### Layer 6: ISO Compliance
**Directory**: `_aegis-output/iso-docs/`

11 work products following ISO 29110 Basic Profile:
- PM process: PM.01–PM.04
- SI process: SI.01–SI.07

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
