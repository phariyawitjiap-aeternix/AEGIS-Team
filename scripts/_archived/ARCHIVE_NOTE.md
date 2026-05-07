---
archived_at: 2026-05-07
archived_by: sprint-v13-01-phase-a
---

# Archived Scripts

## `aegis-migrate-v9.sh` (archived 2026-05-07)

Umbrella migration script for v8 → v9 transition (sprint-v9 era). Calls `tools/aegis-claude-md-lift.sh` which was archived in the same sprint as a confirmed-dead tool.

The v8 → v9 migration completed across all known AEGIS deployments long before this archive. No active project still has a v8-shape install, so this script has no live consumer.

If a v8 install ever surfaces, revive both this script AND `tools/_archived/aegis-claude-md-lift.sh` together (`git log --follow` preserves the relationship).

For active migration patterns, see [`scripts/aegis-migrate-consolidate.sh`](../aegis-migrate-consolidate.sh) (referenced from CLAUDE.md).
