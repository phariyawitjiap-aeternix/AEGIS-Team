---
name: aegis-reengineer
trigger: /aegis-reengineer
description: >
  Re-engineer an existing project — upgrade tech stack, add features, improve performance.
  Beast scans current state → Iron Man drafts target architecture → Loki critiques →
  ultraplan generates full re-engineering spec → AEGIS pipeline executes.
agents: [nick-fury, beast, iron-man, loki]
---

# /aegis-reengineer

## Purpose
Systematically upgrade an existing project by:
1. Scanning current state comprehensively (Beast)
2. Drafting target architecture (Iron Man)
3. Adversarial stress-test of the plan (Loki)
4. Generating full re-engineering spec via ultraplan (cloud, multi-agent critique)
5. Executing via AEGIS pipeline

---

## Phase 1 — Beast: Current State Scan

Nick Fury dispatches Beast with:

```
Task for Beast:
Scan this entire codebase and generate a comprehensive re-engineering report.
Save to: _aegis-output/research/reengineer-current-state.md

Report must include ALL of these sections:

### 1. Tech Stack Inventory
- Language + version
- Framework + version
- All dependencies (package.json / requirements.txt / go.mod / etc.)
- Database + ORM
- Infrastructure (Docker, CI/CD, cloud)
- Dev tools (linter, formatter, test runner)

### 2. Features & Functions Map
For each module/file: list every public function, API endpoint, component.
Format:
  module: src/auth/
    - POST /auth/login — validates credentials, returns JWT
    - POST /auth/refresh — rotates refresh token
    - middleware/auth.js — verifies Bearer token on protected routes

### 3. Performance Profile
- Identify N+1 queries (scan ORM calls in loops)
- Large dependencies (bundle size issues)
- Missing indexes (scan raw SQL / migration files)
- Synchronous blocking operations
- Missing caching (repeated expensive queries)

### 4. Tech Debt
- TODO/FIXME count and locations
- Outdated dependencies (flag anything >1 major version behind)
- Duplicate code patterns
- Untested modules (no test files)

### 5. Architecture Weaknesses
- Tight coupling between modules
- Missing error boundaries
- No rate limiting / auth on public endpoints
- Hardcoded config (env vars not used)

Save the report. Signal Nick Fury when done: "PHASE 1 COMPLETE — report at _aegis-output/research/reengineer-current-state.md"
```

---

## Phase 2 — Iron Man: Target Architecture Draft

After Beast signals PHASE 1 COMPLETE, Nick Fury dispatches Iron Man:

```
Task for Iron Man (ultrathink):
Read: _aegis-output/research/reengineer-current-state.md

Based on the current state analysis, draft a target architecture for re-engineering.
Save to: _aegis-output/architecture/reengineer-target-state.md

Draft must cover:

### 1. Proposed Tech Stack
- What to keep (and why)
- What to upgrade (old → new, with rationale)
- What to replace entirely (with migration path)

### 2. New Features to Add
- List each feature
- Why it's needed (gap in current system)
- Estimated complexity (S/M/L)

### 3. Performance Targets
- Current baseline (from Beast report)
- Target metric (e.g., "API p95 < 200ms", "bundle < 200KB")
- How to achieve (specific techniques)

### 4. Re-Engineering Strategy
- Big bang rewrite vs incremental migration
- Module execution order (what to tackle first)
- Backwards compatibility requirements
- Data migration plan (if schema changes)

### 5. Risk Assessment
- What could break during migration
- Rollback strategy per phase
- Estimated total story points

Use ultrathink for this task.
Signal Nick Fury when done: "PHASE 2 COMPLETE — draft at _aegis-output/architecture/reengineer-target-state.md"
```

---

## Phase 3 — Loki: Adversarial Review

After Iron Man signals PHASE 2 COMPLETE, Nick Fury dispatches Loki:

