<p align="center">
  <img src="https://img.shields.io/badge/version-9.0-blue?style=for-the-badge" alt="Version 9.0"/>
  <img src="https://img.shields.io/badge/agents-10-green?style=for-the-badge" alt="10 Agents"/>
  <img src="https://img.shields.io/badge/skills-30-orange?style=for-the-badge" alt="30 Skills"/>
  <img src="https://img.shields.io/badge/commands-29-yellow?style=for-the-badge" alt="29 Commands"/>
  <img src="https://img.shields.io/badge/gates-6-red?style=for-the-badge" alt="6 Gates"/>
  <img src="https://img.shields.io/badge/hooks-9-teal?style=for-the-badge" alt="9 Hooks"/>
  <img src="https://img.shields.io/badge/tools-20+-slategray?style=for-the-badge" alt="20+ Helper Tools"/>
  <img src="https://img.shields.io/badge/tests-76%2F76-brightgreen?style=for-the-badge" alt="Test Suite"/>
  <img src="https://img.shields.io/badge/ISO--29110-compliant-brightgreen?style=for-the-badge" alt="ISO 29110"/>
  <img src="https://img.shields.io/badge/Claude_4.x-1M_context-blueviolet?style=for-the-badge" alt="Claude 4.x"/>
  <img src="https://img.shields.io/badge/license-MIT-purple?style=for-the-badge" alt="MIT License"/>
</p>

# :shield: AEGIS v9.0 — AI Agent Team Framework for Claude Code

> **"Context is King, Memory is Soul"**
>
> :dna: Nick Fury · 10 Marvel Agents · 30 Skills · 29 Commands · 6-Gate Quality · 9 Hooks · 20+ Helper Tools · ISO 29110 · Claude 4.x 1M Context

---

## :sparkles: What's new in v9.0

**Framework hardening + brain layer + ecosystem prep.** 482-point plan, ~99% of in-repo work shipped. Full audit in [.claude/references/v9-follow-ups.md](.claude/references/v9-follow-ups.md).

### Agent consolidation (13 → 10)
- **War Machine absorbed Vision** (QA Lead + Executor combined)
- **Coulson absorbed Songbird** (docs + content merged)
- **Wasp retired** (UX → Spider-Man + style guide)
- Archived prompts preserved in `.claude/agents/_archived/` for reference

### Brain layer (Sprint v9-03 / v9-04)
- `.aegis/brain/` single-folder home (was `_aegis-brain/`)
- `tools/aegis-brain-sync.sh` regenerates `MEMORY.md` index atomically
- `tools/aegis-brain-write.sh` library/CLI for atomic brain writes + S4-02 proxy directive for `memory_20250818`
- Session-start hook combines version check + brain sync
- Adversarial test suite (`aegis-brain-adversarial-test.sh`, 9/9 green)

### Worktree isolation (Sprint v9-05)
- `tools/aegis-merge-worktree.sh` — rebase-onto-HEAD + `-f -f` cleanup escalation
- Spider-Man default: `isolation: worktree` for code edits
- Real blast-radius via git boundaries, not just markdown rules

### ADR-004: `AEGIS_MAINTAINER_MODE` (Sprint v9-02)
Principled override channel so the framework can evolve in-session when the human explicitly authorizes:
- `tools/aegis-maintainer-grant.sh` — human-run token generator
- Token format: `<path>|<nonce>|<expiry-epoch>`, one-shot, 60s TTL
- `guard-write.sh` honors valid grants; `guard-bash.sh` blocks agent self-grants
- 23/23 test assertions across scope escape, one-shot consume, expiry, concurrent grants

### BLOCK 0 lite mode (Sprint v9-02)
- `tools/aegis-block0-mode.sh` — lite/standard/full mode per task
- 1pt chores skip SI.01/SI.02; security/breaking tags force full gate
- Nick Fury + Coulson agent prompts wired; 31/31 test assertions

