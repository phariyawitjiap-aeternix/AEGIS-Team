# Sprint v12-02 Close: GUARDRAILS.md (Sign migration)

**Status**: CLOSED · 5/5pt · 100% · stacked on sprint-v12-01
**Date**: 2026-05-06
**Branch**: `sprint-v12-02`

## Stories shipped

| ID | Story | Pt | Status | Evidence |
|----|-------|----|--------|----------|
| A | Author `GUARDRAILS.md` skeleton (Scope · Non-negotiables · Signs) with v1.0.0 header | 1 | DONE | [GUARDRAILS.md](../../../GUARDRAILS.md) — 12 Signs in canonical Trigger/Do/Why shape |
| B | Migrate ≥ 10 Signs (target met +20%) | 2 | DONE | 12 Signs covering: wired-not-shipped · set-e-empty-array · grep-c-double-print · fifo-EOF-loop · doc/reality-skew · git-amend-multi-agent · AskUserQuestion-menu · hook-fail-closed · policy-without-test · doc-version-conflation · lint-empty-table · ask-after-explicit-go |
| C | `tools/aegis-doc-canon/add-sign.mjs` w/ interactive + non-interactive modes | 1 | DONE | [add-sign.mjs](../../../tools/aegis-doc-canon/add-sign.mjs) — atomic write, version bump, changelog row, validates 4 fields |
| D | Extend lint.mjs to cover GUARDRAILS.md + tests | 1 | DONE | [lint.mjs:9](../../../tools/aegis-doc-canon/lint.mjs:9) DEFAULT_DOCS expanded; [add-sign-test.sh](../../../tests/aegis-doc-canon-add-sign-test.sh) 13 cases / 20 assertions |

## Acceptance evidence

- [x] `GUARDRAILS.md` exists at repo root with version header + Changelog row + Scope + Non-negotiables + Signs sections
- [x] ≥ 10 Signs captured in canonical Trigger/Do/Why shape (actual: 12)
- [x] `add-sign.mjs` supports interactive AND `--non-interactive --title --trigger --do --why` flags
- [x] add-sign.mjs validates all 4 fields are present and non-empty (also rejects whitespace-only)
- [x] add-sign.mjs writes to the correct section without disturbing earlier content (existing sign preserved test)
- [x] lint.mjs includes GUARDRAILS.md in DEFAULT_DOCS (8 docs total) and passes on the live tree
- [x] CLAUDE_lessons.md gets a "see also: GUARDRAILS.md" pointer (light cross-ref) + version bumped to 1.0.1
- [x] Tests: ≥ 8 assertions (actual: 20 — 2.5× the bar)
- [x] Sprint roadmap row flips to CLOSED 5/5

## Lint output

```
$ node tools/aegis-doc-canon/lint.mjs
✓ CLAUDE.md            — version 1.0.0, changelog 1 row
✓ CLAUDE_safety.md     — version 1.0.0, changelog 1 row
✓ CLAUDE_agents.md     — version 1.0.0, changelog 1 row
✓ CLAUDE_skills.md     — version 1.0.0, changelog 1 row
✓ CLAUDE_lessons.md    — version 1.0.1, changelog 2 rows
✓ DoD.md               — version 1.0.0, changelog 1 row
✓ ARCHITECTURE.md      — version 1.0.0, changelog 1 row
✓ GUARDRAILS.md        — version 1.0.0, changelog 1 row
all 8 governance docs pass.
```

## add-sign tests output

```
T1: live-tree lint includes GUARDRAILS.md (8 docs)         [PASS x3]
T2: happy path — non-interactive append succeeds            [PASS x5]
T3: existing sign preserved                                 [PASS x1]
T4: fixture passes lint after append                        [PASS x1]
T5: missing title rejected                                  [PASS x2]
T6: missing trigger rejected                                [PASS x1]
T7: missing do rejected                                     [PASS x1]
T8: missing why rejected                                    [PASS x1]
T9: whitespace-only title rejected                          [PASS x1]
T10: missing target file exits 2                            [PASS x1]
T11: target lacking version header exits 2                  [PASS x1]
T12: unknown arg rejected                                   [PASS x1]
T13: live GUARDRAILS.md has ≥ 10 Signs (actual: 12)         [PASS x1]
Total: 20 pass / 0 fail
```

## v12 grand-total after this sprint

```
v12: 13 / 39 pt = 33%
  ├── Phase A (doc canon):     13 / 18 pt
  │     v12-01 doc canon       ✅ 8 / 8
  │     v12-02 GUARDRAILS      ✅ 5 / 5
  │     v12-03 frontmatter     ⏳ 0 / 5
  └── Phase B (graph):           0 / 21 pt
        v12-04 NDJSON build    ⏳ 0 / 8
        v12-05 graph queries   ⏳ 0 / 8
        v12-06 wiki + stale    ⏳ 0 / 5
```

## Next sprint

**sprint-v12-03** (skill / tool / sprint frontmatter convergence · 5pt) — define minimal frontmatter schema (`reads`, `writes`, `wires`, `tests`, `supersedes`); audit + backfill across 30+ skills + 12 tool packages; lint asserts schema. Needed before v12-04 graph build can parse uniformly.

## References

- Plan: [.aegis/brain/sprints/sprint-v12-02/plan.md](plan.md)
- Source: `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 §6 v12-02
- Predecessor: sprint-v12-01 (PR #117)
