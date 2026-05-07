---
document: SI.02
title: Requirements Traceability Matrix — AEGIS (living document)
version: 2
status: Approved
created: 2026-03-24
updated: 2026-04-24
author: Coulson (AEGIS v7.1), updated by Nick Fury (sprint-v10-01)
project: AEGIS — AI Agent Team Framework
---

# SI.02 Traceability Matrix

## 1. Purpose

This matrix traces each functional requirement (SI.01) to its design element
(SI.03), implementation files, and test cases (SI.04). Ensures no requirement
is unimplemented or untested.

**Reality snapshot (v9.0, 2026-04-24):**
- 11 agent personas (`.claude/agents/*.md`)
- 30 canonical commands (`.claude/commands/*.md`)
- 61 operational tools (`tools/*.sh`)
- 11 enforcement hooks (`.claude/hooks/*.sh`)
- 28 reference documents (`.claude/references/*.md`)
- 12 ISO documents: PM.01-PM.06 + SI.01-SI.06 (SI.07 removed — does not exist in standard)

## 2. Requirement --> Design --> Implementation --> Test

### 2.1 Original Requirements (FR-01 through FR-11, NFR-01 through NFR-07)

| Req ID | Requirement | Design Element | Implementation File(s) | Test Case(s) | Status |
|--------|-------------|---------------|----------------------|-------------|--------|
| FR-01 | Agent roster and routing | Layer 1: Agent Personas | `.claude/agents/*.md` (11 agents: beast, black-panther, captain-america, coulson, iron-man, loki, nick-fury, spider-man, thor, war-machine, wasp) | TC-01 | Current (was "12 agents", now 11 after v9-03 Songbird+Vision consolidation) |
| FR-02 | Skill command system | Layer 2: Commands | `.claude/commands/*.md` (30 canonical commands) | TC-02 | Current (was "27 skills" in CLAUDE_skills.md; now 30 commands after v9-06 consolidation) |
| FR-03 | Session lifecycle (start/work/retro) | PM State Machine | CLAUDE.md, `.claude/commands/aegis-start.md`, `.claude/commands/aegis-retro.md` | TC-03 | Current |
| FR-04 | Persistent memory (brain directory) | Layer 4: Agent Memory | `.aegis/brain/**` (migrated from `_aegis-brain/` in v9-01) | TC-04 | Current (path changed v9-01) |
| FR-05 | Five-gate quality system | Layer 3: Quality Gates + Gate 0 + Gate 4/5 | `.claude/agents/black-panther.md`, `war-machine.md`, `loki.md`, `nick-fury.md`, `thor.md` | TC-05 | Current (was "three-gate", now 5-gate: Gate 0 Pre-Work + Gate 1 Code + Gate 2 QA + Gate 4 Deploy + Gate 5 Monitor) |
| FR-06 | PM State Machine | PM State Machine (SI.03 S3) | `.claude/references/pm-state-protocol.md` | TC-06 | Current |
| FR-07 | ISO 29110 compliance docs (12 docs) | Layer 6: ISO Compliance | `_aegis-output/iso-docs/` (PM.01-PM.06 + SI.01-SI.06) | TC-07 | Current (was "11 docs, SI.01-SI.07"; now 12 docs, PM.01-PM.06 + SI.01-SI.06, SI.07 removed) |
| FR-08 | Autonomy levels (L1/L2/L3) | Nick Fury, /aegis-mode | CLAUDE.md, `.claude/agents/nick-fury.md`, `.claude/commands/aegis-mode.md` | TC-08 | Current |
| FR-09 | Nick Fury orchestration | Decision Matrix (SI.03 S4) | `.claude/agents/nick-fury.md` | TC-09 | Current |
| FR-10 | In-process agent execution | Layer 0: Framework Core | CLAUDE.md | TC-10 | Current (tmux mode deprecated v9-01; in-process only) |
| FR-11 | Post-install verification (/aegis-doctor) | Health check layer | `skills/aegis-doctor.md` | TC-001..TC-008 | Current |

### 2.2 New Requirements (v9.0 series, FR-12 through FR-21)

