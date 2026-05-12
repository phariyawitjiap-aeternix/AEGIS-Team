<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->
<!-- Source: Hermes-Agent v0.13.0 codebase + docs analysis -->

# v14 Series Plan — Hermes Parity + Audit Hardening

> Series-level plan covering 4 sprints / 47pt across 3 phases + 1 gated POC.
> Adopted into roadmap on 2026-05-12 (Decision D-XXX, framework-source).
>
> **Theme**: borrow Hermes operational patterns where ROI is high, preserve AEGIS's compliance/modularity edge.
>
> **Premise**: AEGIS is the methodology, Hermes is the runtime. Adopt Hermes's *operational discipline* without compromising AEGIS's *audit posture*.

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-12 | 1.0.0 | Initial v14 plan after Hermes-Agent codebase + docs analysis (38 docs pages + repo clone). |

---

## Source analysis

This plan is grounded in two artifacts (in this session):

1. **Full Hermes docs read** — 38 pages of `hermes-agent.nousresearch.com/docs/` plus `llms-full.txt` (1.8 MB concatenated docs)
2. **Hermes codebase analysis** — `git clone --depth=1` of `github.com/NousResearch/hermes-agent` (100 MB, 1,598 .py / 304 .ts / 960 .md, 13 CI workflows, 1,032 test files)

Findings cross-referenced against AEGIS's existing 22 brain dirs, 14 commands, 11 personas, 13 hooks, 62 tools, 38 skills, 60+ tests.

---

## Scope & non-goals

### In-scope (4 sprints / 47pt)

- Adopt Hermes patterns ranked **P0–P1** in gap analysis
- Preserve AEGIS strengths (modularity, MBP, audit trail, ISO 29110)
- Plug 3 measurable gaps: command registry, brain safety nets, security CI

### Out-of-scope (DEFERRED, not counted in denominator)

| Hermes feature | Why not adopted |
|---|---|
| Messaging gateway (25 platforms) | AEGIS lives in Claude Code; not a runtime |
| Voice / browser / image gen / RL trajectory | Outside framework concerns |
| Multi-profile system | Single-team focus is intentional |
| `skill_manage` agent self-modification | Violates ISO 29110 audit trail |
| `cli.py` mega-file pattern (13.5K LOC) | AEGIS modular shell architecture is **better** |
| 22 model providers | Claude Code handles model selection |
| `delegate_task` tool | Claude Code's `Agent` tool already covers this |
| `hermes kanban` SQLite board | Linear sync (v11-09 family) covers this |
| Hermes Curator full implementation | v10-07 pattern miner is the AEGIS-shaped equivalent (observed-only) |

### Gated on v10-08 unblock (separate decision)

- Curator full pattern (`agent/curator.py` 1,781 LOC) — only if L2 pattern-miner data hits 3-6mo accumulation OR human seeds instinct + 3 use-cycles per v10-08 SCOPED-DEFERRED criteria

---

## Roadmap math impact

```
Pre-v14 state (post v13-02-cleanup CLOSED):
  v9 in-repo:    73 / 69 = 100% (CLOSED)
  v10 in-repo:   47 / 47 = 100% (v10-08 SCOPED-DEFERRED)
  v11 TOTAL:     63 / 63 = 100%
  v12 TOTAL:     39 / 39 = 100%
  v13 TOTAL:     30 / 30 = 100%

Adding v14:
  v14-01 Phase A (governance polish):    13 pt
  v14-02 Phase B (brain safety nets):    13 pt
  v14-03 Phase C (operations hardening): 11 pt
  v14-04 Phase D (Persistent Goals POC): 10 pt — GATED
  ───────────────────────────────────────────────
  v14 selected:                          47 pt
```

After v14 ships: framework reaches **Hermes-parity on operational patterns** while keeping ISO 29110 audit posture.

---

## Sprint breakdown

### sprint-v14-01 — Command discipline + governance polish (13pt)

**Goal**: One source of truth for slash commands; harden brain content ingestion; close CI gap.

