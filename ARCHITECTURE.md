<!-- version: 1.1.0 -->
<!-- Last updated: 2026-05-12 -->

Last reviewed: 2026-05-12

# AEGIS Architecture

> **"Where to change what."** This is the document a new agent (or human) reads to know which file to touch when modifying a concern. It complements `CLAUDE.md` (which says *what AEGIS is*) by saying *where AEGIS lives*.
>
> Adapted from GitNexus's `ARCHITECTURE.md` pattern. Source: AEGIS Knowledge-Layer Mega Plan v1.1 (sprint-v12-01).

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial ARCHITECTURE authored as part of sprint-v12-01. Captures repo layout, concern→path map, hook DAG, brain ingestion DAG. Pre-graph (graph DAG arrives in v12-04). |
| 2026-05-06 | 1.0.1 | Added §6.1 (Skill Frontmatter Schema) pointer for sprint-v12-03; backfill tool + manifest documented at `tools/aegis-doc-canon/skill-schema.md`. |
| 2026-05-12 | 1.1.0 | v14 Hermes parity series CLOSED. Concern→File map updated with 8 new concerns: command registry SSOT, brain threat scan, brain checkpoint, decision search, aegis-dump, pattern-miner scheduling, pin 2-axis, persistent goals POC, supply-chain CI. Slash command count 14→16 (+aegis-decisions, +aegis-goal). |

---

## 1. Repository Layout

| Path | Role |
|------|------|
| `CLAUDE.md` | Agent navigation entry point + Golden Rules. Loaded every session. |
| `CLAUDE_safety.md` | Hard safety rules (git, blast radius, secrets, incident response). Load before mutation. |
| `CLAUDE_agents.md` | Agent roster + model routing. Load before spawning. |
| `CLAUDE_skills.md` | Skill catalog by profile (minimal / standard / full). |
| `CLAUDE_lessons.md` | Long-form patterns / anti-patterns / decision log. |
| `DoD.md` | 🆕 v12-01 — repo-wide completion bar (this is one of the 9 bars: see DoD.md §7). |
| `ARCHITECTURE.md` | 🆕 v12-01 — this file. |
| `GUARDRAILS.md` | 🆕 v12-02 (planned) — Sign-shaped recurring-failure catalog. |
| `PROJECT_INDEX.md` | Project-wide wiki (manual today; auto-generated from v12-06). |
| `README.md` | External-facing intro. |
| `AEGIS_v9_UPGRADE_PLAN.md` | Historical 482pt plan; treat as architecture reference. |
| `docs/_archived/AEGIS_v9_PROGRESS_TRACKER.md` | Historical v9 tracker (archived in sprint-v13-01-phase-e; superseded by `.aegis/brain/sprints/roadmap.md`). |
| `AEGIS_v9_ECOSYSTEM_GUIDE.md` | v9 ecosystem narrative. |
| `AEGIS_EXTERNAL_ADOPTION.md` | How external projects adopt AEGIS. |
| `.claude/agents/` | Per-agent persona files (`captain-america.md`, `nick-fury.md`, etc.). |
| `.claude/commands/` | 12 canonical slash commands (`aegis-start.md`, `aegis-status.md`, etc.). |
| `.claude/hooks/` | Bash hook scripts (PreToolUse / PostToolUse / Stop / SessionStart). |
| `.claude/references/` | Protocol references (decision-audit, command-chain, MBP). |
| `.claude/settings.json` | Permission allow/deny + hook wiring. **Single source of truth for hook chain.** |
| `.claude/settings.local.json` | Per-machine overrides (gitignored). |
| `skills/*.md` | Skill definitions with frontmatter triggers. |
| `tools/<pkg>/` | Tool packages (multi-file: `tools/aegis-live-tail/{emit,watch,start,...}.mjs`). |
| `tools/<name>.sh` | Single-file shell tools (`tools/aegis-progress.sh`, `tools/aegis-log-decision.sh`). |
| `tools/aegis-plus-pilot/` | v11 pilot bootstrap for downstream projects. |
| `.aegis/brain/` | Persistent agent memory. **The "soul" half of "Context is King, Memory is Soul."** |
| `.aegis/brain/sprints/` | One dir per sprint with `plan.md` + `close.md`. `roadmap.md` is the index. |
| `.aegis/brain/learnings/` | Append-only patterns observed in flight. |
| `.aegis/brain/resonance/` | Session-end snapshots that bootstrap next session's context. |
| `.aegis/brain/handoffs/` | Cross-session continuity briefs. |
| `.aegis/brain/retrospectives/` | Per-session retros, organized by date. |
| `.aegis/brain/conversations/<date>/chat.log` | Inter-agent dialogue events (DISPATCH / REPORT / VERDICT). |
| `.aegis/brain/logs/activity.log` | Free-form activity (legacy; v11-02 prefers JSONL). |
| `.aegis/brain/activity/<date>.jsonl` | v11-02 structured activity log (one JSON per tool call). |
| `.aegis/brain/logs/decision-audit.log` | v9-02 / S2-02 — Nick Fury's structured decision log (JSONL). |
| `.aegis/brain/issues/*.yaml` | v11-03 — append-only issue threads. |
| `.aegis/brain/approvals/*.yaml` | v11-05 — approval markers (gate-allow records). |
| `.aegis/brain/gate-rules.yaml` | v11-05 — destructive-op rules consumed by `aegis-approval-gate`. |
| `.aegis/brain/runs/` | v11-07 — archived per-session transcripts (Stop hook output). |
| `.aegis/brain/exports/` | v11-08 — redacted trace exports. |
| `.aegis/brain/state/<session>.yaml` | v11-10 — resumable run state (one per active session). |
| `.aegis/brain/routing/policy.yaml` | v11-06 — model-tier routing policy. |
| `.aegis/brain/redaction/patterns.yaml` | v11-08 — PII redaction rules. |
| `.aegis/brain/index.db` | v10-06 — FTS5 search index over the brain (sqlite3). |
| `.aegis/brain/graph/` | 🆕 v12-04 (planned) — NDJSON knowledge graph (`nodes.ndjson`, `edges.ndjson`, `meta.json`). |
| `.aegis/brain/human-queue.md` | Items requiring explicit human action (External access / Identity / Irreversible / Approval). |
| `_aegis-output/` | Tool outputs (gitignored). Architecture archives, reviews, wiki. |
| `_aegis-output/wiki/` | 🆕 v12-06 (planned) — auto-generated per-skill / per-sprint wiki pages. |
| `tests/` | Test fixtures and assertions. |
| `docs/` | External-facing docs (e.g. `AEGIS_APPLICATION_PLAYBOOK.md`). |
| `scripts/` | One-shot operational scripts (e.g. `aegis-migrate-consolidate.sh`). |

