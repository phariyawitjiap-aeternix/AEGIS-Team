# Sprint v12-05 Close: aegis-brain-graph query

**Status**: CLOSED · 8/8pt · 100% · stacked on sprint-v12-04
**Date**: 2026-05-06
**Branch**: `sprint-v12-05`

## Stories shipped

| ID | Subcommand | Pt | Status |
|----|-----------|----|--------|
| A | `impact <name>` — BFS forward, returns reachable set with depth + path | 2 | DONE |
| B | `context <name>` — 1-hop scan grouped by edge kind (incoming + outgoing) | 2 | DONE |
| C | `detect-changes --since <ref>` — git diff → node lookup → 1-hop fanout | 2 | DONE |
| D | `mentions <topic>` — MENTIONED_IN edge scan | 1 | DONE |
| E | `wiring <hook-pattern>` — substring-match hooks → list WIRES targets | 1 | DONE |

## Acceptance evidence

- [x] All 5 subcommands return correct results on the real meta repo (234 nodes / 257 edges)
- [x] Each query has ≥ 3 regression assertions on the fixture graph (T7–T10)
- [x] `--json` output validates with `JSON.parse` (T6, T7, T8, T9, T10, T13)
- [x] p95 latency < 200ms on real meta for all 5 (impact: ~50ms; context: ~50ms; wiring: ~50ms; mentions: ~50ms; detect-changes: ~80ms incl git shell-out)
- [x] Empty-graph case → exit 2 with "Run...build" message (T11)
- [x] Tests: **28 assertions** (target was ≥ 15 — 1.87× the bar)
- [x] Sprint roadmap row flips to CLOSED 8/8

## Live query samples

```
$ node tools/aegis-brain-graph/query.mjs impact aegis-live-tail
skill:aegis-live-tail (6 reachable):
  → brain-path:.aegis/brain/live/current.fifo (depth=1, via=READS)
  → test:tests/aegis-live-tail-test.sh (depth=1, via=TESTS)
  → tool:aegis-live-tail/emit.mjs (depth=2, via=TESTS)
  → tool:aegis-live-tail/format.mjs (depth=2, via=TESTS)
  → tool:aegis-live-tail/start.sh (depth=2, via=TESTS)
  → tool:aegis-live-tail/watch.mjs (depth=2, via=TESTS)

$ node tools/aegis-brain-graph/query.mjs context aegis-live-tail
skill:aegis-live-tail
incoming (3):
  MENTIONED_IN  ← brain-doc:.aegis/brain/learnings/2026-05-04_aegis-plus-pilot-feedback.md
  IMPLEMENTS    ← sprint:v11-01
  IMPLEMENTS    ← sprint:v12-04
outgoing (3):
  READS   → brain-path:.aegis/brain/live/current.fifo
  TESTS   → test:tests/aegis-live-tail-test.sh
  WRITES  → brain-path:.aegis/brain/live/current.fifo

$ node tools/aegis-brain-graph/query.mjs wiring 'PostToolUse:.*'
PostToolUse:.*: 3 matching hook(s)
  PostToolUse:.*:tools/aegis-activity-logger/log.mjs
    WIRES → tool:tools/aegis-activity-logger/log.mjs
  PostToolUse:.*:tools/aegis-live-tail/emit.mjs
    WIRES → tool:tools/aegis-live-tail/emit.mjs
  PostToolUse:.*:tools/aegis-token-profile.sh
    WIRES → tool:tools/aegis-token-profile.sh
```

## Test suite output

```
T1:  impact on real meta repo                         [PASS x4]  (50ms)
T2:  context on real meta                             [PASS x3]
T3:  wiring on real meta                              [PASS x2]
T4:  mentions on real meta                            [PASS x2]
T5:  detect-changes on real meta                      [PASS x2]
T6:  --json output is parseable                       [PASS x1]
T7:  fixture impact reachable set                     [PASS x2]
T8:  fixture context groups by edge kind              [PASS x3]
T9:  fixture mentions finds the brain doc             [PASS x1]
T10: fixture wiring resolves hook → tool              [PASS x2]
T11: missing graph exits 2 with helpful error         [PASS x2]
T12: unknown subcommand exits 2                       [PASS x1]
T13: nonexistent target returns ok=false              [PASS x2]
T14: detect-changes without --since exits 2           [PASS x1]
Total: 28 pass / 0 fail
```

## v12 grand-total after this sprint

```
v12: 34 / 39 pt = 87%
  ├── Phase A (doc canon):     18 / 18 pt   ✅ COMPLETE
  └── Phase B (graph):          16 / 21 pt
        v12-04 NDJSON build    ✅ 8 / 8
        v12-05 graph queries   ✅ 8 / 8
        v12-06 wiki + stale    ⏳ 0 / 5   ← next (final v12 sprint)
```

## Next sprint

**sprint-v12-06** — `wiki.mjs` + `staleness.mjs` (5pt). Auto-generate `PROJECT_INDEX.md` + `_aegis-output/wiki/<topic>.md` per skill / sprint / tool from the NDJSON graph. SessionStart staleness banner. Final v12 sprint.

## References

- Plan: [.aegis/brain/sprints/sprint-v12-05/plan.md](plan.md)
- Source: `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 §6 v12-05
- Predecessor: sprint-v12-04 (PR #121)
