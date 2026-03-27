<p align="center">
  <img src="https://img.shields.io/badge/version-8.2-blue?style=for-the-badge" alt="Version 8.2"/>
  <img src="https://img.shields.io/badge/agents-13-green?style=for-the-badge" alt="13 Agents"/>
  <img src="https://img.shields.io/badge/skills-29-orange?style=for-the-badge" alt="29 Skills"/>
  <img src="https://img.shields.io/badge/commands-22-yellow?style=for-the-badge" alt="22 Commands"/>
  <img src="https://img.shields.io/badge/gates-5-red?style=for-the-badge" alt="5 Gates"/>
  <img src="https://img.shields.io/badge/ISO--29110-compliant-brightgreen?style=for-the-badge" alt="ISO 29110"/>
  <img src="https://img.shields.io/badge/license-MIT-purple?style=for-the-badge" alt="MIT License"/>
</p>

# :shield: AEGIS v8.2 — AI Agent Team Framework for Claude Code

> **"Context is King, Memory is Soul"**
>
> :dna: Mother Brain · 13 AI Agents · 29 Skills · 22 Commands · 5-Gate Quality · Self-Evolving Intelligence

---

## What is AEGIS?

AEGIS (**A**utonomous **E**nhanced **G**roup **I**ntelligence **S**ystem) — production-grade AI agent team framework for Claude Code. 13 agents, 14-stage SDLC pipeline, 5-gate quality, ISO 29110 compliance, JIRA-like PM, self-evolving intelligence. :dna: ยิ่งใช้ยิ่งเก่ง.

---

## :rocket: Installation

```bash
# 1. Prerequisites + Claude Code
brew install node && npm install -g @anthropic-ai/claude-code

# 2. Clone AEGIS
git clone https://github.com/phariyawitjiap-aeternix/AEGIS-Team.git ~/AEGIS-Team

# 3. Install into your project
mkdir ~/Documents/my-project && cd ~/Documents/my-project && git init && ~/AEGIS-Team/install.sh --profile full --project-name "My Project"

# 4. Start Claude Code
claude --dangerously-skip-permissions
```

**Permissions (one-time):**

```bash
cat > ~/.claude/settings.json << 'EOF'
{"permissions":{"defaultMode":"bypassPermissions","allow":["Bash","Edit","Write","Read","Glob","Grep","Agent","TeamCreate","TeamDelete","SendMessage"]},"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}
EOF
```

---

## :arrows_counterclockwise: Update Existing Install

```bash
cd ~/AEGIS-Team && git pull origin main
cd ~/Documents/my-project && ~/AEGIS-Team/install.sh --upgrade
claude --dangerously-skip-permissions
```

> :lock: `--upgrade` preserves your `_aegis-brain/` and `CLAUDE_lessons.md`. A backup is saved to `_aegis-backup/`.

---

## :busts_in_silhouette: The 13 Agents

| # | Agent | Model | Role |
|:-:|:------|:-----:|:-----|
| :dna: | **Mother Brain** | `opus` | Autonomous Controller — scans, decides, spawns teams |
| :compass: | **Navi** | `opus` | Navigator/Lead — orchestrates, synthesizes, retros |
| :triangular_ruler: | **Sage** | `opus` | Architect — specs, system design, ADRs |
| :zap: | **Bolt** | `sonnet` | Implementer — writes code, builds features |
| :shield: | **Vigil** | `sonnet` | Reviewer — code review, quality gates |
| :red_circle: | **Havoc** | `opus` | Devil's Advocate — challenges, finds flaws |
| :wrench: | **Forge** | `haiku` | Scanner/Research — gathers data, metrics |
| :art: | **Pixel** | `sonnet` | UX Designer — UI/UX, accessibility |
| :paintbrush: | **Muse** | `haiku` | Content Creator — docs, changelogs |
| :dart: | **Sentinel** | `sonnet` | QA Lead — test strategy, release gate |
| :microscope: | **Probe** | `haiku` | QA Executor — runs tests, reports |
| :scroll: | **Scribe** | `haiku` | Compliance — ISO 29110, traceability |
| :rocket: | **Ops** | `sonnet` | DevOps — deploy, health check, rollback |

> **Routing:** Opus thinks, Sonnet builds, Haiku gathers.

---

## :factory: 14-Stage SDLC Pipeline

```
IDEA → BREAKDOWN → SPRINT → [ SPEC → BUILD → REVIEW(G1) → QA(G2) → COMPLY(G3) ] → CLOSE → DEPLOY(G4) → MONITOR(G5) → FEEDBACK
                              └──────────── per-task loop ────────────┘
```