| Req ID | Requirement | Design Element | Implementation File(s) | Test Case(s) | Sprint |
|--------|-------------|---------------|----------------------|-------------|--------|
| FR-12 | Master Brain Protocol (MBP) — agents ask Nick Fury, not human | Nick Fury proxy, guard-ask-user hook | `.claude/agents/nick-fury.md`, `.claude/hooks/guard-ask-user.sh`, `tools/aegis-apply-mbp-guard.sh` | `tools/aegis-nick-fury-loop-harness.sh` (20 assertions) | v9-01 |
| FR-13 | BLOCK 0 pre-work documentation gate | Gate 0: 5-check pipeline (0A-0E) | `.claude/agents/nick-fury.md` (BLOCK 0 section), `tools/aegis-block0-mode.sh` | `tests/aegis-block0-gate-test.sh`, `tests/aegis-block0-mode-test.sh` | v9-01 |
| FR-14 | Enforcement hooks (guard-bash, guard-write, guard-ui-edit) | Hook layer | `.claude/hooks/guard-bash.sh`, `.claude/hooks/guard-write.sh`, `.claude/hooks/guard-ui-edit.sh` | `tests/aegis-guard-write-test.sh`, `tests/aegis-guard-ui-edit-test.sh` | v9-01 |
| FR-15 | Decision audit logging | Decision audit protocol | `tools/aegis-log-decision.sh`, `.claude/references/decision-audit-protocol.md` | `tests/aegis-distill-counter-test.sh` | v9-02 |
| FR-16 | Captain America fallback (judgment threshold) | Tier-2 brain escalation | `.claude/references/captain-america-fallback.md`, `.claude/agents/captain-america.md` | `tests/aegis-distill-counter-test.sh` (threshold check) | v9-02 |
| FR-17 | Visual design layer (DESIGN.md, BLOCK 0F) | Wasp design system | `.claude/agents/wasp.md`, `tools/aegis-design-init.sh`, `tools/aegis-design-lint.sh`, `tools/aegis-design-fetch.sh` | `tests/aegis-block0-f-gate-test.sh`, `tests/aegis-design-lint-test.sh`, `tests/aegis-design-fetch-test.sh` | v9-03 |
| FR-18 | Sprint lifecycle (/aegis-sprint plan/close/status) | Sprint management | `.claude/commands/aegis-sprint.md`, `.aegis/brain/sprints/` | Manual (sprint artifact verification) | v9-01 |
| FR-19 | Policy-without-test audit | Enforcement verification | `tools/aegis-policy-audit.sh` | Manual audit + CI lint workflow (sprint-v13-01-D) | v9-06 |
| FR-20 | Hook governance (ADR-005) | Architectural decision record | `.aegis/brain/resonance/architecture-decisions.md` (ADR-005) | `tools/aegis-policy-audit.sh` (covers hook completeness) | v9-06 |
| FR-21 | Application playbook (framework adoption guide) | Layer 7: Documentation | `docs/AEGIS_APPLICATION_PLAYBOOK.md` | Manual (walkthrough verification) | v9-06 |

### 2.3 Non-Functional Requirements (unchanged + additions)

| Req ID | Requirement | Design Element | Implementation File(s) | Test Case(s) | Status |
|--------|-------------|---------------|----------------------|-------------|--------|
| NFR-01 | Zero external runtime dependencies | All layers (no imports) | All `CLAUDE*.md`, `.aegis/brain/` | TC-11 | Current |
| NFR-02 | Token efficiency (model routing) | Layer 1: Model tier assignment | `.claude/agents/*.md` (per-agent effort levels) | TC-12 | Current |
| NFR-03 | Portability | Layer 0: plain file approach | All `*.md`, `*.json` | TC-13 | Current |
| NFR-04 | Graceful degradation | Skill error handling, hook fallbacks | `.claude/commands/*.md`, `.claude/hooks/*.sh` | TC-14 | Current |
| NFR-05 | Audit trail | Layer 4 + Layer 5 + decision log | `.aegis/brain/`, `_aegis-output/`, `tools/aegis-log-decision.sh` | TC-15 | Current |
| NFR-06 | Bilingual operator interface | Songbird (consolidated into Vision), language rules | CLAUDE.md (language rules) | TC-16 | Current (Songbird persona retired v9-03) |
| NFR-07 | Version compatibility | CLAUDE.md version header | CLAUDE.md | TC-17 | Current |
| NFR-08 | Test harness self-validation | Template-based testing | `tests/run-all.sh` (sprint-v13-01-D), `.github/workflows/test.yml` | `tests/aegis-doc-canon-lint-test.sh` (template demonstration) | v9-06 (refreshed v13-01-D) |

## 3. Design Element --> Requirements Coverage

| Design Element | Satisfies Requirements |
|----------------|----------------------|
| Layer 0: Framework Core (CLAUDE.md, CLAUDE_safety.md, CLAUDE_lessons.md) | FR-03, FR-08, FR-10, NFR-07 |
| Layer 1: Agent Personas (`.claude/agents/*.md`, 11 agents) | FR-01, FR-12, NFR-02 |
| Layer 2: Commands (`.claude/commands/*.md`, 30 commands) | FR-02, FR-03, FR-06, FR-18 |
| Layer 3: Quality Gates (5-gate pipeline) | FR-05, FR-13 |
| Layer 4: Agent Memory (`.aegis/brain/`) | FR-04, FR-06, FR-15, NFR-05 |
| Layer 5: Output Artifacts (`_aegis-output/`) | NFR-05 |
| Layer 6: ISO Compliance (`_aegis-output/iso-docs/`, 12 docs) | FR-07 |
| Layer 7: Documentation (`docs/`) | FR-21 |
| Hook Layer (`.claude/hooks/*.sh`, 11 hooks) | FR-14, FR-12 |
| Tool Layer (`tools/*.sh`, 61 tools) | FR-15, FR-17, FR-19 |
| Reference Layer (`.claude/references/*.md`, 28 refs) | FR-16, FR-20 |
| PM State Machine | FR-06, FR-03 |
| Decision Matrix | FR-09 |
| Visual Design System | FR-17 |
| Sprint Management | FR-18 |