| ID | Title | Points | Hermes source |
|----|-------|--------|---------------|
| S14-01-01 | CommandDef central registry | 5 | `hermes_cli/commands.py` (65 entries → 6 consumers) |
| S14-01-02 | Brain content threat scanner | 3 | `tools/memory_tool.py:_MEMORY_THREAT_PATTERNS` (13 regex + 10 invisible chars) |
| S14-01-03 | Narrow supply-chain CI workflow | 5 | `.github/workflows/supply-chain-audit.yml` (no-noise discipline) |

#### S14-01-01 — CommandDef registry

**Why**: AEGIS has 14 commands across `.claude/commands/*.md` with no central registry. Adding a new command requires N edits. Hermes ports the entire surface from one `CommandDef` array.

**Files to touch**:
- NEW `tools/aegis-commands/registry.mjs` — `CommandDef`-equivalent dataclass + `COMMAND_REGISTRY` array (14 entries)
- NEW `tools/aegis-commands/render-help.mjs` — emits help text, autocomplete data, frontmatter validation
- EDIT 14× `.claude/commands/*.md` — switch from authoritative to derived (frontmatter pulls from registry)
- NEW `tests/aegis-commands-registry-test.sh` — regression test that registry covers all 14 .md files

**Acceptance criteria**:
- [ ] Adding a new command requires 1 edit (`registry.mjs`) — not N
- [ ] `aegis-commands list` outputs same 14 commands as `ls .claude/commands/`
- [ ] Aliases tuple support (e.g., `/aegis-status` ⇒ `/status`)
- [ ] Categories: Setup / Workflow / Inspection / Lifecycle (mirror Hermes "Session/Configuration/Tools&Skills/Info/Exit")
- [ ] Test: `aegis-commands-registry-test.sh` passes — registry ⊇ filesystem

#### S14-01-02 — Brain content threat scanner

**Why**: Hermes scans memory writes for prompt-injection / exfiltration / persistence patterns. AEGIS brain ingests external text (issue threads, sprint plans copy-pasted from elsewhere) with **zero scanning**. P0 MBP gap.

**Files to touch**:
- EDIT `tools/aegis-brain-write.sh` — pre-write threat regex check
- NEW `tools/aegis-brain-threat-patterns.yaml` — 13 patterns adapted from `tools/memory_tool.py:_MEMORY_THREAT_PATTERNS`:
  ```yaml
  prompt_injection:    'ignore\s+(previous|all|above|prior)\s+instructions'
  role_hijack:         'you\s+are\s+now\s+'
  deception_hide:      'do\s+not\s+tell\s+the\s+user'
  sys_prompt_override: 'system\s+prompt\s+override'
  disregard_rules:     'disregard\s+(your|all|any)\s+(instructions|rules|guidelines)'
  bypass_restrictions: 'act\s+as\s+(if|though)\s+you\s+(have\s+no|don''t\s+have)\s+(restrictions|limits|rules)'
  exfil_curl:          'curl\s+[^\n]*\$\{?\w*(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL|API)'
  exfil_wget:          'wget\s+[^\n]*\$\{?\w*(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL|API)'
  read_secrets:        'cat\s+[^\n]*(\.env|credentials|\.netrc|\.pgpass|\.npmrc|\.pypirc)'
  ssh_backdoor:        'authorized_keys'
  ssh_access:          '\$HOME/\.ssh|\~/\.ssh'
  aegis_env:           '\$HOME/\.aegis|\~/\.aegis'  # adapted
  ```
- Block 10 invisible unicode chars: `U+200B U+200C U+200D U+2060 U+FEFF U+202A-U+202E`
- NEW `tests/aegis-brain-threat-scan-test.sh` — fixture per pattern + invisible char + benign control

**Acceptance criteria**:
- [ ] `aegis-brain-write.sh` rejects content matching any pattern, returns clear error
- [ ] Invisible-char detection blocks `cat -v` payloads
- [ ] Existing brain content does NOT match any pattern (pre-flight scan)
- [ ] Test: 12 patterns + 10 chars + 5 benign = 27 fixtures pass

**Risk**: false positives on legitimate content (e.g., `learnings/` describing past attacks). Mitigation: `# scan-exempt: <reason>` opt-out comment.

#### S14-01-03 — Supply-chain audit CI workflow