### S6-01 distill reminder (Sprint v9-06)
- Session-start counter + auto-reminder at threshold
- `/aegis-distill` resets via `tools/aegis-distill-reset.sh`
- 13/13 test assertions; no external scheduler needed

### Hardened permissions (Sprint v9-01)
- `defaultMode: acceptEdits` (was `bypassPermissions` — security-sensitive change)
- 26 deny patterns (was 8), 20 scoped allow (was 60+ wildcards)
- `guard-bash.sh` blocks Golden Rule violations + dangerous ops

### New ops tools
- `aegis-status-brief.sh` — single-command repo dashboard
- `aegis-test-all.sh` — unified runner across 4 test suites (76/76 green)
- `aegis-agent-tools-matrix.sh` — subagent tool availability pre-flight
- `aegis-pending-items.sh` — spec-freshness audit primitive

### Ecosystem handoff docs
- [AEGIS_v9_ECOSYSTEM_GUIDE.md](AEGIS_v9_ECOSYSTEM_GUIDE.md) — bootstrap for v9-07 through v9-15 (brain-tier, MCP, plugin, migration+GA) as separate engineering streams
- [AEGIS_EXTERNAL_ADOPTION.md](AEGIS_EXTERNAL_ADOPTION.md) — apply AEGIS to a non-meta target project

---

## What is AEGIS?

AEGIS (**A**utonomous **E**nhanced **G**roup **I**ntelligence **S**ystem) — production-grade AI agent team framework for Claude Code. 10 Marvel-character agents, 14-stage SDLC pipeline, 6-gate quality (including a mandatory pre-work gate), ISO 29110 compliance, JIRA-like PM, self-enforcing instinct system, principled maintainer-override channel, real worktree isolation. :dna: ยิ่งใช้ยิ่งเก่ง.

---

## :rocket: New Install (one command)

**Step 1 — Install prerequisites (skip if already done):**

```bash
brew install node && npm install -g @anthropic-ai/claude-code
```

**Step 2 — Initialize your project:**

```bash
cd ~/Documents/my-project && git init && git commit --allow-empty -m "init"
```

**Step 3 — Install AEGIS:**

```bash
bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/install-remote.sh) --profile full --project-name "My Project"
```

> :bulb: Profile options: `minimal` (7 skills) · `standard` (15 skills) · `full` (30 skills)

**Step 4 — Set permissions (one-time):**

```bash
cat > ~/.claude/settings.json << 'EOF'
{"permissions":{"defaultMode":"bypassPermissions","allow":["Bash","Edit","Write","Read","Glob","Grep","Agent","TeamCreate","TeamDelete","SendMessage"]},"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}
EOF
```

**Step 5 — Start:**

```bash
claude --dangerously-skip-permissions
```

Then type `/aegis-start`. Nick Fury will scan your project, check **BLOCK 0** (required ISO docs + kanban), and begin autonomously.

**What you get with a fresh install:**

| | |
|--|--|
| :dna: **13 Marvel agents** | Nick Fury, Iron Man, Spider-Man, Black Panther, Loki, Coulson, Thor + 6 more |
| :lock: **BLOCK 0 gate** | Coulson creates PM.01 + SI.01 + SI.02 + kanban before any code is written |
| :brain: **Claude 4.x models** | Opus 4.6 (1M ctx) for thinkers · Sonnet 4.6 (1M ctx) for builders · Haiku 4.5 for scanners |
| :chart_with_upwards_trend: **Adaptive thinking** | Each agent uses the right reasoning depth (`max` → `low`) |
| :scroll: **ISO 29110** | 14 work products, activity-time generation, traceability matrix |

---

## :arrows_counterclockwise: Upgrade Existing Install

> :warning: **Exit Claude Code before upgrading** — Claude caches files at session start

**Step 1 — Run the upgrade:**

