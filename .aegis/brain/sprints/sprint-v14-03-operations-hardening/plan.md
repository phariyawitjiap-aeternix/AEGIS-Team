<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# Sprint v14-03 Plan — Operations Hardening

**Goal**: Self-diagnosis tool + first-run defer retrofit for v10-07 pattern miner + pinned 2-axis semantic.

**Capacity**: 11pt (3 stories)
**Status**: ACTIVE (opened 2026-05-12)
**Series**: [v14-series-plan.md](../v14-series-plan.md)

## Stories

| ID | Title | Points | Hermes source |
|----|-------|--------|---------------|
| S14-03-01 | `aegis-dump` redacted setup summary | 3 | `hermes dump` |
| S14-03-02 | First-run defer retrofit for v10-07 pattern miner | 5 | `agent/curator.py:should_run_now()` |
| S14-03-03 | Pinned-skill 2-axis semantic | 3 | `tools/skill_manager_tool.py:_pinned_guard` |

## Audit findings (pre-execution)

- `tools/aegis-pattern-mine/mine.mjs` exists, no defer pattern, no `--auto` flag → full retrofit needed
- `tools/aegis-instinct-promote.sh` has `cmd_create` / `cmd_activate` / `validate_id` → extend with `--pin-axis` flag on pin command (need to find pin command)
- `tools/aegis-instinct-auto-reinforce.sh` is single-purpose → add pin-axis check before promoting changes
- No existing `tools/aegis-skill-pin.sh` → new file
