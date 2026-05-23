# Sprint v15-24 Kanban

## DONE

- [x] **A** — `docs/AEGIS_VS_NATIVE_CC.md` (2pt)
  - Executive verdict + use-when-AEGIS vs use-native checklist
  - Surface-by-surface comparison (subagent dispatch, multi-tenant, hooks, brain, workflow, honesty contracts, session lifecycle, skills, settings)
  - Per-row verdict: ✅ AEGIS adds value, ⚠️ native is enough, 🚧 deprecated
  - Roadmap implication: 4 dimensions AEGIS keeps investing (honesty contracts, process discipline, persona library, brain layer)
  - Explicit "what AEGIS will NOT pursue" list (no plugin marketplace, no MCP framework, no further claude-agents wrapping, no replacing native subagent dispatch)
- [x] **B** — First-pass cuts (1pt)
  - Archived: `mcp-server-architecture.md`, `plugin-architecture.md`, `migration-ga-strategy.md`, `schedule-toolsearch-consolidation.md` → `.claude/references/_archived/`
  - Updated referrers: `AEGIS_v9_ECOSYSTEM_GUIDE.md` (3 paths), `.claude/agents/nick-fury.md` (4 paths), `.claude/references/v9-follow-ups.md` (1 path)
  - Brain artifacts left untouched (historical records — sprint kanbans, handoffs, learnings)
  - `worktree-isolation.md` header now points at native `isolation: "worktree"` + links to AEGIS_VS_NATIVE_CC.md
  - `mt cwd` + `mt run` print deprecation hint to stderr (suppressible via `AEGIS_SUPPRESS_DEPRECATIONS=1`); slated removal v15-25+

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — AEGIS_VS_NATIVE_CC.md | strategic doc | 2 | DONE |
| B — first-pass cuts | refactor + deprecate | 1 | DONE |

**Total**: 3/3 done.

## Strategic outcome

AEGIS-Team now has a clear, written answer to "what is AEGIS for in 2026":

- A **process/discipline/honesty layer** for projects that need audit-readiness or autonomous Master Brain Protocol
- NOT an infrastructure layer (subagent dispatch, multi-tenant, hooks basics) — native CC owns those

## Carry to v15-25+

- Actually delete `mt cwd` + `mt run` (after one sprint of deprecation hints in production)
- Audit `aegis-resume/` vs `claude --resume` — confirm interrupted-work tracking is unique enough to keep, OR replace with native
- Skill format audit — explore opt-in publication to Anthropic skill marketplace (not duplicate, just discoverable)
- Persona library curation pass — review all 11 personas for tool grants + model routing + relevance
