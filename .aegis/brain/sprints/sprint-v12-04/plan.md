# Sprint v12-04 Plan: aegis-brain-graph build → NDJSON

**Points**: 8pt · **Branch**: `sprint-v12-04` (stacked on `sprint-v12-03`)
**Phase B opener** — the first of 3 graph sprints (v12-04 build → v12-05 query → v12-06 wiki).

## Goal

Walk the meta repo + downstream pilots, emit a content-addressable knowledge graph as NDJSON files. Atomic via temp-rename. Idempotent (byte-equal output across rebuilds with deterministic ordering). `--full` and `--incremental` modes. Wire as PostToolUse Edit/Write debounced 3s.

Closes Knowledge-Layer Mega Plan v1.1 §6 v12-04.

## Storage shape (per Mega Plan §5.2)

```
.aegis/brain/graph/
├── nodes.ndjson     # one JSON per line — node records
├── edges.ndjson     # one JSON per line — edge records
└── meta.json        # {built_at, source_mtime_max, node_count, edge_count, builder_version}
```

**Node IDs are content-addressable strings** (`<kind>:<name>`). Stable hunks across re-orders.

```jsonc
// nodes.ndjson — one line per node (sorted by [kind, name])
{"id":"skill:aegis-live-tail","kind":"skill","name":"aegis-live-tail","source_path":"skills/aegis-live-tail.md","mtime":...,"meta":{...}}
{"id":"tool:aegis-live-tail/emit.mjs","kind":"tool","name":"aegis-live-tail/emit.mjs","source_path":"tools/aegis-live-tail/emit.mjs","mtime":...,"meta":{...}}
{"id":"hook:PostToolUse:.*:tools/aegis-live-tail/emit.mjs","kind":"hook","name":"...","source_path":".claude/settings.json","mtime":...,"meta":{...}}
{"id":"sprint:v11-01","kind":"sprint","name":"v11-01","source_path":".aegis/brain/sprints/sprint-v11-01/close.md","mtime":...,"meta":{"status":"CLOSED","points":5}}
```

```jsonc
// edges.ndjson — one line per edge (sorted by [src, kind, dst])
{"src":"hook:PostToolUse:.*:tools/aegis-live-tail/emit.mjs","dst":"tool:aegis-live-tail/emit.mjs","kind":"WIRES","meta":{}}
{"src":"sprint:v11-01","dst":"tool:aegis-live-tail/emit.mjs","kind":"IMPLEMENTS","meta":{"story":"B"}}
{"src":"skill:aegis-live-tail","dst":"brain-path:.aegis/brain/live/current.fifo","kind":"WRITES","meta":{}}
```

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | `tools/aegis-brain-graph/lib.mjs` — NDJSON read/write helpers + atomic write (temp + rename) + minimal frontmatter parser | 1 |
| B | `tools/aegis-brain-graph/build.mjs` — parsers per source kind: skills, tools, settings.json hooks, sprint close.md, tests, brain docs | 3 |
| C | Output discipline — sorted (deterministic), atomic rename across all 3 files, `meta.json` carries built_at + source_mtime_max + counts + builder_version | 2 |
| D | `--incremental` mode — mtime-gate, exits <50ms when no source changed | 1 |
| E | PostToolUse Edit/Write/MultiEdit hook wiring (debounced 3s via flock on `.aegis/brain/state/graph-build.lock`) — fail-OPEN | 1 |

## Source kinds and edge types

