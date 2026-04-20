# Evolved Patterns (Proven)
> Patterns that appeared 3+ times and are auto-applied.
> Promoted from auto-learned.md by the Auto-Learn Protocol.

## P-001: Sentinel Markers for Auto-Managed File Blocks

**Evidence**: 3+ occurrences in v9 dogfood
- tools/aegis-migrate-consolidate.sh uses `<<< AEGIS-V9-START >>>` / `<<< AEGIS-V9-END >>>`
- Loki review flagged comment-regex as fragile (Critical #5)
- Pattern adopted across all auto-managed file edits in v9

**Pattern**: When auto-editing a block inside a user-editable file (`.gitignore`, `.env`, etc.), delimit with sentinel markers, not comment-regex matching.

**Rationale**: User can remove comments while keeping content; sentinels survive edits.

**Application**: All v9 file managers (gitignore tool, plugin context injection, etc.) use sentinels.

---

## P-002: File-System as Source of Truth (memory tool = cache)

**Evidence**: 3+ occurrences
- ADR-002 in v9 plan (file = authoritative)
- Nick Fury Decision 2 post-Loki review
- AEGIS_v9_UPGRADE_PLAN itself stored as file (not in memory tool)

**Pattern**: When integrating external persistence (memory_20250818, KV stores), designate file system as source of truth. External services = read-through cache.

**Rationale**: File system is stable substrate independent of API changes. Files diff/git-track.

**Application**: All Tier 1 brain operations write file first, cache second. On divergence, file wins.

---

## P-003: Master Brain Routing (Single Decision Authority)

**Evidence**: 100+ occurrences across v8 sessions
- Promoted instinct: route-questions-through-nick-fury (confidence 1.0)
- Eliminates agent confusion over who to ask
- v9 dogfood: Nick Fury made 5 decisions with zero human escalation

**Pattern**: All non-Fury agents route questions through Nick Fury; Nick Fury is the single decision point with 4-category escalation to human.

**Rationale**: Prevents N agents asking N variations of the same question.

**Application**: Master Brain Protocol enforced via instinct + agent prompts.

---

## P-004: 3-Tier Model Routing (Cost-Optimized Quality)

**Evidence**: 3+ sessions
- Opus for strategy (Nick Fury, Iron Man, Captain America, Loki)
- Sonnet for implementation (Spider-Man, Black Panther, Thor, War Machine)
- Haiku for scanning (Beast, Vision, Coulson, Songbird)
- Reported 80% cost reduction in CLAUDE_lessons.md P002

**Pattern**: "Haiku gathers, Opus synthesizes" -- assign model tier by role, not by file size.

**Rationale**: Strategy decisions need reasoning; data collection doesn't.

**Application**: All 13 agents have fixed tier in CLAUDE_agents.md.

---

## P-005: Adversarial Review Before Implementation

**Evidence**: 3+ proven outcomes
- Loki caught 9 critical issues in v9 plan v3 that Iron Man missed
- v8 retrospectives show 80% issue catch rate before code (P003 in lessons)
- Loki review = required gate before BLOCK 0 closes

**Pattern**: Spawn Loki adversarial review BEFORE building, not after.

**Rationale**: Cost of issue at design = 1x; cost at implementation = 10x; cost in production = 100x.

**Application**: AEGIS workflow: Iron Man drafts → Loki challenges → revise → build.

---

## P-006: Dogfood on Framework Repo Before Shipping

**Evidence**: 3+ occurrences
- v9 dogfood found 60 stale references that paper review missed
- v8 ECC pattern adoption tested on AEGIS-Team itself first
- Karpathy wiki pattern validated via dogfood before docs

**Pattern**: Apply infrastructure changes to framework's own repo before shipping to users.

**Rationale**: Integration issues only surface in real runs. Cost of one extra session vs cost of bad release.

**Application**: All v9 sprint outputs tested on AEGIS-Team before plugin packaging.

---

## P-007: Atomic Commits Per Logical Unit

**Evidence**: 5+ sessions
- v9 dogfood: 5 commits, each independently revertable
- Sprint 1: 7 tasks, 1 commit (atomic sprint)
- Pattern in CLAUDE_safety.md G-3

**Pattern**: One commit per logical change unit (task, fix, refactor). Avoid mega-commits.

**Rationale**: Easy revert, clear history, parallel review.

**Application**: Sprint commits + per-fix commits; avoid amend; multi-task only when truly atomic.

---

## P-008: Hook-Based Enforcement Over Markdown Documentation

**Evidence**: 3+ confirmations
- guard-write.sh blocked our own .claude/settings.json edit (working as designed)
- guard-bash.sh enforces git push --force ban
- Loki review: "elaborate safety theater" without hooks = paper safety

**Pattern**: Critical safety rules MUST have hook enforcement, not just CLAUDE_safety.md docs.

**Rationale**: Markdown is read by humans; hooks are enforced by machine.

**Application**: v9 S1-04 hardens settings; S5-04 worktree merge protocol; S9-03 conflict resolution.

---

## P-009: Progressive Disclosure (Load-on-Demand)

**Evidence**: 3+ patterns
- Resonance files restored context in 30s vs 5min replay (P005 in lessons)
- ToolSearch deferred tools (planned S6-02)
- Skills load on trigger match, not preload

**Pattern**: Load only what's needed for current task. Defer everything else until trigger fires.

**Rationale**: Context window is finite; preload bloats it.

**Application**: Reference files loaded on-demand; agents loaded on spawn; skills triggered.

---

## P-010: Kanban Symlink for Active Sprint

**Evidence**: 3+ sessions
- `.aegis/brain/sprints/current/` symlink convention
- v8 sprint-1/2/3 all used this pattern
- v9 sprint-v9-01 continues pattern

**Pattern**: `current/` symlink always points to active sprint folder. Updated on sprint transition.

**Rationale**: Stable path for tooling that needs "latest" without knowing sprint number.

**Application**: aegis-sprint commands maintain symlink; CI/dashboards reference it.
