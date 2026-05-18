# Sprint v15-16 — Performance & Process-Leak Fix

> Restore baseline responsiveness lost to (1) `aegis-live-tail/watch.mjs`
> process leak (170 zombies counted across multiple weeks), (2) the
> `.*` matcher firing 3 PostToolUse hooks on EVERY tool call including
> read-only ones, (3) unbounded `.aegis/brain/runs/` (98 MB), (4) noisy
> brain-graph rebuild on every Edit, and (5) absent hook-latency CI
> budget that lets future regressions slip through.

## Sprint metadata

- **ID**: sprint-v15-16-performance-leak-fix
- **Points**: 7
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-16-performance-leak-fix`
- **Driver**: Nick Fury self-analysis 2026-05-18 (this session) — user reported "slower now"; ps confirmed 170 zombie watchers

## Root causes

| # | Symptom | Diagnostic |
|---|---|---|
| 1 | Slow tool calls | 6–7 hook spawns per Bash/Edit, no per-hook latency budget |
| 2 | RAM / FD pressure | 170 `watch.mjs` processes (`pgrep -f aegis-live-tail/watch.mjs \| wc -l`); orphan parent PIDs |
| 3 | Disk-cache pressure | `.aegis/brain/runs/` at 98 MB; never rotated since v11-07 |
| 4 | Every Read/Grep/Glob carries 3 PostToolUse hooks | `.*` matcher in settings.json wires token-profile + live-tail + activity-logger for ALL tool calls |
| 5 | Brain-graph debounce too tight | 3s window means heavy-edit bursts re-trigger build constantly |
| 6 | No CI guard for hook latency | Future hook additions can silently regress p95 |

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — Live-tail process leak: PID-tracked cleanup** | 2 | `tools/aegis-live-tail/start.sh` writes spawned PIDs to `.aegis/brain/live/watchers.pid`. `cmd_stop` reads the file, kills exactly those PIDs (no broad `pkill -f`). Add `cmd_cleanup-orphans` that finds `watch.mjs` processes with `ppid=1` (orphaned) and kills them. SessionStart hook auto-runs cleanup-orphans. |
| **B — `.*` matcher pruning** | 2 | Move `aegis-live-tail/emit.mjs` + `aegis-activity-logger/log.mjs` + `aegis-token-profile.sh` from `.*` to `Bash\|Edit\|Write\|MultiEdit\|Task` matcher in settings.json. Read/Grep/Glob no longer trigger 3 hooks each. Update install-remote.sh + downstream sync notes. |
| **C — Run-archive rotation** | 1 | `tools/aegis-run-rotate.sh` — gzip transcripts older than 7 days, delete > 30 days. SessionStart hook calls it (idempotent, < 100ms when nothing to do). |
| **D — Brain-graph debounce tuning** | 1 | `aegis-brain-graph/hook.sh` debounce 3s → 10s. Adds `AEGIS_BRAIN_GRAPH_DEBOUNCE_S` env var so users can tune. Documented trade-off (longer = fewer rebuilds + slightly more stale graph). |
| **E — Hook-latency CI test** | 1 | `tests/aegis-hook-budget-test.sh`: measure p95 latency of (a) PreToolUse:Bash chain, (b) PostToolUse:Bash chain, (c) PostToolUse:Edit chain. Fail if any p95 > 250ms. Regression net for future hook additions (G12 from §5 audit doc). |

## Acceptance criteria

1. After `bash tools/aegis-live-tail/start.sh stop` — `pgrep -f watch.mjs` returns 0.
2. SessionStart in a new session auto-kills any orphan `watch.mjs` (ppid=1) without touching active ones.
3. `Read`/`Grep`/`Glob` tool call → 0 PostToolUse hook spawns (was 3).
4. `Bash` tool call → 4 PostToolUse hook spawns (token-profile + live-tail + activity-logger + post-tool-use; was 4, unchanged).
5. `.aegis/brain/runs/` size ≤ 50 MB after rotate runs.
6. Brain-graph rebuild during a 10-edit burst: 1–2 rebuilds (was ~5+).
7. `tests/aegis-hook-budget-test.sh` exits 0 with all three p95 < 250ms.
8. Full suite stays 59/59 (60/60 with new test).

## Out of scope

- Replacing python3 in guard-bash + token-profile with pure bash (riskier; defer to v16).
- Merging multiple hooks into one (architectural rewrite; defer).
- Audit of CC 2.1.142/143 changelog (separate v15-17 candidate).

## Risks

- **R1 (cleanup-orphans false positive)**: a legitimately backgrounded watcher with ppid=1 (e.g. user opened tmux in standalone shell) could be killed. Mitigation: cleanup-orphans only targets processes started > 1h ago (uses `ps -o etime`).
- **R2 (`.*` matcher narrowing breaks live-tail completeness)**: visualizing read-only tools would no longer show in live-tail. Decision: acceptable — Read/Grep/Glob are usually noise; the use case for live-tail is tracking destructive ops, which we keep.
- **R3 (debounce 10s leaves stale graph)**: brain-graph is informational; staleness banner already warns on SessionStart. No correctness impact.

## Verification plan

1. `pgrep -f aegis-live-tail/watch.mjs | wc -l` → 0 after stop
2. `tests/aegis-hook-budget-test.sh` → p95 numbers logged + all < 250ms
3. `tests/run-all.sh --continue` → 60/60 PASS
4. Manual smoke: trigger Read tool, observe no hook noise; trigger Bash, observe hooks fire normally
5. `du -sh .aegis/brain/runs/` → bounded after rotate

## Out-of-band actions (already done in this session)

- ✅ Killed 170 zombie `watch.mjs` processes via `pkill`/`xargs kill -9`. The fix in Story A prevents this from recurring.
