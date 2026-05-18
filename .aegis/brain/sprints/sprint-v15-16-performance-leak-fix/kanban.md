# Sprint v15-16 Kanban — Performance & Process-Leak Fix

## TODO

- [ ] **A** — Live-tail PID-tracked cleanup (2pt)
  - `start.sh cmd_start`: append spawned PID to `.aegis/brain/live/watchers.pid`
  - `start.sh cmd_stop`: read PID file → `kill -TERM` → wait → `kill -9` survivors → clear file
  - `start.sh cmd_cleanup-orphans`: find `watch.mjs` with `ppid=1` AND `etime > 1h` → kill them
  - `session-start.sh`: invoke `cmd_cleanup-orphans` (silent, < 200ms when nothing to kill)
- [ ] **B** — `.*` matcher → `Bash|Edit|Write|MultiEdit|Task` (2pt)
  - Update `.claude/settings.json` PostToolUse `.*` entry → narrower matcher
  - Verify aegis-token-profile / live-tail / activity-logger still receive their needed tool events
  - Note for downstream sync — settings.json change requires `--upgrade` propagation
- [ ] **C** — Run-archive rotation (1pt)
  - `tools/aegis-run-rotate.sh`: gzip transcripts > 7 days, delete > 30 days
  - SessionStart hook calls it (idempotent best-effort)
  - Manifest update for install-remote.sh + install.sh
- [ ] **D** — Brain-graph debounce 3s → 10s (1pt)
  - `tools/aegis-brain-graph/hook.sh`: `DEBOUNCE_S=${AEGIS_BRAIN_GRAPH_DEBOUNCE_S:-10}`
  - Comment-doc the trade-off
- [ ] **E** — Hook-latency CI test (1pt)
  - `tests/aegis-hook-budget-test.sh` — measure 30 invocations of each chain, compute p95
  - Fail if any chain > 250ms
  - Add to `tests/run-all.sh` discovery glob

## DONE (pre-sprint cleanup)

- [x] **Z** — Killed 170 zombie `watch.mjs` processes (pre-sprint immediate fix)
  - `pgrep -f aegis-live-tail/watch.mjs | xargs kill -9` → 0 remaining

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — live-tail PID cleanup | bug-fix | 2 | TODO |
| B — `.*` matcher pruning | optimization | 2 | TODO |
| C — run-archive rotation | optimization | 1 | TODO |
| D — brain-graph debounce | optimization | 1 | TODO |
| E — hook-latency CI test | testing | 1 | TODO |

**Total**: 0/7 done.