```bash
cd ~/Documents/my-project
bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/install-remote.sh) --upgrade
```

**Step 2 — Restart:**

```bash
claude --dangerously-skip-permissions
```

**What `--upgrade` does:**

| Step | Action |
|:----:|--------|
| 1 | :lock: **Backup** `.aegis/brain/` (plus `_aegis-brain/` for v8 users), `iso-docs/`, `CLAUDE_lessons.md`, and `.claude/settings.json` → `_aegis-backup-<timestamp>/` |
| 2 | :arrows_counterclockwise: **Migrate** (v8→v9 only) `_aegis-brain/` → `.aegis/brain/` if the new path doesn't exist yet |
| 3 | :wastebasket: **Remove** old agents, commands, references, teams, skills |
| 4 | :arrow_down: **Download** latest AEGIS from GitHub (to `/tmp/`, auto-cleaned) |
| 5 | :package: **Install** 10 Marvel agents, 29 commands, 25+ references, 7 teams, 30 skills, 9 hooks, 20+ helper tools |
| 6 | :mag: **Verify** all files present + auto-detect profile from project-identity.md |

**What's new in v9.0 (vs v8.4):**

| Change | Details |
|--------|---------|
| :busts_in_silhouette: Agent consolidation | 13 → 10 agents. War Machine absorbed Vision, Coulson absorbed Songbird, Wasp retired. Archived in `.claude/agents/_archived/` |
| :brain: Brain folder move | `_aegis-brain/` → `.aegis/brain/`. Single-folder home; installer auto-migrates on upgrade |
| :floppy_disk: Brain sync/write | `tools/aegis-brain-sync.sh` (atomic MEMORY.md regen) + `tools/aegis-brain-write.sh` (atomic write + S4-02 `memory_20250818` proxy directive) |
| :twisted_rightwards_arrows: Worktree isolation | `tools/aegis-merge-worktree.sh` with stale-ancestor rebase + process-lock escalation. Spider-Man default: `isolation: worktree` |
| :key: ADR-004 override | `AEGIS_MAINTAINER_MODE` scoped, time-bounded, one-shot grant for principled framework evolution. `tools/aegis-maintainer-grant.sh` |
| :white_check_mark: BLOCK 0 lite mode | Per-task mode (lite/standard/full). 1pt chores skip SI.01/SI.02; security forces full. `tools/aegis-block0-mode.sh` |
| :lock: Hardened permissions | `defaultMode: acceptEdits` (was bypassPermissions); 26 deny patterns, 20 scoped allow |
| :chart_with_upwards_trend: 76/76 test suite | `tools/aegis-test-all.sh` runs 4 suites: brain-adversarial, maintainer-mode, distill-counter, block0-mode |
| :scroll: Ecosystem docs | [AEGIS_v9_ECOSYSTEM_GUIDE.md](AEGIS_v9_ECOSYSTEM_GUIDE.md) + [AEGIS_EXTERNAL_ADOPTION.md](AEGIS_EXTERNAL_ADOPTION.md) |

**:lock: NEVER touched by upgrade:** `.aegis/brain/` (tasks, sprints, patterns, learnings), `iso-docs/`, `CLAUDE_lessons.md`, project source code. The old `_aegis-brain/` is preserved in the backup dir.

---

## :movie_camera: See It In Action

### `/aegis-start` — Mother Brain activates with heartbeat

```
🛡️ ═══════════════════════════════════════════════════
🛡️  AEGIS v9.0 — Session Started
🛡️  "Context is King, Memory is Soul"
🛡️ ═══════════════════════════════════════════════════

📋 Project:    My SaaS App
📅 Date:       2026-03-30
🎚️  Profile:    full (25 skills)
🔐 Autonomy:   L3 — Autonomous (Mother Brain active)
📊 Context:    8% used

🧬 Mother Brain: ONLINE — persistent heartbeat active

💓 Heartbeat: Scanning project state...
   Mother Brain will continuously monitor and dispatch agents.
   She never sleeps until the session ends.

👀 Watch: Shift+Down to view agent detail | Shift+Up to return
🛑 Stop: Ctrl+C to interrupt | /aegis-mode --autonomy L1 for manual
```

