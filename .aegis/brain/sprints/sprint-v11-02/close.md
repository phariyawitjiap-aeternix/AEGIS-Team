# Sprint v11-02 Close: aegis-activity-logger (JSONL audit)

**Status**: CLOSED (100%) · **Points**: 5/5
**Branch**: `feat/v11-02-aegis-activity-logger`

## Stories shipped

| ID | Story | Pt | Outcome |
|----|-------|----|---------|
| A | log.mjs PostToolUse hook | 2 | ✅ p95 = 146ms (<200ms) |
| B | view.mjs CLI | 1 | ✅ 5 filter modes + --watch + --json |
| C | stats.mjs CLI | 1 | ✅ day/tool/persona/status + day+tool grid |
| D | SKILL.md + tests | 1 | ✅ 16-assertion regression test |

## Acceptance criteria — all green

- [x] Every Edit/Write/Bash produces one JSONL line
- [x] view --today prints today's entries
- [x] view --watch tails today's file (file-watch loop, not tied to live-tail fifo)
- [x] stats --week shows tool counts by day (default = day+tool grid)
- [x] Test: write a file, confirm activity entry exists with correct path
- [x] Hook latency p95 <200ms (measured 146ms)
- [x] Daily file rotation — UTC date in filename, append-only

## Test results

```
tests/aegis-activity-logger-test.sh  — 16/16 pass
tests/aegis-live-tail-test.sh         — 25/25 pass (regression)
tests/aegis-upgrade-grepc-test.sh     —  4/4  pass (regression)
```

## Hook wiring

`.claude/settings.json` PostToolUse `matcher=".*"` now runs three hooks in sequence:
1. `tools/aegis-token-profile.sh` (existing)
2. `tools/aegis-live-tail/emit.mjs` (v11-01)
3. `tools/aegis-activity-logger/log.mjs` (v11-02 — this sprint)

Both v11 hooks share `format.mjs::eventFromHook()` so the live stream and the JSONL log agree on event shape (no divergence risk).

## Notes for v11-03

- `view.mjs --watch` uses `fs.watch` polling — adequate for activity log tailing but not a substitute for the named-pipe live stream.
- `eventFromHook()` is now load-bearing for two consumers; any change there must update both v11-01 and v11-02 tests.
