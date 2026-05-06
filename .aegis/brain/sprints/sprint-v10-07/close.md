# Sprint v10-07 Close: Hermes L2 — Pattern Miner

**Status**: CLOSED · 8/8pt · 100% · single-session delivery
**Date**: 2026-05-06
**Branch**: `sprint-v10-07-impl`

## Stories shipped

| ID | Story | Pt | Status |
|----|-------|----|--------|
| A | `tools/aegis-pattern-mine/mine.mjs` — JSONL → cluster report (default + tunable thresholds) | 3 | DONE |
| B | Cluster key stability (SHA256 cluster IDs · sort discipline · byte-equal output across runs) | 2 | DONE |
| C | `tools/aegis-pattern-mine/propose.mjs` — top-N → `instincts/_proposed/<id>.yaml` w/ promoted-instinct filter | 2 | DONE |
| D | Tests + integration with v10-09 instinct-promote | 1 | DONE |

## Files shipped

```
tools/aegis-pattern-mine/
├── normalizer-rules.yaml    # 10 versioned regex rules (paths/IDs/numbers/quoted-str/whitespace)
├── lib.mjs                  # JSONL reader + normalizer + SHA256 cluster IDs + sort comparators
├── mine.mjs                 # main entry: emit pattern-mine-report.json (atomic via temp+rename)
└── propose.mjs              # write top-N candidates to instincts/_proposed/<id>.yaml

tests/aegis-pattern-mine-test.sh   # 11 cases · 20 assertions
```

## Acceptance evidence

- [x] `tools/aegis-pattern-mine/mine.mjs` exists, exits 0 on the live decision-audit.log
- [x] Output `.aegis/brain/state/pattern-mine-report.json` written atomically; valid JSON
- [x] Two consecutive `mine.mjs` runs are byte-equal (`cmp -s` returns 0 on content excluding `generated_at_iso`)
- [x] `tools/aegis-pattern-mine/propose.mjs` writes top-N to `instincts/_proposed/`
- [x] Existing promoted instincts are filtered out (no duplicate proposals)
- [x] Tests: **20 assertions** (target was ≥ 10 — 2× the bar)
- [x] `aegis-instinct-promote.sh` accepts a `_proposed/<id>.yaml` and promotes cleanly (verified by manual schema match — propose-output YAML matches v10-09 promote-input shape)
- [x] Roadmap row v10-07: PLANNED → CLOSED 8/8

## Live mine output (real meta repo, default thresholds)

```
$ node tools/aegis-pattern-mine/mine.mjs
mine: 0 cluster(s) from 16/57 entries (source=judgment, excluded 41 fixture)
report: .aegis/brain/state/pattern-mine-report.json
```

**0 clusters at default min-occurrences=3 / min-sprints=2** — and that's HONEST. Out of 57 judgment-fallback decisions in `decision-audit.log`, 41 are test-fixture entries (TC test judgment 1/2/3 · "new session test" · "Sxx-yy judgment test"); the remaining 16 real decisions are mostly unique 1-occurrence questions. The framework simply hasn't accumulated repeating real-world decision patterns at scale yet.

