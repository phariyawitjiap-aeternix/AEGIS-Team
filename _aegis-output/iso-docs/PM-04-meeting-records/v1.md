---
document: PM.04
title: Meeting Records — AEGIS Key Decisions
version: 1
status: Approved
created: 2026-03-24
author: Coulson (AEGIS v7.1)
project: AEGIS — AI Agent Team Framework
---

# PM.04 Meeting Records

> AEGIS is an AI-native project. "Meetings" correspond to structured decision sessions captured as retrospectives, debate-team outputs, and architectural reviews. Records are distilled from `_aegis-brain/` and agent retro logs.

## Meeting Record Format
Each record captures: trigger, participants, key discussion points, decision, and rationale.

---

## MR-001: Standalone Framework Decision

**Date**: 2025-Q4 (v6.0 inception)
**Session Type**: Architecture Review
**Participants**: Captain America (Lead), Iron Man (Architect), Loki (Devil's Advocate)
**Triggered By**: Initial project scoping

**Discussion**:
- Option A: Build AEGIS as a plugin/extension to an existing agent framework (LangChain, AutoGen, CrewAI)
- Option B: Build AEGIS as a standalone CLAUDE.md-native framework with no external dependencies
- Loki challenged Option B: "No external framework means reinventing the wheel. What's the unique value proposition?"
- Iron Man argued Option B: "CLAUDE.md is the native instruction surface for Claude Code. Building on it means zero runtime dependencies, maximum portability, and instructions that survive model upgrades."

**Decision**: Option B — standalone, CLAUDE.md-native framework.

**Rationale**:
1. Zero runtime dependencies: AEGIS runs wherever Claude Code runs
2. CLAUDE.md is the canonical instruction layer — no translation layer needed
3. Framework behavior is version-controlled alongside code, not in a separate dependency
4. Avoids external framework API churn and licensing constraints

**Action Items**:
- Iron Man: Draft CLAUDE.md v1 with agent roster and skill stubs
- Captain America: Define Golden Rules and session lifecycle

---

## MR-002: Bilingual Support (English + Thai)

**Date**: 2025-Q4 (v6.0)
**Session Type**: Stakeholder Alignment
**Participants**: Captain America (Lead), Songbird (Content Creator), Human Operator
**Triggered By**: Operator preference for Thai documentation

**Discussion**:
- Human operator (primary user) works in both English and Thai
- English required for: technical documentation, code comments, commit messages, ISO compliance docs
- Thai useful for: operator-facing summaries, retrospective highlights, status reports

**Decision**: English primary, Thai secondary. Framework files (CLAUDE*.md) remain English-only. Agent outputs may include Thai summaries when operator requests.

**Rationale**:
- ISO 29110 compliance requires consistent language in formal documents
- Code and commit messages must be English for team compatibility
- Thai summaries improve operator comprehension without compromising compliance

**Action Items**:
- Songbird: Add "bilingual output" as optional parameter to content generation skills
- CLAUDE_agents.md: Note Thai secondary language capability under Songbird persona

---

## MR-003: In-Process Mode as Default (tmux Optional)

**Date**: 2026-Q1 (v7.0)
**Session Type**: Architecture Review (CR-001 follow-up)
**Participants**: Captain America (Lead), Iron Man (Architect), Spider-Man (Implementer), Black Panther (Reviewer)
**Triggered By**: CR-001 approval — tmux made optional

**Discussion**:
- After CR-001, two modes exist: tmux mode (true parallel agents) and in-process mode (sequential, same session)
- Question: Which should be the DEFAULT for new operators?
- Spider-Man argued tmux default: "Parallelism is the whole point of a multi-agent team."
- Black Panther argued in-process default: "Most operators start solo. tmux adds setup friction. In-process still enforces all quality gates sequentially."
- Iron Man proposed: "Default to in-process. Operators who want parallelism can opt in with `--mode tmux`."

**Decision**: In-process mode is the default. tmux mode available via `/aegis-mode --profile tmux`.

**Rationale**:
- Lowers barrier to entry significantly
- Quality gates (3-gate system) work in both modes
- Nick Fury can still orchestrate sequentially without tmux
- Operator can escalate to tmux after validating the framework works for their project

**Action Items**:
- CLAUDE.md: Update default mode documentation
- GETTING_STARTED.md: Lead with in-process mode, mention tmux as advanced option
- CLAUDE_skills.md: `/aegis-start` defaults to in-process; add `--mode tmux` flag

---

## MR-004: Loki Review as Mandatory Third Gate

**Date**: 2026-Q1 (v7.0)
**Session Type**: QA Architecture Review
**Participants**: Captain America (Lead), War Machine (QA Lead), Loki (Devil's Advocate), Black Panther (Reviewer)
**Triggered By**: Retrospective finding — quality issues reached production that Black Panther's review and War Machine's QA missed

**Discussion**:
- v6.0 used a 2-gate system: Black Panther review → War Machine QA
- Post-v6.0 retrospective identified category of issues that passed both gates: architectural assumptions that were technically correct but strategically wrong (e.g., implemented the right function the wrong way for the use case)
- Loki argued: "I exist to find the assumptions nobody else questions. If I'm not a gate, I'm just a commentator."
- War Machine supported: "QA finds defects against spec. Loki finds defects in the spec itself."

**Decision**: Loki added as mandatory third gate. Pipeline: Black Panther (code quality) → War Machine (test coverage + QA) → Loki (assumptions + strategic risks).

**Rationale**:
- Each gate catches different failure modes:
  - Black Panther: implementation errors, style violations, security issues
  - War Machine: test coverage gaps, regression risks, QA verdicts
  - Loki: wrong abstractions, hidden risks, "what could go wrong in production"
- Three gates increase confidence without requiring human review for every change

**Action Items**:
- CLAUDE_agents.md: Loki role updated to "mandatory 3rd gate reviewer"
- CLAUDE_skills.md: `/aegis-qa-gate` updated to include Loki verdict step
- CLAUDE.md: 3-gate quality system documented in overview

---

## MR-005: ISO 29110 Basic Profile Adoption

**Date**: 2026-Q1 (v7.0 → v7.1)
**Session Type**: Compliance Planning
**Participants**: Captain America (Lead), Coulson (Compliance), Iron Man (Architect)
**Triggered By**: Operator decision to dogfood AEGIS for its own project management

**Discussion**:
- Operator wants to use AEGIS not just as a tool but as a compliant software development process
- ISO 29110 Basic Profile selected: designed for Very Small Entities (VSE), matches AEGIS's single-operator + AI-team structure
- Coulson persona created specifically for ISO work product generation
- Question: Generate docs once or maintain living documents?

**Decision**: Living documents — each version gets `v1.md`, `current.md` (latest), and `changelog.md`. Stored in `_aegis-output/iso-docs/`.

**Action Items**:
- Create Coulson agent persona in CLAUDE_agents.md
- Scaffold `_aegis-output/iso-docs/` with doc-registry.json
- Add `/aegis-doc-gen` and `/aegis-doc-update` skills
- Generate all 11 documents in v7.1 session (this document is a result of that decision)
