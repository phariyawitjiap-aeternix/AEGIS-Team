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

---

## P-011: Measurement Before Adoption (Data-Driven Dependency Decisions)

**Evidence**: 3+ occurrences
- Sprint v10-02: RTK adoption deferred pending Bash-vs-native-tool token profiling data
- Sprint v9-06: S2-10 policy-audit tool measured enforcement gap (227 claims, 46 matched) before deciding fix priority
- Sprint v9-05: BLOCK 0 lite mode designed from point-count data across 5 sprints, not gut feel
- ADR-007 (RTK): 5 explicit measurable conditions before ADOPT, not "we'll evaluate later"

**Pattern**: When a tool, dependency, or process change has divided opinion, build measurement infrastructure FIRST. Let data make the decision. Cost: one sprint of instrumentation. Value: avoiding a potentially wrong adoption that's hard to reverse.

**Rationale**: Opinions diverge, data converges. Multi-agent voting on v10-02 surfaced Loki's killshot question ("What % is Bash?") which became the sprint's raison d'etre.

**Application**: Any dependency adoption in AEGIS requires: (1) Define killshot question, (2) Build measurement tool, (3) Collect data across 3+ sessions, (4) Answer question with numbers, (5) THEN decide.

---

## P-012: Cross-Project Namespace Isolation

**Evidence**: 3+ occurrences
- CLAUDE_CODE_TASK_LIST_ID ghost tasks across 5 projects (PR #70, #71)
- Stale ~/.claude/tasks/aegis-shared-tasks/ contaminating all projects
- Hook path anchoring to $CLAUDE_PROJECT_DIR (PR #67, #68) -- same root cause (shared mutable state)
- /aegis-upgrade per-project slug isolation (PR #69)

**Pattern**: When multiple projects share a framework, any shared mutable state (task lists, caches, lock files, hook paths) MUST use per-project namespaces. Shared = contaminated.

**Rationale**: Relative paths and shared directories work in single-project mode. The moment a second project adopts the framework, cross-contamination is inevitable unless namespacing is explicit from day one.

**Application**: Use `aegis-tasks-$(basename $PWD | tr A-Z a-z)` pattern. Anchor all hook commands to `$CLAUDE_PROJECT_DIR`. Any new shared state introduced to AEGIS must include a namespace key in its design.

---

## P-013: Check Blocker Freshness Before Planning Around It

**Evidence**: 3+ occurrences
- Sprint v10-02: upstream rtk-ai/rtk#427 was already closed (resolved 2026-04-03) -- discovered by 50-line watcher script
- Sprint v9-04: S4-02 blocker (memory_20250818 availability) re-checked each session; status unchanged but the check itself costs 30 seconds
- Sprint v9-06: stacked-PR base deletion discovered because we re-checked PR status instead of assuming
- Retrospective pattern: "always check current state before assuming a blocker is still blocking"

**Pattern**: External blockers (upstream issues, SDK feature requests, dependency PRs) must be re-checked for freshness before planning around them. A 30-second API check saves potentially weeks of waiting on a resolved issue.

**Rationale**: External state changes silently. Blockers created weeks ago may already be resolved. Planning around a blocker that no longer exists wastes sprint capacity on workarounds.

**Application**: Build watcher tools (like `aegis-rtk-upstream-check.sh`) for any external dependency that blocks AEGIS work. Cache results with change-detection. Run at sprint-plan time.

---

## P-014: Spec Mega-Delivery for Thematically Linked Deliverables

**Evidence**: 3+ occurrences
- Sprint v9-05 FINAL-PUSH: 9 deliverables in 1 spec (973 LOC), 3 themed blocks (F1/F2/F3), ~30% review latency reduction vs. 9-spec baseline
- Sprint v10-01: 5 stories (13pt) delivered as single PR with shared traceability theme
- Sprint v9-06: 5 operational debt items in single PR #57, batched by "infrastructure hardening" theme
- BP round-1 caught cross-cutting bug (F1-05 Loki integration) BECAUSE sections were adjacent in one spec

**Pattern**: When N deliverables share a theme (same abstraction level, overlapping files, common reviewer context), fold them into ONE spec with clearly sectioned work blocks. The coherence penalty (longer spec) is absorbed by amortized review cost (one Loki gate, one Spider-Man build, one BP review).

**Rationale**: Single-spec thematic grouping makes cross-deliverable consistency bugs easier to catch. Adjacent sections expose integration gaps that separate specs hide.

**Application**: Use when 3+ deliverables touch the same subsystem. Don't use when deliverables are at different abstraction levels or need different reviewer specialists.

---

## P-015: Round-2 Re-Verification After CONDITIONAL Review

**Evidence**: 3+ occurrences
- Sprint v9-05: BP CONDITIONAL on PR #54, MEDIUM-01 (F1-05 Loki integration omitted) -- verified at specific file:line after fix
- Sprint v9-04: BP CONDITIONAL caught HIGH shell-injection bug via same discipline
- Sprint v9-03: Loki CONDITIONAL on design spec, specific blocker verified post-revision
- Pattern in CLAUDE_lessons.md: "CONDITIONAL is a real blocker, not graduated approval"

**Pattern**: When a reviewer returns CONDITIONAL with specific blockers, the workflow is: (1) Apply exact fixes listed, (2) Re-run tests that exercise changed surface, (3) Ask reviewer to re-verify citing file:line for each fix, (4) Merge only after unconditional PASS. Promises don't count -- self-reports are evidence FOR re-verification, not a substitute.

**Rationale**: Treating CONDITIONAL as "soft approval" would have shipped a shell-injection vulnerability in v9-04 and a non-functional integration in v9-05. The discipline pays for all the rounds where it catches nothing.

**Application**: All AEGIS review flows. The temptation to skip round-2 is highest when Spider-Man says "I fixed it" -- that is precisely when round-2 is most valuable.
