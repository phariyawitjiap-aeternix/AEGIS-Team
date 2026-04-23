---
date: 2026-04-20
category: workflow
confidence: high
status: consolidated
merged_from:
  - 2026-04-20_subagent-tool-availability.md
  - 2026-04-20_verify-primitives-before-speccing.md
---

# Platform Capability Verification Protocol

## Context

Specs written against aspirational platform capabilities fail silently at implementation time. Two specific failure modes surfaced in sprint v9-04 and v9-06:

1. **Subagent tool availability**: Sprint v9-04's `memory-tool-integration.md` spec assumed `memory_20250818` was available in Nick Fury's agent toolkit. It's available to the main orchestrator but not to subagents spawned via `Agent()`. Nick Fury discovered the gap during wiring, forcing a deferred spec.

2. **Non-existent platform primitives**: Sprint v9-06's `schedule-toolsearch-consolidation.md` spec depended on:
   - `ScheduleWakeup(...)` callable from a hook (doesn't exist — ScheduleWakeup only runs in `/loop dynamic` mode; hooks are subprocesses with no tool-use API)
   - `.claude/settings.json` keys `tools.deferred` and `tools.always_load` (don't exist — settings schema supports only `env`, `hooks`, `permissions`, `skipDangerousModePermissionPrompt`)

Both were discovered in 20-minute verification passes. They would have cost multiple sessions of broken implementation otherwise. This is the third consecutive session where "dogfooding reveals it" (per evolved-patterns P-006).

## Lesson: Verify Primitives Before Speccing

Before writing a spec that depends on a platform capability, **prove the capability exists and behaves as expected**. Do not assume API contracts or config keys without verification.

### Verification Checklist

**For tool availability (subagent context)**:

1. Identify the tool required (e.g., `memory_20250818`, `mcp__slack__send_message`).
2. Read the **agent definition file** (e.g., `.claude/agents/nick-fury.md`) and check the `tools:` frontmatter.
3. If the tool is not listed, the spec must either:
   - (a) Add it to the agent's tools frontmatter (may require SDK changes),
   - (b) Reassign the work to the main agent/orchestrator, or
   - (c) Use a between-agent handoff (main agent calls tool on subagent's behalf, subagent handles result).
4. If the tool IS listed, verify it's not deferred or conditional (check `.claude/settings.json` and agent instantiation code).

**For platform settings and API keys**:

1. Load the current `.claude/settings.json` and search for similar keys to understand the schema.
2. Consult the platform's docs (Claude Code guide, SDK reference) for the exact key names and supported values.
3. If neither source shows the key, it's aspirational — do not spec against it.
4. When in doubt, test in a short standalone script or REPL before committing the spec.

**For hook integration points**:

1. Remember: **Hooks are subprocesses with no tool-use API.** They cannot call `Agent()`, `CronCreate()`, `ScheduleWakeup()`, or any other tool.
2. A hook can:
   - Read/write files
   - Read environment variables
   - Emit structured JSON (the harness can parse and act on it)
   - Call Bash commands
3. Any spec claiming "hook triggers X tool" is broken. Redesign to: hook writes a signal file or JSON, main agent polls or reacts on next invocation.

### Application: Pre-Flight Spec Review

When reviewing a spec (yours or inherited):

1. **Spend 5 minutes on primitive verification** before budgeting implementation time.
2. For each "the system does X" claim, ask: "Which API/config/hook does X, and does it actually work that way?"
3. If any answer is hand-wavy, add a **Verification step** to the spec before approval:
   - "Verify `ScheduleWakeup` callable from post-task hook" (likely to fail)
   - "Check if `.claude/settings.json` supports `tools.deferred` key" (likely to fail)
   - "Confirm `memory_20250818` in Nick Fury's agent tools" (check before wiring)

### Application: Spec Template Additions

Every `.claude/references/*.md` spec should include a **"Primitives & Dependencies"** section:

```markdown
## Primitives & Dependencies

| Item | Type | Usage | Verified? |
|------|------|-------|-----------|
| `memory_20250818` | Tool | Nick Fury brain_write() | ✅ Check agent.md tools list |
| `.claude/settings.json` keys | Config | Deferred tool loading | ❌ Keys don't exist; use file-based signals instead |
| `ScheduleWakeup` from hooks | API | Auto-trigger /aegis-distill | ❌ Hooks have no tool-use API; redesign as signal file |

```

Each row documents the primitive, what it's used for, and whether it was verified to exist and work as specified.

### Application: Pre-Flight Script

Consider a `tools/verify-spec-primitives.sh` script that:

1. Grep-searches a spec file for tool names and config keys.
2. Cross-references against `.claude/agents/*.md` (for tool availability) and `.claude/settings.json` (for config keys).
3. Warns on mismatches (tool not in agent's tools list, config key not in settings schema).
4. Can be run as a pre-commit gate or as a spec-review step.

Example:
```bash
tools/verify-spec-primitives.sh .claude/references/my-spec.md
# Output: ❌ Tool 'memory_20250818' not in nick-fury.md tools list
#         ❌ Key 'tools.deferred' not in .claude/settings.json schema
```

## Audit Trail: v9 Dogfooding Failures

| Spec | Primitive | Type | Expected | Reality | Impact | Fix |
|------|-----------|------|----------|---------|--------|-----|
| memory-tool-integration (v9-04) | `memory_20250818` in Nick Fury | Tool | Available in agent toolkit | Not in `tools:` list | Deferred 1 session | Documented blocker |
| schedule-toolsearch-consolidation (v9-06) | `ScheduleWakeup` from post-task hook | API | Hook can trigger tool | Hooks have no tool-use API | Blocked implementation | Redesigned as file signal |
| schedule-toolsearch-consolidation (v9-06) | `tools.deferred` in settings | Config | Config key exists | Key doesn't exist in schema | Blocked implementation | Deferred to API-level tools |

All three would have been caught by the 5-minute primitive-verification checklist before spec approval.

## Forward-Looking: Capability Verification Infrastructure

As AEGIS adopts new SDKs, MCPs, and platform features:

1. **Pre-spec audit**: Before marking a spec "ready to implement," run the primitive-verification checklist. It costs 5-10 minutes and saves a session's worth of blocked work.
2. **Schema catalog**: Maintain `.aegis/brain/platform-schemas/` with copies of current schemas (agent tools, settings keys, hook capabilities, tool descriptions). Update quarterly.
3. **Blocker database**: When verification finds a missing primitive, log it as a "blocker for spec X" in `.aegis/brain/blockers/`. Reference it in the spec so next reader knows why a feature is deferred.
4. **Test-before-spec discipline**: For any "new platform feature" introduced to AEGIS, write a 10-line test that verifies it exists and works before committing to a spec that uses it.

This transforms platform assumptions from implicit (and wrong) into explicit (and verified).