| Source | Node kind | Edges produced |
|--------|-----------|----------------|
| `skills/*.md` (frontmatter) | `skill` | READS / WRITES (to brain-path nodes), WIRES (← from hook), TESTS (← from test), SUPERSEDES |
| `tools/<pkg>/<file>` | `tool` | (referenced by skills/hooks; tools don't have outbound edges in v12-04) |
| `.claude/settings.json` hooks | `hook` | WIRES → tool node |
| `.aegis/brain/sprints/<id>/close.md` | `sprint` | IMPLEMENTS → tool/skill nodes (parsed from "Stories shipped" rows) |
| `tests/*.sh`, `tests/*.mjs` | (no node — tests are leaves) | TESTS → tool/skill (parsed from path mentions) |
| `.aegis/brain/{learnings,resonance,handoffs,retrospectives}/**/*.md` | `brain-doc` | MENTIONED_IN → skill/tool/sprint (regex match of names) |
| `.aegis/brain/issues/*.yaml` | `issue` | (yaml frontmatter scan; nodes only in v12-04) |
| `.aegis/brain/approvals/*.yaml` | `approval` | (nodes only in v12-04) |
| `.aegis/brain/{gate-rules,routing/policy,redaction/patterns}.yaml` | `config` | (nodes only) |
| brain paths (synthetic, from skill manifest) | `brain-path` | (target of READS/WRITES from skills) |

## Build behavior

**`--full`** (cold rebuild from scratch):
- Walk every source kind; emit nodes + edges.
- Sort deterministically: nodes by `(kind, name)`, edges by `(src, kind, dst)`.
- Write `nodes.ndjson.tmp`, `edges.ndjson.tmp`, `meta.json.tmp`; fsync each; then atomic rename trio.
- Two consecutive `--full` runs produce byte-equal output (`cmp -s` returns 0).

**`--incremental`** (default for hooks):
- Compare each source file's mtime to `meta.json.source_mtime_max`.
- If no source changed: exit 0 in <50ms (no parse, no rewrite).
- If sources changed: re-parse only those, surgically replace their nodes/edges.
- (For v12-04, surgical replacement may be approximated by full rebuild + dedupe — performance budget allows.)

## Acceptance criteria (Mega Plan v12-04)

- [ ] `--full` cold build on the real meta repo: ≥ 100 nodes, ≥ 50 edges
- [ ] `--full` two consecutive runs: `cmp -s` returns 0 (byte-equal output)
- [ ] `--incremental` with zero source changes: < 200ms wall-clock (relaxed from spec's < 50ms — node startup dominates at this scale)
- [ ] `--full` cold build < 2s wall-clock on the real meta repo (relaxed from spec's < 1s)
- [ ] Crash-mid-build leaves the previous good graph intact (no partial writes)
- [ ] `meta.json` schema complete: built_at, source_mtime_max, node_count, edge_count, builder_version
- [ ] Tests: ≥ 10 assertions covering parser correctness, sort determinism, atomic rename, incremental skip
- [ ] Hook wired in `.claude/settings.json` PostToolUse Edit/Write/MultiEdit
- [ ] Hook is debounced (3s coalesce via flock) — second invocation within 3s exits without rebuild
- [ ] Hook fail-OPEN (any internal error → exit 0 with stderr warning)
- [ ] `.aegis/brain/graph/` added to `.gitignore` (rebuildable from sources, not tracked by default)

## Out of scope (v12-04)

- Query subcommands → v12-05 (`impact / context / detect-changes / mentions / wiring`)
- Auto-wiki + staleness → v12-06
- Embeddings / vector search → REJECTED in plan §2.9
- LadybugDB / SQLite for graph → REJECTED in plan §2.10 (NDJSON is the chosen storage)

## Performance notes

- AEGIS scale: ~100-200 nodes, ~150-300 edges expected on meta repo.
- JS in-memory load + BFS is < 5ms at this scale; storage cost dominated by disk writes.
- The ≥ 1s build budget allows for cold I/O on slow disks.

## References

- Knowledge-Layer Mega Plan v1.1 §5.2 (storage), §5.3 (tools), §6 v12-04 (story spec), §8.2 (perf budget)
- Mega Plan §2.10 (REJECT SQLite for graph — NDJSON wins on file-as-contract grounds)
- Predecessor: sprint-v12-03 (PR #120) — provides skill frontmatter input contract
