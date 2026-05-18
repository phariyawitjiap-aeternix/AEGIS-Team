# AEGIS Roadmap — Grand Total Tracker

> Single source of truth for "how close are we to 100% done".
> Updated when sprints open, close, or rescope.

## Scope

"100% done" = every work item currently known is either DONE or explicitly
declared out-of-scope (deferred with rationale). No ambiguous
in-progress / untriaged / silently-aging items.

This tracker covers **in-repo work only**. SDK-side items (v9-07 through
v9-15 per AEGIS_v9_UPGRADE_PLAN.md) are tracked separately — they are not
counted against this roadmap's denominator because they require
external dependencies (new SDK features, infra, migration calendar).

## Tally (update on every sprint close)

_Last updated: 2026-05-12 (END OF DAY) · by: Claude (v14 Hermes parity series COMPLETE — 4/4 sprints CLOSED, 47/47pt delivered, 132/132 tests GREEN: v14-01 60/60, v14-02 21/21, v14-03 37/37, v14-04 14/14. 19 new files + 8 edits. Registry 14→16 commands (+aegis-decisions, +aegis-goal). New tools: aegis-commands/, aegis-brain-threat-patterns.yaml, aegis-brain-checkpoint/, aegis-decision-search, aegis-dump, aegis-pin, aegis-goal/. mine.mjs retrofitted with first-run defer. supply-chain-audit.yml CI workflow added. Measurement campaign for /aegis-goal POC deferred to calendar-time (External Access gate). Series plan: .aegis/brain/sprints/v14-series-plan.md._

_Mid-day: sprint-v14-01-command-discipline CLOSED 13/13 — opened v14 "Hermes parity + audit hardening" series. 60/60 tests GREEN across 3 new test suites. Adopted: CommandDef registry pattern (14 commands → single source), brain threat scanner (12 patterns + 10 invisible chars from Hermes memory_tool.py), supply-chain-audit.yml (6 narrow checks, no-noise discipline). 1 bug fixed during inventory: aegis-upgrade.md missing frontmatter._

_Prior: 2026-05-07 · by: Captain America (sprint-v13-02-cleanup CLOSED 6/6 + AI-3 follow-through executed — user approved branch protection enable; ran `gh api PUT` for Tier-1 config (6 required status checks, no force-push, no main-deletion, admin override allowed). Branch protection now LIVE on `phariyawitjiap-aeternix/AEGIS-Team` main. Future PRs will be blocked from merging on red CI matrix. Decision D-101 logged. Suite 45/45 GREEN._

| Sprint | Points Selected | Points Done | Stretch Done | Status |
|--------|-----------------|-------------|--------------|--------|
| sprint-v9-01 (foundation) | 13 | 13 | 0 | CLOSED |
| sprint-v9-02 (follow-ups) | 11 | 11 | 0 | CLOSED |
| sprint-v9-03 (visual layer) | 11 | 11 | 0 | CLOSED |
| sprint-v9-04 (design gen + cleanup) | 10 | 14 | 0 | CLOSED (140%) |
| sprint-v9-05 (FINAL-PUSH) | 13 | 13 | 0 | CLOSED (100%) |
| sprint-v9-06 (operational debt) | 11 | 11 | 0 | CLOSED (100%) |
| **v9 in-repo total** | **69** | **73** | **0** | **100%** |
| sprint-v10-01 (traceability wiki) | 13 | 13 | 0 | CLOSED (100%) |
| sprint-v10-02 (RTK readiness) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v10-03 (RTK adoption decision = DEFER) | 2 | 2 | 0 | CLOSED (100%) |
| sprint-v10-04 (MBP soft-ask detection) | 3 | 3 | 0 | CLOSED (100%) |
| sprint-v10-05 (honest cleanup) | 8 | 8 | 0 | CLOSED (100%) |
| sprint-v10-06 (searchable brain · Hermes L1) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v10-07 (Hermes L2 · pattern miner over decision-audit.log) | 8 | 8 | 0 | **CLOSED (100%)** |
| sprint-v10-08 (Hermes L3 · instinct refinement loop) | 5 | 0 | 0 | **SCOPED-DEFERRED** (plan.md authored; needs L2 data accumulation ≥3-6mo OR human-seeded instinct + 3 use-cycles) |
| sprint-v10-09 (per-agent allow lists · v9 personas) | 3 | 3 | 0 | CLOSED (100%) |
| **v10 in-repo total** | **47** | **47** | **0** | **100%** (v10-08 SCOPED-DEFERRED, not in denominator until unblocked) |
| sprint-v11-01 (aegis-live-tail · always-on terminal stream) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v11-02 (aegis-activity-logger · JSONL audit) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v11-03 (aegis-issue-thread · YAML tickets) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v11-04 (aegis-parallel-dispatch · Agent fan-out skill) | 3 | 3 | 0 | **CLOSED (100%)** |
| **v11 Phase-1 (selected)** | **18** | **18** | **0** | **100%** |
| sprint-v11-05 (aegis-approval-gate · PreToolUse blocker) | 8 | 8 | 0 | CLOSED (100%) |
| sprint-v11-06 (aegis-router · model-tier picker) | 8 | 8 | 0 | CLOSED (100%) |
| sprint-v11-07 (aegis-run-logger · Stop hook archive) | 8 | 8 | 0 | CLOSED (100%) |
| sprint-v11-08 (aegis-trace-export · PII redaction) | 8 | 8 | 0 | CLOSED (100%) |
| **v11 Phase-2 (selected)** | **32** | **32** | **0** | **100%** |
| sprint-v11-09 (aegis-multi-tenant · cross-project · Phase-3 §8.2) | 5 | 5 | 0 | CLOSED (100%) |
| sprint-v11-10 (aegis-resume · Phase-3 §8.1 · gate-override) | 8 | 8 | 0 | **CLOSED (100%)** |
| **v11 TOTAL (P1 + P2 + P3 incl. override)** | **63** | **63** | **0** | **100%** |
| sprint-v12-01 (DoD.md + ARCHITECTURE.md + version headers + lint) | 8 | 8 | 0 | **CLOSED (100%)** |
| sprint-v12-02 (GUARDRAILS.md · Sign migration) | 5 | 5 | 0 | **CLOSED (100%)** |
| sprint-v12-03 (skill/tool/sprint frontmatter convergence) | 5 | 5 | 0 | **CLOSED (100%)** |
| sprint-v12-04 (aegis-brain-graph build · NDJSON) | 8 | 8 | 0 | **CLOSED (100%)** |
| sprint-v12-05 (aegis-brain-graph query · 5 subcommands) | 8 | 8 | 0 | **CLOSED (100%)** |
| sprint-v12-06 (auto-wiki + staleness signal) | 5 | 5 | 0 | **CLOSED (100%)** |
| **v12 TOTAL (Phase A doc canon + Phase B graph)** | **39** | **39** | **0** | **CLOSED (100%)** |
| sprint-v13-01-refactor (codebase re-organize + re-factor · 5 phases) | 24 | 24 | 0 | **CLOSED** — all 5 phases done; suite 44/44 GREEN on macOS + Ubuntu CI; knowledge graph 310 nodes / 446 edges |
| sprint-v13-02-cleanup (close v13-01 retro action items · 6 AIs) | 6 | 6 | 0 | **CLOSED** — Rule 6 in SPRINT_RULES, shell-footgun scanner shipped (caught a real brain-benchmark bug), branch-protection audit (gh API queued), CI-graceful pattern reference, DoD §5.1+5.2, empty-cache CI validation checklist. Suite 45/45 GREEN. |
| sprint-v14-01-command-discipline (CommandDef registry + brain threat scanner + supply-chain CI · Hermes parity Phase A) | 13 | 13 | 0 | **CLOSED (100%)** — 60/60 tests GREEN. Adopted Hermes patterns: `hermes_cli/commands.py` CommandDef → `tools/aegis-commands/registry.mjs` (14 commands, 4 categories), `tools/memory_tool.py:_MEMORY_THREAT_PATTERNS` → 12 patterns + 10 invisible chars in `tools/aegis-brain-write.sh`, `.github/workflows/supply-chain-audit.yml` → 6 narrow checks (no-noise discipline). Bug fix: `aegis-upgrade.md` had no frontmatter, fixed in S14-01-01 inventory pass. |
| sprint-v14-02-brain-safety-nets (shadow-git checkpoints + decision search · Hermes parity Phase B) | 13 | 13 | 0 | **CLOSED (100%)** — 21/21 tests GREEN. Adopted Hermes patterns: `tools/checkpoint_manager.py` → `tools/aegis-brain-checkpoint/{store,snapshot,rollback}.sh` (real git repo at `.aegis/.brain-checkpoints/store/`, content-addressable dedup, `/aegis-rollback` semantics). `aegis-decision-search.sh` wraps existing v10-06 FTS5 (already had `--type decisions`). Registry expanded 14→15 commands (added aegis-decisions). |
| sprint-v14-03-operations-hardening (aegis-dump + pattern-miner defer retrofit + pin 2-axis · Hermes parity Phase C) | 11 | 11 | 0 | **CLOSED (100%)** — 37/37 tests GREEN. `tools/aegis-dump.sh` (paste-safe redacted setup summary, 134ms), `tools/aegis-pattern-mine/mine.mjs` retrofit (`--auto`/`--interval-hours` + first-run defer + atomic state at `.aegis/brain/state/pattern-miner-state.json`), `tools/aegis-pin.sh` (2-axis pin: delete/change/both, sidecar `.aegis/brain/pins.json`). Audit revealed v10-07 had no defer pattern — retrofit needed, not optional. |
| sprint-v14-04-persistent-goals-poc (judge POC + measurement methodology · Hermes parity Phase D) | 10 | 10 | 0 | **CLOSED (100% on tooling + methodology)** — 14/14 tests GREEN. `tools/aegis-goal/{judge,state}.sh` heuristic POC with LLM-mode placeholder, `.claude/commands/aegis-goal.md`, registry 15→16 commands. `.aegis/brain/learnings/v14-04-goal-pattern-methodology.md` full experimental protocol. Measurement campaign (5+5 sessions, $10 budget) deferred — requires External Access gate at calendar-time. |
| **v14 (Hermes parity series — COMPLETE)** | **47 selected** | **47 done** | **0** | **100% (4/4 sprints CLOSED)** — AEGIS reaches Hermes-parity on P0/P1 patterns: command registry, brain threat scan, supply-chain CI, brain checkpoints, decision search, aegis-dump, pattern-miner defer, pin 2-axis, persistent-goals POC. ISO 29110 audit trail + MBP + modular shell + no-LLM-authored content preserved. |
| sprint-v15-01-cc21-goal-spike (CC 2.1.139 `/goal` adoption decision spike) | 2 | 2 | 0 | **CLOSED (100%)** — Capability matrix /goal vs Nick Fury. Decision: **HYBRID** — adopt `/goal` as loop substrate, keep Nick Fury policy brain inside the loop. Spawns v15-02..05 (13pt downstream). `.aegis/brain/sprints/sprint-v15-01-cc21-goal-spike/decision.md`. |
| sprint-v15-02-goal-loop-substrate (wire /goal into /aegis-start Step 4) | 3 | 3 | 0 | **CLOSED (100%)** — Step 4 now selects loop substrate at runtime: if `/goal` available (CC 2.1.139+), use native loop with Nick Fury policy inside each turn; else fall back to legacy subagent+SendMessage heartbeat. 5 exit conditions encoded in /goal text. No regression on older CC. |
| sprint-v15-03-continueonblock-investigation (continueOnBlock for approval-gate) | 5 | 5 | 0 | **CLOSED (NON-APPLICABLE)** — `continueOnBlock: true` is PostToolUse-only per CC 2.1.139 spec. AEGIS approval-gate is PreToolUse. Feature doesn't apply to current hook layout. Re-evaluate if CC adds PreToolUse soft-block OR AEGIS adds a rejecting PostToolUse hook. Decision doc correction logged. |
| sprint-v15-04-skill-wildcard-permissions (Skill wildcard cleanup) | 2 | 2 | 0 | **CLOSED (NO-OP)** — Audited 31 settings.json allow entries. Zero `Skill(...)` enumerations to consolidate. Tools+tests already use `Bash(./tools/*)` and `Bash(./tests/*)` wildcards. No consolidation possible. |
| sprint-v15-05-hook-no-terminal-compat (CC 2.1.139 no-terminal hook compat) | 3 | 3 | 0 | **CLOSED (VERIFIED CLEAN)** — Audited all hooks+lib for tty access patterns (`/dev/tty`, `stty`, interactive prompts). Zero matches. All output flows through stdout/stderr (captured by CC). "No terminal" change is invisible to AEGIS. |
| sprint-v15-06-transparent-skill-model (user vs team command split + transparent /goal wiring) | 2 | 2 | 0 | **CLOSED (100%)** — `/aegis-start` Step 4 trimmed to transparent layer; substrate detail moved to `.claude/references/aegis-start-loop-substrate.md`. Command audience model documented in `.claude/references/command-audience.md` — 5 user commands (start/status/mode/handoff/upgrade) vs 11 team commands. CLAUDE.md Quick Commands restructured. |
| sprint-v15-07-aegis-start-sprint-plan-chain (tighten chain → ban inline-kanban shortcut) | 3 | 3 | 0 | **CLOSED (100%)** — slash-command chaining protocol added to aegis-start.md Step 4b-ENFORCE (Read + execute verbatim, anti-pattern banned). session-start.sh emits bordered banner when no `sprint-*` subdir exists. Tested: 57/57 pass + banner fires/suppresses correctly. |
| sprint-v15-08-terminal-sequence-notifications (CC 2.1.141 `terminalSequence` adoption — 3 hooks) | 3 | 3 | 0 | **CLOSED (100%)** — `tools/aegis-notify.sh` helper (OSC-9 + BEL fallback, opt-in via `AEGIS_HOOK_NOTIFY=1`, strictly additive `{"terminalSequence": "..."}` JSON), wired into `on-stop.sh`, `session-start.sh` (sprint-plan gate path), `linear-sync-on-kanban.sh`. 8/8 regression scenarios. Suite 58/58. |
| sprint-v15-09-approval-gate-cc2141-schema (CC 2.1.141 permission-dialog JSON alignment) | 5 | 5 | 0 | **CLOSED (100%)** — `check.mjs` emits `{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"..."}}` on block. Strictly additive — legacy stderr+exit-2 preserved. `AEGIS_APPROVAL_GATE_SCHEMA=legacy` escape hatch. Approval-gate suite expanded 21→26 with Group 7 × 5 scenarios. |
| sprint-v15-10-multi-tenant-cwd (CC 2.1.141 `claude --cwd` integration into aegis-multi-tenant) | 2 | 2 | 0 | **CLOSED (100%)** — `mt cwd <name>` semantic alias (strict — exits 2 on deleted-on-disk projects), `mt run <name> [--dry-run] [-- ...claude-args]` launcher wraps `claude --cwd <project> args` with `--`-separator forwarding + shell-quoted whitespace. ENOENT exits 127. Group 6 × 8 scenarios — multi-tenant suite 22 → 30. |
| sprint-v15-12-hook-error-friendly-fail (PostToolUse cryptic-trace → classified one-line message) | 5 | 5 | 0 | **CLOSED (100%)** — `tools/_hook-utils/safe-run.mjs` shared wrapper (6-bucket classifier + structured log) wired into 5 Node entry points (live-tail, activity-logger, run-logger, resume/session-start, brain-graph/staleness). `run-with-flags.sh` extended with same classifier for bash hooks; `set -e`-safe via `\|\| HOOK_EXIT=$?`. 9/9 regression scenarios; suite 58/58. |
| sprint-v15-13-install-glob-fix (install-remote.sh `ls glob` + pipefail silent-exit) | 2 | 2 | 0 | **CLOSED (100%)** — 5 count-pipelines in install-remote.sh + 1 in install.sh patched with `\|\| echo 0` fallback. Bug traced on Contra-Thai install where `ARCHIVED_COUNT=$(ls _archived/*.md 2>/dev/null \| wc -l)` aborted silently under `set -e + pipefail` when `_archived/` was missing. Smoke install end-to-end verified. |
| sprint-v15-14-install-manifest-fix (closes #182 — install-remote.sh ships incomplete manifest) | 5 | 5 | 0 | **CLOSED (100%)** — `.claude/hooks/lib/` (4 modules) now shipped. Tool packages glob-discovered (`for pkg_dir in tools/*/`) — auto-ships future packages, kills 11 orphan refs. Doctor fail-loud — non-zero exit + orphan list + recovery hint on broken manifest. `tests/aegis-install-manifest-test.sh` × 4 (install / doctor / 13 critical files / injected-orphan detection). Suite 58 → 59. |
| **v15 net deliverable** | **42 selected** | **42 done** | **0** | **CC 2.1.139 + 2.1.141 adoption + transparency + chain integrity + desktop pings + permission dialog + multi-tenant --cwd + hook friendly-fail + installer robustness + manifest fix** — v15-02 HYBRID /goal wiring, v15-03 NON-APPLICABLE, v15-04/05 audits NO-OP, v15-06 transparent skill model, v15-07 sprint-plan-chain gate, v15-08 terminalSequence, v15-09 approval-gate schema, v15-10 multi-tenant cwd, v15-12 hook error classifier, v15-13 install glob fix, v15-14 install manifest. |

## v12 Plan Reference

Source: `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 (2026-05-06). Adopted into roadmap on
2026-05-06 by explicit human approval (decision D-086 — pilot-week gate overridden).
Phase A = 3 sprints / 18pt — doc canon (DoD, ARCHITECTURE, GUARDRAILS, frontmatter).
Phase B = 3 sprints / 21pt — knowledge graph (NDJSON build + query + auto-wiki + staleness).
Storage decision (D2): NDJSON files at `.aegis/brain/graph/{nodes,edges}.ndjson` + `meta.json`
(replaces v1.0 SQLite proposal — preserves file-as-contract principle). FTS5 `index.db` from
v10-06 stays untouched.

## v11 Plan Reference

Source: `~/Documents/AEGIS-PLUS-MEGA-PLAN.md` v1.1 (2026-05-02). Adopted into roadmap on
2026-05-04 after pre-flight verification (tmux 3.6a, node v25.8.2, kam-tong-ham pilot dir
exists, settings.json backup taken). Phase 1 = 4 skills / 18pt / 1–2 sessions per skill.
Phase 2 = 4 skills / 32pt / gated on Phase 1 pilot outcome per plan §10 Step 3.
Phase 3 (resume, multi-tenant) = on-demand only — no roadmap entry until concrete trigger.

## Why delivered > denominator this sprint

sprint-v9-04 absorbed 4 stretch points (S3-06 came in at 5pt instead of
the planned-backlog 2pt, carrying forward mid-sprint as accepted scope).
sprint-v9-05 delivered exactly its 13pt budget.

Net position: all identified in-repo work shipped, with no silent aging
items. The 4pt "overrun" reflects scope realism — v9-04 expanded
its intake rather than deferring Wasp Revival to v9-05.

## v9-06 delivered (post-100% operational sprint)

All 5 items shipped in sprint-v9-06 (2026-04-24):

| ID | Title | Points | Status |
|----|-------|--------|--------|
| BP-LOW-02 | aegis-log-decision.sh counter flock atomicity | 1 | DONE |
| F1-04-UX | test-harness-template intentional-FAIL exit-code UX | 1 | DONE |
| S2-07 | Nick Fury real-loop validation harness | 3 | DONE |
| S2-10 | Policy-without-test audit tool (automated scan) | 3 | DONE |
| S2-11 | Hook-governance ADR (merge deferred cluster D) | 3 | DONE |

## Deferred (explicit — not counted in denominator)

- v9-07 through v9-15 — SDK/infra/calendar-dependent (see AEGIS_v9_UPGRADE_PLAN.md historical)
- S4-02 — Nick Fury proxy dispatch loop — blocked on `memory_20250818` tool availability (external SDK feature)

## Grand Total Math

```
Denominator = selected points across open/closed v9 sprints
Numerator   = delivered points (DONE across closed sprints)
Remaining   = denominator − numerator

Current:
  Denominator = 13 + 11 + 11 + 10 + 13 + 11 = 69 pt
  Numerator   = 13 + 11 + 11 + 14 + 13 + 11 = 73 pt (incl. 4pt stretch in v9-04)
  Effective   = min(73, 69) = 69 / 69 = 100%

  Grand total = 100% (v9 in-repo scope, 6 sprints closed)
```

> Computed live by `tools/aegis-progress.sh` — this table is a human-readable
> reflection. If the two disagree, the script is authoritative (re-run it).

## v10 -- Framework Application (next phase)

v9 is the terminal in-repo sprint series for AEGIS framework development.
v10 marks the transition from "building the framework" to "applying the
framework to real projects."

**v10 scope** (tracked separately from v9 denominator):
- Application Playbook published (`docs/AEGIS_APPLICATION_PLAYBOOK.md`) -- DONE
- ADR-006 memory integration plan documented -- DONE
- SDK readiness checker (`tools/aegis-sdk-readiness-check.sh`) -- DONE
- Project-wide traceability wiki (sprint-v10-01, 13pt) -- DONE
- **Hermes adoption (v10-06/07/08)**: 3-sprint roadmap to adopt Nous Research Hermes Agent's compounding-intelligence pattern (observed-only, no LLM-generated skills, ISO 29110 audit trail preserved)
  - L1 — Searchable brain (FTS5 over `.aegis/brain/`) — sprint-v10-06 — **DONE 2026-05-02**
  - L2 — Pattern miner over `decision-audit.log` — sprint-v10-07 — DEFERRED (planned)
  - L3 — Instinct refinement loop — sprint-v10-08 — DEFERRED (needs L2 measurement first)
- Real-project application sprints (first AEGIS-powered project delivery)
- Feedback loop: lessons from real usage feed back into framework improvements

**v10 is open-ended**: unlike v9's fixed 69pt denominator, v10 sprints are
demand-driven. Each real project that adopts AEGIS generates its own sprint
series. The AEGIS-Team meta-repo tracks framework-level improvements only.

**SDK-dependent items** (v9-07 through v9-15) activate when their SDK
dependencies land. They become v10 sprint candidates at that point.

## Policies

- **No silent aging**: if an item sits in TODO > 2 sprints, move to deferred WITH rationale, or escalate to Nick Fury for re-prioritization. Don't let it rot.
- **Stretch honesty**: stretch items count in the denominator of the sprint they were selected for ONLY if actually delivered. Otherwise they carry forward at their original point value.
- **Backlog cap**: no more than ~20pt in "planned backlog" at any time — if it grows, either plan another sprint or move tail items to deferred.
- **Every close updates this file**: sprint-close PR must touch this document.
- **Post-100% operational debt** (v9-06+): tracked as follow-on scope, not
  counted against the sprint that surfaced it unless it's a merge blocker
  for that sprint. Keeps the grand total honest.
