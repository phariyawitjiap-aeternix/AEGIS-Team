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

**Date**: 2026-04-20 (Proposed) / 2026-04-20 (Accepted, Phase 2 shipped)
**Status**: Accepted
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
**Implementation**: Shipped 2026-04-20 across two phases.
- **Phase 1 (observation)**: `guard-write.sh` reads the env and logs every invocation to `.aegis/brain/logs/maintainer-mode.log` without changing blocking behavior. Plants the hook without breaking anything.
- **Phase 2 (authorization)**: full token scheme.
  - Token format: `<path>|<nonce>|<expiry-epoch>` issued by `tools/aegis-maintainer-grant.sh` (human runs in their own terminal, `eval`s the output, then launches Claude Code).
  - `guard-write.sh` parses the token, checks expiry (60s TTL), checks one-shot state (`.aegis/brain/state/maintainer-grants/<nonce>.used`), checks the target file matches the granted path, and only then allows the write -- skipping all other blocking categories for that one call. Every decision (allow/deny with reason) is appended to `.aegis/brain/logs/maintainer-mode.log`.
  - `guard-bash.sh` blocks any agent-originated bash that tries to set the flag (`export AEGIS_MAINTAINER_MODE=`, inline `AEGIS_MAINTAINER_MODE=...`, `env AEGIS_MAINTAINER_MODE=`). Read-only references (`echo`, `grep`, `unset`) remain allowed.
  - Helper rejects wildcards, absolute paths, directories, and `..` traversal at issue time.
  - Test matrix: `tools/aegis-maintainer-test.sh` -- 23 assertions covering scope escape, self-grant block, read-only safe forms, one-shot consume, time expiry, concurrent grants, malformed grants, baseline deny, happy path, helper validation, audit log presence. All green.
- **Known limitation**: true "subagent inheritance denial" via env-stripping is not implementable from a hook (subagents run in-process and inherit parent env). The combination of (a) one-shot grants and (b) guard-bash blocking any `AEGIS_MAINTAINER_MODE=` set attempt provides the equivalent guarantee: a subagent cannot self-grant, and any inherited grant is already consumed once the main agent's tool call finishes.

---

## ADR-005: Hook Governance -- Lifecycle, Naming, and Authorization Policy

**Date**: 2026-04-24
**Status**: Accepted (Nick Fury D-062, merging deferred cluster D from DIST-01)
**Source**: Cluster D learnings (`2026-04-20_hook-authorization-one-shot-state.md`, `2026-04-20_self-enforcement-override-channel.md`), sprint-v9-06 S2-11
**Context**: AEGIS has 10 hooks in `.claude/hooks/` accumulated across 6 sprints with no formal governance document. Hooks are the lowest-level enforcement layer -- they run before/after every tool call and can block or audit operations. Without clear governance, hooks risk: (a) naming collisions, (b) conflicting block/allow decisions, (c) unaudited additions, (d) orphaned hooks that no settings.json entry wires. ADR-004 (AEGIS_MAINTAINER_MODE) solved the *authorization* problem for modifying hooks; this ADR solves the *lifecycle* problem for managing them.

**Decision**: Establish a 5-rule governance policy for all AEGIS hooks.

### Rule 1: Naming Convention
All hook scripts MUST follow the pattern `<lifecycle>-<purpose>.sh`:
- **Lifecycle prefixes**: `guard-` (PreToolUse blockers), `post-` (PostToolUse observers), `on-` (Stop/lifecycle handlers), `session-` (SessionStart), `tinman-` (cron-based health checks)
- **Purpose suffix**: descriptive, lowercase, hyphenated (e.g., `guard-bash`, `post-tool-use`, `on-stop`)
- **Test hooks**: test files live in `tools/` (e.g., `tools/aegis-maintainer-test.sh`), never in `.claude/hooks/`
- Non-conforming hooks are renamed on next framework update

