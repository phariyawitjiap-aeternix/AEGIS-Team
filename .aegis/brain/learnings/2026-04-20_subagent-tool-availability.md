---
date: 2026-04-20
category: architecture
confidence: high
---
# Subagent Tool Availability Is a Hard Constraint That Specs Must Check

## Context

Sprint v9-04 included S4-02: wire `memory_20250818` into Nick Fury's brain_write() helper so the cache layer stays in sync with the file layer. The spec (`.claude/references/memory-tool-integration.md`) assumed `memory_20250818` was accessible from the Nick Fury agent runtime.

When Nick Fury tried to wire it, he found the tool is NOT in his agent's tools list. It's available to the main orchestrator (me) but not to subagents spawned via the Agent tool. He documented the blocker honestly in the integration guide and deferred rather than faking the wiring.

This is the third consecutive session where "dogfooding reveals it" (per P-006 in evolved-patterns). Same pattern played out with `isolation: "worktree"` last session — spec assumed availability, implementation discovered it isn't.

## Lesson

A subagent's tool set is whatever appears in its agent definition's `tools:` frontmatter (plus anything the harness grants by default). It is NOT the same as the main agent's tool set. Specs that assume "this agent will call tool X" need to verify X is actually in that agent's toolkit before committing to the design.

Memory tool (`memory_20250818`), `mcp__*` tools, and anything added via ToolSearch are the most likely gotchas — these are often main-agent-only or deferred/on-demand.

## Application

- Before writing any spec that requires a subagent to call a specific tool:
  1. Read the agent's definition file (e.g., `.claude/agents/<name>.md`).
  2. Check the `tools:` frontmatter list.
  3. If the required tool isn't listed, the spec must either: (a) add it to the agent's tools, (b) reassign the work to the main agent, or (c) use a between-agent handoff (main calls the tool on subagent's behalf).
- Add a "Tool Availability" section to every `.claude/references/*.md` spec template: list every tool the design uses and which agent calls it.
- Consider a pre-flight script that grep-checks spec files against agent definitions and warns on mismatches.
- When a subagent reports "tool not available," prefer documenting the blocker over hacking around it — the blocker is a real architectural signal.
