# Sprint v15-12 Close — Hook Error Friendly-Fail

**Status**: CLOSED (100%)
**Date**: 2026-05-18
**Tests**: 58/58 PASS (added `aegis-hook-safe-run-test.sh` × 9 scenarios)
**Branch**: `claude/sprint-v15-12-hook-error-friendly-fail`

## What shipped

- `tools/_hook-utils/safe-run.mjs` — shared Node hook wrapper.
  6-bucket error classifier + structured log writer.
- 5 Node hook entry points wired through `safeRun`:
  live-tail/emit, activity-logger/log, run-logger/archive,
  resume/session-start, brain-graph/staleness.
- `.claude/hooks/run-with-flags.sh` extended with stderr classifier +
  exit-code routing (guard-*/approval-* propagate; others exit 0).
- `tests/aegis-hook-safe-run-test.sh` × 9 scenarios.

## Behavior change

**Before:**
```
PostToolUse:Bash hook error
Failed with non-blocking status code:
node:internal/modules/esm/resolve:271
  throw new ERR_MODULE_NOT_FOUND(...)
        ^
Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'foo'
    at packageResolve (node:internal/modules/esm/resolve:864:12)
    at moduleResolve (...)
    [50 more lines of stack trace]
```

**After:**
```
⚠ [aegis-live-tail/emit] missing Node module — run: bash tools/aegis-doctor.sh --fix
```

Full stack still preserved at `.aegis/brain/logs/hook-errors.log` for
forensics + future doctor heuristics.

## Classification buckets

| Pattern | Friendly message |
|---|---|
| `ERR_MODULE_NOT_FOUND` / `Cannot find module` | "missing Node module — run: bash tools/aegis-doctor.sh --fix" |
| `ENOENT` | "missing file: <path> — run: bash tools/aegis-doctor.sh" |
| `EACCES` / "permission denied" | "permission denied — try: chmod +x <script>" |
| `ERR_REQUIRE_ESM` | "CommonJS/ESM mismatch — Node version may be stale" |
| `SyntaxError` | "syntax error in hook script — see .aegis/brain/logs/hook-errors.log" |
| `JSON.parse` / unexpected token | "malformed hook input — Claude Code may have sent unexpected JSON" |
| _everything else_ | "failed: <first line of err> (full trace in .aegis/brain/logs/hook-errors.log)" |

## Implementation notes

- **No settings.json changes** — downstream projects don't need a fresh
  sync. The .mjs entry points pick up the wrapper transparently because
  their existing import path (`../_hook-utils/safe-run.mjs`) ships with
  the rest of `tools/` on install.
- **`set -e` safety in bash wrapper** — `|| HOOK_EXIT=$?` captures the
  downstream hook's exit code without aborting the wrapper. Without
  this, the classifier never ran.
- **Profile-gating preserved** — wrapper still respects
  `AEGIS_HOOK_PROFILE` and `AEGIS_DISABLED_HOOKS` before the hook runs.
- **Exit-code routing convention** — `case "$HOOK_ID" in guard-*|approval-*) exit $HOOK_EXIT ;; *) exit 0 ;; esac`. This is a NAMING convention; hook authors must use `guard-` or `approval-` prefix to opt into block-on-fail semantics.

## Known not-shipped (explicit out-of-scope)

- Import-time errors of an entry-point file itself (would need impl
  split). The proper fix for missing-files-on-disk is `aegis-doctor.sh
  --fix` (PR #161, #171); this sprint targets runtime errors.
- Routing `linear-sync-on-kanban.sh` and `aegis-token-profile.sh`
  through the wrapper (would require settings.json change).
- Log rotation for `hook-errors.log` (G5 in audit; deferred).

## Verification

```
$ bash tests/aegis-hook-safe-run-test.sh
Results: 9 passed, 0 failed

$ bash tests/run-all.sh --continue
ALL TESTS PASS — 58/58 in 103s

$ echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' \
    | node tools/aegis-live-tail/emit.mjs
[exit 0, no stderr]
```

## Roadmap impact

v15 net deliverable: 30pt → 35pt.

## Follow-ups

- v15-13 candidate: log rotation for `hook-errors.log` (G5)
- v15-14 candidate: route remaining bash hooks through wrapper