## 4. Implementation File --> Requirements Coverage

| File / Directory | Requirements Satisfied |
|------------------|----------------------|
| CLAUDE.md | FR-03, FR-08, FR-09, FR-10, NFR-07 |
| CLAUDE_safety.md | NFR-05, NFR-04 |
| CLAUDE_lessons.md | NFR-05 |
| `.claude/agents/nick-fury.md` | FR-09, FR-12, FR-13, FR-16 |
| `.claude/agents/black-panther.md` | FR-05 |
| `.claude/agents/war-machine.md` | FR-05 |
| `.claude/agents/loki.md` | FR-05 |
| `.claude/agents/thor.md` | FR-05 |
| `.claude/agents/wasp.md` | FR-17 |
| `.claude/agents/spider-man.md` | FR-02 |
| `.claude/agents/iron-man.md` | FR-01 |
| `.claude/agents/captain-america.md` | FR-16 |
| `.claude/agents/coulson.md` | FR-07 |
| `.claude/agents/beast.md` | NFR-02 |
| `.claude/hooks/guard-bash.sh` | FR-14 |
| `.claude/hooks/guard-write.sh` | FR-14 |
| `.claude/hooks/guard-ui-edit.sh` | FR-14 |
| `.claude/hooks/guard-ask-user.sh` | FR-12 |
| `.claude/hooks/on-stop.sh` | FR-12 |
| `tools/aegis-log-decision.sh` | FR-15, NFR-05 |
| `tools/aegis-block0-mode.sh` | FR-13 |
| `tools/aegis-policy-audit.sh` | FR-19 |
| `tools/aegis-design-init.sh` | FR-17 |
| `tools/aegis-design-lint.sh` | FR-17 |
| `.aegis/brain/` | FR-04, FR-06, NFR-05 |
| `_aegis-output/iso-docs/` | FR-07 |
| `docs/AEGIS_APPLICATION_PLAYBOOK.md` | FR-21 |

## 5. Module --> Requirements Crosstab

See SI.03 S2.8 "Module Catalog (MOD-XX)" for module definitions.

| Module | Requirements Satisfied |
|--------|----------------------|
| MOD-CORE | FR-03, FR-08, FR-10, NFR-04, NFR-07 |
| MOD-AGENTS | FR-01, FR-05, FR-09, FR-12, FR-16, FR-17, NFR-02 |
| MOD-COMMANDS | FR-02, FR-03, FR-06, FR-11, FR-18 |
| MOD-HOOKS | FR-12, FR-13, FR-14 |
| MOD-BRAIN | FR-04, FR-06, FR-15, NFR-05 |
| MOD-TOOLS | FR-13, FR-15, FR-17, FR-19, NFR-08 |
| MOD-ISO | FR-07 |
| MOD-REFS | FR-16, FR-20 |
| MOD-SPRINTS | FR-18 |
| MOD-SPECS | FR-05, FR-09 |
| MOD-PLAYBOOK | FR-21 |

## 6. Coverage Summary

| Category | Total | Covered | Gap |
|----------|-------|---------|-----|
| Functional Requirements (FR-01..FR-21) | 21 | 21 | 0 |
| Non-Functional Requirements (NFR-01..NFR-08) | 8 | 8 | 0 |
| Design Elements | 15 | 15 | 0 |
| Implementation Paths | 28 | 28 | 0 |
| Modules (MOD-XX) | 11 | 11 | 0 |

**Coverage: 100% -- No untraced requirements.**

## 7. Open Traceability Issues

| ID | Issue | Status |
|----|-------|--------|
| TI-01 | Automated traceability checking | CLOSED -- delivered as `tools/aegis-trace-audit.sh` (sprint-v10-01-E) |
| TI-02 | NFR-02 (token efficiency) -- no automated cost measurement | Open -- deferred (requires API billing integration) |

## Changelog (v2)

- 2026-04-24: Major refresh (sprint-v10-01-A)
  - Updated agent count: 12 -> 11 (Songbird+Vision consolidated in v9-03)
  - Updated command count: 27 skills -> 30 canonical commands (v9-06 consolidation)
  - Updated ISO doc count: "SI.01-SI.07" -> "PM.01-PM.06 + SI.01-SI.06" (SI.07 removed)
  - Updated brain path: `_aegis-brain/` -> `.aegis/brain/` (v9-01 migration)
  - Updated gate system: 3-gate -> 5-gate (Gate 0 Pre-Work, Gate 4 Deploy, Gate 5 Monitor)
  - Added FR-12 through FR-21 (v9.0 series requirements)
  - Added NFR-08 (test harness self-validation)
  - Added Module -> Requirements crosstab (S5)
  - Closed TI-01 (automated traceability checking shipped)
  - Fixed header: was "SI.03 Traceability Matrix", corrected to "SI.02 Traceability Matrix"