```
🧬 Mother Brain: Scan complete.

📊 Scan Results:
  ├── Git: clean (main, 12 commits)
  ├── Tests: PASS (28/28)
  ├── Sprint: sprint-2 active (day 3/5)
  ├── Kanban: 3 TODO, 1 IN_PROGRESS, 2 DONE
  ├── QA: pending for PROJ-T-007
  ├── Compliance: 8/11 ISO docs current
  └── Tech Debt: 5 TODOs, 2 FIXMEs

🎯 Decision: P2.5 — Active sprint, pick next TODO from kanban
   Task: PROJ-T-008 "Add payment webhook handler" [5pts]
   Rationale: Highest priority TODO in sprint-2, spec exists.

⚡ Action: Spawning build team...
   → 📐 Sage: Validate spec for PROJ-T-008
   → ⚡ Bolt: Implement webhook handler
   → 🛡️ Vigil: Code review (Gate 1)

💓 Heartbeat: 3 agents alive | context 15% | next pulse in 30s
```

### `/aegis-status` — Live dashboard with heartbeat

```
╔══════════════════════════════════════════════════════════════════╗
║  AEGIS Team Status                              v9.0            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                 ║
║  💓 Mother Brain: ALIVE (last pulse: 8s ago)                    ║
║     Cycle: #4 | Agents spawned: 3 | Tasks done: 2              ║
║                                                                 ║
║  Agent          Task                    Status      Progress    ║
║  ─────────────  ──────────────────────  ──────────  ────────    ║
║  📐 Sage        Validating spec         ✅ Done     100%        ║
║  ⚡ Bolt        Implementing webhook    🔄 Working  60%         ║
║  🛡️ Vigil       Waiting for Bolt        ⏳ Waiting  —           ║
║                                                                 ║
║  Pipeline: Build Team [████████████░░░░░░░░] Step 2/3           ║
║  Context: 22% used 🟢 | ~78% remaining                         ║
║                                                                 ║
╚══════════════════════════════════════════════════════════════════╝
```

### `/super-spec` — Human Q&A then full autonomy

```
📐 Sage: I've analyzed your brief and researched similar systems.
Before I write the spec, I need your input:

📌 BUSINESS CONTEXT
1. Who are the primary users?
2. What specific problem does this solve?
3. How do they solve this today?

📌 SCOPE & PRIORITIES
4. What are the MUST-HAVE features for v1? (top 3-5)
5. What is explicitly OUT of scope?

📌 CONSTRAINTS
7. Tech stack preference?
8. Timeline pressure?

📌 SUCCESS
10. How will you measure success?
```

> :bulb: After you answer and approve the spec, Mother Brain enters **Spec Proxy mode** — she answers all team questions using your approved spec. No more interruptions.

```
🧬 Mother Brain: Spec approved. Entering Spec Proxy mode.
   I now have full context from BRD + SRS + UX Blueprint.
   I will answer team questions on your behalf.
   I'll only ask you for business decisions outside the spec.

💓 Resuming full autonomy (L3)...
   → Running /aegis-breakdown from spec...
   → Running /aegis-sprint plan...
   → Spawning build team for first task...
```

---

## :busts_in_silhouette: The 10 Agents (v9 consolidated)

