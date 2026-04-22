---
date: 2026-04-22
category: architecture
confidence: high
---
# MBP / No-Pause-For-Human Needs Enforcement at Four Distinct Layers

## Context

Initial MBP fix added the protocol to 9 agent prompts and a PreToolUse hook on `AskUserQuestion`. Thought that was complete. User then observed the SAME pattern at a different layer: commands like `/aegis-start` ending with "run retro? handoff? start?" menus.

The "ask human" violation surfaces at multiple different layers because the model reaches decision points through different paths. Fixing one layer leaves the others exposed.

## Lesson

MBP (and any rule about "don't ask the user") must be enforced at **four layers**, because agents and sessions arrive at "ask?" through different routes:

| Layer | Where it fires | Enforcement mechanism |
|---|---|---|
| **Prompt** | Subagent reading its own prompt | MBP section + MUST-NOT constraint in every agent `.md` |
| **Tool** | Any code calling `AskUserQuestion` | PreToolUse hook (`guard-ask-user.sh`) blocks non-Nick-Fury callers |
| **Command boundary** | Main orchestrator finishing a `/aegis-*` command | Continuation Protocol footer in every command `.md` + `command-chain.md` reference |
| **Session end** | Main orchestrator ending a turn after work is "done" | Stop hook scans last assistant text for option-menu + open-question pattern |

Missing any one layer leaves a failure mode:
- No prompt layer → subagent default-asks mid-task
- No tool layer → agent bypasses prompt weighting and calls `AskUserQuestion` directly
- No command-boundary layer → orchestrator finishes command and next turn asks "what next?"
- No session-end layer → option-menu violations in final text go undetected

## Application

- **When designing a "don't do X" rule for agents**: check every surface where X could originate. Prompt ≠ tool ≠ command ≠ session. Fix all four.
- **Priority order for enforcement build-out**: prompt first (it changes behavior at decision time), then tool (hard stop), then command boundary (routes post-completion), then session-end scanner (observability / learning signal).
- **Symptom to layer mapping**: if the violation appears in subagent output → prompt layer; if `AskUserQuestion` is invoked → tool layer; if it appears right after a slash command finishes → command-boundary layer; if the main session's final text has an option menu → session-end layer.
- **Dogfooding check**: after shipping a rule fix, watch for the same symptom in the NEXT session at a DIFFERENT layer. That's how the command-boundary gap surfaced in this session — right after the first fix shipped.
