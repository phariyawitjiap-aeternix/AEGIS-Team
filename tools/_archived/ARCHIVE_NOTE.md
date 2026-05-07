---
archived_at: 2026-05-07
archived_by: sprint-v13-01-phase-a
archived_via: git mv (audit trail preserved in `git log --follow`)
---

# Archived Tools

This directory holds tools that were once part of AEGIS but are no longer used. They are kept for **audit / provenance** rather than active use. Same pattern as `.claude/agents/_archived/` (sprint-v9-06 retiree retirement) and ADR-004 maintainer-mode preservation.

If you need to revive any of these, `git log --follow tools/_archived/<name>.sh` shows the full pre-archive history.

## Archived 2026-05-07 (sprint-v13-01 Phase A)

All 5 had **zero references** in `.claude/settings.json`, `.claude/agents/`, `.claude/commands/`, `skills/`, `tests/`, `tools/` (other than themselves), and root governance docs at the time of archive. Audit performed via direct grep across all reference surfaces — see [`.aegis/brain/sprints/sprint-v13-01-refactor/plan.md`](../../.aegis/brain/sprints/sprint-v13-01-refactor/plan.md) audit findings §1 for methodology.

| Tool | Original purpose | Why archived |
|---|---|---|
| `aegis-apply-mbp-guard.sh` | One-off rollout helper for the MBP-guard settings.json patch (sprint-v10-04 era) | The patch landed in main; the rollout helper is no longer needed. The new pattern (`tools/aegis-brain-graph/settings-patch.md`) is doc-driven, not script-driven. |
| `aegis-claude-md-lift.sh` | One-off migration helper that "lifted" CLAUDE.md content into the v9 `.aegis/brain/` structure | The migration completed in sprint-v9-03 (Brain layer). No new project bootstraps need to "lift" anything. |
| `aegis-nick-fury-loop-harness.sh` | Validation harness for Nick Fury's autonomous loop (sprint-v9-06 / S2-07) | Per ADR-008, Nick Fury is a persona overlay, not a daemon. The loop concept changed; this harness no longer matches the actual runtime model. |
| `aegis-rtk-upstream-check.sh` | RTK readiness check (sprint-v10-02 / v10-03 era) | RTK adoption was explicitly DEFERRED in sprint-v10-03's close (decision recorded in roadmap.md). The check has no live consumer. |
| `aegis-sdk-readiness-check.sh` | SDK readiness checker for v9-07..15 deferred items | All SDK-side items (v9-07..15) remain DEFERRED per `.aegis/brain/sprints/roadmap.md`. The checker has no callers. If they un-defer, revive from this directory. |

## Reviving an archived tool

```bash
git mv tools/_archived/<name>.sh tools/<name>.sh
git commit -m "chore: revive tools/<name>.sh — <reason>"
# Then wire it back into a hook / agent / skill / command as appropriate.
```

## Policy

- Tools land here only after audit confirms zero references in living code
- Tools stay here indefinitely (small file size, large provenance value)
- This directory is NOT in any agent's `tools:` allow-list — agents can't discover or invoke archived tools by accident
- ARCHIVE_NOTE.md is the source of truth for "why was this archived?" — not git log
