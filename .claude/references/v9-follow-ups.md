# AEGIS v9 Follow-Ups Backlog

> Last updated: 2026-04-20 (post spec-freshness audit)
> Purpose: single-page pickup point for the next session. Each item has a clear
> entry criterion ("start when…") and a defined done condition.

## Active Sprint State (post-audit 2026-04-20 late PM)

A full spec-freshness audit found substantial drift: several sprints'
acceptance criteria were written as "pending" long after the work
shipped. The true remaining in-repo backlog is far smaller than the
earlier "441pt unshipped" figure suggested.

- **v9-01 Foundation Hardening**: ✅ SHIPPED (13pt)
- **v9-02 Resilience**: ✅ MOSTLY SHIPPED
  - S2-01 Captain America fallback: spec + doc done; behavioral tests unrun.
  - S2-02 Decision audit: doc ✅, Nick Fury integration ✅, **retro-summary
    wiring still pending** (~2pt).
  - S2-03/04 BLOCK 0: general gate is **live** in Nick Fury (36 refs) +
    Coulson (9 refs). **Lite-mode switching is NOT implemented** (no
    `block0_mode` field in meta, no `determine_block0_mode()` branch);
    ~4pt follow-up.
- **v9-03 Brain Seeding**: ✅ SHIPPED (28pt, brain populated + seeded)
- **v9-04 Memory Tool Integration**: ✅ SHIPPED (previously marked partial)
  - File layer (sync, write, adversarial test, benchmarks): ✅ all shipped
    and tested (audit surfaced this — spec was stale).
  - Proxy pattern: ✅ shipped (brain_write emits `AEGIS_MEMORY_WRITE`).
  - Nick Fury dispatch-loop wiring for proxy directives: ⏳ ~6pt.
  - Direct `memory_20250818` call: ⏸ blocked on SDK (tool not exposed to
    main-agent runtime).
  - `aegis migrate brain` command (S4-03): ⏸ low priority -- tree already
    lives under `.aegis/brain/`.
- **v9-05 Worktree Isolation**: ✅ SHIPPED
  - Merge script + spider-man guidance: ✅
  - Real-use validation: ✅ (9/9 adversarial + scenario H)
  - Quirks fix (stale-ancestor rebase + process-lock double-force): ✅
  - Spawn-from-current-HEAD investigation: ✅ CLOSED (no SDK option exists;
    rebase step is permanent).
- **v9-06 Schedule + ToolSearch + Agent Consolidation**: ✅ MOSTLY SHIPPED
  - S6-01 distill reminder (Pattern A): ✅ shipped this session.
  - S6-02 tools.deferred: ❌ closed -- SDK has no such key.
  - S6-03/04/05/07 agent merger + retirements + docs: ✅ all in place
    (audit surfaced this — spec was stale).
  - S6-06 29→12 command cut: ⏸ deferred pending user-pain signal.
- **v9-07/08/09 Brain-tier** (94pt): ⏸ ACCURATELY DEFERRED -- requires real
  S3/git backend, multi-machine testing, adversarial security review.
- **v9-10/11 Plugin** (83pt): ⏸ ACCURATELY DEFERRED -- requires Plugin SDK,
  marketplace access, 4-6wk real engineering.
- **v9-12/13 MCP** (66pt): ⏸ ACCURATELY DEFERRED -- requires Node.js
  project, real backend infra, 3-5wk real engineering.
- **v9-14/15 Migration + GA** (73pt): ⏸ ACCURATELY CALENDAR-BOUND -- 6mo
  wall time (beta, GA, bridge).

### True remaining in-repo work

- Decision-audit retro-summary wiring (S2-02): ~2pt
- BLOCK 0 lite-mode switching (S2-03/04): ~4pt
- Nick Fury proxy dispatch loop (S4-02 partial): ~6pt
- Migrate-brain command (S4-03, low urgency): ~3pt
- Command cut S6-06 (deferred): ~4pt

Total meta-repo-shippable: **~15-20pt** (not 441pt). Everything else is
SDK-gated, infra-gated, or calendar-bound -- correctly deferred until
those externals materialize.

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

From the 2026-04-20 retrospective and session work. Session-5 extended
closed three of the four at the tool/doc level; integration into agent
prompts and skill flows is a future session's call.

1. **Reviewer-disagreement adjudication protocol** — ✅ DOC SHIPPED
   (`.claude/references/reviewer-adjudication-protocol.md`). 5-step
   protocol with claim-to-probe mapping, anti-patterns, integration
   points. Remaining: `/aegis-team-review` skill integration (~2pt),
   black-panther.md + loki.md prompt refs (~1pt).
2. **Subagent tool availability pre-flight** — ✅ TOOL SHIPPED
   (`tools/aegis-agent-tools-matrix.sh` with `--check <tool>` /
   `--agent <name>` / `--json` modes). Spec authors can now run
   `./tools/aegis-agent-tools-matrix.sh --check memory_20250818` before
   writing "subagent X calls tool Y". No integration gap.
3. **Spec freshness audit** — ✅ PRIMITIVE SHIPPED
   (`tools/aegis-pending-items.sh`, three modes). Reports 46 unchecked
   items across 10 spec files (most correctly deferred). Heuristic
   drift-detector (comparing claims against filesystem) is a future
   build on top of this primitive.
4. **Out-of-repo dogfood** — ⏸ STILL OPEN. Not in-repo work; requires
   a real external project to apply AEGIS to. All session-5 work so
   far is meta (AEGIS-improving-AEGIS).

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