### Rule 2: Registration Requirement
Every hook script in `.claude/hooks/` MUST have a corresponding entry in `.claude/settings.json` `hooks` section. An orphaned script (exists on disk but not wired in settings.json) is dead code and MUST be either wired or removed. The `run-with-flags.sh` wrapper and `profiles.json` are infrastructure, not hooks -- they are exempt from this rule.

### Rule 3: Hook Conflict Resolution
When multiple hooks fire on the same tool call (e.g., two PreToolUse matchers both match `Bash`):
- **Block wins**: if ANY hook returns BLOCK, the tool call is blocked regardless of other hooks
- **Order**: hooks execute in the order listed in settings.json; first BLOCK short-circuits
- **Audit**: all hook decisions (allow/block) are logged; a blocked call logs which hook blocked it

### Rule 4: Addition/Modification Protocol
Adding or modifying hooks requires:
1. **ADR or spec**: document the hook's purpose, trigger condition, and expected behavior
2. **Test harness**: at least 5 assertions in `tools/` covering happy path, block path, edge cases
3. **Guard-write authorization**: use ADR-004 maintainer-mode for the write (human-initiated, time-bounded, audited)
4. **Settings.json update**: wire the hook in the same commit that adds the script
5. **Loki review**: hook changes are security-sensitive and require adversarial review

### Rule 5: One-Shot State Pattern
For hooks that need stateful authorization (e.g., maintainer-mode grants):
- Use filesystem-backed state files in `.aegis/brain/state/` (not env variables, not runtime memory)
- State files are consumed on first use (`.used` marker) to prevent replay
- Guard-bash blocks any agent attempt to self-issue authorization via env-set patterns
- This pattern delivers the "non-inheritable" property without requiring env-stripping (which is impossible from hooks -- subagents inherit parent process env)

**Consequences (+)**:
- Clear naming makes hook purpose discoverable at a glance
- Registration requirement prevents orphaned dead code
- Conflict resolution rule prevents ambiguous block/allow outcomes
- Addition protocol ensures every hook has a spec, tests, and review
- One-shot state pattern is proven (ADR-004 Phase 2, 23/23 test matrix)

**Consequences (-)**:
- More ceremony for adding hooks (spec + test + review + maintainer-mode)
- Naming convention may require renaming existing hooks in future (currently all conform)
- Conflict resolution "block wins" means a buggy hook can deny-of-service the framework

**Alternatives**:
- No governance (status quo) -- rejected: accumulating hooks without policy leads to the exact problems seen in sprints v9-01 through v9-05
- Centralized hook registry file -- rejected: settings.json already serves as the registry; adding a second one creates dual-source-of-truth
- Hook plugins (dynamic loading) -- rejected: overengineered for 10 hooks; revisit if count exceeds 20

**Supersedes**: Informal hook conventions accumulated across sprints v9-01 through v9-05
**Owner**: Framework Security (Thor) + Brain Governance (Nick Fury)

**Current Hook Inventory** (as of 2026-04-24):

| Hook | Lifecycle | Matcher | Purpose |
|------|-----------|---------|---------|
| `guard-bash.sh` | PreToolUse | Bash | Blocks destructive git ops, env-set attacks, --force flags |
| `guard-write.sh` | PreToolUse | Edit/Write/MultiEdit | Protects `.claude/` framework files from agent writes |
| `guard-ask-user.sh` | PreToolUse | AskUserQuestion | Enforces MBP -- only Nick Fury can ask user |
| `guard-ui-edit.sh` | PreToolUse | Edit/Write/MultiEdit | Blocks UI file edits without DESIGN.md (0F gate) |
| `post-tool-use.sh` | PostToolUse | Bash | Logs git commits + test results |
| `post-edit-accumulate.sh` | PostToolUse | Edit/Write/MultiEdit | Tracks file edit accumulation |
| `on-stop.sh` | Stop | * | Session-end checks, MBP violation scan, retro reminder |
| `session-start.sh` | SessionStart | * | Brain loading, health checks, session initialization |
| `tinman-heartbeat.sh` | Cron (5min) | N/A | BLOCK 0 docs, brain dirs, kanban, activity staleness |
| `aegis-version-check.sh` | SessionStart | * | Framework version compatibility check |