| # | Agent | Model | Role |
|:-:|:------|:-----:|:-----|
| :dna: | **Nick Fury** | `opus 4.6` | Autonomous Controller — scans, decides, spawns teams, enforces BLOCK 0 |
| :compass: | **Captain America** | `opus 4.6` | Navigator/Lead — orchestrates, synthesizes, retros |
| :triangular_ruler: | **Iron Man** | `opus 4.6` | Architect — specs, system design, ADRs |
| :zap: | **Spider-Man** | `sonnet 4.6` | Implementer — writes code, builds features |
| :shield: | **Black Panther** | `sonnet 4.6` | Reviewer — 5-pass code review, quality gates |
| :red_circle: | **Loki** | `opus 4.6` | Devil's Advocate — challenges assumptions, finds flaws |
| :wrench: | **Beast** | `haiku 4.5` | Scanner/Research — programmatic codebase analysis |
| :art: | **Wasp** | `sonnet 4.6` | UX Designer — UI/UX, accessibility |
| :paintbrush: | **Songbird** | `haiku 4.5` | Content Creator — docs, changelogs |
| :dart: | **War Machine** | `sonnet 4.6` | QA Lead — test strategy, release gate |
| :microscope: | **Vision** | `haiku 4.5` | QA Executor — runs tests, reports raw results |
| :scroll: | **Coulson** | `haiku 4.5` | Compliance — ISO 29110, BLOCK 0 gate owner |
| :rocket: | **Thor** | `sonnet 4.6` | DevOps — deploy, health check, rollback |

> **Routing:** Opus (1M ctx, max thinking) → Sonnet (1M ctx, medium thinking) → Haiku (200k ctx, low thinking)

---

## :factory: SDLC Pipeline

```
BLOCK 0 (Coulson) → BREAKDOWN → SPRINT PLAN
     ↓
[ SPEC → BUILD → REVIEW(G1) → QA(G2) → COMPLY(G3) ] → CLOSE → DEPLOY(G4) → MONITOR(G5) → FEEDBACK
  └──────────────── per-task loop ─────────────────┘
```

> BLOCK 0 is a hard gate. No task enters the per-task loop until PM.01 + SI.01 + SI.02 + kanban exist.

---

## :vertical_traffic_light: 6-Gate Quality System

| Gate | Name | Owner | Blocks |
|:----:|:-----|:------|:-------|
| **G0** | **Pre-Work Docs** | **Coulson** | **PM.01 + SI.01 + SI.02 + Epic/Task/Sub-task + Kanban must exist** |
| G1 | Code Review | Black Panther | 5-pass: correctness, security, performance, maintainability, compliance |
| G2 | Product QA | War Machine | Test plan, execution, coverage, verdict |
| G3 | Compliance | Coulson | ISO 29110 work products, traceability matrix |
| G4 | Deploy | Thor | Build, deploy, health check, smoke test |
| G5 | Monitor | Thor | Post-deploy health, metrics, rollback readiness |

> Gate 0 is enforced by Nick Fury at session start and before every IN_PROGRESS transition.

---

## :keyboard: Commands (29)

| Command | Purpose |
|:--------|:--------|
| `/aegis-start` | Begin session — Nick Fury activates + checks BLOCK 0 |
| `/aegis-retro` | End session — retrospective + lessons |
| `/aegis-handoff` | Handoff document for next session |
| `/aegis-pipeline` | Full analysis pipeline (all agents) |
| `/aegis-status` | Check all agent progress |
| `/aegis-mode` | Switch profile: `minimal` / `standard` / `full` |
| `/aegis-context` | Context budget usage + token breakdown |
| `/aegis-distill` | Compress conversation context |
| `/aegis-memory` | Read/write persistent brain |
| `/aegis-verify` | Verify outputs meet acceptance criteria |
| `/aegis-launch` | Launch specific agent with task |
| `/aegis-flow` | Visualize pipeline flow + dependencies |
| `/aegis-team-build` | Spawn build team (Iron Man + Spider-Man + Black Panther) |
| `/aegis-team-review` | Spawn review team (Black Panther + Loki + Beast) |
| `/aegis-team-debate` | Spawn debate team (Iron Man + Loki + Captain America) |
| `/aegis-kanban` | Task board with WIP limits |
| `/aegis-breakdown` | Decompose stories → epics → tasks |
| `/aegis-sprint` | Sprint ceremonies — plan, standup, review, close |
| `/aegis-qa` | QA pipeline — plan, run, report, gate |
| `/aegis-compliance` | ISO 29110 document management + audit |
| `/aegis-deploy` | Deploy pipeline — build, deploy, health, monitor |
| `/aegis-dashboard` | Project dashboard — burndown, metrics, workload |

