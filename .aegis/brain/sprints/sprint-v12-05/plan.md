# Sprint v12-05 Plan: aegis-brain-graph query

**Points**: 8pt · **Branch**: `sprint-v12-05` (stacked on `sprint-v12-04`)

## Goal

Five MCP-style query subcommands over the NDJSON graph from v12-04. Pure-JS load (NDJSON → Map), pure-JS traversal (BFS / DFS / scan). Human and JSON output.

Closes Knowledge-Layer Mega Plan v1.1 §6 v12-05.

## Stories

| ID | Subcommand | Pt | Behavior |
|----|-----------|----|----------|
| A | `impact <name>` | 2 | BFS forward through `WIRES` / `IMPLEMENTS` / `WRITES` / `READS` / `TESTS` / `SUPERSEDES` / `MENTIONED_IN` edges from the target. Returns reachable set with depth + path. |
| B | `context <name>` | 2 | Single 1-hop scan: every edge where `src == target \|\| dst == target`. Group by edge kind. |
| C | `detect-changes --since <ref>` | 2 | Shells out `git diff --name-only <ref> HEAD`, maps changed paths to nodes via `node.source_path === changed`, fans out 1 hop. |
| D | `mentions <topic>` | 1 | Scans `MENTIONED_IN` edges; returns brain-docs that mention the topic. |
| E | `wiring <hook-name>` | 1 | Given a hook (e.g. `PostToolUse:.*`), list every tool wired through it via WIRES edges. |

## CLI shape

```
$ node tools/aegis-brain-graph/query.mjs <subcommand> <args> [--json] [--max-depth N] [--limit N]
```

Examples:

```
$ node tools/aegis-brain-graph/query.mjs impact aegis-live-tail
skill:aegis-live-tail
  → tool:aegis-live-tail/emit.mjs (depth=1, via WRITES)
  → tool:aegis-live-tail/emit.mjs (depth=1, via WIRES)
  ...

$ node tools/aegis-brain-graph/query.mjs context tools/aegis-live-tail/emit.mjs
incoming:
  WIRES from hook:PostToolUse:.*:tools/aegis-live-tail/emit.mjs
  IMPLEMENTS from sprint:v11-01
outgoing: (none)

$ node tools/aegis-brain-graph/query.mjs detect-changes --since main
changed paths since main:
  skills/aegis-live-tail.md
    → 1 node match (skill:aegis-live-tail)
    → 4 connected nodes (TESTS, WIRES, IMPLEMENTS)
  ...

$ node tools/aegis-brain-graph/query.mjs mentions super-spec
brain-doc:learnings/2026-04-23_spec-mega-delivery-pattern.md mentions super-spec
brain-doc:retrospectives/2026-04/20/08.50_*.md mentions super-spec
...

$ node tools/aegis-brain-graph/query.mjs wiring 'PostToolUse:.*'
hook:PostToolUse:.*:tools/aegis-live-tail/emit.mjs WIRES tool:aegis-live-tail/emit.mjs
hook:PostToolUse:.*:tools/aegis-activity-logger/log.mjs WIRES tool:aegis-activity-logger/log.mjs
...
```

## Acceptance criteria

- [ ] All 5 subcommands return correct results on the real meta repo (234 nodes / 257 edges)
- [ ] Each query has ≥ 3 regression assertions on a fixture graph
- [ ] `--json` output validates with `JSON.parse(...)`
- [ ] p95 latency on the real meta-repo graph: < 100ms for all 5 (relaxed from spec's 50ms — node startup dominates)
- [ ] Empty-graph case (`nodes.ndjson` missing): exit 2 with clear "run `build` first" message
- [ ] Tests: ≥ 15 assertions
- [ ] Sprint roadmap row flips to CLOSED 8/8

## Out of scope

- Cypher-style query language → not needed at AEGIS scale
- Hot-reload / daemon mode → query is one-shot CLI
- Auto-rebuild before query → user runs `build` explicitly (or hook handles it)

## References

- Knowledge-Layer Mega Plan v1.1 §6 v12-05
- v12-04 (PR #121) — NDJSON storage shape and edge kinds
- Plan §8.2 — performance budgets (revised < 100ms for all queries given node startup overhead)
