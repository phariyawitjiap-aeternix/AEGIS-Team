# Sprint v12-01 Plan: Doc Canon (DoD + ARCHITECTURE + version headers + lint)

**Points**: 8pt · **Branch**: `sprint-v12-01`
**v12 Phase A gate**: pilot-week gate explicitly overridden by user "approve" (2026-05-06) — kicks off Phase A immediately. Decision D-086.

## Goal

Author the two missing top-level governance docs (`DoD.md`, `ARCHITECTURE.md`), retro-add `<!-- version: X.Y.Z -->` + Changelog tables to every `CLAUDE_*.md`, and build a lint that fails CI when any governance doc lacks the header pattern.

Closes Knowledge-Layer Mega Plan v1.1 §6 (sprint v12-01).

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | Author top-level `DoD.md` with 9 sub-bars adapted to AEGIS (Brain integrity, Hook fail-OPEN, MBP rule compliance, Sprint close.md present, Test ≥1 assertion-per-AC, Roadmap update, Version-headers present, Activity-log captured, Reversibility) | 3 |
| B | Author top-level `ARCHITECTURE.md` with: repository layout, concern→file map, PreToolUse / PostToolUse / Stop / SessionStart hook DAG, brain ingestion DAG (FTS5 v10-06 + future graph v12-04) | 3 |
| C | Add `<!-- version: 1.0.0 -->` header + Changelog table to CLAUDE.md / CLAUDE_safety.md / CLAUDE_agents.md / CLAUDE_skills.md / CLAUDE_lessons.md (5 files) | 1 |
| D | Build `tools/aegis-doc-canon/lint.mjs` — asserts header pattern present on every governance doc; CI fails if missing. Tests cover: pass-fixture, fail-fixture (missing header), fail-fixture (missing changelog) | 1 |

## Schema (Story A — DoD sub-bars)

Each sub-bar is a checkbox section with: scope, gate, evidence file path. AEGIS-specific adaptation of GitNexus's 9-bar shape:

1. **Brain integrity** — `.aegis/brain/` writes are atomic (temp + rename via `tools/aegis-brain-write.sh`); index rebuilds idempotently.
2. **Hook fail-OPEN** — every PostToolUse/PreToolUse/Stop/SessionStart hook exits 0 on internal error. No hook ever blocks legitimate work due to its own bug.
3. **MBP compliance** — no agent ends a turn with an option-menu / "what next?" prompt; `AskUserQuestion` only callable from Nick Fury via 4 escalation categories.
4. **Sprint close.md present** — every closed sprint has a `close.md` adjacent to `plan.md`; no silent closures.
5. **Test coverage** — every Acceptance Criterion has ≥1 assertion in a regression test. No AC ships without a test.
6. **Roadmap update** — sprint-close PR touches `.aegis/brain/sprints/roadmap.md`. Grand-total math stays honest.
7. **Version headers (v12+)** — every governance doc carries `<!-- version: X.Y.Z -->` + Changelog table (≥1 row).
8. **Activity captured** — every tool invocation that mutates state appears in `.aegis/brain/activity/<date>.jsonl` (v11-02 logger).
9. **Reversibility** — destructive operations (`rm`, force-push, `reset --hard`) are gated by `aegis-approval-gate` (v11-05); no undocumented bypass paths.

## Schema (Story B — ARCHITECTURE.md sections)

```
1. Repository Layout       — top-level dirs and their roles
2. Concern → File Map      — "if I'm changing X, edit Y"
3. Hook Chain DAG          — Pre/PostToolUse / Stop / SessionStart
4. Brain Ingestion DAG     — FTS5 index (v10-06) + future graph (v12-04)
5. Tool Package Layout     — tools/<pkg>/ convention
6. Skill Resolution        — skills/*.md → SKILL.md frontmatter → trigger phrases
7. Persona Routing         — model tiers, agent allow-lists (v10-09)
```

## Schema (Story C — version-header pattern)

Top-of-file pattern for every governance doc:

```markdown
<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

Last reviewed: 2026-05-06

# <existing title>

> <existing tagline>

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Version header pattern introduced (sprint-v12-01) |

<rest of file unchanged>
```

Decision D1 from the plan: **semver** (matches GitNexus + AEGIS VERSION pin).

## Schema (Story D — lint.mjs)

```
$ node tools/aegis-doc-canon/lint.mjs
✓ CLAUDE.md          — version 1.0.0, changelog 1 row
✓ CLAUDE_safety.md   — version 1.0.0, changelog 1 row
✓ CLAUDE_agents.md   — version 1.0.0, changelog 1 row
✓ CLAUDE_skills.md   — version 1.0.0, changelog 1 row
✓ CLAUDE_lessons.md  — version 1.0.0, changelog 1 row
✓ DoD.md             — version 1.0.0, changelog 1 row
✓ ARCHITECTURE.md    — version 1.0.0, changelog 1 row
all 7 governance docs pass.
exit 0
```

Failure mode (missing header on a file):

```
✗ DoD.md             — missing <!-- version: --> header
1 governance doc failed lint.
exit 1
```

## Acceptance criteria (Mega Plan v12-01)

- [ ] `DoD.md` exists at repo root with 9 checkbox sub-bars
- [ ] `ARCHITECTURE.md` exists at repo root with both required tables (layout + concern→path) + at least one DAG
- [ ] Every `CLAUDE_*.md` has `<!-- version: -->` header + Changelog table with ≥1 row
- [ ] `tools/aegis-doc-canon/lint.mjs` exists, exits 0 on the live tree
- [ ] Lint test: fixture missing header → exit 1
- [ ] Lint test: fixture missing changelog → exit 1
- [ ] Lint test: passing fixture → exit 0
- [ ] Hook integration deferred to v12-04 (PostToolUse Edit/Write debounce); v12-01 ships as standalone tool
- [ ] All assertions ≥ 6 (3 lint scenarios × 2 doc types)

## Out of scope (this sprint)

- GUARDRAILS.md migration → v12-02
- Skill / tool frontmatter convergence → v12-03
- NDJSON graph build → v12-04
- Auto-wiki / staleness → v12-06
- Hook wiring (PostToolUse Edit/Write debounce) → v12-04 (with graph build)

## References

- `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 §6 v12-01
- GitNexus governance pattern (studied 2026-05-06)
- Decision D-086 (judgment fallback — Captain America acted under MBP rule while Nick Fury on STANDBY)
