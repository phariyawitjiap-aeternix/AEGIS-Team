# AEGIS vs Native Claude Code — Strategic Positioning (v15-24)

> Authoritative breakdown of what AEGIS still adds on top of native Claude
> Code (CC 2.1.148 as of 2026-05-23), what duplicates native facilities,
> and what's deprecated.
>
> Driver: user question 2026-05-22 — "AEGIS-Team ตอนนี้ยังจำเป็นมั้ย?"
> Honest answer: yes, but the value proposition has narrowed since v9. This
> doc draws the line.

## Executive verdict

**AEGIS is still useful FOR:**

- Process-disciplined work (ISO 29110 compliance, audit-ready outputs)
- Multi-session knowledge accumulation (brain layer with FTS5)
- Honest delivery contracts (coverage screen, verified-vs-produced gates)
- Persona-driven thinking diversity (Loki adversarial, Coulson compliance, etc.)
- Master Brain Protocol (agent-doesn't-ask-human enforcement at hook level)

**AEGIS is NOT needed if you just want:**

- Subagent dispatch (native `.claude/agents/*.md` + Task tool covers this)
- Multi-tenant execution (`claude --cwd <path>` does this)
- Worktree isolation (native `isolation: "worktree"` in Agent tool)
- Hook framework (native PreToolUse/PostToolUse/Stop/SessionStart with `permissionDecision` + `terminalSequence` are first-class)
- MCP server integration (first-class native)
- Plugin loading (`--plugin-dir` is first-class native)

## Surface-by-surface comparison

### Subagent dispatch

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Persona files | `.claude/agents/*.md` with frontmatter | 11 curated Marvel personas with tool grants + model routing | ✅ **AEGIS adds CONTENT** (the personas themselves) |
| Dispatch mechanism | `Task` tool with `subagent_type` | Nothing — uses native | ⚠️ **Native is enough** for the wiring |
| Tool grants per persona | `tools:` in frontmatter | Same | ⚠️ **Native pattern** |
| Model routing per persona | `model:` in frontmatter | Same | ⚠️ **Native pattern** |
| Background spawning | `claude agents` CLI with --effort/--model/--mcp-config | `aegis-multi-tenant/mt.mjs run` (deprecated v15-24) | 🚧 **AEGIS deprecate** — native is richer |

### Multi-tenant / cross-project

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Run agent in different cwd | `claude --cwd <path>` | `mt cwd <name>` + `mt run <name>` | 🚧 **DEPRECATE** the wrappers; keep registry + `mt sessions` for awareness |
| List live sessions | `claude agents --json` | `aegis-claude-agents.sh` wrapper + `mt sessions` (v15-22) | ✅ **AEGIS adds VALUE** via registry merge (`mt sessions` shows project name + version + path + session status in one table) |
| Cross-project warnings | none | `/aegis-start` Step 2.7 (v15-22) | ✅ **Unique to AEGIS** |

### Hooks

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Hook event matchers | PreToolUse / PostToolUse / Stop / SessionStart with full schema | Same | ⚠️ **Native is enough** |
| Hook output schema | `permissionDecision`, `terminalSequence`, etc. | Uses native | ⚠️ **Native** |
| Governance hooks (specific to AEGIS) | none | `guard-bash.sh`, `guard-write.sh`, `guard-ui-edit.sh`, `guard-ask-user.sh` (MBP), `aegis-approval-gate` | ✅ **AEGIS adds CONTENT** (specific governance patterns) |
| Hook auto-fire on edits | Wires PostToolUse `Edit|Write|MultiEdit` | `research-probe-on-write.sh` (v15-21) | ✅ **Unique to AEGIS** (verified-vs-produced enforcement) |

### Memory + brain layer

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Per-project memory | `.claude/memory/` (CC native) | `.aegis/brain/` (separate hierarchy) | ⚠️ **Partial duplicate** — but AEGIS adds structure |
| Cross-session memory | CC's `~/.claude/projects/<hash>/memory/` | Uses CC native | ⚠️ **Native** |
| FTS5 search across brain | none | `aegis-brain-index.sh` + `aegis-brain-search.sh` | ✅ **Unique to AEGIS** |
| Decision audit log | none | `aegis-log-decision.sh` + `aegis-decisions` command | ✅ **Unique to AEGIS** |
| Learning archive | none | `.aegis/brain/learnings/` (cross-sprint synthesis) | ✅ **Unique to AEGIS** |
| Resonance docs (project identity) | none | `.aegis/brain/resonance/` | ✅ **Unique to AEGIS** |

### Workflow / ceremony

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Sprint plan/standup/review/retro/close | none | `/aegis-sprint <subcommand>` | ✅ **Unique to AEGIS** |
| ISO 29110 work products | none | `_aegis-output/iso-docs/` (PM.01, SI.01, SI.02, etc.) + Coulson persona | ✅ **Unique to AEGIS** |
| BLOCK 0 gate (spec+breakdown before code) | none | `/aegis-start` Step 4b | ✅ **Unique to AEGIS** |
| Sprint close DoD gate | none | `aegis-sprint-close-gate.sh` (v15-20) | ✅ **Unique to AEGIS** |
| Master Brain Protocol (no-menu rule) | none | `guard-ask-user.sh` hook + Stop hook regex | ✅ **Unique to AEGIS** |

### Honesty contracts (the v15-19/20/21 series)

| Surface | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Tool-boundary coverage screen at intake | none | `aegis-coverage-screen.sh` (v15-19) — 25 stack detection rubric | ✅ **Unique to AEGIS** |
| Sub-agent return tagging convention | none | `aegis-return-validator.sh` + `skills/aegis-return-format.md` (v15-20 F-C) | ✅ **Unique to AEGIS** |
| Sprint-close playtest gate | none | `aegis-sprint-close-gate.sh` (v15-20 F-B) | ✅ **Unique to AEGIS** |
| Research URL probe gate | none | `aegis-research-probe.sh` + auto-fire hook (v15-20 F-E + v15-21) | ✅ **Unique to AEGIS** |
| Coverage warning at session start | none | `/aegis-start` Step 2.3 (v15-19) | ✅ **Unique to AEGIS** |

### Session lifecycle

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Resume session | `claude --resume` | `aegis-resume/session-start.mjs` hook + checkpoint files | 🚧 **PARTIAL DUPLICATE** — AEGIS resume tracks INTERRUPTED work, native CC resumes any session. Keep for now but evaluate in v15-25. |
| Handoff between sessions | none | `/aegis-handoff` + `.aegis/brain/handoffs/` | ✅ **Unique to AEGIS** |
| Run-logger archive | none | `aegis-run-logger/archive.mjs` (Stop hook) | ✅ **Unique to AEGIS** |

### Skills (the `/skill-name` system)

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Skill invocation | `/skill-name` syntax | Uses native | ⚠️ **Native** |
| Skill discovery / marketplace | Anthropic skill marketplace | Local `skills/*.md` + frontmatter auto-discovery | ⚠️ **AEGIS uses local skills only** — no marketplace participation |
| Skill profile tiers (minimal/standard/full) | none | `install.sh` glob-discovery via frontmatter `profile:` (v15-18A) | ✅ **Unique to AEGIS** |

### Settings.json

| Aspect | Native CC | AEGIS adds | Verdict |
|---|---|---|---|
| Hook configuration | Yes, in `.claude/settings.json` | Uses native | ⚠️ **Native** |
| Setting sources (user/project/local) | First-class (`--setting-sources`) | Uses native | ⚠️ **Native** |
| Safe mid-session migration | none (CC reloads settings only at session start) | `aegis-settings-patch.sh` + `tools/aegis-settings-patches/*.jq` (v15-18B) | ✅ **Unique to AEGIS** |

## Deprecation list (v15-24)

These surfaces duplicate native CC and are slated for removal in v15-25+:

| Surface | Native equivalent | Status | Removal target |
|---|---|---|---|
| `mt.mjs run` subcommand | `claude --cwd <path>` | DEPRECATED with warning | v15-25 candidate |
| `mt.mjs cwd` subcommand | Use registry → `claude --cwd "$(mt where alpha)"` | DEPRECATED with warning | v15-25 candidate |
| `references/worktree-isolation.md` | `isolation: "worktree"` in Agent tool | UPDATED with native pointer at top | keep updated |
| `references/mcp-server-architecture.md` | Native MCP first-class | ARCHIVED 2026-05-23 | done |
| `references/plugin-architecture.md` | Native `--plugin-dir` first-class | ARCHIVED 2026-05-23 | done |
| `references/migration-ga-strategy.md` | Plan never shipped — historical only | ARCHIVED 2026-05-23 | done |
| `references/brain-tier-architecture.md` | Plan never shipped — kept as design reference | KEEP but mark "design-only, not in flight" | review v15-25 |
| `aegis-resume/` package | `claude --resume` | UNDER REVIEW — adds interrupted-work tracking | v15-25 audit |

## What this means for users

### If you're starting a new project

**Use AEGIS** if you need:
- Audit-ready ISO 29110 work products
- Honest coverage warnings up front (especially for Unity / mobile / non-web stacks)
- Brain layer that accumulates across many sessions
- Loki-style adversarial review baked in
- Master Brain Protocol (autonomous agents that don't bother you with menus)

**Use native CC** if:
- You just want a smart assistant with subagent fan-out
- You're not planning to audit or compliance-review the output
- Your stack is web/CLI/library (no Unity, no closed mobile)
- You don't need cross-session memory
- The project lifespan is one session or a few days

### If you're already running AEGIS

**You don't lose anything.** v15-24 is a leaning pass — we mark duplicates as deprecated but don't remove them yet. v15-25+ will remove confirmed duplicates with a migration path.

## What AEGIS will NOT pursue further

To stay lean, AEGIS will explicitly NOT:

1. **Build a plugin marketplace** — Anthropic's plugin system is first-class
2. **Build an MCP framework** — Anthropic's MCP is first-class
3. **Wrap `claude agents` CLI further** than the observability layer we already have (v15-22)
4. **Compete on hook framework basics** — only ship hooks that add unique governance (MBP, coverage gate, probe-gate, etc.)
5. **Wrap session resume** beyond the interrupted-checkpoint tracking already in `aegis-resume`
6. **Replace native subagent dispatch** — `.claude/agents/*.md` IS the native pattern; AEGIS adds curated content, not new infrastructure

## Roadmap implication

The 4 dimensions where AEGIS will continue to invest:

1. **Honesty contracts** — coverage / verified-vs-produced / probe-gate / sprint-close gate
2. **Process discipline** — ISO 29110 / sprint ceremony / Master Brain Protocol
3. **Persona library** — curated Marvel agents with tool grants + model routing
4. **Brain layer** — FTS5 search, learnings, resonance, decision audit, cross-session knowledge

Everything else either matches native or sits in a deprecation queue.

---

**Last updated:** 2026-05-23 (sprint v15-24 lean pass)
**Driver:** [feedback_aegis_coverage_contract](.aegis/brain/learnings/2026-05-21_verified-not-produced-bug-class.md) + 2026-05-22 user question on native CC vs AEGIS
