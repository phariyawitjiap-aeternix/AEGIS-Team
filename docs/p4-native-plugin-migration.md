# P4 — Repackage AEGIS as a Native Plugin (migration plan)

> Status: **SCAFFOLD PRODUCED — NOT YET VERIFIED.** Plugin manifest drafted;
> nothing moved, `install.sh` untouched (Loki's parallel-run gate). The plugin
> is inert until someone runs `/plugin marketplace add` — so this commit cannot
> break an existing install.

## Why P4 is the only surviving "real" native-alignment move
The 7-persona vote ranked 6 moves. On verification: P2 dissolved into P4
(D-009 — skills aren't native-loaded), P5's migration premise dissolved
(brain is load-bearing), P6's queue was already done. P1 was docs. **P4 is the
remaining substantive move** — and it now *absorbs P2* (the triggers→description
migration only becomes real once skills live in native `.claude/skills/` form).

## Native plugin convention (ground-truthed from installed plugins)
- `.claude-plugin/plugin.json` — metadata + `commands`/`agents`/`hooks`/`skills`.
  Keys may be `null` (auto-discover `commands/`,`agents/`,`skills/`,`hooks/hooks.json`
  at plugin root) OR explicit relative-path arrays.
- `hooks/hooks.json` mirrors the `settings.json` hooks block but uses
  `${CLAUDE_PLUGIN_ROOT}` instead of `${CLAUDE_PROJECT_DIR}`.
- Skills are dirs: `skills/<name>/SKILL.md` with `name` + rich `description`
  (description drives native auto-trigger — there is no `triggers[]` array).

## What this commit ships (step 1, additive)
| File | Content | Safe? |
|------|---------|:----:|
| `.claude-plugin/plugin.json` | metadata + **explicit** arrays → existing `.claude/commands/*.md` (16) and `.claude/agents/*.md` (11), no moves | ✅ inert |
| `.claude-plugin/hooks.json` | settings.json hooks block, `${CLAUDE_PROJECT_DIR}`→`${CLAUDE_PLUGIN_ROOT}` | ✅ inert |

Explicit arrays point at the current `.claude/` locations, so the manifest is
valid WITHOUT relocating anything — true parallel-run.

## Remaining P4 work (not in this commit)
1. **Skills → native format (absorbs P2).** Convert `skills/*.md` (39 flat files)
   to `skills/<name>/SKILL.md`. Fold each skill's `triggers.en[]/th[]` into a
   rich `description` (the actual native trigger surface). **Port the internal
   consumers in the same pass** — `aegis-brain-graph/build.mjs+wiki.mjs`,
   `aegis-doc-canon/skill-frontmatter.mjs`, `aegis-commands/*` read the old
   frontmatter (per D-009); they must read the new layout or be retired.
2. **Hook de-dup.** When the plugin is enabled, the `settings.json` hooks block
   must be REMOVED or hooks double-fire (plugin hooks + project hooks). Sequence:
   add plugin → verify hooks fire once → strip settings.json hooks.
3. **MCP.** If AEGIS exposes brain tools (FTS5 search, decision-audit) as an MCP
   server, declare it under `mcpServers`.
4. **Retire `install.sh` glob-discovery + `skill-marketplace` skill** — ONLY after
   the plugin loads and passes a smoke test. Publish via a `marketplace.json`
   source instead of the bash installer (Loki: needs a parallel-run window +
   rollback before hard cutover).

## Verification gate before calling P4 done
- [ ] `/plugin marketplace add <local path>` loads the plugin with 0 errors
- [ ] all 16 commands + 11 agents resolve
- [ ] hooks fire exactly once (no double-fire with settings.json)
- [ ] at least 3 converted skills auto-trigger from `description` alone
- [ ] brain-graph + doc-canon still build against the new skill layout
- [ ] `install.sh` still works during the parallel-run window