**Why**: AEGIS has 2 workflows (lint + test). Hermes has 13. Most adoptable: `supply-chain-audit.yml` (narrow scope, no-noise discipline, AEGIS .mjs files have same vector as Hermes .py).

**Files to touch**:
- NEW `.github/workflows/supply-chain-audit.yml` — adapted from Hermes:
  - Trigger on PR to `**/*.mjs`, `**/*.sh`, `package.json`, `package-lock.json`
  - Check 1: pre-install / post-install script added to package.json
  - Check 2: `eval(...)` or `Function(...)` constructor introduced in any new .mjs
  - Check 3: outbound POST/PUT to non-allowlisted domain in any new .mjs
  - Check 4: `node_modules/` modification or `.npmrc` change
- NEW `tests/aegis-supply-chain-ci-test.sh` — local fixtures triggering each check
- COMMENT block in workflow citing Hermes commit (no-noise discipline)

**Acceptance criteria**:
- [ ] Workflow triggers on synthetic PR with bad fixture
- [ ] Workflow does NOT trigger on benign fixtures (false-positive rate measured at 0/10 control fixtures)
- [ ] Findings posted as PR comment with line-number citations
- [ ] Workflow takes <30s on average PR

---

### sprint-v14-02 — Brain safety nets (13pt)

**Goal**: Add reversibility to `.aegis/brain/` mutations + searchability to decision audit.

| ID | Title | Points | Hermes source |
|----|-------|--------|---------------|
| S14-02-01 | Shadow-git checkpoints for brain | 8 | `tools/checkpoint_manager.py` |
| S14-02-02 | `aegis-decision-search` tool | 5 | (no Hermes equivalent — AEGIS-original) |

#### S14-02-01 — Shadow-git brain checkpoints

**Why**: Today, edits to `.aegis/brain/MEMORY.md` / instincts / learnings are unrecoverable except via the working repo's git history (which doesn't track brain mutations atomically per-action). Hermes solved this with a shadow-git store under `~/.hermes/checkpoints/` that auto-snapshots before destructive ops.

**Files to touch**:
- NEW `tools/aegis-brain-checkpoint/store.sh` — initializes `.aegis/.brain-checkpoints/store/` (shadow git, content-addressable, deduplicated)
- NEW `tools/aegis-brain-checkpoint/snapshot.sh` — invoked by hook before mutations
- NEW `tools/aegis-brain-checkpoint/rollback.sh` — `--list`, `--restore <N>`, `--diff <N>`, `--restore <N> <file>`
- EDIT `.claude/settings.json` — add PreToolUse matcher on `Edit|Write|MultiEdit` when path matches `.aegis/brain/.*`
- NEW `.claude/commands/aegis-rollback.md` — slash command wiring
- EDIT `.gitignore` — add `.aegis/.brain-checkpoints/`
- NEW `tests/aegis-brain-checkpoint-test.sh` — fixtures for snapshot/restore/diff/single-file

**Pre-decided defaults** (Hermes verbatim per D-114):
- Storage path: `.aegis/.brain-checkpoints/store/`
- Cap: 20 checkpoints, 500MB total, 10MB per file
- Max 1 checkpoint per directory per turn

**Acceptance criteria**:
- [ ] Pre-write hook creates snapshot in <100ms (measured on 50-file brain)
- [ ] Caps enforced; oldest dropped round-robin
- [ ] `/aegis-rollback list` shows last 20 with timestamps + 1-line diffs
- [ ] `/aegis-rollback restore 3` reverts brain to that state AND emits a chat message documenting it
- [ ] Concurrent worktree writes safe via `flock(1)`

**Edge cases**:
- Brain mutation during `aegis-retro` write — snapshot must NOT include the partial retro
- Brain mutation during `aegis-handoff` — must include
- Concurrent worktree writes — file-lock via `flock(1)`

#### S14-02-02 — `aegis-decision-search`

**Why**: AEGIS has `decision-audit.log` (JSONL) with rich Nick Fury reasoning trails — but **no search tool**. Hermes has FTS5 session search. AEGIS already has FTS5 brain index (v10-06). Just extend it.

