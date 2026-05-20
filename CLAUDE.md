<!-- version: 1.1.0 -->
<!-- Last updated: 2026-05-13 -->

Last reviewed: 2026-05-13

# AEGIS v15.0 -- Agent Team Framework

> "Context is King, Memory is Soul"

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Version header pattern introduced (sprint-v12-01). Doc-version starts at 1.0.0 independent of AEGIS framework version (v11.0 in title above refers to the framework). |
| 2026-05-13 | 1.1.0 | Framework version bump v12.0 → v15.0 to catch up with shipped work: v13 (refactor+cleanup, 30pt) + v14 (Hermes parity, 47pt) + v15 (CC 2.1.139 adoption + transparent skill model, 17pt) had all shipped without VERSION bump. Quick Commands restructured into user-surface (5) vs team-surface (11) per `.claude/references/command-audience.md`. |

## Navigation
| File | When to Read | Priority |
|------|-------------|----------|
| CLAUDE.md | Every session | Required |
| CLAUDE_safety.md | Before git/file thor | Required |
| CLAUDE_agents.md | Before spawning agents | As needed |
| CLAUDE_skills.md | When choosing skills | As needed |
| CLAUDE_lessons.md | When stuck or deciding | Reference |
| PROJECT_INDEX.md | Project-wide wiki (doc/req/mod/func/task cross-ref) | Reference |

