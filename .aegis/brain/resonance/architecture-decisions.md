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
