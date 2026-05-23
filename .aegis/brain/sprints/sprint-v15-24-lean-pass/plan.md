# Sprint v15-24 — Lean Pass (Native CC vs AEGIS Positioning)

> User question 2026-05-22: "AEGIS-Team ตอนนี้ยังจำเป็นมั้ย มี advantage มั้ย"
> Honest answer: yes, but the value proposition has narrowed. CC 2.1.148
> caught up on subagent dispatch, multi-tenant, worktree isolation, MCP,
> plugins. AEGIS still uniquely owns ISO 29110, honesty contracts, brain
> layer, MBP, and curated personas. v15-24 = strategic lean pass.

## Sprint metadata

- **ID**: sprint-v15-24-lean-pass
- **Points**: 3
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-24-lean-pass`
- **Driver**: 2026-05-22 user question + my honest analysis response

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — `docs/AEGIS_VS_NATIVE_CC.md`** | 2 | Authoritative strategic doc. Surface-by-surface comparison, deprecation list, roadmap implication. Becomes the lean roadmap for v15-25+. |
| **B — First-pass cuts (deprecate duplicates + archive obsolete planning docs)** | 1 | (a) Archive 4 obsolete v9-era planning docs (mcp-server-architecture, plugin-architecture, migration-ga-strategy, schedule-toolsearch-consolidation) into `.claude/references/_archived/`. (b) Update referrers (CLAUDE.md path resolution / nick-fury.md / AEGIS_v9_ECOSYSTEM_GUIDE.md). (c) Update `worktree-isolation.md` header to point at native equivalent. (d) Add `AEGIS_SUPPRESS_DEPRECATIONS`-aware deprecation hints to `mt cwd` and `mt run` (slated removal v15-25+). |

**Total: 3 pt** — small but surgical

## Decision principles

This sprint is the START of a multi-sprint lean process. We DON'T delete code today. We:

1. **Make the decisions visible** (the doc)
2. **Archive — don't delete — historical planning docs** that never shipped (mcp/plugin/migration-ga) so the link graph stays intact
3. **Warn — don't fail — when users invoke deprecated subcommands** so existing scripts keep working through one more sprint cycle
4. **Plan actual removal for v15-25+** once the deprecation hints have run in production for one cycle

## Acceptance criteria

- [ ] `docs/AEGIS_VS_NATIVE_CC.md` exists with surface comparison + deprecation list + roadmap
- [ ] 4 obsolete planning docs moved to `.claude/references/_archived/`
- [ ] All non-historical referrers (CLAUDE.md, nick-fury.md, AEGIS_v9_ECOSYSTEM_GUIDE.md, v9-follow-ups.md) updated to point at archived paths
- [ ] Brain artifacts (sprint kanbans, learnings, handoffs) NOT touched — they're historical records
- [ ] `mt cwd` + `mt run` print `DEPRECATED (v15-24)` to stderr unless `AEGIS_SUPPRESS_DEPRECATIONS=1`
- [ ] `worktree-isolation.md` header points at native `isolation: "worktree"` equivalent
- [ ] All existing tests still green (deprecation hints go to stderr; don't break command output assertions)
- [ ] Full suite green

## What this does NOT do (deferred)

- **Actually delete deprecated code** — v15-25+ once one sprint of deprecation hints has run
- **Audit `aegis-resume/` vs `claude --resume`** — needs separate evaluation; v15-25 candidate
- **Skill audit vs Anthropic skill marketplace** — out of scope (skills aren't infrastructure)
- **Persona library curation pass** — they're the core asset, not the audit target
- **Brain layer schema cleanup** — separate concern, not part of "lean infrastructure" theme

## Closes

- Opens: 2026-05-22 user question about AEGIS necessity vs native CC
- Closes: nothing — sets up the lean roadmap

## Strategic consequence

After this sprint, AEGIS-Team has a clear answer to "what is AEGIS for in 2026" — it's a process/discipline/honesty layer, not an infrastructure layer. The lean direction prevents creep.
