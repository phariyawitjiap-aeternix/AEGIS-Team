# AEGIS v9 Ecosystem Engineering Guide

> **Purpose**: bootstrap reference for the three remaining v9 work streams
> that cannot be done in the meta-repo. Each becomes its own engineering
> project. Scope, entry criteria, and deliverables live here so the person
> who starts each stream can pick up cold.

Current state (as of 2026-04-20 merge of PR #8): the AEGIS meta-repo is
~98% complete. The meta-framework is live, tested (76/76 assertions green),
and dogfooding itself. What remains is **ecosystem**, not framework.

## Stream 1 — Brain-Tier Architecture (Sprints v9-07/08/09)

**Spec**: [.claude/references/brain-tier-architecture.md](.claude/references/brain-tier-architecture.md)
**Est.**: 94 story points · 2-3 weeks engineering · 1 engineer
**Repo**: separate project (e.g., `aegis-brain-tier`)

### Entry criteria

- Second machine available for multi-machine testing (required: conflict
  resolution can't be validated on one machine).
- An S3 bucket OR git-based backend provisioned (the spec supports either).
- Adversarial security review scheduled (Loki pass on the backend
  implementation before production).

### Deliverables

1. **Backend adapter implementation** (~40pt): pluggable interface with
   concrete S3 + git adapters. Read/write/list ops.
2. **Conflict resolution engine** (~20pt): per ADR-003 — file wins, merge
   on append-only logs, stale-ancestor rebase on structured docs.
3. **Privacy guard** (~15pt): PII scrubber between Tier 1 (project) and
   Tier 2 (user), audit log on every tier promotion.
4. **Status + migration commands** (~19pt): `/aegis-brain-tier status`,
   `/aegis-brain-tier migrate`, plus integration with existing
   `brain_write()` helper.

### Setup checklist

```
□ New git repo created
□ AEGIS applied to this repo (see AEGIS_EXTERNAL_ADOPTION.md)
□ Second machine access provisioned
□ Backend choice decided (S3 vs git-backed)
□ Iron Man writes spec: adapter interface + conflict matrix
□ Black Panther + Loki review before impl
□ 4 sprints × 2 weeks each
```

### Exit criteria

- Project / User / Team tiers operational.
- Multi-machine conflict resolution validated with adversarial tests.
- Privacy guard passes Loki's red-team review.
- `./tools/aegis-brain-tier-test.sh` suite >=20 assertions, all green.

## Stream 2 — MCP Server (Sprints v9-12/13)

**Spec**: [.claude/references/_archived/mcp-server-architecture.md](.claude/references/_archived/mcp-server-architecture.md)
**Est.**: 66 story points · 3-5 weeks engineering · 1-2 engineers
**Repo**: separate project (e.g., `aegis-mcp-server`)

### Entry criteria

- Node.js 20+ development environment.
- `@modelcontextprotocol/sdk` installed (Anthropic's MCP SDK public).
- Brain-Tier backends from Stream 1 finished, OR a decision to ship MCP
  against the Tier 1 file layer only for V1.
- Cross-project test fixtures available (at least 2 real projects using
  AEGIS, OR willingness to generate synthetic ones).

### Deliverables

1. **MCP server scaffold** (~15pt): Node.js/TypeScript project, connects
   to Claude Code via MCP protocol, exposes tool API.
2. **Tool API** (~25pt): `brain.read`, `brain.write`, `brain.search`,
   `brain.tier_status`, `brain.tier_promote`. JSON schemas for each.
3. **Backend adapter pattern** (~15pt): factored out of Stream 1 so both
   MCP and direct-file access share the same backend code.
4. **Configuration schema + installer** (~11pt): `aegis.mcp.yaml`,
   `.claude/settings.json` block injection.

### Setup checklist

```
□ Verify @modelcontextprotocol/sdk in npm
□ Create aegis-mcp-server repo
□ Copy the shared backend adapter from Stream 1
□ Iron Man: tool API spec (JSON schemas, error codes, rate limits)
□ Thor: deployment model (local-only vs hosted)
□ Implement + test
□ Publish to npm + wire into .claude/settings.json template
```

### Exit criteria

- MCP server runs locally, Claude Code can discover its tools.
- Cross-project brain read/write works end-to-end.
- Performance: read <100ms, write <250ms on a real project's brain
  (benchmark in the test suite).
- Security: Loki adversarial pass — the MCP server is a new trust
  boundary; treat accordingly.

## Stream 3 — Plugin + Migration + GA (Sprints v9-10/11/14/15)

**Spec**: [.claude/references/_archived/plugin-architecture.md](.claude/references/_archived/plugin-architecture.md),
[.claude/references/_archived/migration-ga-strategy.md](.claude/references/_archived/migration-ga-strategy.md)
**Est.**: 156 story points · 4-6 weeks engineering + 6 months beta/GA
**Repo**: separate project (e.g., `aegis-plugin`)

### Entry criteria

- Claude Code Plugin SDK (TypeScript/JavaScript) publicly available.
- Marketplace publishing access approved.
- Beta tester pool identified (minimum 3 real v8.x user repos).
- Coordination with Anthropic on plugin review timeline.

### Deliverables

Phase A — Plugin (v9-10/11, ~83pt, 4-6 weeks):
1. Plugin package structure + manifest.
2. `IPluginAdapter` interface implementation.
3. `aegis.config.yaml` schema + validator.
4. Install flow (`npx aegis install`) + activation commands.
5. Marketplace publishing pipeline.

Phase B — Migration (v9-14, ~37pt, 2 weeks engineering):
1. `aegis-migrate-v8-to-v9.sh` — scans v8.x layouts, offers automated
   migration with rollback manifest.
2. Bridge UX scripts for the deprecation window.
3. Migration tested on 3+ real v8.x user repos.

Phase C — GA (v9-15, ~36pt, 6 months calendar):
1. 4-week beta period with 10+ real users.
2. GA criteria checklist passes (no CRITICAL bugs, Loki/Black Panther
   audits green, docs complete).
3. Deprecation timeline: T0 (GA), T0+3 months (curl|bash sunset warning),
   T0+6 months (curl|bash removed).
4. Marketing / comms announcements.

### Why this is one stream

Plugin + Migration + GA are tightly coupled: the plugin *is* the v9
distribution mechanism, and GA can't happen without real migration
tooling and real beta users. Splitting this across three separate teams
invites coordination debt.

### Exit criteria

- Plugin installable from the Claude Code marketplace.
- `npx aegis install` works on a fresh project.
- Migration tool moves a real v8.x repo to v9 layout with zero data loss.
- 4-week beta completes with all CRITICAL bugs fixed.
- GA release tagged. curl|bash sunset enforced on schedule.

## Cross-stream practices

All three streams MUST:

1. **Use AEGIS on themselves.** Apply the framework via the external
   adoption guide (`AEGIS_EXTERNAL_ADOPTION.md`). The streams dogfood
   AEGIS while building ecosystem for it.
2. **Write ADRs for every non-obvious decision.** Backend choice,
   protocol version, conflict strategy, deprecation policy — all ADRs.
3. **Ship adversarial tests alongside feature tests.** Loki passes
   before any PR merges. This is non-negotiable for infrastructure.
4. **Publish learnings back to this repo.** Any insight that generalizes
   (security pattern, conflict strategy, migration trap) gets a
   `.aegis/brain/learnings/<date>_<slug>.md` in *that* stream's repo,
   plus a PR here to port it back.

## What stays in the meta-repo

- Framework core (hooks, agents, skills, references, brain).
- Protocols (ADRs, resonance patterns, anti-patterns, tech debt).
- Meta-tooling (`tools/aegis-*.sh`).
- The `/aegis-start` → Nick Fury autonomous controller.

When a stream delivers something meta-framework-relevant (a new hook, a
new agent type), it ships back to the meta-repo via PR. Ecosystem code
stays in its own repo; framework evolution lands here.

## TL;DR handoff

```
Meta-repo (this):           DONE at ~98%. Merge PR #8, stop.
Stream 1 (brain-tier):      2-3 week sprint, new repo, needs second machine.
Stream 2 (MCP server):      3-5 week sprint, new repo, needs MCP SDK + N20+.
Stream 3 (plugin+GA):       4-6 weeks engineering + 6 months calendar.
                            Needs Plugin SDK public + beta users.
```

None of these should run inside this meta-repo. Open dedicated projects.