---

## 2. Concern → File Map

If you're changing **<concern>**, edit **<file/dir>**.

| Concern | Path |
|---------|------|
| **Adding a slash command** | `tools/aegis-commands/registry.mjs` (SSOT, 16 entries as of v14-04) + `.claude/commands/<name>.md` |
| **Adding a skill** | `skills/<name>.md` + register in `CLAUDE_skills.md` |
| **Adding an agent persona** | `.claude/agents/<name>.md` + roster in `CLAUDE_agents.md` |
| **Wiring a new hook** | `.claude/settings.json` `hooks` section + script in `.claude/hooks/` or `tools/<pkg>/` |
| **Approval gate rules** | `.aegis/brain/gate-rules.yaml` (consumed by `tools/aegis-approval-gate/check.mjs`) |
| **Model routing policy** | `.aegis/brain/routing/policy.yaml` (consumed by `tools/aegis-router/`) |
| **PII redaction patterns** | `.aegis/brain/redaction/patterns.yaml` (consumed by `tools/aegis-trace-export`) |
| **Brain content threat scan** (v14-01) | `tools/aegis-brain-threat-patterns.yaml` (consumed by `tools/aegis-brain-write.sh:_aegis_threat_scan`) |
| **Brain mutation rollback** (v14-02) | `tools/aegis-brain-checkpoint/{store,snapshot,rollback}.sh` → `.aegis/.brain-checkpoints/store/` (real git repo) |
| **Decision audit search** (v14-02) | `tools/aegis-decision-search.sh` (wraps `aegis-brain-search.sh --type decisions`) |
| **Setup summary for support** (v14-03) | `tools/aegis-dump.sh` (paste-safe, `--show-keys`, `--json`) |
| **Pattern-miner scheduling** (v14-03) | `tools/aegis-pattern-mine/mine.mjs --auto --interval-hours N` → `.aegis/brain/state/pattern-miner-state.json` |
| **Pinning instincts/skills** (v14-03) | `tools/aegis-pin.sh {pin,unpin,list,check} <type> <id> [--axis delete\|change\|both]` → `.aegis/brain/pins.json` |
| **Persistent goals POC** (v14-04) | `tools/aegis-goal/{judge,state}.sh` + `/aegis-goal` command (heuristic mode; LLM mode gated on measurement campaign) |
| **Supply-chain CI** (v14-01) | `.github/workflows/supply-chain-audit.yml` + `tools/aegis-supply-chain-scan.sh` (narrow, no-noise) |
| **Sprint open** | `.aegis/brain/sprints/sprint-<id>/plan.md` + new row in `roadmap.md` |
| **Sprint close** | `.aegis/brain/sprints/sprint-<id>/close.md` + status flip in `roadmap.md` |
| **Per-agent permissions** | Agent's frontmatter `permissions:` block in `.claude/agents/<name>.md` (sprint v10-09 pattern) |
| **Project-level permission allow/deny** | `.claude/settings.json` `permissions` section |
| **Adding a hard safety rule** | `CLAUDE_safety.md` § + matching enforcement (hook/test) — see DoD §3 + §5 |
| **Logging a decision (Nick Fury)** | `tools/aegis-log-decision.sh` writes to `.aegis/brain/logs/decision-audit.log` |
| **Recording activity (any tool)** | PostToolUse `.*` hook fires `tools/aegis-activity-logger/log.mjs` (auto) |
| **Adding a Sign (recurring failure)** | `GUARDRAILS.md` (v12-02) via `tools/aegis-doc-canon/add-sign.mjs` |
| **Bumping a doc version** | Top of file `<!-- version: X.Y.Z -->` + Changelog row in same PR |
| **MBP escalation** | Nick Fury appends to `.aegis/brain/human-queue.md` via `tools/aegis-queue-human.sh`; resolves via `tools/aegis-queue-resolve.sh` |
| **Brain search** | `tools/aegis-brain-search.sh` (FTS5 over `.aegis/brain/index.db`) |
| **Brain re-index** | `tools/aegis-brain-index.sh --full` or `--incremental` |
| **Roadmap math** | `tools/aegis-progress.sh --bar` reads `.aegis/brain/sprints/roadmap.md` |
| **Adding a tool package** | `tools/<pkg>/` with `<entry>.mjs` + `tests/` + register in relevant skill |