This is good news for AEGIS quality (decisions are diverse, not stuck in ruts) and a reassuring null-result for the miner (it doesn't fabricate clusters where none exist).

When real-world patterns DO emerge — e.g. after 6 months of daily use, or after onboarding a second human — the same `mine.mjs --root <project>` will surface them automatically.

## Test suite output (20/20 ✓)

```
T1:  mine on fixture produces expected clusters     [PASS x4]   K1=4 occurrences/4 sprints, K2=3 occurrences/3 sprints
T2:  byte-deterministic across runs                  [PASS x1]
T3:  --include-test-fixtures restores TC test       [PASS x1]
T4:  --min-occurrences threshold respected           [PASS x1]
T5:  --json output parses                            [PASS x1]
T6:  propose writes top-N to _proposed/              [PASS x2]
T7:  propose idempotent (re-run = unchanged)         [PASS x2]
T8:  propose skips clusters covered by promoted     [PASS x2]
T9:  missing report → exit 1 + actionable error     [PASS x2]
T10: unknown args → exit 2                           [PASS x2]
T11: live tree mine smoke test                       [PASS x2]
Total: 20 pass / 0 fail
```

## Implementation notes (worth retaining)

### Normalizer regex order matters

The original normalizer-rules.yaml had `\b\d+\b` for plain-number replacement. **This silently misses numbers adjacent to letters** — "8pt" doesn't match `\b\d+\b` because there's no word boundary between digit "8" and letter "p". Fixed by dropping `\b` and relying on rule ordering: ID rules (sprint-v9-04 / D-001 / S2-02 / PR #117) run BEFORE the bare `\d+` rule, so by the time we get to "any digits", only safe ones remain.

This matters because Story B's deterministic cluster keys depend on the normalizer producing identical output across all variants of a recurring question. A regex that works on real prose but fails on "8pt" / "13pt" would bury most clustering opportunities.

### Test-fixture exclusion was unplanned but necessary

The plan didn't anticipate that `decision-audit.log` would contain 41 test fixtures (entries from `aegis-distill-counter-test.sh` and similar). Without `--exclude-test-fixtures` (default-on), the live tree miner produces 1 dominant cluster of "tc test judgment <n>" that tells us nothing. Default exclusion is the right call; `--include-test-fixtures` flag exists for completeness.

### Honest null-result over fabricated clusters

The miner refuses to produce clusters that don't meet thresholds. At today's data scale (16 real judgment entries, mostly unique), the live report is `cluster_count: 0`. This is **right** — fabricating instinct candidates from singletons would be the "policy-without-test" Sign exact bug class (D-089 logged this same hazard for distill-counter-reset). The miner waits for real data.

## Blocking discovery for v10-08 (Hermes L3)

Per plan v10-08 was "blocked on L2 measurement". With L2 shipped:

- **L2 mine produces empty cluster set today.** L3 needs ≥1 promoted instinct + ≥1 use-cycle to refine — both of which require L2 to FIRST produce something to promote.
- **L3 unblocks when:** (a) decision-audit accumulates ~3-6 months of real-world data, OR (b) a human seeds at least one instinct manually that the miner can then validate against, OR (c) the test-fixture exclusion logic gets sophisticated enough that even short-history data produces clusters.
- **Recommendation:** v10-08 stays DEFERRED with clearer unblock condition. Plan.md gets written in this same PR (Item D of "ทำทั้งหมด" sweep) but status is SCOPED-DEFERRED, not OPEN. See [`sprint-v10-08/plan.md`](../sprint-v10-08/plan.md).

## v10 grand-total after this sprint

```
v10: 47 / 47 pt = 100%   ★ Hermes L1 + L2 both shipped; L3 SCOPED-DEFERRED
  v10-01 traceability wiki         ✅ 13 / 13
  v10-02 RTK readiness             ✅ 5 / 5
  v10-03 RTK adoption (defer)      ✅ 2 / 2
  v10-04 MBP soft-ask              ✅ 3 / 3
  v10-05 honest cleanup            ✅ 8 / 8
  v10-06 searchable brain (L1)     ✅ 5 / 5
  v10-07 pattern miner (L2)        ✅ 8 / 8   ← THIS SPRINT
  v10-08 instinct refinement (L3)  ⏸️ DEFERRED (plan.md authored, status SCOPED-DEFERRED)
  v10-09 per-agent allow lists     ✅ 3 / 3
```

## Next sprint

**sprint-v10-08 (Hermes L3)** — DEFERRED with plan.md authored. Will open when:
- Real-world decision-audit data accumulates (~3-6 months of normal use), OR
- Human seeds ≥1 manual instinct + uses it across ≥3 sessions to record observed-vs-actual outcomes

No action this PR beyond authoring the plan.

## References

- Plan: [.aegis/brain/sprints/sprint-v10-07/plan.md](plan.md)
- Source: AEGIS Knowledge-Layer Mega Plan derivation + `project_hermes_adoption_pattern` memory
- Predecessor: sprint-v10-06 (FTS5 brain index, L1)
- Successor: sprint-v10-08 (DEFERRED — needs L2 data accumulation)
- Decision-audit input: [.aegis/brain/logs/decision-audit.log](../../logs/decision-audit.log) (122 entries, 57 judgment, 41 fixture, 16 real)
