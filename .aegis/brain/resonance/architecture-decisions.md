# Architecture Decision Records

> Accumulated from /aegis-team-debate sessions and retrospectives.
> Each decision is immutable once recorded. New decisions may supersede old ones.

---

## ADR-001: All-in Plugin Distribution + 6-Month curl|bash Bridge

**Date**: 2026-04-19
**Status**: Accepted (Nick Fury Decision 1, post-Loki review)
**Source**: AEGIS_v9_UPGRADE_PLAN.md ADR-001
**Context**: v8.x distribution via `bash <(curl -sL ...)` had supply chain risk + version drift across 4 files
**Decision**: AEGIS v9 distributes as Claude Code Plugin (primary). curl|bash supported during 6-month bridge: GA → warning → error → removed.
**Consequences (+)**: Signed releases, auto-update, single config, Claude Code-aligned
**Consequences (−)**: Air-gapped users need offline mode; legacy users must migrate
**Alternatives**: 12-month bridge (rejected: too long), all-in immediate (rejected: breaks v8 users), keep curl|bash forever (rejected: maintenance burden)
**Supersedes**: v8.x curl|bash-only distribution
**Owner**: Architecture (Iron Man) + Operations (Thor)

---

## ADR-002: File System as Source of Truth (memory_20250818 = Cache)

**Date**: 2026-04-19
**Status**: Accepted (Nick Fury Decision 2, post-Loki review)
**Source**: AEGIS_v9_UPGRADE_PLAN.md ADR-002 (revised in v3.1)
**Context**: Plan v3.0 had memory tool + file as dual-write peers; Loki flagged inconsistency risk
**Decision**: File system is authoritative. memory_20250818 is read-through cache. On divergence, file wins. Cache re-syncs from file at session start.
**Consequences (+)**: Single truth, stable substrate, diffable, git-trackable
**Consequences (−)**: Cache may serve slightly stale data; sync overhead at session start
**Alternatives**: memory tool = truth (rejected: API may change), dual-write peers (rejected: consistency hell), no cache (rejected: latency)
**Supersedes**: Implicit dual-write assumption
**Owner**: Brain Architecture (Iron Man)

---

## ADR-003: Tier Conflict Resolution Priority -- Tier 1 > Tier 3 > Tier 2

**Date**: 2026-04-19
**Status**: Accepted (Nick Fury Decision 3, preserves promoted instinct)
**Source**: AEGIS_v9_UPGRADE_PLAN.md ADR-006 (3-Tier Brain Architecture)
**Context**: 3-tier brain (Project / User / Team) needed conflict resolution rule. Loki noted conflict with promoted instinct "agents never ask human"
**Decision**: When tiers conflict, Nick Fury auto-resolves via priority: Tier 1 (Project) > Tier 3 (Team) > Tier 2 (User). Logs all resolutions to `.aegis/brain/logs/conflict-resolution.log`. NO user prompt (preserves Master Brain Protocol).
**Consequences (+)**: Project context wins (most specific); team conventions override individual prefs; no agent-asks-human violation
**Consequences (−)**: User preferences may be silently overridden in project context (acceptable)
**Alternatives**: User prompted (rejected: violates promoted instinct), timestamp wins (rejected: stale conventions could override fresh decisions), Tier 2 > Tier 3 (rejected: team conventions should prevail over individual)
**Supersedes**: S9-03 acceptance criteria "user prompted to choose"
**Owner**: Brain Governance (Nick Fury + Iron Man)

---

## ADR-004: AEGIS_MAINTAINER_MODE -- Principled Override Channel for Guard-Write

**Date**: 2026-04-20
**Status**: Proposed
**Source**: Retrospective 2026-04/20/13.03 → learning `2026-04-20_self-enforcement-override-channel.md`
**Context**: `guard-write.sh` correctly blocks agent writes to `.claude/` (hooks, agents, settings) to prevent self-modification attacks. But this has now blocked *legitimate* framework evolution three consecutive sessions: settings hardening (2026-04-20 AM), hook install (2026-04-20 PM), spider-man agent update (2026-04-20 PM). Each time the workaround was "stage in `tools/` + manual apply-*.sh between sessions." Accumulated manual steps drift and rot; the pattern defeats the purpose of having agents maintain the framework.
**Decision**: Introduce an env-flag override channel — `AEGIS_MAINTAINER_MODE` — that guard-write reads per tool call. When set, writes to a user-specified allowlist of `.claude/` paths are permitted for the next N tool calls, then auto-expires. **Must be:**
- **Scoped**: user names the specific paths (e.g., `AEGIS_MAINTAINER_MODE=".claude/agents/spider-man.md"`). Never a wildcard like `.claude/**`.
- **Time-bounded**: expires after 1 tool call or 60s, whichever first. Never persists across sessions.
- **User-invoked**: set only by the human via explicit `export` in a terminal the human owns. `guard-bash.sh` must block `AEGIS_MAINTAINER_MODE=` patterns in any Agent-tool-originated command.
- **Audited**: every write performed under this flag appends to `.aegis/brain/logs/maintainer-mode.log` with timestamp, authorizing process, resolved path, and diff summary.
- **Non-inheritable**: subagents spawned via Agent tool get a clean env (flag stripped).
**Consequences (+)**: Framework can evolve in-session when explicitly authorized; removes accumulated between-session manual steps; audit trail enables post-hoc review
**Consequences (−)**: Adds complexity to `guard-write.sh`; introduces an attack surface (compromise the env, compromise the framework); subagent env-stripping requires careful implementation; the flag is a foot-gun if users over-scope it (e.g., setting to `.claude/` wholesale)
**Alternatives**:
- Always-off (status quo) — rejected: causes ossification, 3 sessions of accumulated drift already
- Always-on when human present — rejected: no way to distinguish human from agent reliably in a shared shell
- Approval-per-write UI prompt — rejected: Claude Code doesn't expose a native prompt primitive from hooks
- Agent-self-grant with audit — rejected: defeats self-protection; any compromised agent grants itself
- Move framework files outside `.claude/` — rejected: Claude Code expects them there; fighting the platform
**Supersedes**: The implicit "stage in `tools/*.apply-*.sh`" workaround pattern used in Sprints v9-01, v9-04, v9-05
**Owner**: Framework Security (Thor) + Brain Governance (Nick Fury)
**Implementation**: Deferred to a dedicated sprint (v9-XX, not yet scheduled). This ADR records the decision; the implementation will be a new sprint with: (1) `guard-write.sh` flag parsing, (2) expiration/counter state in `.aegis/logs/maintainer-mode.state`, (3) `guard-bash.sh` env-stripping for Agent-tool processes, (4) audit log writer, (5) test matrix covering scope escape, subagent inheritance, expiration, and concurrent flag sets.

---
