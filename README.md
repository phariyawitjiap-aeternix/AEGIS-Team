<p align="center">
  <img src="https://img.shields.io/badge/version-8.3-blue?style=for-the-badge" alt="Version 8.3"/>
  <img src="https://img.shields.io/badge/agents-13-green?style=for-the-badge" alt="13 Agents"/>
  <img src="https://img.shields.io/badge/skills-29-orange?style=for-the-badge" alt="29 Skills"/>
  <img src="https://img.shields.io/badge/commands-22-yellow?style=for-the-badge" alt="22 Commands"/>
  <img src="https://img.shields.io/badge/gates-6-red?style=for-the-badge" alt="6 Gates"/>
  <img src="https://img.shields.io/badge/ISO--29110-compliant-brightgreen?style=for-the-badge" alt="ISO 29110"/>
  <img src="https://img.shields.io/badge/Claude_4.x-1M_context-blueviolet?style=for-the-badge" alt="Claude 4.x"/>
  <img src="https://img.shields.io/badge/license-MIT-purple?style=for-the-badge" alt="MIT License"/>
</p>

# :shield: AEGIS v8.3 — AI Agent Team Framework for Claude Code

> **"Context is King, Memory is Soul"**
>
> :dna: Nick Fury · 13 Marvel Agents · 29 Skills · 22 Commands · 6-Gate Quality · ISO 29110 · Claude 4.x 1M Context

---

## What is AEGIS?

AEGIS (**A**utonomous **E**nhanced **G**roup **I**ntelligence **S**ystem) — production-grade AI agent team framework for Claude Code. 13 Marvel-character agents, 14-stage SDLC pipeline, 6-gate quality (including a mandatory pre-work gate), ISO 29110 compliance, JIRA-like PM, self-evolving intelligence. :dna: ยิ่งใช้ยิ่งเก่ง.

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

> :bulb: Profile options: `minimal` (7 skills) · `standard` (15 skills) · `full` (29 skills)

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
| 1 | :lock: **Backup** `_aegis-brain/`, `iso-docs/`, `CLAUDE_lessons.md` → `_aegis-backup/` |
| 2 | :wastebasket: **Remove** old agents, commands, references, teams, skills |
| 3 | :arrow_down: **Download** latest AEGIS from GitHub (to `/tmp/`, auto-cleaned) |
| 4 | :package: **Install** 13 Marvel agents, 22 commands, 13 references, 7 teams, 29 skills |
| 5 | :mag: **Verify** all files present + migrate old versions (v6→v8, v7→v8, v8.2→v8.3) |

**What changes in v8.3:**

| Change | Details |
|--------|---------|
| :superhero: Agent renames | All 13 agents renamed to Marvel characters matching their behavior |
| :lock: BLOCK 0 gate | Coulson enforced as mandatory pre-work checkpoint before any task starts |
| :brain: Claude 4.x models | Haiku agents updated to `claude-haiku-4-5-20251001`; Opus/Sonnet get 1M context |
| :wrench: Beast capabilities | `code_execution_20260120` added — scans 100s of files in one round-trip |
| :6: Gate 0 added | Quality pipeline is now 6 gates (Gate 0 = pre-work docs) |
| :books: New references | `adaptive-thinking-guide.md`, `context-editing-protocol.md` |

**:lock: NEVER touched by upgrade:** `_aegis-brain/` (tasks, sprints, patterns, learnings), `iso-docs/`, `CLAUDE_lessons.md`, project source code

---

## :busts_in_silhouette: The 13 Agents

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

## :keyboard: Commands (22)

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
└── _aegis-brain/                # Persistent memory (never overwritten by upgrade)
    ├── resonance/               # Project identity + conventions + ADRs
    ├── learnings/               # Accumulated lessons
    ├── tasks/                   # Epic/Task/Sub-task hierarchy (BLOCK 0)
    ├── sprints/                 # Sprint plans + kanban boards
    └── logs/                    # Activity tracking
```

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
