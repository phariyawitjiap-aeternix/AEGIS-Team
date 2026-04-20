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

## Priority 1 — Unblock recurring friction (next session: ~25pt)

### ADR-004 Implementation: AEGIS_MAINTAINER_MODE (~15pt)

Spec: `.aegis/brain/resonance/architecture-decisions.md` ADR-004 (Proposed).
Learning: `.aegis/brain/learnings/2026-04-20_self-enforcement-override-channel.md`.

Entry criterion: you have one fresh session with >=70% context budget.
Done condition:
- `guard-write.sh` reads `AEGIS_MAINTAINER_MODE` env and grants writes ONLY to
  paths in that env's allowlist for one tool call, then expires the grant.
- `guard-bash.sh` strips the env when Agent tool spawns subagents (non-inheritable).
- Writes under the flag log to `.aegis/brain/logs/maintainer-mode.log` with
  timestamp, path, and diff stat.
- Test matrix covers: scope escape (try writing outside allowlist → denied),
  subagent inheritance (subagent inherits flag → denied), expiration (grant
  used twice → second denied), concurrent flags (two sessions set different
  allowlists → isolated).

Do NOT skip the test matrix. This touches security-sensitive infrastructure.

### Nick Fury dispatch loop: process S4-02 proxy directives (~6pt)

Spec: `tools/v9-04-integration-guide.md` "S4-02 Proxy Pattern" section.

Entry criterion: main agent has access to `memory_20250818` (current state).
Done condition:
- After each subagent returns, Nick Fury greps stdout for `AEGIS_MEMORY_WRITE: {...}`
- For each directive, reads the file and calls `memory_20250818.write`
- Logs replayed directives to `.aegis/brain/logs/memory-replay.log`
- Tested with a real subagent spawn + verify memory tool updated

### v9-05 spawn-from-HEAD investigation (~4pt)

Open question in `.claude/references/worktree-isolation.md` Known Quirks.

Entry criterion: any session with 30 min of research budget.
Done condition:
- Read current Claude Code Agent tool docs/schema for isolation params
- Either: confirm no spawn-from-HEAD option exists → document in spec, remove
  investigation item from backlog; OR: confirm it exists → remove rebase step
  from `aegis-merge-worktree.sh` and test the simpler path
- Update `.claude/references/worktree-isolation.md` Known Quirks with the finding

## Priority 2 — Next architectural moves (2-4 sessions each)

### Sprint v9-06: Schedule + ToolSearch Consolidation (22pt)

Spec: `.claude/references/schedule-toolsearch-consolidation.md`.

Entry criterion: ADR-004 implemented (because this sprint touches agent defs).
Done condition per the spec's acceptance criteria.

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
