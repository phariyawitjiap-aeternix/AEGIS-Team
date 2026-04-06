# 🛡️ AEGIS v7.0 — Getting Started Guide

> ขั้นตอนการติดตั้งและใช้งาน AEGIS กับ project ใหม่ ผ่าน Terminal
> 12 Agents · 26 Skills · 20 Commands · ISO 29110 · 3-Gate Quality

---

## Prerequisites

```bash
# 1. Node.js + npm (required for Claude Code)
brew install node           # macOS
node --version              # v18+ required

# 2. Claude Code CLI (required)
npm install -g @anthropic-ai/claude-code
claude --version            # Should show: Claude Code vX.X.X

# 3. Git (required)
git --version

# 4. tmux (recommended — for visual agent panes)
brew install tmux           # macOS
sudo apt install tmux       # Linux
tmux -V                     # tmux 3.x
```

<details>
<summary><b>🔧 Troubleshooting: command not found</b></summary>

```bash
# If "claude" or "node" not found after install:

# 1. Check Homebrew PATH
grep -q '/opt/homebrew/bin' ~/.zshrc && echo "OK" || echo "MISSING"

# 2. If MISSING — add it:
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 3. Verify:
node --version && npm --version && claude --version && tmux -V
```

</details>

---

## Step 1: Clone AEGIS Framework (one-time)

```bash
git clone https://github.com/phariyawitjiap-aeternix/AEGIS-Team.git ~/AEGIS-Team
```

---

## Step 2: Create Your Project

```bash
# New project:
mkdir ~/my-project && cd ~/my-project && git init

# Or existing project:
cd ~/my-existing-project
```

---

## Step 3: Install AEGIS

```bash
~/AEGIS-Team/install.sh --profile full --project-name "My Project"
```

**Profile options:**

| Profile | Skills | Agents | Best For |
|---------|:------:|:------:|----------|
| `minimal` | 7 | 9 | Quick scripts, small fixes |
| `standard` | 15 | 12 | Normal development + sprint tracking |
| `full` | 26 | 12 | Enterprise + ISO 29110 + QA pipeline |

**What gets installed:**
```
your-project/
├── CLAUDE.md                  # Hub — golden rules
├── CLAUDE_agents.md           # 12 agent personas
├── CLAUDE_safety.md           # Safety rules
├── CLAUDE_skills.md           # 26 skill catalog
├── CLAUDE_lessons.md          # Patterns & anti-patterns
├── .claude/
│   ├── settings.json          # Permissions (auto-bypass)
│   ├── commands/              # 20 slash commands
│   ├── agents/                # 12 agent definitions
│   ├── teams/                 # 3 team configs
│   └── references/            # 6 protocol files
├── skills/                    # Skill definitions
└── _aegis-brain/              # Persistent memory
    ├── resonance/             # Project identity
    ├── learnings/             # Accumulated lessons
    ├── logs/                  # Activity tracking
    └── retrospectives/        # Session retros
```

---

## Step 4: Configure Agent Permissions (สำคัญมาก!)

Agents need permission to work autonomously. Add this to your **global** settings:

```bash
cat > ~/.claude/settings.json << 'SETTINGS'
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": [
      "Bash", "Edit", "Write", "Read",
      "Glob", "Grep", "Agent",
      "TeamCreate", "TeamDelete", "SendMessage"
    ]
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
SETTINGS
```

> ⚠️ **Why global?** There's a [known bug](https://github.com/anthropics/claude-code/issues/26479) where teammates don't inherit project-level settings. Global settings work reliably.

---

## Step 5: Start AEGIS

```bash
claude --dangerously-skip-permissions
```

Inside Claude Code:

```
> /aegis-start

🧬 Nick Fury: ONLINE
🧬 Scanning project state...
🧬 Decision: P10 — Empty project
🧬 "What is this project? One sentence."

> E-commerce platform with payment, shipping, and admin dashboard

🧬 Nick Fury: Got it. Starting autonomous pipeline...
🧬 → /aegis-breakdown (decomposing user story)
🧬 → /aegis-sprint plan (creating sprint)
🧬 → Spawning Build Team...
```

**Nick Fury ทำทุกอย่างเอง — ไม่ต้องสั่งเพิ่ม**

---

## Step 6: Watch Agents Work

### In-Process Mode (default — recommended):

```
Shift+Down  = ดู agent ที่กำลังทำงาน
Shift+Up    = กลับ main view
Ctrl+C      = หยุดทุกอย่าง
```

### tmux Split Panes (optional — visual but has permission bug):

```bash
# Start inside tmux first:
tmux new-session -s aegis
cd ~/my-project
claude --dangerously-skip-permissions

# Agents auto-split into tmux panes
# Ctrl+B o = switch pane | Ctrl+B z = zoom | Ctrl+B d = detach
```

---

## Commands Reference

### 🏗️ Project Management

| Command | Purpose |
|---------|---------|
| `/aegis-breakdown "story"` | Decompose: Story → Journey → Epic → Task → Subtask |
| `/aegis-sprint plan` | Start sprint — select from backlog, assign agents |
| `/aegis-sprint standup` | Auto-generated daily standup from agent activity |
| `/aegis-sprint status` | Burndown chart — points done vs remaining |
| `/aegis-sprint review` | Sprint review — demo completed work |
| `/aegis-sprint retro` | Sprint retrospective — lessons learned |
| `/aegis-sprint close` | Close sprint — velocity, carry-over |
| `/aegis-kanban` | View kanban board |
| `/aegis-kanban move T-001 DONE` | Move task to column |

### 🔨 Build

