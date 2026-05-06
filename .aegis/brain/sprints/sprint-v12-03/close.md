# Sprint v12-03 Close: Skill / tool / sprint frontmatter convergence

**Status**: CLOSED · 5/5pt · 100% · stacked on sprint-v12-02
**Date**: 2026-05-06
**Branch**: `sprint-v12-03`
**Phase A milestone**: COMPLETE 18/18pt (all 3 doc-canon sprints shipped)

## Stories shipped

| ID | Story | Pt | Status | Evidence |
|----|-------|----|--------|----------|
| A | Document schema in ARCHITECTURE.md + standalone skill-schema.md | 1 | DONE | [skill-schema.md](../../../tools/aegis-doc-canon/skill-schema.md) (175 lines), [ARCHITECTURE.md §6.1](../../../ARCHITECTURE.md) extended |
| B | Build skill-frontmatter.mjs (--lint / --backfill / --apply-manifest) | 2 | DONE | [skill-frontmatter.mjs](../../../tools/aegis-doc-canon/skill-frontmatter.mjs) — 240 LoC, zero deps |
| C | Backfill 39 skills + manifest covers 12 tool-backed | 1 | DONE | All 39 skills lint clean; [skill-graph-manifest.json](../../../tools/aegis-doc-canon/skill-graph-manifest.json) covers 12 entries |
| D | Tests + lint enforcement | 1 | DONE | [aegis-skill-frontmatter-test.sh](../../../tests/aegis-skill-frontmatter-test.sh) — 13 cases, 22 assertions |

## Acceptance evidence

- [x] Schema documented in ARCHITECTURE.md §6.1 + `tools/aegis-doc-canon/skill-schema.md` (v1.0.0)
- [x] `skill-frontmatter.mjs` exists with `--lint`, `--backfill`, `--apply-manifest`, `--dry-run`, `--json`
- [x] All 39 skills have the 5 graph keys present (post-backfill)
- [x] Manifest covers 12 tool-backed skills with non-empty values
- [x] Lint exits 0 on the live tree post-backfill
- [x] Lint exits 1 on a fixture with a missing key
- [x] Backfill is idempotent: second `--backfill` leaves files byte-identical
- [x] Tests: 22 assertions (target was ≥ 8 — 2.75× the bar)
- [x] Sprint roadmap row flips to CLOSED 5/5

## Pre-existing skill fixes (incidental)

Two skills had non-conforming base frontmatter discovered during backfill:

| Skill | Issue | Fix |
|-------|-------|-----|
| `iso-29110-docs.md` | No YAML frontmatter at all (only prose `> Profile:` header) | Added complete frontmatter block with `name`/`description`/`profile`/`triggers` |
| `design-system-md.md` | Missing `profile` and `triggers` (had `name`/`description`/`agents`/`owner`) | Added missing keys; preserved `agents` + `owner` for backward compat |
| `aegis-doctor.md` | Missing `profile`; `triggers` was a flat array instead of `{en, th}` | Restructured triggers to `{en, th}` shape; added `profile: full` |
| `aegis-reengineer.md` | Missing `profile` and `triggers` | Added; preserved `agents` for backward compat |

These were pre-existing schema drift, not new issues introduced by v12-03.

## Live tree lint output

```
$ node tools/aegis-doc-canon/skill-frontmatter.mjs --lint
all 39 skills satisfy schema.

$ node tools/aegis-doc-canon/skill-frontmatter.mjs --backfill
0 skills backfilled, 39 already complete.

$ node tools/aegis-doc-canon/lint.mjs
✓ CLAUDE.md / safety / agents / skills / lessons / DoD / ARCHITECTURE / GUARDRAILS
all 8 governance docs pass.
```

## Manifest coverage

12 tool-backed skills with non-empty graph values:

| Skill | reads | writes | wires | tests |
|-------|:-----:|:------:|:-----:|:-----:|
| aegis-activity-logger | ✓ | ✓ | ✓ | ✓ |
| aegis-approval-gate   | ✓ | ✓ | ✓ | ✓ |
| aegis-issue-thread    | ✓ | ✓ |   | ✓ |
| aegis-live-tail       | ✓ | ✓ | ✓ | ✓ |
| aegis-multi-tenant    |   |   |   | ✓ |
| aegis-parallel-dispatch |  |   |   | ✓ |
| aegis-plus-pilot      |   |   |   | ✓ |
| aegis-resume          | ✓ | ✓ | ✓ | ✓ |
| aegis-router          | ✓ |   |   | ✓ |
| aegis-run-logger      | ✓ | ✓ | ✓ | ✓ |
| aegis-trace-export    | ✓ | ✓ |   | ✓ |
| aegis-distill         | ✓ | ✓ |   | ✓ |

Remaining 27 skills have all 5 graph keys present with empty arrays (correct: they're command/workflow-style skills that don't tie to brain paths or hooks).

## v12 grand-total after this sprint

```
v12: 18 / 39 pt = 46%   ★ Phase A complete
  ├── Phase A (doc canon):     18 / 18 pt   ✅ COMPLETE
  │     v12-01 doc canon       ✅ 8 / 8
  │     v12-02 GUARDRAILS      ✅ 5 / 5
  │     v12-03 frontmatter     ✅ 5 / 5
  └── Phase B (graph):           0 / 21 pt
        v12-04 NDJSON build    ⏳ 0 / 8   ← next
        v12-05 graph queries   ⏳ 0 / 8
        v12-06 wiki + stale    ⏳ 0 / 5
```

## Next sprint

**sprint-v12-04** — `aegis-brain-graph build` → NDJSON (8pt). Walk skills/ + tools/ + .claude/settings.json + sprints/ + brain content, emit `.aegis/brain/graph/{nodes,edges}.ndjson` + `meta.json`. Atomic via temp-rename, idempotent (byte-equal output across rebuilds), supports `--full` and `--incremental`. Wire as PostToolUse Edit/Write debounced 3s.

## References

- Plan: [.aegis/brain/sprints/sprint-v12-03/plan.md](plan.md)
- Source: `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 §6 v12-03
- Predecessor: sprint-v12-02 (PR #119)
- Schema doc: [tools/aegis-doc-canon/skill-schema.md](../../../tools/aegis-doc-canon/skill-schema.md)
