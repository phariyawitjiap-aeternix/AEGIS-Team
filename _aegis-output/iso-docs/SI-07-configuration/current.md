---
document: SI.07
title: Configuration Management — AEGIS Version History and Dependencies
version: 1
status: Approved
created: 2026-03-24
author: Coulson (AEGIS v7.1)
project: AEGIS — AI Agent Team Framework
---

# SI.07 Configuration Management

## 1. Purpose

This document defines the configuration management approach for AEGIS, including version identification, dependency inventory, release notes, and configuration item (CI) registry.

## 2. Configuration Management Approach

AEGIS uses git as its configuration management system. All framework files are tracked in version control. The `_aegis-brain/` directory is tracked (brain state is part of the project's configuration). The `_aegis-output/` directory is tracked (artifacts are deliverables, not ephemera).

**Branching strategy**: feature branches + PR always; never push directly to main. Enforced by Golden Rule #2.

**Version numbering**: MAJOR.MINOR format (e.g., v7.1). MAJOR increments on breaking changes to agent behavior or CLAUDE.md instruction format. MINOR increments on additive features, new agents, new skills.

## 3. Configuration Items

| CI ID | Item | Type | Location | Owner |
|-------|------|------|----------|-------|
| CI-01 | CLAUDE.md | Framework core | /AEGIS-Team/CLAUDE.md | Captain America |
| CI-02 | CLAUDE_agents.md | Agent definitions | /AEGIS-Team/CLAUDE_agents.md | Iron Man |
| CI-03 | CLAUDE_skills.md | Skill commands | /AEGIS-Team/CLAUDE_skills.md | Captain America |
| CI-04 | CLAUDE_safety.md | Permission model | /AEGIS-Team/CLAUDE_safety.md | Black Panther |
| CI-05 | CLAUDE_lessons.md | Retrospective learnings | /AEGIS-Team/CLAUDE_lessons.md | Captain America |
| CI-06 | _aegis-brain/ | Persistent memory (10 JSON) | /AEGIS-Team/_aegis-brain/ | Nick Fury |
| CI-07 | _aegis-output/ | Artifacts and docs | /AEGIS-Team/_aegis-output/ | Coulson |
| CI-08 | GETTING_STARTED.md | Operator setup guide | /AEGIS-Team/GETTING_STARTED.md | Songbird |
| CI-09 | .claude/commands/ | Skill command files | /AEGIS-Team/.claude/commands/ | Captain America |
| CI-10 | CLAUDE_upgrades/ | Version upgrade plans | /AEGIS-Team/CLAUDE_upgrades/ | Iron Man |

## 4. Dependency Inventory

| Dependency | Type | Required | Version | Notes |
|-----------|------|----------|---------|-------|
| Claude Code CLI | Runtime | Yes | Latest stable | Primary execution host |
| Anthropic API | Service | Yes | Current | Access to claude-opus, claude-sonnet, claude-haiku |
| git | CLI tool | Yes | 2.x+ | Version control, branching, PRs |
| macOS / Linux | OS | Yes | Any modern | Darwin tested (Darwin 25.3.0) |
| tmux | CLI tool | No | 3.x+ | Optional; enables true parallel agent windows |
| GitHub | Service | No | — | Remote repository; PRs use gh CLI |
| gh CLI | CLI tool | No | Latest | GitHub PR creation (optional) |

**Zero runtime library dependencies.** AEGIS requires no npm, pip, cargo, or any package manager.

## 5. Release Notes

### v7.1 — 2026-03-24

**Focus**: ISO 29110 Basic Profile documentation (dogfooding)

**New in this release**:
- PM.01 Project Plan
- PM.02 Progress Status Report
- PM.03 Change Requests Log (CR-001 through CR-004)
- PM.04 Meeting Records (MR-001 through MR-005)
- SI.01 Requirements Specification (10 FR + 7 NFR)
- SI.02 Design Document (6-layer architecture)
- SI.03 Traceability Matrix (100% coverage)
- SI.04 Test Plan (17 test cases)
- SI.05 Test Report (11 Pass, 2 Blocked)
- SI.06 Acceptance Record (v6.0, v7.0, v7.1)
- SI.07 Configuration Management (this document)
- doc-registry.json: 11 entries
- counters.json: DOC=11

**No breaking changes.** All v7.0 agents and skills remain compatible.

---

### v7.0 — 2026-Q1

**Focus**: Enterprise agents, QA system, PM state, ISO scaffolding

**New in this release**:
- 4 new agents: War Machine, Vision, Coulson, Nick Fury (12 total)
- 3-gate quality pipeline
- PM State Machine (planning/in-process/review/retro)
- pm-state.json persistence
- 7 new skills (PM: 3, QA: 3, Docs: 2)
- In-process mode (tmux optional) — CR-001
- "cycle" terminology — CR-002
- Planning gate before build — CR-003
- PM state persistence — CR-004
- GETTING_STARTED.md operator guide
- doc-registry.json, counters.json scaffolded

**Breaking change**: Agents that previously referenced "loop" must use "cycle". CLAUDE_agents.md behavioral rules updated.

---

### v6.0 — 2025-Q4

**Focus**: Foundation — standalone agent framework for Claude Code

**Delivered**:
- 8 agents: Captain America, Iron Man, Spider-Man, Black Panther, Loki, Beast, Wasp, Songbird
- ~20 slash command skills
- _aegis-brain/ directory (10 JSON files)
- tmux multi-agent orchestration
- CLAUDE_safety.md permission model
- Session lifecycle (start/retro)
- CLAUDE_lessons.md retrospective capture

## 6. Version Control Status

| Branch | Status | Description |
|--------|--------|-------------|
| main | Protected | Current stable release |
| feature/* | Active during development | Never merge to main directly |

**Recent commits (relevant)**:
- `82b8239` — docs: GETTING_STARTED.md complete v7.0 setup guide
- `529258b` — feat: AEGIS v7.0 enterprise + QA + ISO 29110
- `a61a87f` — docs: Iron Man's team upgrade plan v6.1
- `3d9ff19` — feat: v6.1 team upgrade — 5 Iron Man plan changes + in-process mode
- `f45bf57` — fix: bypassPermissions + expanded allow rules for agent teams

## 7. Configuration Audit

**Last audit date**: 2026-03-24
**Auditor**: Coulson (AEGIS v7.1)

| CI | Expected | Actual | Status |
|----|----------|--------|--------|
| CI-01 CLAUDE.md | Present, v6.0 header | Present | OK |
| CI-02 CLAUDE_agents.md | 12 agents | 12 agents verified | OK |
| CI-03 CLAUDE_skills.md | 27 skills | 27 skills | OK |
| CI-06 _aegis-brain/ | 10 JSON files | 10 files verified | OK |
| CI-07 _aegis-output/iso-docs/ | 11 doc dirs | 11 dirs, 33 files | OK |
| counters.json | DOC=11 | DOC=11 | OK |
| doc-registry.json | 11 entries | 11 entries | OK |