---

## :vertical_traffic_light: 5-Gate Quality System

| Gate | Name | Owner | Checks |
|:----:|:-----|:------|:-------|
| G1 | Code Review | Vigil | 5-pass review: correctness, security, performance, maintainability, compliance |
| G2 | Product QA | Sentinel | Test plan, execution, coverage, verdict |
| G3 | Compliance | Scribe | ISO 29110 work products, traceability matrix |
| G4 | Deploy | Ops | Build, deploy, health check, smoke test |
| G5 | Monitor | Ops | Post-deploy health, metrics, rollback readiness |

---

## :keyboard: Commands (22)

| Command | Purpose |
|:--------|:--------|
| `/aegis-start` | Begin session — Mother Brain activates |
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
| `/aegis-team-build` | Spawn build team (Sage + Bolt + Vigil) |
| `/aegis-team-review` | Spawn review team (Vigil + Havoc + Forge) |
| `/aegis-team-debate` | Spawn debate team (Sage + Havoc + Navi) |
| `/aegis-kanban` | Task board with WIP limits |
| `/aegis-breakdown` | Decompose stories → epics → tasks |
| `/aegis-sprint` | Sprint ceremonies — plan, standup, review, close |
| `/aegis-qa` | QA pipeline — plan, run, report, gate |
| `/aegis-compliance` | ISO 29110 document management + audit |
| `/aegis-deploy` | Deploy pipeline — build, deploy, health, monitor |
| `/aegis-dashboard` | Project dashboard — burndown, metrics, workload |

---

## :jigsaw: Skill Profiles

| Profile | Skills | Context | Use Case |
|:--------|:------:|:-------:|:---------|
| `minimal` | 7 | ~3K tokens | Quick tasks, small projects |
| `standard` | 15 | ~6K tokens | Normal development (default) |
| `full` | 29 | ~12K tokens | Enterprise, full SDLC |

Switch: `/aegis-mode minimal` · `/aegis-mode standard` · `/aegis-mode full`

---

## :star2: Key Features

- **Self-Evolving Intelligence** — auto-learn from tasks, shared cache across agents, skill evolution
- **JIRA-like PM State** — sequential IDs, per-task history, sprint dashboard
- **ISO 29110 Compliance** — 14 work products, activity-time generation, audit trail
- **Sprint/Scrum/Kanban** — ceremonies, velocity tracking, WIP limits, burndown
- **Context Router** — Hermes-like routing to the right agent based on intent
- **Knowledge Pipeline** — 4-stage: capture :arrow_right: extract :arrow_right: distill :arrow_right: propagate
- **Architecture Decision Records (ADRs)** — structured decisions with status tracking
- **Tech Debt Tracking** — continuous scanning, sprint-integrated, priority scoring
- **Release Management** — semver, checklist, rollback, health monitoring
- **Persistent Brain** — resonance, learnings, retrospectives survive across sessions

---

## :thailand: Thai Triggers (ภาษาไทย)

| พิมพ์ | Triggers |
|:------|:---------|
| "เริ่ม session" | `/aegis-start` |
| "รีวิวโค้ดให้" | code-review + Vigil |
| "ทีมสร้าง" | `/aegis-team-build` |
| "ทีมรีวิว" | `/aegis-team-review` |
| "ถกเถียง" | `/aegis-team-debate` |
| "เช็ค context" | `/aegis-context` |
| "สถานะ" | `/aegis-status` |
| "จบ session" | `/aegis-retro` |
| "ส่งต่อ" | `/aegis-handoff` |
| "วางแผน" | orchestrator + Navi |
| "เขียน spec" | super-spec + Sage |
| "ตรวจความปลอดภัย" | security-audit |
| "หนี้เทคนิค" | tech-debt-tracker |
| "ท้าทายการตัดสินใจ" | adversarial-review + Havoc |

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
│   ├── agents/                  # 13 agent personas
│   ├── references/              # Protocol files
│   ├── teams/                   # Team configurations
│   └── settings.json            # Permissions + env
├── skills/                      # 29 skill definitions
└── _aegis-brain/                # Persistent memory (never overwritten)
    ├── resonance/               # Project identity + conventions + ADRs
    ├── learnings/               # Accumulated lessons
    ├── retrospectives/          # Session retros + AI diaries
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
  <sub>Powered by Claude Code · Anthropic</sub>
</p>