Infrastructure (exempt from Rule 2):
- `run-with-flags.sh` -- hook runner wrapper (profile-aware execution)
- `profiles.json` -- hook profile definitions (standard/strict/permissive)

---

## ADR-006: Nick Fury Proxy Dispatch Loop + memory_20250818 Integration Plan

**Date**: 2026-04-24
**Status**: Proposed (implementation blocked on SDK feature availability)
**Source**: S4-02 roadmap item, learning `2026-04-20_subagent-tool-availability.md`, ADR-002 (file = truth, memory = cache)
**Context**: Nick Fury's decision loop currently runs as a subagent spawned via the Agent tool. The `memory_20250818` tool (Claude's built-in cross-session memory) is available only to the main orchestrator process, not to subagents. This means Nick Fury cannot directly read/write Claude-level memory -- a gap that prevents the 3-tier brain architecture from having a native cache layer. S4-02 was deferred in sprint-v9-04 after this constraint was discovered empirically.

**Decision**: Design a proxy dispatch architecture where Nick Fury's memory operations are mediated by the main agent. The plan has 3 phases.

### Phase 1: Proxy Dispatch (when memory_20250818 is subagent-accessible)
When the SDK makes `memory_20250818` available to subagents (or provides an equivalent API):
1. Nick Fury reads memory at loop start (`/memories` directory scan)
2. Nick Fury writes key decisions to memory after each cycle
3. Memory serves as a read-through cache over `.aegis/brain/` files (per ADR-002)
4. On conflict: file wins, memory re-syncs from file

### Phase 2: Main-Agent Mediation (current workaround)
Until Phase 1 is possible:
1. Main agent reads memory before spawning Nick Fury
2. Main agent passes relevant memory contents as context to Nick Fury's prompt
3. Nick Fury returns memory-write requests as structured output
4. Main agent executes memory writes on Nick Fury's behalf
5. This is the "main-agent-as-router" pattern proven in sprint-v9-05

### Phase 3: 3-Tier Brain Integration
Maps the AEGIS brain architecture to memory_20250818 primitives:

| Brain Layer | File System | memory_20250818 | Purpose |
|-------------|-------------|-----------------|---------|
| **Working** (hot) | `.aegis/brain/logs/`, kanban, activity | Session-scoped memory entries | Current sprint state, active decisions |
| **Semantic** (warm) | `.aegis/brain/resonance/`, instincts, ADRs | Persistent memory entries (tagged) | Project identity, patterns, conventions |
| **Episodic** (cold) | `.aegis/brain/retrospectives/`, learnings | Persistent memory entries (dated) | Historical lessons, past sprint outcomes |

**Memory entry structure** (proposed):
```
Title: [brain-layer]/[category]/[short-id]
Content: [structured summary, not full file content]
Tags: aegis, brain-layer, category, sprint-id
```

**Sync protocol**:
- Session start: main agent reads memory entries tagged `aegis`, writes any that are newer than file timestamps to `.aegis/brain/`
- Session end: main agent reads `.aegis/brain/` files modified this session, writes summaries to memory
- Conflict: file is authoritative (ADR-002). Memory entry is overwritten from file.
- Pruning: episodic entries older than 10 sprints are archived (tagged `aegis-archive`)

**Migration path**:
1. Current: file-only brain, no memory_20250818 integration (status quo)
2. Phase 2: main-agent-mediated memory reads/writes (can implement today)
3. Phase 1: native subagent memory access (requires SDK update)
4. Phase 3: full 3-tier sync with conflict resolution (requires Phase 1)

