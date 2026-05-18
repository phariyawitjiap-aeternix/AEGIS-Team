# Sprint v15-12 Kanban

## DONE

- [x] **A** — `tools/_hook-utils/safe-run.mjs` (2pt)
  - `safeRun(mainFn, { hookName, failOpen, exitOnSuccess })`
  - Installs `uncaughtException` + `unhandledRejection` handlers (gated by listenerCount)
  - Logs full stack to `.aegis/brain/logs/hook-errors.log`
  - Classifies into 6 buckets (ERR_MODULE_NOT_FOUND, ENOENT, EACCES, ERR_REQUIRE_ESM, SyntaxError, JSON.parse, generic)
- [x] **B** — Wrap 5 Node entry points (1pt)
  - `tools/aegis-live-tail/emit.mjs`
  - `tools/aegis-activity-logger/log.mjs`
  - `tools/aegis-run-logger/archive.mjs`
  - `tools/aegis-resume/session-start.mjs` (also converted IIFE → named `main()`)
  - `tools/aegis-brain-graph/staleness.mjs`
- [x] **C** — Extend `.claude/hooks/run-with-flags.sh` (1pt)
  - Capture stderr to temp file
  - `|| HOOK_EXIT=$?` pattern (set-e-safe)
  - 6-bucket classification on bash hook stderr
  - PreToolUse (`guard-*` / `approval-*`) propagates exit; everything else exits 0
- [x] **D** — `tests/aegis-hook-safe-run-test.sh` × 9 (1pt)
  - T1 happy path / T2 throw classified / T3 log written / T4 ERR_MODULE_NOT_FOUND / T5 generic / T6 failOpen=false / T7 bash wrapper classify / T8 guard-* propagation / T9 PostToolUse fail-open

## Stories table

| Story | Type | Points | Status | Hash |
|-------|------|--------|--------|------|
| A — safe-run.mjs | new file | 2 | DONE | — |
| B — wrap 5 entry points | enhancement | 1 | DONE | — |
| C — bash classifier in wrapper | enhancement | 1 | DONE | — |
| D — regression tests | testing | 1 | DONE | — |

**Total**: 5/5 points done.