---

## 3. Hook Chain DAG

The full hook chain wired in `.claude/settings.json` as of v11-10:

```
PreToolUse:
├── matcher: "Bash"
│   ├── .claude/hooks/run-with-flags.sh → guard-bash.sh        (block dangerous commands)
│   └── tools/aegis-approval-gate/check.mjs                    (block destructive ops without approval)
├── matcher: "Edit|Write|MultiEdit"
│   └── .claude/hooks/run-with-flags.sh → guard-write.sh       (block writes outside scope)
└── matcher: "AskUserQuestion"
    └── .claude/hooks/run-with-flags.sh → guard-ask-user.sh    (block non-Fury callers — MBP enforcement)

PostToolUse:
├── matcher: "Bash"
│   └── .claude/hooks/run-with-flags.sh → post-tool-use.sh     (token profiling, etc.)
├── matcher: "Edit|Write|MultiEdit"
│   └── .claude/hooks/run-with-flags.sh → post-edit-accumulate.sh
└── matcher: ".*"   (every tool call)
    ├── tools/aegis-token-profile.sh                           (profile token usage)
    ├── tools/aegis-live-tail/emit.mjs                         (v11-01 — emit to live FIFO)
    └── tools/aegis-activity-logger/log.mjs                    (v11-02 — JSONL audit log)

Stop:
├── .claude/hooks/run-with-flags.sh → on-stop.sh               (false-ready guard, MBP scan)
└── tools/aegis-run-logger/archive.mjs                         (v11-07 — archive run transcript)

SessionStart:
├── (no matcher)
│   └── .claude/hooks/session-start.sh                         (greet + context bootstrap)
└── matcher: "startup"
    └── tools/aegis-resume/session-start.mjs                   (v11-10 — surface interrupted runs)
```

