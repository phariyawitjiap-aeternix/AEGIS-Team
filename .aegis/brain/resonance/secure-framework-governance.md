---
date: 2026-04-25
category: architecture
confidence: high
status: consolidated
merged_from:
  - 2026-04-20_hook-authorization-one-shot-state.md
  - 2026-04-20_self-enforcement-override-channel.md
---

# Secure Framework Governance: Self-Protection with Principled Override

## Context

AEGIS's `guard-write.sh` hook protects framework files (`.claude/hooks/`, `.claude/agents/`,
`.claude/settings.json`) from agent writes. This is deliberate self-protection -- agents
should not rewrite the rules that govern them. But self-protection that can never be turned
off becomes self-ossification. Two complementary lessons emerged from v9 dogfooding:

1. **The override mechanism**: `AEGIS_MAINTAINER_MODE` env flag (ADR-004) provides a
   scoped, time-bounded, audited override for framework self-protection.

2. **The implementation constraint**: Hooks are subprocesses whose env mutations die
   with them. You cannot "strip" an env var from a subagent that inherits the parent
   Claude Code process's env. The ADR's original "env-stripping for subagents" is a
   property, not a mechanism.

## Lesson 1: Property vs. Mechanism in Security Design

When an ADR names a mechanism you cannot implement, do not fake it. Instead:

1. Derive the **property** the ADR was buying (e.g., "subagents cannot use this flag to write")
2. Find an alternate mechanism that delivers the same property
3. Document the substitution explicitly in the ADR so future readers don't re-litigate

For ADR-004, two-component equivalence delivers the property:

- **One-shot consume**: State file per nonce. First matching write consumes the grant;
  every subsequent write finds the `.used` marker and is denied. Subagents cannot inherit
  a live grant if the parent used it first.
- **Guard-bash env-set block**: Agent-originated bash commands that try to
  `export AEGIS_MAINTAINER_MODE=` are hard-blocked. Subagents cannot self-issue a fresh grant.

Together: a subagent cannot (a) use an existing grant if parent consumed it, (b) re-use a
consumed grant, or (c) mint a new grant. Functionally equivalent to env-stripping.

## Lesson 2: Self-Protection Needs a Principled Override Channel

The right shape for framework self-governance is:

| Property | Why |
|----------|-----|
| **Scoped** | Only applies to specific paths the user explicitly names |
| **Time-bounded** | Effective for a single tool call or session, not persistent |
| **User-invoked** | Set by the human, never self-granted by an agent |
| **Audited** | Every write under override is logged with authorizing command and path |
| **Non-inheritable** | Subagents do NOT inherit the flag (via one-shot + env-set block) |

Without this channel, every framework evolution requires "stage in tools/ with a manual apply step."
Accumulated manual steps are a drift risk -- each one is a chance for the framework to rot.

## Application

### For Hook-Based Security Generally

Prefer external observable state (files, sockets, logs) over runtime env state. Hooks cannot
mutate parent runtime state, but they can read/write files that subsequent hook invocations
will see.

### For One-Shot Tokens

`<nonce>.used` marker files are a simple, filesystem-backed consumption record. Cheap to
create, cheap to check, trivially recoverable (delete to reset), and race-free at the
granularity of "one hook invocation per tool call."

### For Framework Updates During Sessions

When a framework update is blocked by guard-write:
1. Check if `AEGIS_MAINTAINER_MODE` can be activated for this change
2. If not, surface the change clearly as "framework self-protection triggered; apply X
   manually between sessions"
3. Enumerate pending manual steps at session end so they don't accumulate
4. Add a "pending framework updates" check to `/aegis-start`

### Guard-Bash Hardening

`guard-bash.sh` should explicitly block patterns like:
- `export AEGIS_MAINTAINER_MODE=`
- `AEGIS_MAINTAINER_MODE=val cmd`
- `env AEGIS_MAINTAINER_MODE= ...`

This prevents any agent from self-escalating to maintainer mode.