**Files to touch**:
- NEW `tools/aegis-decision-search.sh` — wraps `aegis-brain-search.sh` with `--type=decision` filter + JSONL parsing
- EDIT `tools/aegis-brain-index.sh` — index `decision-audit.log` lines as separate FTS5 doc-type
- NEW `.claude/commands/aegis-decisions.md` — slash command for inline use
- NEW `tests/aegis-decision-search-test.sh` — fixture decision log + 5 queries

**Acceptance criteria**:
- [ ] `aegis-decision-search "MBP escalation"` returns ranked decisions with timestamps + reasoner + outcome
- [ ] Filter by `--reasoner=nick-fury`, `--outcome=approved|rejected|deferred`, `--since=7d`
- [ ] JSON output mode (`--json`) for piping
- [ ] Index rebuild incremental (only new JSONL lines since last run)

---

### sprint-v14-03 — Operations hardening (11pt)

**Goal**: Self-diagnosis tools + first-run defer pattern audit/retrofit for v10-07.

| ID | Title | Points | Hermes source |
|----|-------|--------|---------------|
| S14-03-01 | `aegis-dump` redacted setup summary | 3 | `hermes dump` |
| S14-03-02 | First-run defer audit/retrofit for v10-07 | 5 | `agent/curator.py:should_run_now()` |
| S14-03-03 | Pinned-skill 2-axis semantic | 3 | `tools/skill_manager_tool.py:_pinned_guard` |

#### S14-03-01 — `aegis-dump`

**Why**: Hermes's `hermes dump` outputs shareable redacted setup summary (version, env, profile, model, terminal backend, API keys present/absent, features, services, workload, config overrides). AEGIS has `aegis-status-brief.sh` but lighter.

**Files to touch**: NEW `tools/aegis-dump.sh`

**Output structure** (mirror Hermes format):
```
--- aegis dump ---
version:        v12.0 (.aegis/brain/index v10-06)
framework_path: ~/Documents/AEGIS-Team
worktree:       <name> (path)
os:             Darwin 25.4.0 / arm64
shell:          zsh
git_branch:     <branch>
git_status:     clean | dirty (N files)
hooks:          standard | maximum (per AEGIS_HOOK_PROFILE)
agents:         11 personas + 6 teams
commands:       14 canonical
skills:         38 active / N marketplace
brain:          22 dirs, M sprints, K decisions logged
brain_index:    last-rebuild=<ts>, N entries indexed
human_queue:    K open items
external_keys:  linear=set | github=set | claude=auto (redacted)
recent_activity: 5 most-recent JSONL lines
--- end dump ---
```

`--show-keys` (mirror Hermes) shows redacted prefixes (e.g., `lin_api_*****abc`).

**Acceptance criteria**:
- [ ] Runs in <500ms
- [ ] Default output excludes secrets entirely; `--show-keys` shows last-4 only
- [ ] Output is paste-safe to Discord/Slack for support

#### S14-03-02 — First-run defer audit/retrofit for v10-07

**Why**: The Hermes Curator pattern includes a critical UX choice: on first observation, seed `last_run_at` to "now" and **defer the first real run by full interval**. Without this, every fresh AEGIS install would mass-mutate on first session-end.

**Step 1 (1pt)**: AUDIT `tools/aegis-pattern-mine.sh` to check if defer pattern already present.