---

## :jigsaw: Skill Profiles

| Profile | Skills | Use Case |
|:--------|:------:|:---------|
| `minimal` | 7 | Quick tasks, small projects |
| `standard` | 15 | Normal development (default) |
| `full` | 29 | Enterprise, full SDLC |

Switch: `/aegis-mode minimal` · `/aegis-mode standard` · `/aegis-mode full`

---

## :star2: Key Features

- **BLOCK 0 Pre-Work Gate** — Coulson generates PM.01 + SI.01 + SI.02 + kanban before any code is written. Nick Fury hard-blocks the team until complete.
- **Claude 4.x 1M Context** — Opus 4.6 and Sonnet 4.6 agents operate with 1M token context windows. No more session fragmentation on large codebases.
- **Adaptive Thinking** — Each agent uses the right reasoning depth: `max` for architecture, `high` for review, `medium` for implementation, `low` for scanning.
- **Programmatic Scanning (Beast)** — `code_execution_20260120` lets Beast scan 100s of files in a single round-trip, not N sequential reads.
- **Self-Evolving Intelligence** — auto-learn from tasks, shared cache across agents, skill evolution
- **ISO 29110 Compliance** — 14 work products, activity-time generation, audit trail
- **Sprint/Scrum/Kanban** — ceremonies, velocity tracking, WIP limits, burndown
- **Architecture Decision Records (ADRs)** — structured decisions with status tracking
- **Tech Debt Tracking** — continuous scanning, sprint-integrated, priority scoring
- **Persistent Brain** — resonance, learnings, retrospectives survive across sessions

---

## :thailand: Thai Triggers (ภาษาไทย)

| พิมพ์ | Triggers |
|:------|:---------|
| "เริ่ม session" | `/aegis-start` |
| "รีวิวโค้ดให้" | code-review + Black Panther |
| "ทีมสร้าง" | `/aegis-team-build` |
| "ทีมรีวิว" | `/aegis-team-review` |
| "ถกเถียง" | `/aegis-team-debate` |
| "เช็ค context" | `/aegis-context` |
| "สถานะ" | `/aegis-status` |
| "จบ session" | `/aegis-retro` |
| "ส่งต่อ" | `/aegis-handoff` |
| "วางแผน" | orchestrator + Captain America |
| "เขียน spec" | super-spec + Iron Man |
| "ตรวจความปลอดภัย" | security-audit |
| "หนี้เทคนิค" | tech-debt-tracker |
| "ท้าทายการตัดสินใจ" | adversarial-review + Loki |

---

## :file_folder: Directory Structure

```
your-project/
├── CLAUDE.md                    # Hub file (loaded every session)
├── CLAUDE_agents.md             # Agent quick reference
├── CLAUDE_skills.md             # Skill catalog
├── CLAUDE_safety.md             # Safety rules
├── CLAUDE_lessons.md            # Accumulated learnings
├── .claude/
│   ├── commands/                # 22 slash commands
│   ├── agents/                  # 13 Marvel agent personas
│   ├── references/              # 13 protocol files
│   ├── teams/                   # Team configurations
│   └── settings.json            # Permissions + env
├── skills/                      # 29 skill definitions
└── .aegis/brain/                # Persistent memory (never overwritten by upgrade)
    ├── resonance/               # Project identity + conventions + ADRs
    ├── learnings/               # Accumulated lessons
    ├── tasks/                   # Epic/Task/Sub-task hierarchy (BLOCK 0)
    ├── sprints/                 # Sprint plans + kanban boards
    └── logs/                    # Activity tracking
```

