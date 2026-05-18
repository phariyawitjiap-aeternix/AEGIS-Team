# Sprint v15-12 — Hook Error Friendly-Fail

> Replace cryptic Node stack traces and bash hook failures with one-line
> classified messages users can act on. Full traces still get logged for
> forensics.

## Sprint metadata

- **ID**: sprint-v15-12-hook-error-friendly-fail
- **Points**: 5
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-12-hook-error-friendly-fail`
- **Driver**: prior pain — `PostToolUse:Bash hook error / node:internal/modules/esm/resolve:271` cryptic dumps when a hook lib was missing post-upgrade

## Stories

| Story | Points | Description |
|-------|--------|-------------|
| A — `safe-run.mjs` shared wrapper | 2 | New `tools/_hook-utils/safe-run.mjs` exporting `safeRun(mainFn, { hookName, failOpen })`. Catches uncaughtException + unhandledRejection + main() throw → logs full stack → emits one classified line. |
| B — wrap 5 Node entry points | 1 | live-tail/emit, activity-logger/log, run-logger/archive, resume/session-start, brain-graph/staleness. Replace `main().then(...)` tail with `safeRun(main, { hookName, failOpen: true })`. |
| C — extend `run-with-flags.sh` | 1 | Capture downstream hook stderr; classify into 6 buckets (module-not-found / command-not-found / permission / no-such-file / python3-missing / generic). PreToolUse (`guard-*`, `approval-*`) propagates exit; everything else exits 0. |
| D — regression tests | 1 | `tests/aegis-hook-safe-run-test.sh` × 9 scenarios — happy path / throw / log written / ERR_MODULE_NOT_FOUND classify / generic fallback / failOpen=false propagation / bash wrapper classify / guard-* propagation / post-tool-use fail-open. |

## Acceptance criteria

1. `safeRun(main, { hookName: "X", failOpen: true })` exits 0 on any throw and writes a one-line stderr message starting with `⚠ [X]`.
2. Full stack appended to `${CLAUDE_PROJECT_DIR}/.aegis/brain/logs/hook-errors.log` (created if absent).
3. ERR_MODULE_NOT_FOUND → "missing Node module — run: bash tools/aegis-doctor.sh --fix"
4. Generic throw → "failed: <first line> (full trace in .aegis/brain/logs/hook-errors.log)"
5. `failOpen: false` propagates exit 1 (for future PreToolUse use cases).
6. Bash hook wrapper (`run-with-flags.sh`) classifies same 6 buckets and is set-e-safe (uses `|| HOOK_EXIT=$?` to capture exit code without aborting).
7. `guard-*` / `approval-*` hook IDs propagate exit code; others exit 0.
8. Full test suite 58/58 PASS.

## Design decisions

- **No settings.json changes** — downstream projects don't need a re-sync hop.
- **safe-run uses static imports of node:core only** (fs, path) — never crashes at import time.
- **`process.on()` handlers gated by `listenerCount()`** — don't clobber if a hook installs its own.
- **Bash wrapper uses `|| HOOK_EXIT=$?`** instead of `set +e` toggle — local scope, no global state mutation.
- **6 classification buckets, not more** — keep maintainable; everything else falls back to generic + log pointer.
- **`hookName` is path-style** (`aegis-live-tail/emit`) — disambiguates the 5 hooks since their basenames overlap.

## Out of scope

- **Catching import errors of the entry-point file itself** — would require splitting each .mjs into wrapper + impl with dynamic import. The right fix for missing-module-on-disk is `aegis-doctor.sh --fix` (PR #161, #171); v15-12 is for runtime errors.
- **Routing existing non-wrappered hooks (`linear-sync-on-kanban.sh`, `aegis-token-profile.sh`) through `run-with-flags.sh`** — would change settings.json; deferred to v15-13 if needed.
- **Log rotation for `hook-errors.log`** — G5 in earlier audit; deferred.

## Verification plan

1. `bash tests/aegis-hook-safe-run-test.sh` → 9/9 PASS
2. `bash tests/run-all.sh --continue` → 58/58 PASS
3. Smoke: each updated .mjs run with valid input → exit 0, no stderr noise
4. Smoke: bash wrapper with a deliberately broken hook → friendly stderr + log entry