```
Task for Loki (ultrathink):
Read both files:
  - _aegis-output/research/reengineer-current-state.md
  - _aegis-output/architecture/reengineer-target-state.md

Stress-test the re-engineering plan. Find everything that could go wrong.
Save findings to: _aegis-output/adversarial/reengineer-loki-review.md

Challenge:
- Is the migration strategy realistic for this codebase size?
- Will the new tech stack introduce new problems?
- Are the performance targets achievable with the proposed changes?
- What's the worst-case data migration failure scenario?
- What features might regress during re-engineering?
- Is the execution order correct? (dependencies between modules)

Respond with PLAN_APPROVAL_RESPONSE:
  Verdict: APPROVE | CONDITIONAL | REJECT
  Conditions: [if CONDITIONAL]
  Blockers: [if REJECT]

Signal Nick Fury when done.
```

---

## Phase 4 — ultraplan: Full Re-Engineering Spec

After Loki gives APPROVE or CONDITIONAL, Nick Fury triggers ultraplan.

**How Nick Fury builds the ultraplan prompt:**

```bash
# Nick Fury reads the two files and builds a rich seed prompt:
CURRENT=$(cat _aegis-output/research/reengineer-current-state.md)
TARGET=$(cat _aegis-output/architecture/reengineer-target-state.md)
LOKI=$(cat _aegis-output/adversarial/reengineer-loki-review.md)
```

Then invokes:
```
ultraplan — Re-engineer this project based on the analysis below.

=== CURRENT STATE (from Beast scan) ===
[CURRENT content]

=== TARGET ARCHITECTURE (from Iron Man) ===
[TARGET content]

=== ADVERSARIAL REVIEW (from Loki — addressed concerns) ===
[LOKI content]

=== INSTRUCTIONS FOR ULTRAPLAN ===
Strategy: three_subagents_with_critique
Goal: Generate a complete, executable re-engineering plan covering:
1. Exact files to create / modify / delete
2. Migration steps in order
3. Test strategy for each phase
4. Rollback checkpoints
5. Definition of Done per phase
```

**What ultraplan does with this:**
- Sub-agent 1 (Architecture): validates tech stack choices against codebase
- Sub-agent 2 (Files): maps every file change needed (create/modify/delete)
- Sub-agent 3 (Risks): cross-checks against Loki's concerns
- Critique agent: synthesizes into executable plan

Human reviews plan → Approve → teleport to terminal

---

## Phase 5 — AEGIS Pipeline: Execute

After ultraplan approved, Nick Fury:

```
1. Coulson: Convert ultraplan output → PM.01 + SI.01 + SI.02
2. /aegis-breakdown: Break plan into Epics → Tasks → Sub-tasks
3. /aegis-sprint plan: Prioritize by dependency order
4. Execute sprint by sprint:
   - Iron Man validates each task spec
   - Loki gates each spec (Plan-Approval Gate)
   - Spider-Man implements
   - Black Panther reviews (Gate 1)
   - War Machine + Vision QA (Gate 2)
   - Coulson updates ISO docs (Gate 3)
5. After each sprint: Thor deploys to staging, validates health
6. Only after staging stable: promote to production
```

---

## Quick Start Command

To trigger this workflow, just tell Nick Fury:

```
/aegis-reengineer — upgrade this project: modernize to [tech stack], add [features], target [performance goal]
```

Nick Fury will automatically run Phase 1–5 in order.

---

## When NOT to Use ultraplan Here

Skip ultraplan (use Iron Man directly) if:
- Project is small (< 20 files) → Iron Man alone is faster
- Re-engineering scope is narrow (1 module only) → `/aegis-breakdown` is sufficient
- No GitHub app installed → ultraplan won't work, fall back to Iron Man + Loki

In those cases: skip Phase 4, use Iron Man's Phase 2 output directly as the spec.

---

## Output Files

| Phase | Agent | Output |
|-------|-------|--------|
| 1 | Beast | `_aegis-output/research/reengineer-current-state.md` |
| 2 | Iron Man | `_aegis-output/architecture/reengineer-target-state.md` |
| 3 | Loki | `_aegis-output/adversarial/reengineer-loki-review.md` |
| 4 | ultraplan | `_aegis-output/specs/reengineer-ultraplan-spec.md` (teleported) |
| 5 | Coulson | `_aegis-output/iso-docs/PM-01.../SI-01.../SI-02...` |
