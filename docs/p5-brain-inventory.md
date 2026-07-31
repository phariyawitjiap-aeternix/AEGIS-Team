# P5 — Brain Stay/Go Inventory (read-only, pre-migration gate)

> Generated 2026-06-19. First step of P5 per Captain America's sequencing call
> (D-010). **Read-only**: this manifest touches nothing under `.aegis/brain/`.
> sha256 baseline of the GO slice: `/tmp/brain-go-baseline.txt` (regenerate with
> `shasum -a 256` before any move; diff after to prove no loss).

## Classification (verified by consumer grep, the D-009 load-bearing trap check)

| Path | Size | Files | Class | Consumers (tools/hooks) | Rationale |
|------|-----:|------:|:-----:|:-----------------------:|-----------|
| `index.db` | 7.0M | 1 | **STAY** | FTS5 search | unique value — `aegis-brain-search` |
| `logs/` | 3.4M | 12 | **STAY** | decision-audit, activity | audit trail, gitignored |
| `instincts/` | 24K | 6 | **STAY** | Loki auto-REJECT | confidence lifecycle |
| `learnings/` | 184K | 34 | **STAY** | distill, FTS | cross-sprint synthesis |
| `resonance/` | 88K | 9 | **STAY** | `/aegis-start` | project-identity layer |
| `handoffs/` | 152K | 22 | **STAY** | 8 readers + FTS-indexed | NOT flat — feeds search |
| `retrospectives/` | 104K | 14 | **STAY** | 6 readers + FTS-indexed | NOT flat — feeds search |
| `graph/` | 168K | 3 | **STAY** | brain-graph | dependency graph |
| `sprints/` | 956K | 171 | **STAY** | sprint tooling | live kanban/plan data |
| `tasks/` | 264K | 66 | **STAY** | BLOCK 0 meta.json | task hierarchy |
| `state/` | 52K | 12 | **STAY** | aegis-resume checkpoints | interrupted-run tracking |
| `metrics/` | 1.5M | 41 | **STAY** | dashboards | observability |
| `func-catalog.json`,`gate-rules.yaml`,`counters.json`,`skill-cache/`,`design-library/` | — | — | **STAY** | various | programmatic consumers |
| `MEMORY.md` | 4K | 1 | **STAY** | 3 readers | brain index |
| `conversations/` | 20K | 2 | go? | 3 readers, stale (Apr) | borderline; low value |
| `index.md` | 4K | 1 | **GO** | **0 consumers** | display-only — safe to migrate |
| `runs/` | **114M** | 73 | **PRUNE** | run archives | gitignored bloat — GC, not migrate |
| `index-backups/`,`redaction/`,`live/` | — | — | PRUNE/STAY | stale | housekeeping |

## Verdict — P5 as framed has near-zero migratable surface

The vote imagined a "flat-storage half" of the brain that native auto-memory
could absorb. Grep does not support it: the brain is **overwhelmingly
load-bearing** — `handoffs/` and `retrospectives/`, the obvious "flat doc"
candidates, are FTS-indexed (8 and 6 readers); only `index.md` has **zero**
consumers. Migrating the genuine GO slice (`index.md`, maybe stale
`conversations/`) saves ~4–24K and buys nothing.

This is the **same verification-overturns-plan pattern as P2/D-009 and P6**:
the high-level move dissolves on contact with the actual consumer graph.

### Re-scope
1. **Drop P5's migration goal.** Native auto-memory cannot absorb the brain
   without losing FTS/audit/instinct value; the flat slice is trivial.
2. **The real brain win is housekeeping, not native-alignment:** `runs/` is
   **114 MB / 73 files** of gitignored archives — add a GC pass
   (`aegis-run-logger` retention) instead. Separate, low-risk chore.
3. Keep `.aegis/brain/` as the unique-value store it is (its defensibility was
   the whole point of the audit's "12% unique" core).
