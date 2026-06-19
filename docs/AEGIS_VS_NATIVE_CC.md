# AEGIS vs Native Claude Code — Strategic Positioning (v15-27)

> Authoritative breakdown of what AEGIS still adds on top of native Claude
> Code, what duplicates native facilities, and what's deprecated.
>
> **2026-06-19 re-baseline:** the prior pass (v15-24) was pinned to CC 2.1.148
> (2026-05-23) and never evaluated the surfaces that shipped right after it —
> the **Workflow tool**, **Agent Teams**, **native cron / ScheduleWakeup**, the
> **plugin marketplace**, and **MCP Tool Search**. This revision adds them (see
> the new section below). Net effect: the earlier "~80% redundant / 20% unique"
> split has slipped to **~88% redundant-or-thin-wrapper / ~12% defensible** —
> native now also covers orchestration, scheduling, packaging, and skill-routing.
>
> Driver: user question 2026-05-22 — "AEGIS-Team ตอนนี้ยังจำเป็นมั้ย?" +
> 2026-06-19 capability-refresh + 7-persona priority vote.
> Honest answer: yes, but the value proposition has narrowed again. This doc
> draws the current line.

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

## 2026-06 re-baseline — surfaces that went native after CC 2.1.148

These shipped *after* the v15-24 pass and each subsumes a layer AEGIS still
simulates. Verdict on all five: **native is enough for the mechanism; AEGIS
keeps only the policy/content on top.**

