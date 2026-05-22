# Sprint v15-22 Kanban

## DONE

- [x] **A** — `tools/aegis-claude-agents.sh` wrapper (1pt)
  - Subcommands: `list / list --json / where / filter --cwd / self / help`
  - 1-sec disk cache via `${TMPDIR}/aegis-claude-agents-cache/agents.json`
  - Graceful fallback to `[]` when `claude` missing from PATH
  - Validated on live machine: saw 2 sessions (AEGIS-Team busy + GenGoogleForm idle)
- [x] **B** — `mt.mjs sessions` subcommand (1pt)
  - Merges registry with live `claude agents --json` via wrapper
  - Per-row: name, version, exists, status, sessionId (first 8), age (min/hour), path
  - Surfaces unregistered live sessions as `(unregistered)` rows
  - `--json` flag for scripting
- [x] **C** — `/aegis-start` Step 2.7 cross-session warning (1pt)
  - Filters out self via `CLAUDE_SESSION_ID`
  - Warns on (a) another session at SAME cwd (brain-write race risk), (b) idle session > 1h (handoff candidate)
  - Soft gate — never blocks
- [x] **D** — `/aegis-status` Step 5.5 cross-project map (1pt)
  - Embeds `mt sessions` output as a new section
  - Inventory only — warnings live in `/aegis-start`
- [x] **E** — Tests × 10 (1pt)
  - `tests/aegis-claude-agents-test.sh` × 6: array shape / human / filter / self / claude-missing-fallback / cache hit
  - `tests/aegis-mt-sessions-test.sh` × 4: header / json-array / record-keys / empty-registry
  - All 10 green standalone; full suite: 70/70 PASS in 150s

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — claude-agents wrapper | new tool | 1 | DONE |
| B — mt sessions extension | tool extension | 1 | DONE |
| C — /aegis-start warning | command integration | 1 | DONE |
| D — /aegis-status map | command integration | 1 | DONE |
| E — tests × 10 | testing | 1 | DONE |

**Total**: 5/5 done.

## Install scope

- `install.sh` ships `aegis-claude-agents.sh` via `runtime_helpers` array
- Downstream gets the wrapper + the updated `mt.mjs` (multi-tenant already in `tool_packages`)
- After next install, downstream's `/aegis-start` will start surfacing cross-session warnings automatically

## Closes

- Cross-session awareness gap surfaced by 2026-05-22 user question
- v15-22 plan story acceptance: 9/9 criteria met

## Carry to v15-23+

- **Background dispatch** — actually spawn `claude agents` for long-running work (Beast research, Spider-Man builds). Needs PID tracking + lifecycle capture.
- **Inter-session messaging** — share state mid-flight between sessions
- **Auto-handoff of stale idle sessions** — upgrade from warning to action
- **`--mcp-config` / `--plugin-dir` per-dispatch profiles**

## Recursive validation

- AEGIS-Team's own `/aegis-start` now surfaces the GenGoogleForm idle session (38h+ idle) as the first real-world hit — proves the observability layer works end-to-end without a fixture.
