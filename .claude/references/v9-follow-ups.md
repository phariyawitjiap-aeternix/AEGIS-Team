# AEGIS v9 Follow-Ups Backlog

> Last updated: 2026-04-20 (after PR #8 close-out session)
> Purpose: single-page pickup point for the next session. Each item has a clear
> entry criterion ("start when…") and a defined done condition.

## Active Sprint State

- **v9-01 Foundation Hardening**: ✅ SHIPPED (13pt)
- **v9-02 Resilience design**: ✅ SPEC COMPLETE (29pt)
- **v9-03 Brain Seeding**: ✅ SHIPPED (28pt, brain populated + seeded)
- **v9-04 Memory Tool Integration**:
  - File layer: ✅ SHIPPED (sync, write, adversarial test, benchmarks)
  - Proxy pattern: ✅ SHIPPED (brain_write emits `AEGIS_MEMORY_WRITE` directive)
  - Main-agent proxy WIRING: ⏳ NOT WIRED (Nick Fury dispatch loop needs to
    parse directives after subagent returns)
  - Direct `memory_20250818` call: ⏸ DEFERRED (SDK gap; proxy pattern is the
    workaround until Anthropic exposes the tool in subagent runtimes)
- **v9-05 Worktree Isolation**:
  - Merge script + spider-man guidance: ✅ SHIPPED
  - Real-use validation: ✅ PASSED (9/9 adversarial, Scenario H via isolated Spider-Man)
  - Quirks fix (stale-ancestor rebase + process-lock double-force): ✅ SHIPPED
  - Investigate spawn-from-current-HEAD SDK option: ⏳ OPEN (may make rebase unnecessary)
- **v9-06 through v9-15**: ⏸ SPEC ONLY (441pt unshipped)

## Priority 1 — Unblock recurring friction (next session: ~10pt remaining)

### ADR-004 Implementation: AEGIS_MAINTAINER_MODE — ✅ SHIPPED (2026-04-20)

Spec: `.aegis/brain/resonance/architecture-decisions.md` ADR-004 (**Accepted**).
Learning: `.aegis/brain/learnings/2026-04-20_self-enforcement-override-channel.md`.

- **Phase 1 (observation)**: shipped earlier in session -- `guard-write.sh`
  logs `AEGIS_MAINTAINER_MODE` reads without changing behavior.
- **Phase 2 (authorization)**: shipped -- full token scheme with
  `tools/aegis-maintainer-grant.sh` helper, one-shot grants, 60s TTL,
  `guard-bash.sh` blocking agent-originated sets, audit log at
  `.aegis/brain/logs/maintainer-mode.log`, and `tools/aegis-maintainer-test.sh`
  with 23 assertions all green (scope escape, self-grant block, one-shot,
  expiry, concurrent grants, malformed, baseline, happy path, helper
  validation, audit trail).
- **Known limitation**: true subagent env-stripping is not implementable from
  a hook (in-process inheritance). One-shot + guard-bash deliver the
  equivalent guarantee. Documented in the ADR.

### Nick Fury dispatch loop: process S4-02 proxy directives (~6pt)

Spec: `tools/v9-04-integration-guide.md` "S4-02 Proxy Pattern" section.

Entry criterion: main agent has access to `memory_20250818` (current state).
Done condition:
- After each subagent returns, Nick Fury greps stdout for `AEGIS_MEMORY_WRITE: {...}`
- For each directive, reads the file and calls `memory_20250818.write`
- Logs replayed directives to `.aegis/brain/logs/memory-replay.log`
- Tested with a real subagent spawn + verify memory tool updated

### v9-05 spawn-from-HEAD investigation — ✅ CLOSED (2026-04-20)

Empirical probe + schema inspection confirmed no spawn-from-current-HEAD option
exists. `Agent({isolation: "worktree"})` spawned with `HEAD=f940591` produced a
worktree at `HEAD=1d5da1d` (20 commits behind). The `isolation` parameter is
`enum: ["worktree"]` -- single value, no base/ref sub-parameter -- and
`EnterWorktree` only accepts `name` / `path`. The rebase-onto-HEAD step in
`tools/aegis-merge-worktree.sh` is permanent until/unless Anthropic adds a
base-ref parameter to the Agent tool. Finding recorded in
`.claude/references/worktree-isolation.md` Known Quirks.

Learning: `.aegis/brain/learnings/2026-04-20_worktree-base-is-session-start-HEAD.md`.

## Priority 2 — Next architectural moves (2-4 sessions each)

### Sprint v9-06: Schedule + ToolSearch Consolidation (mostly DONE, ~5pt remaining)

Spec: `.claude/references/schedule-toolsearch-consolidation.md`.

**Spec-vs-reality audit (2026-04-20 late PM) surfaced that most of Part 3 is
already shipped** -- the spec was written as "to do" but the moves happened
in an unrecorded prior session.

- **S6-01 ScheduleWakeup auto-distill**: ❌ NOT STARTED -- Pattern A redesign
  ready to implement (~5pt). This is the real remaining work.
- **S6-02 `tools.deferred`**: ❌ CLOSED -- blocked on SDK.
- **S6-03 Vision → War Machine**: ✅ DONE -- war-machine.md absorbed Vision,
  vision.md archived.
- **S6-04 Wasp retire**: ✅ DONE -- archived.
- **S6-05 Songbird retire**: ✅ DONE -- Coulson absorbed content role,
  songbird.md archived.
- **S6-06 command consolidation (29 → 12)**: ⚠ PARTIAL -- 29 commands still
  active; target of 12 requires user-facing breakage. Deferred pending
  actual user pain signal. See spec's "S6-06 decision point" section.
- **S6-07 CLAUDE_agents.md updates**: ✅ DONE -- top of file declares "v9
  Model: 10 agents", table matches reality.

Entry criterion for S6-01 impl: any session. No blockers.
Done condition for S6-01: see "Redesigned S6-01 (Pattern A)" in spec.

Learning: `.aegis/brain/learnings/2026-04-20_verify-primitives-before-speccing.md`.

### Sprints v9-07/08/09: Brain-tier Architecture (94pt combined)

Spec: `.claude/references/brain-tier-architecture.md`.

Entry criterion: second machine available for multi-machine testing.
Done condition: Project / User / Team tiers operational with conflict
resolution per ADR-003.

## Priority 3 — Ecosystem work (calendar-bound)

- **v9-10/11 Plugin SDK** (83pt): needs Claude Code Plugin SDK access
- **v9-12/13 MCP server** (66pt): needs real MCP infrastructure
- **v9-14/15 Migration + GA** (73pt): 6-month beta → GA calendar time

Do NOT attempt these in the meta-repo. When ready, open dedicated engineering
sessions with the relevant external dependencies loaded.

## Dogfood Observations (candidates for future work)

From the 2026-04-20 retrospective and session work:

1. **Reviewer-disagreement adjudication protocol**. When Black Panther and Loki
   return contradictory findings on the same file, main agent must verify with
   filesystem evidence. Consider formalizing as `/aegis-team-review` step:
   require citations (file:line, bash output) on every finding.
2. **Subagent tool availability pre-flight**. Every spec that assumes a subagent
   can call tool X should grep that agent's `tools:` frontmatter before
   committing. Consider a pre-flight script that cross-checks specs against
   agent definitions.
3. **Spec freshness audit** (quarterly): 441pt of unshipped specs will rot. An
   automated "specs older than N months, re-review" check would help.
4. **Out-of-repo dogfood**. Every session so far has been AEGIS-improving-AEGIS.
   Running AEGIS on an external real app would surface richer failure modes.

## Pending Manual Steps

None. All between-session staging resolved in this session.

## Entry Points for the Next Session

- If fresh context: start with ADR-004 implementation (P1 highest leverage)
- If <50% context left: pick from P1's smaller items (Nick Fury dispatch loop,
  v9-05 investigation) or do Priority-3 research only
- If >90% context left: consider bundling P1 Nick Fury dispatch + P1 v9-05
  investigation into one sprint

Retrospective from this session:
`.aegis/brain/retrospectives/2026-04/20/13.03_v9-04-v9-05-complete.md`

Handoff:
`.aegis/brain/handoffs/2026-04-20_v9-04-v9-05-complete.md`

PR awaiting review:
https://github.com/phariyawitjiap-aeternix/AEGIS-Team/pull/8