### Coming in v12

```
PostToolUse:
└── matcher: "Edit|Write|MultiEdit"   (additional)
    ├── tools/aegis-brain-graph/build.mjs --incremental --quiet    (v12-04, debounced 3s)
    └── tools/aegis-brain-graph/wiki.mjs                            (v12-06, debounced 3s)

SessionStart:
└── matcher: "startup"   (additional)
    └── tools/aegis-brain-graph/staleness.mjs                       (v12-06)
```

All current and planned hooks are **fail-OPEN** per DoD §2 (R6 in Mega Plan), with `aegis-approval-gate` as the single fail-CLOSED exception.

---

## 4. Brain Ingestion DAG

How content flows into the brain's indexes:

```
                    ┌─ skills/*.md ──────────────────────────┐
                    ├─ tools/<pkg>/<file> ───────────────────┤
                    ├─ .claude/{agents,commands,hooks}/* ────┤
                    ├─ .aegis/brain/sprints/*/*.md ──────────┤
   source files ────┼─ .aegis/brain/{learnings,resonance,    │
                    │    handoffs,retrospectives}/*.md       │
                    ├─ .aegis/brain/issues/*.yaml ───────────┤
                    └─ CLAUDE*.md / DoD.md / ARCHITECTURE.md ┘
                                       │
                                       │ tools/aegis-brain-index.sh
                                       │   (--full | --incremental)
                                       ▼
                          .aegis/brain/index.db   ← v10-06 FTS5 (live)
                                       │
                                       ▼
                  tools/aegis-brain-search.sh   ← ranked snippets

       ┌────────────────────────────────────────────────────┐
       │ v12-04 (planned — additional pipeline branch):      │
       │                                                     │
       │   source files                                      │
       │       │                                             │
       │       │ tools/aegis-brain-graph/build.mjs           │
       │       │   (--full | --incremental, debounced 3s)    │
       │       ▼                                             │
       │   .aegis/brain/graph/{nodes,edges}.ndjson +         │
       │   .aegis/brain/graph/meta.json                      │
       │       │                                             │
       │       ├──► tools/aegis-brain-graph/query.mjs        │
       │       │     (impact / context / detect-changes /    │
       │       │      mentions / wiring)                     │
       │       │                                             │
       │       └──► tools/aegis-brain-graph/wiki.mjs         │
       │             → PROJECT_INDEX.md (auto)               │
       │             → _aegis-output/wiki/<topic>.md         │
       └────────────────────────────────────────────────────┘
```

Both branches share the source set. The FTS5 branch is for **content search** (free-text). The NDJSON-graph branch is for **structural queries** (which tool wires to which hook? what does this skill depend on?).

---

## 5. Tool Package Layout

A multi-file tool package follows this convention:

```
tools/<package-name>/
├── README.md            (optional — purpose + commands)
├── <entry>.mjs          (main entry, typically the verb: emit / build / query / archive)
├── start.sh             (optional — convenience launcher)
├── tests/               (sprint-scoped or package-scoped)
│   └── <suite>.test.mjs
└── lib/                 (optional — shared helpers)
    └── *.mjs
```

Single-file tools live directly under `tools/` as `<name>.sh` or `<name>.mjs`.

**Naming convention.** All AEGIS tool packages are prefixed `aegis-`. Examples:

- `tools/aegis-live-tail/` — v11-01 — terminal stream
- `tools/aegis-activity-logger/` — v11-02 — JSONL audit
- `tools/aegis-issue-thread/` — v11-03 — YAML tickets
- `tools/aegis-parallel-dispatch/` — v11-04 — Agent fan-out
- `tools/aegis-approval-gate/` — v11-05 — PreToolUse blocker
- `tools/aegis-router/` — v11-06 — model-tier picker
- `tools/aegis-run-logger/` — v11-07 — Stop archive
- `tools/aegis-trace-export/` — v11-08 — PII-redacted export (under `tools/` per package)
- `tools/aegis-multi-tenant/` — v11-09 — cross-project ops
- `tools/aegis-resume/` — v11-10 — resumable runs
- `tools/aegis-doc-canon/` — 🆕 v12-01 — version-header lint
- `tools/aegis-brain-graph/` — 🆕 v12-04 (planned) — NDJSON graph build/query/wiki