| Command | Purpose |
|---------|---------|
| `/aegis-team-build` | Spawn build team: Iron Man specs → Spider-Man builds → Black Panther reviews |
| `/aegis-team-review` | Spawn review team: Beast scans → Loki challenges → Black Panther gates |
| `/aegis-team-debate` | Architecture debate: Iron Man vs Spider-Man vs Loki → Captain America decides |
| `/aegis-pipeline` | Full analysis pipeline with quality gates |

### 🧪 Quality

| Command | Purpose |
|---------|---------|
| `/aegis-qa plan` | War Machine creates test plan from requirements |
| `/aegis-qa run` | Vision executes tests |
| `/aegis-qa full` | Plan + run + report in sequence |
| `/aegis-qa gate` | QA quality gate check (PASS/FAIL) |
| `/aegis-verify` | Quick verification: tests, lint, git, security |

### 📜 Compliance

| Command | Purpose |
|---------|---------|
| `/aegis-compliance check` | Audit which ISO 29110 docs are missing |
| `/aegis-compliance generate` | Auto-generate all missing docs |
| `/aegis-compliance matrix` | Show traceability matrix |

### 📊 Session

| Command | Purpose |
|---------|---------|
| `/aegis-start` | Begin session — Nick Fury activates |
| `/aegis-status` | Team dashboard — agents, tasks, progress |
| `/aegis-context` | Context budget — token usage |
| `/aegis-retro` | Session retrospective |
| `/aegis-handoff` | Handoff brief for next session |
| `/aegis-mode` | Switch profile (minimal/standard/full) |

---

## The 12 Agents

| # | Agent | Model | Role |
|:-:|-------|:-----:|------|
| 🧬 | **Nick Fury** | opus | Autonomous controller — scans, decides, spawns |
| 🧭 | **Captain America** | opus | Navigator — orchestrates, sprints, retros |
| 📐 | **Iron Man** | opus | Architect — specs, design, breakdown |
| ⚡ | **Spider-Man** | sonnet | Implementer — writes code, runs tests |
| 🛡️ | **Black Panther** | sonnet | Code Reviewer — Gate 1: code quality |
| 🔴 | **Loki** | opus | Devil's Advocate — challenges everything |
| 🔧 | **Beast** | haiku | Scanner — gathers data, researches |
| 🖌️ | **Wasp** | sonnet | UX Designer — accessibility, dark mode |
| 🎨 | **Songbird** | haiku | Content Creator — docs, changelogs |
| 🎯 | **War Machine** | sonnet | QA Lead — Gate 2: product quality |
| 🔬 | **Vision** | haiku | QA Executor — runs test suites |
| 📜 | **Coulson** | haiku | Compliance — Gate 3: ISO 29110 docs |

### 3-Gate Quality System

```
Code written → Gate 1 (Black Panther): Code review
            → Gate 2 (War Machine): QA testing
            → Gate 3 (Coulson): ISO 29110 compliance
            → DONE ✅
```

Tasks under 3 story points skip Gates 2-3 (solo mode).

---

## 3-Scale Auto-Selection

Nick Fury auto-selects the right mode:

| Task Size | Mode | Agents | Gates |
|-----------|------|:------:|:-----:|
| 1-2 files, ≤2 pts | **Solo** | 2 (Spider-Man + Black Panther) | 1 |
| 3-5 files, 3-8 pts | **Team** | 6 (Build + QA) | 3 |
| 6+ files, 8+ pts | **Full Pipeline** | 8-10 (all teams) | 3 |

---

## ISO 29110 Documents (auto-generated)

| Doc | Name | When Generated |
|-----|------|---------------|
| PM.01 | Project Plan | Sprint planning |
| PM.02 | Progress Status | Daily standups |
| PM.03 | Change Requests | Scope changes |
| PM.04 | Meeting Records | Each ceremony |
| SI.01 | Requirements Spec | After breakdown |
| SI.02 | Design Document | After architecture |
| SI.03 | Traceability Matrix | Every doc update |
| SI.04 | Test Plan | Before QA |
| SI.05 | Test Report | After QA |
| SI.06 | Acceptance Record | Sprint close |
| SI.07 | Software Config | Release prep |

All docs live in `_aegis-output/iso-docs/` and are generated by **Coulson** from agent outputs.

---

## Update AEGIS

When a new version is released:

```bash
# 1. Exit Claude Code first!
# 2. Update source
cd ~/AEGIS-Team && git pull origin main

# 3. Upgrade your project (preserves brain + learnings)
cd ~/my-project
~/AEGIS-Team/install.sh --upgrade

# 4. Restart
claude --dangerously-skip-permissions
> /aegis-start
```

---

## Thai Triggers (ภาษาไทย)

พิมพ์ภาษาไทยได้เลย:

| พิมพ์ | ทำอะไร |
|-------|--------|
| "เริ่ม session" | `/aegis-start` |
| "แตกงาน user story" | `/aegis-breakdown` |
| "วางแผนสปรินต์" | `/aegis-sprint plan` |
| "สแตนอัพ" | `/aegis-sprint standup` |
| "คันบัง" | `/aegis-kanban` |
| "ทีมสร้าง" | `/aegis-team-build` |
| "ทีมรีวิว" | `/aegis-team-review` |
| "ถกเถียง" | `/aegis-team-debate` |
| "คิวเอ" | `/aegis-qa full` |
| "ตรวจเอกสาร" | `/aegis-compliance check` |
| "จบ session" | `/aegis-retro` |

---

<p align="center">
  <b>🛡️ AEGIS v7.0 — "Context is King, Memory is Soul"</b><br/>
  <sub>12 Agents · 26 Skills · 20 Commands · ISO 29110 · Powered by Claude Code</sub>
</p>
