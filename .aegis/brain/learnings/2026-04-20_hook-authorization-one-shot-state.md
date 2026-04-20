---
date: 2026-04-20
category: architecture
confidence: high
---
# Hook-based authorization: one-shot state + env-set blocking beats env-stripping

## Context

ADR-004 Phase 2 implementation needed to grant time-bound, one-shot write
permissions through `guard-write.sh`. The ADR originally listed
"non-inheritable (subagents spawned via Agent tool get a clean env, flag
stripped)" as a required property.

The design question: how do we actually strip env from a subagent that
Claude Code spawns in-process?

Answer: we can't -- not from a hook. Subagents inherit the parent Claude
Code process's env; hooks are subprocesses whose env mutations die with
them. `unsetenv` in a hook doesn't propagate upward.

## Lesson

When an ADR asks for "env-stripping for subagents", read that as a
*property* ("subagents can't use this flag to write"), not a *mechanism*
("literally strip the env variable"). Then design the cheapest mechanism
that delivers the property.

For ADR-004, two-component equivalence works:

1. **One-shot consume** (state file per nonce). First matching write consumes
   the grant; every subsequent write, from main or subagent, finds the
   `.used` marker and is denied. The subagent *can't* inherit a live grant
   if the parent used it first.

2. **Guard-bash env-set block**. Agent-originated bash commands that try to
   `export AEGIS_MAINTAINER_MODE=` (or `AEGIS_...=val cmd`, or `env AEGIS_...=`)
   are hard-blocked. So a subagent can't self-issue a fresh grant either.

Together: a subagent cannot `(a)` use an existing grant if the parent
consumed it, `(b)` re-use a consumed grant, or `(c)` mint a new grant.
That's functionally equivalent to env-stripping, verifiable in a test
matrix (23/23 green), and implementable entirely in bash.

## Application

- **When an ADR names a mechanism you can't implement**: don't fake it.
  Derive the *property* the ADR was buying, then find an alternate
  mechanism. Document the substitution explicitly in the ADR's
  "Implementation" / "Known limitation" section so future readers don't
  re-litigate the original.
- **For hook-based security** generally: prefer external observable state
  (files, sockets, logs) over runtime env state -- hooks can't mutate
  parent runtime state, but they can read/write files that subsequent
  hook invocations will see.
- **For one-shot tokens**: `<nonce>.used` marker files are a simple,
  filesystem-backed consumption record. Cheap to create, cheap to check,
  trivially recoverable (delete to reset), and race-free at the granularity
  of "one hook invocation per tool call".
