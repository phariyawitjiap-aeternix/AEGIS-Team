# Sprint v15-07 — Close

**Status**: CLOSED 2026-05-14
**Velocity**: 3/3 pt

## Delivered

### 1. `.claude/commands/aegis-start.md` Step 4b-ENFORCE
Added "How to actually 'Run /aegis-X NOW' — slash-command chaining protocol" section explaining that slash commands can't be invoked mid-flow; executor must Read + execute verbatim. Anti-pattern "I'll create kanban.md inline" explicitly banned.

### 2. `.claude/hooks/session-start.sh` sprint-gate banner
Bordered banner emits on session-start when `.aegis/brain/sprints/` has no `sprint-*` subdirectory. Instructions tell Nick Fury exactly which file to Read and which subcommand to execute. Logs to `activity.log` for audit trail.

## Tested
- 57/57 PASS
- Banner fires on empty-sprints synthetic target
- Banner suppressed when sprint-v1-test/ exists

## Why this matters

Without this fix: Nick Fury could `/aegis-start` in a project like Auto-Affi (which has no sprint dirs), then "satisfy" BLOCK 0D by writing a kanban.md inline — skipping the ISO 29110 work-product generation that Coulson runs in parallel. Audit trail had holes.

With this fix: the gap is closed two ways. The aegis-start.md doc tells the executor explicitly; the session-start hook fires a visible banner so neither human nor Nick Fury can miss it.

## Re-evaluate when

- Empirical test: run /aegis-start in a fresh project (no sprint dirs). Verify kanban.md AND plan.md AND ISO 29110 work products are all generated (not just kanban.md alone).
- If the banner is ignored: escalate to a true hook gate that blocks Edit/Write to `.aegis/brain/tasks/` until kanban.md exists.
