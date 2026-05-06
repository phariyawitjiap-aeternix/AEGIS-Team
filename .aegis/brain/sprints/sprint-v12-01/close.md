# Sprint v12-01 Close: Doc Canon

**Status**: CLOSED · 8/8pt · 100% · 1 session
**Date**: 2026-05-06
**Branch**: `sprint-v12-01`
**Decision**: D-086 (judgment fallback — Captain America acted while Nick Fury on STANDBY)

## Stories shipped

| ID | Story | Pt | Status | Evidence |
|----|-------|----|--------|----------|
| A | Author top-level `DoD.md` (9 sub-bars adapted to AEGIS) | 3 | DONE | [DoD.md](../../../DoD.md) — 220 lines, 9 checkbox sections (Brain integrity / Hook fail-OPEN / MBP / Sprint close.md / Test coverage / Roadmap update / Version headers / Activity captured / Reversibility) |
| B | Author top-level `ARCHITECTURE.md` (layout + concern→path + hook DAG + brain ingestion DAG) | 3 | DONE | [ARCHITECTURE.md](../../../ARCHITECTURE.md) — 8 sections, 60+ row Repository Layout table, 22-row Concern→File map, hook DAG with current + planned v12 additions, brain ingestion DAG showing FTS5 + future NDJSON-graph branch |
| C | Add `<!-- version: -->` + Changelog to 5 CLAUDE_*.md files | 1 | DONE | [CLAUDE.md](../../../CLAUDE.md), [CLAUDE_safety.md](../../../CLAUDE_safety.md), [CLAUDE_agents.md](../../../CLAUDE_agents.md), [CLAUDE_skills.md](../../../CLAUDE_skills.md), [CLAUDE_lessons.md](../../../CLAUDE_lessons.md) — all at version 1.0.0 |
| D | Build `tools/aegis-doc-canon/lint.mjs` + 18-assertion test | 1 | DONE | [tools/aegis-doc-canon/lint.mjs](../../../tools/aegis-doc-canon/lint.mjs) (228 LoC, zero deps) + [tests/aegis-doc-canon-lint-test.sh](../../../tests/aegis-doc-canon-lint-test.sh) (10 test cases / 18 assertions) |

## Acceptance evidence (Mega Plan v12-01)

- [x] `DoD.md` exists at repo root with 9 checkbox sub-bars
- [x] `ARCHITECTURE.md` exists at repo root with both required tables (layout + concern→path) + at least one DAG
- [x] Every `CLAUDE_*.md` has `<!-- version: -->` header + Changelog table with ≥ 1 row
- [x] `tools/aegis-doc-canon/lint.mjs` exists, exits 0 on the live tree
- [x] Lint test: fixture missing version header → exit 1
- [x] Lint test: fixture missing Last-updated → exit 1 (additional, beyond plan)
- [x] Lint test: fixture missing Changelog section → exit 1
- [x] Lint test: fixture with empty Changelog table → exit 1 (additional, beyond plan)
- [x] Lint test: missing file → exit 1 (additional, beyond plan)
- [x] Lint test: passing fixture → exit 0
- [x] Lint test: `--json` output parses as JSON with expected shape (additional)
- [x] Lint test: `--quiet` suppresses pass lines (additional)
- [x] Lint test: mixed batch (pass + fail) exits 1 (additional)
- [x] Plan said "≥ 6 assertions"; actual count is **18** (3× the bar)

## Live-tree lint output

```
$ node tools/aegis-doc-canon/lint.mjs
✓ CLAUDE.md            — version 1.0.0, changelog 1 row
✓ CLAUDE_safety.md     — version 1.0.0, changelog 1 row
✓ CLAUDE_agents.md     — version 1.0.0, changelog 1 row
✓ CLAUDE_skills.md     — version 1.0.0, changelog 1 row
✓ CLAUDE_lessons.md    — version 1.0.0, changelog 1 row
✓ DoD.md               — version 1.0.0, changelog 1 row
✓ ARCHITECTURE.md      — version 1.0.0, changelog 1 row
all 7 governance docs pass.
exit 0
```

## Test suite output

```
=================================================
AEGIS doc-canon lint — sprint v12-01 acceptance
=================================================
T1: live tree lint (all 7 governance docs)              [PASS x2]
T2: passing fixture exits 0                             [PASS x1]
T3: missing version header exits 1                      [PASS x2]
T4: missing Last-updated exits 1                        [PASS x2]
T5: missing Changelog section exits 1                   [PASS x2]
T6: empty Changelog table (0 data rows) exits 1         [PASS x2]
T7: missing file exits 1                                [PASS x2]
T8: --json output is valid JSON                         [PASS x2]
T9: --quiet suppresses pass lines                       [PASS x1]
T10: mixed batch — one pass + one fail exits 1          [PASS x2]

Total: 18 pass / 0 fail
```

## Lessons / Signs to migrate to GUARDRAILS.md (v12-02)

Two new candidates surfaced during this sprint that should land in v12-02:

1. **"Doc-version vs framework-version conflation"** — Trigger: A doc has `# AEGIS v11.0` in the title. Do: Treat the title-version as the *framework* version, and add an independent doc-level `<!-- version: 1.0.0 -->`. Why: They evolve at different cadences; conflating them means a doc edit forces a framework version bump, or a framework bump silently hides doc drift.
2. **"Lint must check for malformed-table, not just missing-table"** — Trigger: Adding a new structural lint rule. Do: Cover the empty-table case explicitly (header rows present, data rows absent). Why: A markdown table with `| Date | Version | Change |` and no data row passes a simple `grep "## Changelog"` check but is functionally empty.

## v12 grand-total after this sprint

```
v12: 8 / 39 pt = 21%
  ├── Phase A (doc canon):      8 / 18 pt
  │     v12-01 doc canon       ✅ 8 / 8
  │     v12-02 GUARDRAILS      ⏳ 0 / 5
  │     v12-03 frontmatter     ⏳ 0 / 5
  └── Phase B (graph):           0 / 21 pt
        v12-04 NDJSON build    ⏳ 0 / 8
        v12-05 graph queries   ⏳ 0 / 8
        v12-06 wiki + stale    ⏳ 0 / 5
```

## Next sprint

**sprint-v12-02** (GUARDRAILS.md · 5pt) — migrate ≥ 10 Signs from `CLAUDE_lessons.md` + auto-memory feedback into Trigger/Do/Why form. Add `tools/aegis-doc-canon/add-sign.mjs`. Plan ref: Knowledge-Layer Mega Plan v1.1 §6 v12-02.

## References

- Plan: [.aegis/brain/sprints/sprint-v12-01/plan.md](plan.md)
- Source: `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 §6 v12-01
- Decision log entry: D-086 in `.aegis/brain/logs/decision-audit.log`
- Predecessor: sprint-v11-10 (closes v11 at 100%)
