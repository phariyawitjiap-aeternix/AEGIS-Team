---
date: 2026-04-20
category: tooling
confidence: medium
---
# Self-Enforcement Needs a Principled Override Channel

## Context

AEGIS's `guard-write.sh` (hook) protects `.claude/hooks/`, `.claude/agents/`, `.claude/settings.json`, and other framework files from agent writes. This is deliberate self-protection — agents should not rewrite the rules that govern them.

The friction: every time AEGIS itself needs to evolve (new hook, new agent definition, new settings hardening), guard-write correctly blocks the write. The workaround each time has been to stage the change in `tools/` with a separate manual "apply" step the user runs between sessions.

Accumulated manual apply steps across 3 sessions:
- Settings hardening (`tools/v9-proposed-settings.json` → `.claude/settings.json`) — DONE
- Session-start hook (`tools/v9-session-start-hook.sh` → `.claude/hooks/session-start.sh`) — DONE this session
- Settings hook wiring (`tools/apply-session-hook-settings.sh`) — PENDING
- Spider-man agent update (`tools/v9-05-spider-man-worktree-guidance.md` → merge into `.claude/agents/spider-man.md`) — PENDING

That's 2 pending steps the user still has to run. Each one is a chance for the framework to drift or rot.

## Lesson

Self-protection that can never be turned off becomes self-ossification. But a bypass that's always on defeats the protection. The right shape is a principled, time-bounded, audited override:

- **Scoped**: only applies to specific paths the user explicitly names.
- **Time-bounded**: effective for a single tool call or session, not persistent.
- **User-invoked**: set by the human, never self-granted by an agent.
- **Audited**: every write performed under override is logged, with the authorizing command and the path written.
- **Non-inheritable**: subagents do NOT inherit the flag from the main agent.

The name "maintainer mode" captures the intent — the user is acting as framework maintainer, not as project user.

## Application

- Propose an ADR: `AEGIS_MAINTAINER_MODE` env flag, readable only by guard-write.sh, set via an explicit bash command (not a memory or setting). When set, guard-write allows writes to a user-specified allowlist of paths under `.claude/` for the next N tool calls, then auto-expires.
- Require every maintainer-mode activation to log: timestamp, user, paths allowed, expiration.
- Subagents MUST NOT be able to set it — `guard-bash.sh` should explicitly block `export AEGIS_MAINTAINER_MODE=` from the Agent tool's environment.
- Until this exists: when a framework update is blocked, surface it clearly to the user as "framework self-protection triggered; apply X manually between sessions" rather than silently pivoting to a staging file. Enumerate pending manual steps at session end so they don't accumulate.
- Add a "pending framework updates" check to `/aegis-start` that lists any `tools/apply-*.sh` scripts that haven't been run.