## Golden Rules
1. NEVER use --force flags on git
2. NEVER push to main -- branch + PR always
3. NEVER git commit --amend -- breaks all agents
4. NEVER end turn before agents finish (false-ready guard)
5. Run /aegis-start at session begin
6. Run /aegis-retro at session end
7. **Agents ask Nick Fury, not the human** -- Master Brain Protocol (v9.0)
   - ❌ NEVER end a response with "Options: A/B/C — what do you want?" (the classic violation pattern — this is the #1 observed MBP failure mode)
   - ❌ NEVER end a command with "run retro? handoff? start?" — follow the chain in [`.claude/references/command-chain.md`](.claude/references/command-chain.md)
   - ❌ NEVER present a menu of choices back to the human mid-task
   - ❌ NEVER call `AskUserQuestion` unless you are Nick Fury escalating one of the 4 allowed categories
   - ✅ When you need a decision: send `QUESTION_TO_BRAIN` to Nick Fury (see `.claude/references/context-rules.md`)
   - ✅ When a command finishes: apply the chain in [`.claude/references/command-chain.md`](.claude/references/command-chain.md) — no "what next?" menus
   - ✅ Only 4 categories ever reach the human (Identity / Irreversible scope / External access / Explicit approval gate) — and only Nick Fury escalates
   - ✅ If Nick Fury is offline (no recent Agent dispatch): make the best call from brain/instincts/ADRs, log it to `.aegis/brain/logs/activity.log`, continue — do NOT fall back to asking the human
   - 🛡️ Loki auto-REJECTs any spec or response that violates this rule
   - 🛡️ `guard-ask-user.sh` hook blocks `AskUserQuestion` calls from non-Nick-Fury callers at the tool level
   - 🛡️ `on-stop.sh` hook scans the last response for the option-menu pattern and logs violations
   - 👤 **Human-required items go to [`.aegis/brain/human-queue.md`](.aegis/brain/human-queue.md)** — bilingual EN/TH, surfaces at `/aegis-start`, `/aegis-status`, `/aegis-handoff`, session end. Use `tools/aegis-queue-human.sh` to append, `tools/aegis-queue-resolve.sh` to resolve.

## Nick Fury (🧬)
After /aegis-start, Nick Fury takes full control:
- Scans project state (git, tests, specs, deps, tech debt)
- Decides what to do next (Decision Matrix P0-P10)
- Spawns the right team automatically (in-process agents)
- Does NOT ask human -- analyzes, decides, executes
- Human watches via Shift+Down to view agent detail
- Human can interrupt anytime (Ctrl+C) or downgrade: /aegis-mode --autonomy L1

Default autonomy: L3 (Autonomous) with Nick Fury active

## Quick Commands

> **User vs team split** — see [`.claude/references/command-audience.md`](.claude/references/command-audience.md).
> Humans only need `/aegis-start` + a few others; the team uses the rest internally. The full surface below is the *team's* tool catalog, not a user manual.

### User-facing (5 — the entire human-facing surface)

| Command | Purpose |
|---------|---------|
| /aegis-start | Begin session — the team takes over |
| /aegis-status | Quick health snapshot mid-session |
| /aegis-mode | Switch autonomy level or profile |
| /aegis-handoff | Save state before quitting |
| /aegis-upgrade | Framework maintenance (rare) |

### Team-facing (11 — invoked autonomously by Nick Fury / Captain America / personas)

| Command | Purpose |
|---------|---------|
| /aegis-sprint | Sprint lifecycle (plan/standup/review/retro/status/close) |
| /aegis-breakdown | Decompose stories into tasks |
| /aegis-pipeline | Full analysis pipeline (--qa, --flow modes) |
| /aegis-team | Spawn a team (build / review / debate) |
| /aegis-verify | Run verification pipeline (--doctor mode) |
| /aegis-deploy | Deploy pipeline (--launch mode, gated on human approval) |
| /aegis-retro | Session/sprint retrospective + lessons |
| /aegis-memory | Memory management (--adr, --instinct, --distill, --evolve, --ingest, --lint, --iso modes) |
| /aegis-linear | Kanban → Linear one-way mirror (auto-fired after kanban writes) |
| /aegis-goal | Set explicit completion condition (CC 2.1.139+ wrapping; transparent inside /aegis-start) |
| /aegis-decisions | FTS query over decision-audit log |

> 16 canonical commands total. Legacy shims removed in v10-05.

## Diagram-First Reflex (v15-17)

When the thought is **structural** — flow > 3 steps, decision > 2 branches, multi-actor sequence, state machine, hierarchy > 5 nodes — lead with a Mermaid diagram BEFORE the prose. Each persona has a default diagram type (Nick Fury → decision tree, Captain America → sequenceDiagram, Iron Man → architecture flowchart, Loki → attack paths with `:::warning` class, Coulson → traceability flow).

Anti-triggers (use PROSE instead): single facts, retros, post-mortems, apologies, code review feedback, 1-2 step instructions. See [`skills/diagram-first-reflex.md`](skills/diagram-first-reflex.md) for the full trigger / anti-trigger matrix.

## Coverage Contract (v15-19)

**AEGIS contract = 100% autonomous execution.** Human role is ONLY (1) requirements and (2) credentials. For any project where AEGIS cannot drive end-to-end (Unity / Unreal / Xcode / closed mobile / hardware-in-the-loop), the team MUST emit a coverage warning at intake — `/super-spec` Phase 0 runs `tools/aegis-coverage-screen.sh`, lists every gap, and writes `.aegis/brain/state/coverage.json`. `/aegis-start` re-surfaces the warning each session until the user types `ack gaps`. Soft gate (warns but never blocks). See [`skills/aegis-coverage-screen.md`](skills/aegis-coverage-screen.md). Driver: Contra-Thai post-mortem 2026-05-21 — 3 "100% velocity" sprints produced zero playable artifact because Unity Editor work AEGIS cannot drive was never surfaced as a gap on day 1.

## Verified vs Produced (v15-20)

Three habits closing the Contra-Thai "produced ≠ verified" bug class:

1. **Sub-agent return tagging** — every non-trivial claim (counts, status booleans, closures, DONE/SHIPPED) must be tagged `[VERIFIED: <command>]` (backed by executed command) or `[PRODUCED: unverified]` (artifact exists but not run). Validator: `bash tools/aegis-return-validator.sh check <file>`. See [`skills/aegis-return-format.md`](skills/aegis-return-format.md). (F-C)
2. **Sprint-close playtest gate** — for projects with coverage < 100%, `/aegis-sprint close` runs `bash tools/aegis-sprint-close-gate.sh check .` which checks for `_aegis-output/playtests/S<NN>-<NN>.md` with `verified_by:` + `pass: true`. Soft gate: warns but doesn't block. (F-B)
3. **Research probe-gate** — Beast must run `bash tools/aegis-research-probe.sh apply <file>` on any research doc citing URLs. URLs tagged `[PROBED ✓]`, `[PROBED ✗]`, or `[UNPROBED]`; downstream agents do NOT cite payload/schema from `[UNPROBED]` URLs. (F-E)

Driver: Contra-Thai research report 2026-05-20 — sub-agent returns conflated "produced" with "verified"; main agent inherited paper claims; sprint reports showed "100% velocity" while product didn't run; research-doc URLs cited without probe led to 5 fabricated API bugs.

## Applying AEGIS to Other Projects
See [`docs/AEGIS_APPLICATION_PLAYBOOK.md`](docs/AEGIS_APPLICATION_PLAYBOOK.md) for a step-by-step guide covering brain seeding, persona assembly, CLAUDE.md tailoring, BLOCK 0 bootstrap, and a greenfield React app walkthrough.

## Observability Helpers

| Tool | Purpose |
|------|---------|
| `tools/aegis-team-chat.sh` | Append inter-agent dialogue event (DISPATCH / REPORT / VERDICT / etc.) to today's chat log. Surfaces team conversation during processing — not just final results. |
| `tools/aegis-progress.sh` | Compute grand-total progress % against the roadmap. Denominator = all selected + planned scope. `--bar` / `--json` flags available. |
| `tools/aegis-log-decision.sh` | Nick Fury's decision-audit logger (S2-02). Every non-trivial decision gets one JSONL entry. |
| `tools/aegis-brain-index.sh` | Build/refresh FTS5 search index over `.aegis/brain/` (handoffs, retros, learnings, resonance, sprints, logs). v10-06 Hermes L1. `--full` / `--incremental` / `--stats`. |
| `tools/aegis-brain-search.sh` | Query the FTS5 brain index with ranked snippets + provenance. Filters: `--type` / `--since` / `--limit` / `--json`. v10-06 Hermes L1. |
| `.aegis/brain/sprints/roadmap.md` | Single source of truth for "how close are we to 100% done". Update on every sprint open/close. |

## v9 Transition State (largely shipped)

Spec-freshness audit on 2026-04-20 found the project is ~90% complete.
See [.claude/references/v9-follow-ups.md](.claude/references/v9-follow-ups.md)
for the single-page breakdown.

**Shipped in the meta-repo:**
- Sprints v9-01 through v9-06: foundation hardening, resilience design,
  brain seeding, memory-tool file layer, worktree isolation, agent
  consolidation (13→10), ADR-004 maintainer-mode override.
- Brain migrated: `.aegis/brain/` (POC dogfood complete).
- Backup retained: `.aegis-backup/_aegis-brain/` (untracked rollback net).

**Remaining in-repo work (~15-20pt)**:
- S2-02 retro-summary wiring (needs Nick Fury to first log decisions at runtime).
- S2-03/04 BLOCK 0 lite-mode switching (general gate is live; lite-mode skip logic not wired).
- S4-02 Nick Fury proxy dispatch loop (blocked on `memory_20250818` tool availability).
- S6-06 29→12 command cut (shipped v10-05: 18 shims removed, 12 canonical remain).

**Correctly deferred (not in-repo work)**: v9-07/08/09 brain-tier (infra),
v9-10/11 plugin (SDK), v9-12/13 MCP (infra), v9-14/15 migration+GA (6mo
calendar time).

**Plan doc**: [AEGIS_v9_UPGRADE_PLAN.md](AEGIS_v9_UPGRADE_PLAN.md) — the original
15-sprint, 482pt plan. Treat as historical architecture reference; current
state lives in `v9-follow-ups.md`.

**Migration tool**: [scripts/aegis-migrate-consolidate.sh](scripts/aegis-migrate-consolidate.sh) (one-time, moved to scripts/ in v10-05)