**Step 2 (4pt, conditional)**: If missing, retrofit:
```bash
STATE=".aegis/brain/state/.pattern-miner-state.json"
if [ ! -f "$STATE" ]; then
  # First observation — seed and defer
  jq -n --arg ts "$(date -u +%FT%TZ)" \
    '{last_run_at: $ts, summary: "deferred first run — seeded, will run after one interval"}' \
    > "$STATE"
  exit 0
fi
# Then check interval gate
```
- Atomic state writes via `mktemp + mv` (mirroring Hermes's `tempfile + os.replace`)
- NEW `tests/aegis-pattern-mine-defer-test.sh`

**Acceptance criteria**:
- [ ] Fresh install does not run pattern miner on first session-end
- [ ] State file created on first observation, marks `deferred first run`
- [ ] Atomic write: never half-written state file
- [ ] Subsequent runs honor `interval_hours` gate

**Risk**: v10-07 may already implement this. If yes, story collapses to a 1pt audit + close-out.

#### S14-03-03 — Pinned-skill 2-axis semantic

**Why**: Hermes distinguishes pin = no-delete from pin = no-change (pinned skills can be patched but NOT deleted). AEGIS instinct pinning today is binary. Adopt the 2-axis split for instincts + skills.

**Files to touch**:
- EDIT `tools/aegis-instinct-promote.sh` — add `--pin-axis=delete|change|both` (default: `delete`)
- NEW `tools/aegis-skill-pin.sh` — pin/unpin skills with same axis option
- EDIT `tools/aegis-instinct-auto-reinforce.sh` — honor `--pin-axis=change`
- NEW `tests/aegis-pin-axis-test.sh`

**Acceptance criteria**:
- [ ] Default behavior unchanged (binary pin = no-delete)
- [ ] `--pin-axis=both` blocks both delete and change
- [ ] `--pin-axis=change` blocks change only
- [ ] Documented in CLAUDE_lessons.md

---

### sprint-v14-04 — Persistent Goals POC (10pt) — GATED

**Goal**: Proof-of-concept for Hermes's `/goal` Ralph-loop pattern in Nick Fury L3 autonomous mode. **NOT shipped to canonical commands until POC measured.**

| ID | Title | Points | Status |
|----|-------|--------|--------|
| S14-04-01 | Judge-loop POC | 5 | RESEARCH + IMPL |
| S14-04-02 | Measurement + decision | 5 | EXPERIMENT + REPORT |

**GATE** for v14-04 sprint-open: requires explicit human go (External Access budget + new pattern). To be revisited at end of v14-03 close.

#### S14-04-01 — Judge-loop POC

**Why**: Hermes `/goal` keeps a goal alive across turns via lightweight judge model after each turn. AEGIS's Decision Matrix is priority-queue-based, not goal-loop. For Nick Fury L3 autonomous mode, the Ralph-loop pattern would let "agent runs until goal achieved or 20-turn budget exhausted" — cleaner stop semantics than current polling.

**Scope (POC, not production)**:
- NEW `tools/aegis-goal/judge.sh` — calls Claude (auxiliary tier per `routing/policy.yaml`) with: goal text, last response, asks `goal_achieved: yes|no|unclear`
- NEW `tools/aegis-goal/state.sh` — load/save goal state per session at `.aegis/brain/state/goal-<session>.yaml`
- NEW `.claude/commands/aegis-goal.md` — `/aegis-goal <text> | pause | resume | clear | status`
- 20-turn budget enforced
- Stops on: judge=yes / user message / budget exhausted / explicit clear

**Acceptance criteria (POC, not full DoD)**:
- [ ] Judge call returns yes/no/unclear in <2s using Haiku tier
- [ ] State persists across `--continue` resume
- [ ] Documented in `.aegis/brain/learnings/v14-04-goal-pattern.md` with measured costs

#### S14-04-02 — Measurement + decision

**Methodology**:
- Run 5 real sprint-end retros via `/aegis-goal` instead of manual `/aegis-retro` orchestration
- Measure: judge cost per session (target <$0.10), false-positive rate (judge says done when not), session-completion rate, user-interruption rate
- Compare against control: 5 retros via current orchestration

**Decision criteria** (binary, pre-committed):
- IF judge cost < $0.10/session AND false-positive < 10% AND user-interrupt < 30% → **promote** to v15-XX sprint for canonical adoption
- ELSE → archive POC + log Decision D-XXX with rationale, REJECT pattern adoption

**Risk**: judge model latency adds friction in interactive sessions. Mitigation: run judge async after agent reply, only block if `enabled_inline=true`.

**Pre-committed POC budget cap**: $10 total across 10 measurement sessions. If exceeded, POC stops + reports.

---

## Risk register

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| Brain checkpoint hook adds >100ms latency to every brain edit | M | M | Use git plumbing (`git hash-object` + content-addressable) instead of full commit; benchmark before merge |
| Brain content threat scanner blocks legitimate content (e.g., `learnings/` describing past attacks) | M | M | `# scan-exempt: <reason>` opt-out comment; require justification |
| CommandDef registry desyncs from `.claude/commands/` markdown | L | L | Test asserts registry ⊇ filesystem; fail CI on mismatch |
| Supply-chain CI false-positives train reviewers to ignore | H | M | Adopt Hermes's no-noise discipline explicitly; remove low-signal checks at first false alarm |
| `aegis-pattern-mine.sh` retrofit breaks v10-07 (already-CLOSED sprint) | H | L | Audit-first sub-task; if defer-pattern already present, story collapses to 1pt close-out |
| Persistent Goals judge model adds cost | M | M | POC-first, kill-criterion explicit; budget cap $10 total |
| 47pt across 4 sprints exceeds typical AEGIS capacity | L | L | Sprints sized 13/13/11/10pt — within norm; v14-04 gated separately |

---

## Sequencing + dependencies

```
v14-01 (Polish — 13pt)
  ├── S14-01-01 (CommandDef) — independent
  ├── S14-01-02 (Threat scan) — depends on aegis-brain-write.sh existing (it does)
  └── S14-01-03 (Supply-chain CI) — independent

v14-02 (Safety nets — 13pt)
  ├── S14-02-01 (Brain checkpoints) — depends on .gitignore edit (1-line)
  └── S14-02-02 (Decision search) — depends on v10-06 FTS5 index (DONE)

v14-03 (Ops hardening — 11pt)
  ├── S14-03-01 (aegis-dump) — independent
  ├── S14-03-02 (Defer audit) — depends on v10-07 audit (1st task)
  └── S14-03-03 (Pin 2-axis) — independent

v14-04 (Goals POC — 10pt) — GATED on user OK + v14-01/02/03 closed
  ├── S14-04-01 (Judge POC) — depends on routing/policy.yaml having Haiku tier
  └── S14-04-02 (Measurement) — depends on S14-04-01
```

**Recommended order**: v14-01 → v14-02 → v14-03 → (decision gate) → v14-04.

**Estimated calendar time** at typical AEGIS velocity (1 sprint per session-day): 4 working days for v14-01 through v14-03, plus 2 days for v14-04 if gated through.

---

## DoD checklist (per sprint)

| Bar | sprint-v14-01 | v14-02 | v14-03 | v14-04 |
|-----|---------------|--------|--------|--------|
| §1 Functional | ✅ all 3 stories deliver tooling | ✅ checkpoints + search work | ✅ dump + defer + pin | ⚠️ POC only |
| §2 Tests | ✅ 3 new test files | ✅ 2 new test files | ✅ 3 new test files | ⚠️ measurement, not unit tests |
| §3 Safety | ✅ no new escalation paths | ✅ checkpoint = safer; threat scan = safer | ✅ no new paths | ⚠️ judge model = new external call |
| §4 Documentation | ✅ AGENTS.md updated for registry | ✅ ARCHITECTURE.md updated | ✅ AGENTS.md updated | ✅ learnings entry |
| §5 CI green | ✅ lint + test + new supply-chain | ✅ lint + test | ✅ lint + test | ⚠️ POC may skip |
| §6 Decision audit | ✅ D-XXX per story | ✅ D-XXX per story | ✅ D-XXX per story | ✅ D-XXX for go/no-go |
| §7 Roadmap | ✅ math reflects 13pt | ✅ math reflects 13pt | ✅ math reflects 11pt | ⚠️ POC = separate counter |
| §8 Retro | ✅ standard | ✅ standard | ✅ standard | ✅ measurement-driven |
| §9 Brain update | ✅ learnings + instincts | ✅ learnings | ✅ learnings | ✅ POC outcome → learning |

---

## Files-to-touch summary (47pt total)

```
NEW (new files):
  tools/aegis-commands/registry.mjs                       [v14-01-01]
  tools/aegis-commands/render-help.mjs                    [v14-01-01]
  tools/aegis-brain-threat-patterns.yaml                  [v14-01-02]
  tools/aegis-brain-checkpoint/{store,snapshot,rollback}.sh [v14-02-01]
  tools/aegis-decision-search.sh                          [v14-02-02]
  tools/aegis-dump.sh                                     [v14-03-01]
  tools/aegis-skill-pin.sh                                [v14-03-03]
  tools/aegis-goal/{judge,state}.sh                       [v14-04-01]
  .github/workflows/supply-chain-audit.yml                [v14-01-03]
  .claude/commands/aegis-rollback.md                      [v14-02-01]
  .claude/commands/aegis-decisions.md                     [v14-02-02]
  .claude/commands/aegis-goal.md                          [v14-04-01]
  tests/aegis-commands-registry-test.sh                   [v14-01-01]
  tests/aegis-brain-threat-scan-test.sh                   [v14-01-02]
  tests/aegis-supply-chain-ci-test.sh                     [v14-01-03]
  tests/aegis-brain-checkpoint-test.sh                    [v14-02-01]
  tests/aegis-decision-search-test.sh                     [v14-02-02]
  tests/aegis-pattern-mine-defer-test.sh                  [v14-03-02]
  tests/aegis-pin-axis-test.sh                            [v14-03-03]

EDIT (existing files):
  .claude/commands/*.md (×14)                             [v14-01-01 derive from registry]
  .claude/settings.json                                   [v14-02-01 hook wiring]
  tools/aegis-brain-write.sh                              [v14-01-02]
  tools/aegis-brain-index.sh                              [v14-02-02]
  tools/aegis-pattern-mine.sh                             [v14-03-02]
  tools/aegis-instinct-promote.sh                         [v14-03-03]
  tools/aegis-instinct-auto-reinforce.sh                  [v14-03-03]
  ARCHITECTURE.md                                         [v14-02-01 add concern→file row]
  AGENTS.md (root)                                        [v14-01-01 reference registry]
  .gitignore                                              [v14-02-01 add .brain-checkpoints/]
  .aegis/brain/sprints/roadmap.md                         [each sprint close]
```

**Net new**: ~19 new files, ~10 edits, 4 sprints, ~12 working hours per sprint at AEGIS velocity.

---

## Decision Audit slots (allocated at sprint-open time)

| Sprint | Topic | Reasoner |
|--------|-------|----------|
| v14 plan-adoption | Adopt v14 series — framework-source | Nick Fury (D-XXX, this turn) |
| v14-01-01 | CommandDef pattern adoption | Iron Man |
| v14-01-02 | Threat scanner patterns — 12 verbatim from Hermes | Loki review → Spider-Man impl |
| v14-01-03 | Supply-chain CI scope — narrow only | Thor |
| v14-02-01 | Shadow-git store path + caps | Iron Man + Loki (architecture review) |
| v14-02-02 | Extend FTS5 vs separate decision DB | Iron Man |
| v14-03-02 | v10-07 audit outcome | Black Panther |
| v14-03-03 | Pin axis default = `delete` (back-compat) | Captain America |
| v14-04 gate | Promote vs archive POC | Nick Fury (judgment-source, post-measurement) |

---

## Memory entries to honor (from session memory)

- **MBP regression class** — every "MUST" claim in this plan needs matching hook/test code (per "Policy-without-test bug class")
- **Run test before re-auditing known-failures** — for S14-03-02 audit task: graduate-by-running, not by-reading
- **External Access stays gated** — v14-04 budget approval at v14-04 sprint-open, not now
- **No menu, no pause** — sprint-opens are commands the user runs, not options I offer

---

## Series-level success criteria

When all 4 sprints close (or v14-04 archived):

- [ ] v14 in roadmap with all phases CLOSED or DEFERRED with rationale
- [ ] AEGIS reaches Hermes-parity on: command registry / brain content safety / brain rollback / decision search / setup diagnostics / first-run defer pattern / 2-axis pin
- [ ] AEGIS preserves: ISO 29110 audit trail, MBP, modularity, persona system, sprint discipline, no-LLM-authored content
- [ ] Net file count delta: +19 new, ~10 edits, 0 deletions
- [ ] All new tools have ≥1 test file
- [ ] All new docs have version header + changelog row

---

## Next step (no menu, no question)

Plan committed to brain at this path. Sprint-v14-01 is the next sprint-open candidate. To open it, run `/aegis-sprint plan v14-01` — that command will create `.aegis/brain/sprints/sprint-v14-01-command-discipline/plan.md` with stories pre-populated from this series-plan and update `roadmap.md` denominator.

This series plan is reversible: deletion of this file + sprint dirs + roadmap row reverts state. No external commitments made.