---

## :sparkles: Version History

### v9.0 (current) — Framework Hardening + Brain Layer + Ecosystem Prep

| Feature | Before (v8.4) | After (v9.0) |
|---------|---------------|--------------|
| Agent roster | 13 Marvel characters | 10 (Vision→War Machine, Songbird→Coulson, Wasp retired) |
| Brain home | `_aegis-brain/` | `.aegis/brain/` (single-folder, easy uninstall) |
| Brain tooling | manual file ops | `aegis-brain-sync`, `aegis-brain-write` (atomic + S4-02 proxy) |
| Blast radius | markdown rule | Real git worktrees via `aegis-merge-worktree` |
| Framework self-protection | rigid (3 sessions of blocked edits) | ADR-004 override channel (scoped, one-shot, audited) |
| BLOCK 0 | always full gate | lite/standard/full per task (`aegis-block0-mode`) |
| Permissions | `bypassPermissions`, 8 deny | `acceptEdits`, 26 deny, 20 scoped allow |
| Test suite | none | 76/76 assertions across 4 suites |
| Ecosystem plan | buried in 482-pt roadmap | [ECOSYSTEM_GUIDE.md](AEGIS_v9_ECOSYSTEM_GUIDE.md) + [EXTERNAL_ADOPTION.md](AEGIS_EXTERNAL_ADOPTION.md) |

### v8.4 — Global Patterns Adopted

| Feature | Before (v8.3) | After (v8.4) |
|:--------|:-------------|:-------------|
| **Hook config** | Edit settings.json to toggle | Live env var: `AEGIS_HOOK_PROFILE=minimal\|standard\|strict` |
| **Quality checks** | Per-edit or Gate 1 only | Batched at Stop time (10× faster) |
| **Lint configs** | Agents could weaken rules | Blocked by `guard-write.sh` |
| **Lessons** | Freeform markdown | Confidence-scored instincts with auto-promotion |
| **Visual design** | No artifact | `DESIGN.md` 9-section skeleton (Wasp-owned) |
| **Spec guardrails** | Optional | Mandatory Do's/Don'ts + Agent Prompt Guide |
| **ISO 29110 docs** | Variable structure | Frozen H2 skeletons per doc type |
| **Iron Man specs** | Prose-heavy | Matrix tables + soul paragraphs |

### v8.3 — Marvel Rename + BLOCK 0 + Claude 4.x

| Feature | Before (v8.2) | After (v8.3) |
|:--------|:-------------|:-------------|
| **Agent names** | Sage, Bolt, Vigil, Havoc... | 13 Marvel characters (Nick Fury, Iron Man, ...) |
| **Pre-work gate** | None | BLOCK 0 — Coulson enforces PM.01+SI.01+SI.02 |
| **Haiku Models** | Mixed (3-5 / 4-5) | All standardized to `claude-haiku-4-5-20251001` |
| **Context window** | 200k | 1M (Opus 4.6 / Sonnet 4.6) |
| **Quality gates** | 5 | 6 (Gate 0 = pre-work docs) |
| **Thinking** | Manual | `ultrathink` keyword + adaptive thinking guide |

---

## :handshake: Credits

| Contribution | Credit |
|:-------------|:-------|
| Oracle Brain (ψ/) | **Nat Weerawan** — [Soul-Brews-Studio](https://github.com/Soul-Brews-Studio) |
| MAW Framework | **Soul-Brews-Studio** |
| Claude Thailand Community | **Joon**, **Mickey** (AX Digital), **New** (Debox) |
| Claude Code Agent Teams | **Anthropic** |

---

## :scroll: License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>Built with :brain: by the AEGIS community</b><br/>
  <sub>Powered by Claude Code · Anthropic · Claude 4.x</sub>
</p>