> Verification note: surface *existence* is verified in-session (the Workflow
> tool is in active use here; `claude --help` confirms `--worktree` / `--resume`
> / `--continue`; `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set in
> `.claude/settings.json`; `ScheduleWakeup` / `CronCreate` are live tools).
> Exact version/date stamps below are research-sourced (capability-refresh
> agent), not all independently re-verified — treat as approximate.

| Surface | Native CC (≈ when) | What AEGIS simulates today | Verdict |
|---|---|---|---|
| **Multi-agent orchestration** | **Workflow tool** (≈ CC 2.1.154, late May 2026) — deterministic JS control flow, schema validation, parallel fan-out | Nick Fury role-play + `orchestrator.md` + BLOCK 0 / 5-gate hand-coded dispatch | ⚠️ **Native is enough for the wiring** — port the gate sequence onto Workflow; keep Nick Fury as the *judgment + decision-audit* layer only |
| **Peer agent coordination** | **Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, ≈ Feb 2026) — `SendMessage` mailbox, `Task*` shared queue, per-agent context | Star-topology routing through Nick Fury + `aegis-team-chat.sh` flat log | ⚠️ **Native primitive is richer** — AEGIS lists it `adopted` but still keeps the central-dispatch mental model |
| **Parallel scale** | Workflow parallel (~1,000 agents, state via script vars / shared FS) | `aegis-parallel-dispatch` skill (hard cap 5, state via chat context) | ⚠️ **Native is higher-capacity and less context-wasteful** |
| **Scheduling / recurring** | `CronCreate` / `CronList` / `ScheduleWakeup` + scheduled-tasks MCP (≈ CC 2.1.72+) | `aegis-daemon.sh` restart loop + `/loop` + heartbeat assumptions | ⚠️ **Native is durable + restart-surviving** — external loop already contradicts verified Desktop assumptions (no heartbeat) |
| **Skill auto-trigger + packaging** | `description`-based SKILL.md auto-trigger + progressive disclosure; plugin marketplace (`.claude-plugin/`, version pinning, GitHub/npm sources) | `triggers.en[]/th[]` + `profile:` frontmatter; `install.sh` glob + `skill-marketplace` skill | ⚠️ **Native reads `description`, not the arrays** — but see the P2 caveat below: those fields are NOT free to delete in this repo |

### P2 caveat — dead-to-native ≠ dead-to-AEGIS (verified 2026-06-19)

The capability audit flagged `triggers.en[]/triggers.th[]` and `profile:` as
"dead metadata native never reads." A grep-gate before deletion found that
**AEGIS's own tooling still consumes them**, so stripping is NOT a free quick
win:

| Consumer | Reads | Breakage if stripped |
|---|---|---|
| `tools/aegis-doc-canon/skill-frontmatter.mjs` | `BASE_KEYS = [name, description, profile, triggers]` | canon/lint **fails** |
| `tools/aegis-brain-graph/build.mjs` + `wiki.mjs` | `fm.profile`, `fm.triggers.en/th` | brain wiki rendering loses data |
| `tools/aegis-upgrade.sh` + `/aegis-mode` | `profile:` tier | profile switching degrades |

→ **P2 is blocked on a precursor**: retire/relax these internal consumers
first, *then* strip frontmatter. Effort/risk are higher than the vote assumed.

#### Deeper finding (2026-06-19, D-009) — P2 is downstream of P4, not standalone

A second check overturned the premise entirely: **AEGIS skills are not native
skills at all.** There is no `.claude/skills/` directory; `install.sh` copies
`skills/*.md` to `TARGET/skills/` (a plain folder), so native Claude Code never
loads them, never reads their `description`, and never auto-triggers them. They
are AEGIS-internal docs invoked via `/aegis-*` commands, the router, and
personas. The `triggers.en[]/th[]` arrays are therefore the *actual* matching
mechanism for AEGIS's own routing/help — not redundant carryover.

Consequence: the "native reads `description`, delete the arrays" rationale only
becomes true **after P4** repackages AEGIS as a native plugin and moves skills
into `.claude/skills/<name>/SKILL.md`. Only then does description-based
triggering apply and the arrays become migratable (triggers → description),
*and* the brain-graph/doc-canon consumers must be ported in the same pass.

**Re-scope: P2 is no longer an independent Wave-1 quick win. It is a sub-step of
P4** (migrate triggers→description while converting to native plugin format).
Do not execute P2 in isolation — it breaks brain-graph/doc-canon/router for
zero native benefit.

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
| `mt.mjs run` subcommand | `claude --cwd <path>` | ✅ **REMOVED v15-25** (exits 2 with native recipe) | done |
| `mt.mjs cwd` subcommand | Use registry → `claude --cwd "$(mt where alpha)"` | ✅ **REMOVED v15-25** | done |
| `tools/aegis-worktree-gc.sh`, `aegis-merge-worktree.sh` | `isolation: "worktree"` in Agent tool | ✅ **ARCHIVED** (`tools/_archived/`) | done |
| `references/worktree-isolation.md` | `isolation: "worktree"` in Agent tool | UPDATED with native pointer at top | keep updated |
| `references/mcp-server-architecture.md` | Native MCP first-class | ARCHIVED 2026-05-23 | done |
| `references/plugin-architecture.md` | Native `--plugin-dir` first-class | ARCHIVED 2026-05-23 | done |
| `references/migration-ga-strategy.md` | Plan never shipped — historical only | ARCHIVED 2026-05-23 | done |
| `references/brain-tier-architecture.md` | Plan never shipped — kept as design reference | KEEP but mark "design-only, not in flight" | review v15-25 |
| `aegis-resume/` package | `claude --resume` | ✅ **KEEP (audit resolved v15-27)** — scans `.aegis/brain/state/` for *interrupted* checkpoints at SessionStart and surfaces them; native `--resume` resumes any session but has no interrupted-vs-clean distinction or brain-checkpoint scan. Genuine value above native. | keep |

> **P6 finalization (2026-06-19, v15-27):** the v15-25 deprecation queue was
> already executed (mt run/cwd removed, worktree scripts archived) — this pass
> only closed the two loose ends a smoke-test surfaced: (1) `tools/aegis-claude-agents.sh`
> `cmd_where` still called the removed `mt cwd` and silently returned nothing —
> rewired to `mt where`; (2) `aegis-resume` was stuck "UNDER REVIEW" — audited
> and resolved to **KEEP** with the rationale above.

## Priority order (7-persona vote, 2026-06-19)

The capability-refresh produced six native-alignment moves. The AEGIS persona
team (Nick Fury, Captain America, Iron Man, Loki, Spider-Man, War Machine,
Coulson) voted; deterministic Borda tally (rank-1 = 6 pts):

| Rank | Move | Borda | Avg rank | Impact / Effort / Risk | Wave |
|---|---|:---:|:---:|:---:|:---:|
| 1 | **P1** Re-baseline this doc | 37 | 1.71 | 2.6 / 1.0 / 1.0 | 1 ✅ done |
| 2 | **P6** Finalize v15-25 deprecation queue | 36 | 1.86 | 2.9 / 2.0 / 1.9 | 1 |
| 3 | **P2** Strip dead frontmatter (~30 skills) | 30 | 2.71 | 2.1 / 2.0 / 1.7 | 1 ⛔ blocked (see P2 caveat) |
| 4 | **P5** Migrate flat brain → native auto-memory | 22 | 3.86 | 3.9 / 3.3 / 3.0 | 2 |
| 5 | **P4** Repackage AEGIS as native plugin | 12 | 5.29 | 3.7 / 4.3 / 4.0 | 3 |
| 6 | **P3** Port Nick Fury → Workflow tool | 10 | 5.57 | **5.0** / 5.0 / 4.7 | 3 |

Consensus: do the safe quick wins first (P1/P6/P2), defer the deep
re-architecture. **P3 has the highest impact but 5/7 named it the biggest
risk** — sequence it last, behind a shadow run, never touching MBP/honesty
enforcement until the Workflow path is proven equivalent. This
"enforcement-before-belief" ordering matches AEGIS's own DNA.

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

**Last updated:** 2026-06-19 (v15-27 re-baseline — Workflow/Agent Teams/cron/marketplace/MCP-Tool-Search added; 7-persona priority vote)
**Prior pass:** 2026-05-23 (sprint v15-24 lean pass, pinned to CC 2.1.148)
**Driver:** [feedback_aegis_coverage_contract](.aegis/brain/learnings/2026-05-21_verified-not-produced-bug-class.md) + 2026-05-22 user question on native CC vs AEGIS + 2026-06-19 capability-refresh & priority vote