**Risks**:
- **SDK API change**: memory_20250818 naming and API may change before GA. Design to the abstract (read/write/list/delete), not the concrete tool name.
- **Memory capacity**: unknown limits on memory entry count/size. Design for summarization, not full-file dumps.
- **Sync drift**: file and memory can diverge between sessions (other tools edit files, memory entries accumulate). Session-start sync mitigates but doesn't prevent all cases.
- **Performance**: memory reads/writes add latency to the decision loop. Budget ~500ms per memory operation.

**Rollback strategy**:
- Memory integration is additive -- file-based brain continues working regardless
- `AEGIS_MEMORY_ENABLED=false` env flag disables all memory reads/writes
- If memory tool becomes unavailable mid-session, graceful fallback to file-only (already proven)

**SDK readiness check**: `tools/aegis-sdk-readiness-check.sh` reports whether memory_20250818 is available in the current runtime.

**Consequences (+)**: Cross-session continuity without manual handoffs; Claude-native memory reinforces file-based brain; 3-tier architecture enables intelligent pruning and summarization
**Consequences (-)**: Adds sync complexity; memory tool availability is an external dependency; dual-write risk (mitigated by ADR-002 file-wins rule)
**Alternatives**:
- Wait for full SDK support (rejected: blocks all progress; Phase 2 workaround is viable now)
- Abandon memory integration (rejected: loses cross-session continuity benefit)
- Memory as primary, files as backup (rejected: violates ADR-002; files are diffable, git-trackable, auditable)
**Supersedes**: None (new capability)
**Owner**: Brain Architecture (Iron Man) + Framework (Nick Fury)

---

## ADR-007: Shell Output Compression — Governance + ISO 29110 NFR-05 Impact

**Date**: 2026-04-25
**Status**: DEFERRED pending measurement + upstream fix + canary pass
**Source**: Team vote (sprint-v10-02 planning session), Loki adversarial review
**Context**: RTK (Rust Token Killer) is a Rust-based compression proxy that intercepts shell output to reduce token consumption in LLM agent workflows. The team evaluated RTK adoption for AEGIS with the following vote result:

| Agent | Vote | Key Concern |
|-------|------|-------------|
| Iron Man | CONDITIONAL | Opt-in gate via `AEGIS_RTK=1` env var; never default-on |
| Spider-Man | ADOPT | Token savings could be significant for Bash-heavy sessions |
| Black Panther | ADOPT | Compression benefits code review diffs |
| War Machine | CONDITIONAL | Must prove no signal loss in quality gate output |
| Loki | REJECT | Killshot: "What % of AEGIS tokens is Bash vs Read/Grep/Glob?" If Bash <30%, RTK adds complexity for marginal gain. Supply chain risk. |
| Coulson | DEFER | ISO 29110 NFR-05 audit trail impact — compressed output may not meet retention requirements |
| Nick Fury | DEFER | Need data before commitment. Passthrough allowlist required for gate-critical commands. Pinned version, no auto-update. |

**Result**: 2 ADOPT, 2 DEFER, 2 CONDITIONAL, 1 REJECT — no majority to ship.

**Decision**: DEFERRED. Build measurement infrastructure (sprint-v10-02) to answer Loki's killshot question. Adoption decision moves to v10-03 if and only if all 5 gate conditions pass.

### Opt-in Gate Mechanism

RTK is NEVER default-on. Activation requires:
```
export AEGIS_RTK=1
```
- Only the human sets this (Master Brain Protocol: agents cannot self-activate)
- `guard-bash.sh` blocks any agent attempt to `export AEGIS_RTK=` (same pattern as maintainer-mode)
- When not set, RTK is completely bypassed even if installed

### Retention Policy

Per Coulson's ISO 29110 NFR-05 concern:
- RTK tee directory: `~/.local/share/rtk/tee/`
- Uncompressed originals MUST be retained for 30 days minimum
- AEGIS hooks that read tool output (post-tool-use.sh, token-profile.sh) operate on the ORIGINAL output, not compressed
- If RTK is activated, session logs MUST note `RTK_ACTIVE=true` in the session header for audit trail

