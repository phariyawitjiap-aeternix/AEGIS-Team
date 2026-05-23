# Sprint v15-25 Kanban

## DONE

- [x] **A** — Remove `mt cwd` + `mt run` (1pt)
  - cmdCwd + cmdRun removed from mt.mjs (~70 LOC)
  - Switch dispatcher returns exit 2 with `Use: claude --cwd "$(mt where <name>)" <args>` migration hint
  - Help text updated
  - Test Group 6 collapsed 8 → 2 (just verifies removal + migration hint)
  - All 24 mt tests green
- [x] **B** — Archive v9-era worktree tools (1pt)
  - `tools/aegis-worktree-gc.sh` (150 LOC) → `tools/_archived/`
  - `tools/aegis-merge-worktree.sh` (314 LOC) → `tools/_archived/`
  - Updated 4 referrers: `.claude/agents/thor.md`, `README.md`, `install-remote.sh`, `.claude/references/v9-follow-ups.md`
  - aegis-trace-audit shows 0 orphan refs
- [x] **C** — Audit + KEEP confirmations (1pt)
  - KEEP `aegis-resume/` — unique SessionStart crash-detection (not duplicate of `claude --resume`)
  - KEEP `aegis-status-brief.sh` — terminal-side companion to `/aegis-status` slash command
  - KEEP `aegis-dump.sh` — Hermes parity (v14-03), shareable redacted setup summary
  - KEEP `aegis-pin.sh` — Hermes parity (v14-03), 2-axis instinct/skill pinning
  - KEEP `aegis-contrast-check.sh` — wired into wasp tests
  - KEEP `aegis-router.sh` — deferred (needs fuller audit)

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — remove mt cwd/run | code removal | 1 | DONE |
| B — archive worktree tools | code archive | 1 | DONE |
| C — audit + keep confirmations | documentation | 1 | DONE |

**Total**: 3/3 done.

## Measurement

| Surface | Before | After | Δ |
|---|---|---|---|
| `tools/aegis-*.sh` count | 55 | 52 | −3 |
| LOC removed from mt.mjs | — | — | −70 |
| LOC moved to `_archived/` | — | — | −464 |
| Test cases (Group 6) | 8 | 2 | −6 |
| Cwd-integration concepts | `mt cwd` / `mt run` / `mt where` / `claude --cwd` | just `mt where` + `claude --cwd` | −2 redundant |

## Strategic outcome

The leaning bound: AEGIS now has ONE canonical recipe per concern. `mt cwd` and
`mt run` were two parallel wrappers around the same `claude --cwd` invocation —
they competed with native for no functional reason. Removed. The remaining
surfaces all add value native doesn't have.

## Carry to v15-26+

- Fuller `aegis-router.sh` audit (model-tier picker vs native per-Agent --model)
- References doc audit (28 active refs — many tagged v7-v9; how many are still load-bearing?)
- Skills audit vs Anthropic marketplace