---

## 6. Skill Resolution

### 6.1 Frontmatter schema (v12-03)

Every `skills/<name>.md` file must satisfy a uniform YAML frontmatter shape. Required keys: `name`, `description`, `profile`, `triggers`, plus 5 graph keys (`reads`, `writes`, `wires`, `tests`, `supersedes`) — present-required, value-may-be-empty-array.

The schema is documented in [`tools/aegis-doc-canon/skill-schema.md`](tools/aegis-doc-canon/skill-schema.md). Validated by `node tools/aegis-doc-canon/skill-frontmatter.mjs --lint`. Backfill missing keys with `--backfill` (idempotent). Set non-empty graph values for tool-backed skills via [`tools/aegis-doc-canon/skill-graph-manifest.json`](tools/aegis-doc-canon/skill-graph-manifest.json) + `--apply-manifest`.

This schema is the **input contract** for the v12-04 knowledge-graph builder; without it, the graph cannot generate `READS` / `WRITES` / `WIRES` / `TESTS` / `SUPERSEDES` edges from skills.

### 6.2 Resolution flow

A skill resolves through this chain when an agent considers "should I invoke this?":

1. User message arrives.
2. Skill matcher scans `skills/*.md` frontmatter `description` for trigger phrases (EN + TH).
3. Active profile (minimal / standard / full) filters which skills are eligible.
4. Matched skill is invoked via the `Skill` tool — its body becomes the agent's instruction.
5. If the skill has a checklist, agent creates one TodoWrite todo per item.
6. Skill follows its own steps; agent reports back with the result.

**Profile sizing** (per `CLAUDE_skills.md`):

| Profile | Skill count | Approx context |
|---------|------------:|---------------:|
| minimal | 7 | ~3K tokens |
| standard | 15 | ~6K tokens |
| full | 28 | ~12K tokens |

Profile is set via `/aegis-mode` and persisted in session state.

---

## 7. Persona Routing

11 active agents (Wasp restored in S3-06 design-approval-gate work after v9 consolidation):

| Persona | Model tier | Role |
|---------|:----------:|------|
| Nick Fury | opus | Autonomous controller |
| Captain America | opus | Navigator / fallback brain |
| Iron Man | opus | Architect |
| Loki | opus | Devil's advocate |
| Spider-Man | sonnet | Implementer (worktree default) |
| Black Panther | sonnet | Reviewer (read-only worktree) |
| War Machine | sonnet | QA + executor (absorbed Vision) |
| Thor | sonnet | DevOps |
| Beast | haiku | Scanner / research |
| Coulson | haiku | Compliance + docs (absorbed Songbird) |

**Routing rules:**

- opus = strategy, synthesis, architecture, devil's-advocate
- sonnet = implementation, review, QA, deploy
- haiku = bulk scanning, research gathering

**Per-agent allow lists** (sprint v10-09): each agent's frontmatter has a `permissions:` block with either:
- DENY-only (broad-access roles like Spider-Man, Nick Fury, Captain America, Thor)
- ALLOW + DENY tight (read-mostly roles like Beast, Black Panther, War Machine)
- Tools-list omission (Wasp, Iron Man, Loki, Coulson — Bash not granted at all)

**Retired in v9 (archived in `.claude/agents/_archived/`):** Vision (merged into War Machine), Wasp (UX rare), Songbird (marketing rare).

---

## 8. See Also

- `CLAUDE.md` — what AEGIS is + Golden Rules
- `DoD.md` — repo-wide completion bars
- `GUARDRAILS.md` (v12-02 planned) — Sign-shaped recurring-failure catalog
- `CLAUDE_safety.md` — hard safety rules
- `CLAUDE_agents.md` — agent roster + protocol references
- `CLAUDE_skills.md` — skill catalog
- `.aegis/brain/sprints/roadmap.md` — sprint state + grand-total math
- `~/Documents/AEGIS-PLUS-MEGA-PLAN.md` — v11 source plan (shipped)
- `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` — v12 source plan (in progress)