### Audit Trail Impact (NFR-05 + SI.02)

- **SI.02 traceability**: requirement traces reference tool output. If output is compressed, the trace target may not match the stored artifact. Mitigation: traces reference the tee file (original), not the compressed output.
- **NFR-05 retention**: compressed output is a derived artifact. The tee file is the primary record. Retention policy applies to tee files, not compressed output.
- **Retrospectives**: session learnings reference specific tool output. With RTK, the retrospective must reference the tee file or the pre-compression content.

### Supply Chain

Per Loki and Nick Fury:
- **Pinned version**: RTK version is locked in configuration (e.g., `rtk==0.3.2`). No auto-update.
- **No auto-install**: AEGIS never runs `cargo install rtk` or equivalent automatically
- **Integrity check**: if RTK is present, `aegis-verify` validates the binary hash against a known-good value (added when version is pinned)
- **Sunset trigger**: if Anthropic ships native token compression (e.g., server-side output compaction), the RTK layer is removed entirely. The proxy becomes unnecessary overhead.

### Passthrough Allowlist

Per Nick Fury: certain commands MUST NOT be compressed because their output is consumed by quality gates:
- `git status` — parsed by post-tool-use.sh for commit detection
- `git diff` — parsed by Black Panther for code review
- Test runners (`pytest`, `jest`, `npm test`, etc.) — parsed for TEST_PASS/TEST_FAIL
- `jq` output — structured data consumed by hooks
- Any command whose output contains JSON consumed by AEGIS tools

The allowlist is stored in `.aegis/brain/state/rtk-passthrough.txt` (one command pattern per line). RTK is configured to bypass compression for matching commands.

### Five Conditions for v10-03 ADOPT Gate

ALL must pass before RTK can be adopted:

1. **Measurement data**: `aegis-token-profile.sh` has data from 3+ real AEGIS sessions showing Bash token % (if <30%, adoption is rejected — Loki's killshot stands)
2. **Upstream fix**: `aegis-rtk-upstream-check.sh` reports issue #427 state=closed
3. **Canary pass**: `aegis-rtk-canary-test.sh` reports 3/3 PASS with the candidate RTK version
4. **Version pinned**: RTK binary version is locked and hash-verified
5. **Passthrough validated**: all gate-critical commands verified to bypass compression

### Measurement Tools (sprint-v10-02 deliverables)

| Tool | Purpose |
|------|---------|
| `tools/aegis-token-profile.sh` | Logs token counts per tool category; answers Loki's killshot |
| `tools/aegis-rtk-upstream-check.sh` | Watches issue #427 status; caches weekly |
| `tools/aegis-rtk-canary-test.sh` | Dormant signal-loss test; activates when RTK installed |

**Consequences (+)**:
- Data-driven decision instead of opinion-driven
- No risk from premature adoption — RTK is dormant until all 5 gates pass
- Measurement tools have independent value (token profiling useful regardless of RTK)
- Team vote is codified — future sessions know the full context

**Consequences (-)**:
- Delays potential token savings by at least one sprint
- Measurement overhead (token-profile hook adds ~1ms per tool call)
- If Bash tokens are <30%, the entire RTK evaluation was unnecessary (but the data itself is valuable)

**Alternatives**:
- Adopt immediately (rejected: no data, Loki's killshot unanswered, upstream #427 unresolved)
- Reject permanently (rejected: premature — data may show strong value proposition)
- Wait for Anthropic native compression (rejected: timeline unknown — measurement infrastructure is useful regardless)
- Adopt with passthrough only (rejected: complexity without proven benefit)

**Supersedes**: None (new decision area)
**Owner**: Framework Governance (Nick Fury) + Architecture (Iron Man) + Compliance (Coulson)
