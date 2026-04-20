---
date: 2026-04-20
category: workflow
confidence: high
---
# Verify platform primitives exist before speccing features against them

## Context

Sprint v9-06's spec (`schedule-toolsearch-consolidation.md`) was written
against two primitives that turned out to not exist as assumed:

1. **`ScheduleWakeup` from a hook**: the spec had a post-task hook call
   `ScheduleWakeup(...)` to auto-trigger `/aegis-distill`. But
   `ScheduleWakeup` only runs in `/loop dynamic` mode, and hooks have no
   access to the tool-use API in any mode. The integration point didn't
   exist.
2. **`tools.deferred` / `tools.always_load` in `.claude/settings.json`**:
   the spec claimed these keys would let us defer slash commands and save
   ~4.8k tokens per session. Claude Code's settings schema supports only
   `env`, `hooks`, `permissions`, `skipDangerousModePermissionPrompt`.
   There is no `tools` key. Deferred loading in Claude Code applies to
   API-level tools (MCP + built-ins), not slash commands.

Both findings surfaced in a 20-minute verification pass (one
WebFetch-style research subagent + one inspection of the current
settings.json). They would have cost multiple sessions of broken
implementation work otherwise.

## Lesson

Before writing a spec that depends on a platform capability, prove the
capability exists. Specifically:

- **For tools**: load the schema and read the description. Tool
  descriptions are the contract; if the spec contradicts the description
  (e.g. "ScheduleWakeup fires outside /loop"), the spec is wrong.
- **For settings / config keys**: check the current `settings.json` for
  similar keys, then consult the platform's docs. If neither shows the
  key, it's aspirational.
- **For hook integration points**: remember that hooks are subprocesses
  with no tool-use API. A hook can write files, read env, and emit
  JSON; it cannot call `Agent`, `CronCreate`, `ScheduleWakeup`, or any
  other tool. Any "hook triggers X tool" design is broken.

## Application

- **When reviewing a spec**: do a 5-minute primitive check before
  budgeting implementation time. Skim each "the system does X" claim and
  ask: "which API call does X, and does it actually behave that way?"
  If any answer is hand-wavy, flag as a verification step before spec
  approval.
- **When writing a spec**: include a "Primitives used" section that
  names each API call or config key the spec depends on, with a one-line
  verification note ("confirmed via tool schema", "confirmed via
  settings docs", etc.).
- **When you inherit a spec** (like v9-06): do the primitive check as
  the first task, before any implementation. If it fails, the spec
  needs a rewrite -- do that first, then implement against the
  corrected version.

This practice would have caught ADR-004's "env-stripping for subagents"
requirement as a mechanism-not-property issue (another session's
learning: `2026-04-20_hook-authorization-one-shot-state.md`). The same
habit catches both.
