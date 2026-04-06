---
document: PM.01
title: Project Plan — AEGIS AI Agent Team Framework
version: 1
status: Approved
created: 2026-03-24
author: Coulson (AEGIS v7.1)
project: AEGIS — AI Agent Team Framework
---

# PM.01 Project Plan

## 1. Project Objective

Build and maintain AEGIS (Autonomous Engineered General Intelligence System), a production-grade AI agent team framework for Claude Code. AEGIS enables a single operator to coordinate a team of 12 specialized AI agents — each with a defined role, model tier, blast radius, and communication protocol — to perform software engineering tasks with minimal human intervention.

**Primary goal**: Replace ad-hoc, single-Claude sessions with a structured, multi-agent pipeline that enforces quality gates, maintains persistent memory, and self-improves through retrospectives.

## 2. Scope

### In Scope
- 12 agent personas with routing rules (CLAUDE_agents.md)
- 27 skills as slash commands (CLAUDE_skills.md)
- Persistent brain directory (`_aegis-brain/`) for cross-session memory
- PM state system (planning, in-process, review, retro cycles)
- 3-gate quality system (Black Panther review → War Machine QA → Loki challenge)
- ISO 29110 Basic Profile compliance documentation
- tmux-based multi-agent orchestration (optional; graceful degradation)
- Bilingual support: English primary, Thai secondary

### Out of Scope
- Custom model fine-tuning
- External API integrations beyond Claude Code
- Web or mobile UI
- Multi-repository orchestration

### Agents (12 total)
| # | Agent | Model Tier | Primary Role |
|---|-------|-----------|-------------|
| 1 | Captain America | opus | Orchestrator, retro author |
| 2 | Iron Man | opus | Architect, system design |
| 3 | Spider-Man | sonnet | Implementer, code writer |
| 4 | Black Panther | sonnet | Code reviewer, quality gate |
| 5 | Loki | opus | Devil's advocate, risk finder |
| 6 | Beast | haiku | Scanner, research gatherer |
| 7 | Wasp | sonnet | UX designer, accessibility |
| 8 | Songbird | haiku | Docs, content, copywriting |
| 9 | War Machine | sonnet | QA lead, test strategy |
| 10 | Vision | haiku | QA executor, test runner |
| 11 | Coulson | haiku | ISO 29110 compliance docs |
| 12 | Nick Fury | opus | Autonomous controller |

### Skills (27 total)
Categories: Session (aegis-start, aegis-retro, aegis-status, aegis-mode), Pipeline (aegis-pipeline, aegis-plan, aegis-build, aegis-review, aegis-qa, aegis-retro-deep), Team (aegis-team-build, aegis-team-review, aegis-team-debate), Brain (aegis-brain-scan, aegis-brain-update, aegis-brain-reset), PM (aegis-pm-start, aegis-pm-cycle, aegis-pm-status), QA (aegis-qa-plan, aegis-qa-run, aegis-qa-gate), Docs (aegis-doc-gen, aegis-doc-update), Util (aegis-diff, aegis-checkpoint).

## 3. Timeline

| Phase | Version | Date | Deliverables |
|-------|---------|------|-------------|
| Foundation | v6.0 | 2025-Q4 | 8 agents, basic skills, brain directory, tmux orchestration |
| Enterprise | v7.0 | 2026-Q1 | +4 agents (War Machine, Vision, Coulson, Nick Fury), QA system, ISO 29110, PM state |
| Stabilization | v7.1 | 2026-03-24 | PM.01–PM.04 + SI.01–SI.07 docs, counters, changelog system |
| Next | v7.2 | TBD | Automated test harness, skill coverage expansion |

## 4. Team

| Role | Agent | Human Equivalent |
|------|-------|-----------------|
| Project Lead | Captain America | Project Manager |
| System Architect | Iron Man | Senior Architect |
| Developer | Spider-Man | Senior Engineer |
| QA Lead | War Machine | QA Manager |
| Reviewer | Black Panther | Tech Lead |
| Challenger | Loki | Risk Manager |
| Researcher | Beast | Research Analyst |
| Human Sponsor | User/Operator | Product Owner |

## 5. Milestones

| ID | Milestone | Target | Status |
|----|-----------|--------|--------|
| M1 | v6.0 baseline — 8 agents, 20 skills | 2025-Q4 | Done |
| M2 | v7.0 — 12 agents, QA system, ISO compliance stub | 2026-Q1 | Done |
| M3 | v7.1 — Full ISO 29110 Basic Profile (11 docs) | 2026-03-24 | In Progress |
| M4 | v7.2 — Automated regression, skill parity | TBD | Planned |

## 6. Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|-----------|--------|-----------|
| R1 | Context window exhaustion in long sessions | High | Medium | aegis-checkpoint, brain summaries |
| R2 | tmux unavailable on target machine | Medium | Low | tmux marked optional; in-process fallback |
| R3 | Model tier routing changes break agent behavior | Medium | High | Model references abstracted in CLAUDE_agents.md |
| R4 | Agent coordination deadlock (false-ready) | Low | High | Golden Rule #4: never end turn before agents finish |
| R5 | CLAUDE.md instruction drift across versions | Medium | Medium | Version-tagged CLAUDE.md with navigation table |

## 7. Resources

- **Repository**: `/Users/phariyawit.jiap/Documents/AEGIS-Team/` (local), GitHub remote
- **Brain storage**: `_aegis-brain/` — 10 JSON files, persistent across sessions
- **Output**: `_aegis-output/` — retros, ISO docs, QA reports
- **Framework files**: CLAUDE.md, CLAUDE_agents.md, CLAUDE_skills.md, CLAUDE_safety.md, CLAUDE_lessons.md
- **Cost model**: Claude API — opus for reasoning-heavy agents, haiku for high-frequency tasks
