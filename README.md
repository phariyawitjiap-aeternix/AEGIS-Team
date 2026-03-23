<p align="center">
  <img src="https://img.shields.io/badge/version-6.0-blue?style=for-the-badge" alt="Version 6.0"/>
  <img src="https://img.shields.io/badge/agents-9_(+Mother_Brain)-green?style=for-the-badge" alt="9 Agents"/>
  <img src="https://img.shields.io/badge/skills-21-orange?style=for-the-badge" alt="21 Skills"/>
  <img src="https://img.shields.io/badge/license-MIT-purple?style=for-the-badge" alt="MIT License"/>
  <img src="https://img.shields.io/badge/platform-Claude%20Code-black?style=for-the-badge" alt="Claude Code"/>
</p>

# :shield: AEGIS v6.0 — AI Agent Team Framework for Claude Code

> **"Context is King, Memory is Soul"**
>
> 🧬 Mother Brain · 9 AI Agents · 21 Skills · 15 Commands · Persistent Brain · tmux Agent Teams

---

AEGIS (**A**utonomous **E**nhanced **G**roup **I**ntelligence **S**ystem) is a production-grade framework that transforms Claude Code into a coordinated team of 8 specialized AI agents. Each agent carries a distinct role — from architecture to adversarial review — with intelligent model routing across Opus, Sonnet, and Haiku tiers. Blast radius containment ensures agents only touch what they own. Built for real-world SDLC workflows, AEGIS handles everything from sprint planning and code generation to security audits and retrospectives, with a persistent brain that remembers across sessions.

---

## :wrench: Prerequisites

```bash
# 1. Node.js + npm (required for Claude Code)
brew install node
node --version     # v18+ required
npm --version

# 2. Claude Code CLI
npm install -g @anthropic-ai/claude-code
claude --version   # Should show: Claude Code vX.X.X

# 3. Git
git --version

# 4. tmux (REQUIRED — core of Agent Teams)
brew install tmux

# 5. Enable Agent Teams (REQUIRED — add to shell config)
echo 'export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1' >> ~/.zshrc
source ~/.zshrc
```

> :rotating_light: **IMPORTANT:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` must be set as a **shell environment variable** (in `~/.zshrc` or `~/.bashrc`). Without it, team commands won't spawn agents. The `install.sh` script will auto-detect and add it if missing.

> :bulb: **Tip:** If `claude` or `node` not found after install, open a **new terminal tab** — your PATH needs to reload.

<details>
<summary><b>:wrench: Troubleshooting: command not found</b></summary>

```bash
# If "claude: command not found" or "node: command not found":

# 1. Check if Homebrew PATH is in your shell config
grep -q '/opt/homebrew/bin' ~/.zshrc && echo "OK" || echo "MISSING"
grep -q '/opt/homebrew/bin' ~/.zprofile && echo "OK" || echo "MISSING"

# 2. If MISSING — add it:
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 3. If node is installed but not linked:
brew link node

# 4. Verify everything works:
node --version    # v18+
npm --version     # 9+
claude --version  # Claude Code vX.X.X
tmux -V           # tmux 3.x (REQUIRED)
```

</details>

---

## :rocket: Installation

### :new: Mode A — New Install (first time)

```bash
# ┌─────────────────────────────────────────────────────────────┐
# │  ONE-TIME SETUP (only do this once on your machine)         │
# └─────────────────────────────────────────────────────────────┘

# 1. Install prerequisites
brew install node tmux
npm install -g @anthropic-ai/claude-code

# 2. Clone AEGIS framework
git clone https://github.com/phariyawitjiap-aeternix/AEGIS-Team.git ~/AEGIS-Team
```

```bash
# ┌─────────────────────────────────────────────────────────────┐
# │  PER-PROJECT INSTALL (do this for each new project)         │
# └─────────────────────────────────────────────────────────────┘

# 1. Create or navigate to your project
mkdir ~/my-project && cd ~/my-project
git init

# 2. Install AEGIS into this project
~/AEGIS-Team/install.sh --profile standard --project-name "My Project"
#
# ✅ 55 files installed (full content, not stubs)
# ✅ 9 agents, 15 commands, 13 skills, brain, settings.json

# 3. Start working
claude                    # Open Claude Code
> /aegis-start            # Mother Brain activates automatically
#
# 🧬 Mother Brain: ONLINE
# 🧬 Scanning project state...
# 🧬 Decision: P10 — Empty project
# 🧬 Spawning team in tmux...
# (agents work autonomously — watch with: tmux attach -t aegis-team)
```

**Profile options:** `minimal` (7 skills) · `standard` (13 skills) · `full` (21 skills)

### :arrows_counterclockwise: Mode B — Update Existing Install

When AEGIS releases a new version:

```bash
# ┌─────────────────────────────────────────────────────────────┐
# │  ⚠️  STEP 0: EXIT CLAUDE CODE FIRST!                       │
# │  Claude caches files at startup. If you update while Claude │
# │  is running, it will still use the OLD cached files.        │
# │  You MUST exit → update → restart.                          │
# └─────────────────────────────────────────────────────────────┘

# 1. Exit Claude Code (if running)
> /exit                   # inside Claude Code
# or Ctrl+C then "exit"

# 2. Kill old tmux agent sessions
tmux kill-server 2>/dev/null

# 3. Update AEGIS source
cd ~/AEGIS-Team && git pull origin main

# 4. Re-install with --upgrade (preserves your brain + learnings)
cd ~/my-project
~/AEGIS-Team/install.sh --upgrade

# 5. Start fresh Claude Code session
claude
> /aegis-start
# 🧬 Mother Brain loads from NEW files ✅
```

**Quick one-liner (copy-paste safe):**

```bash
# Exit claude first, then:
tmux kill-server 2>/dev/null; cd ~/AEGIS-Team && git pull && cd ~/my-project && ~/AEGIS-Team/install.sh --upgrade && claude
```

**What `--upgrade` preserves vs overwrites:**

| :lock: Preserved (your data) | :arrows_counterclockwise: Updated (framework files) |
|:---------------------------|:---------------------|
| `_aegis-brain/` (all memory) | `.claude/commands/` (15 slash commands) |
| `_aegis-brain/resonance/` (project identity) | `.claude/agents/` (9 agent personas) |
| `_aegis-brain/learnings/` (accumulated lessons) | `.claude/references/` (6 protocol files) |
| `_aegis-brain/retrospectives/` (session retros) | `.claude/teams/` (3 team configs) |
| `_aegis-brain/logs/` (activity history) | `.claude/settings.json` (permissions) |
| `CLAUDE_lessons.md` (your patterns) | `CLAUDE.md`, `CLAUDE_agents.md` |
| | `CLAUDE_safety.md`, `CLAUDE_skills.md` |
| | `skills/` (13-21 skill definitions) |

> :lock: **Your brain is sacred.** `--upgrade` never touches `_aegis-brain/` or `CLAUDE_lessons.md`. All project memory, learnings, and retrospectives survive across updates. A backup of overwritten files is saved to `_aegis-backup/` before each upgrade.

### :computer: 3 Ways to Spawn Agent Teams

After install, there are **3 ways** to start an AEGIS team:

#### Mode 1: Mother Brain Auto-Spawns (Recommended)

Just run `/aegis-start` — Mother Brain scans, decides, and spawns the right team automatically.

```bash
# Inside Claude Code:
> /aegis-start
#
# 🧬 Mother Brain: ONLINE
# 🧬 Scanning project state...
# 🧬 Decision: P3 — Spec exists, no code
# 🧬 Spawning build team in tmux...
#
# Watch agents: tmux attach -t aegis-team
```

**Human does nothing.** Mother Brain picks the team, assigns tasks, manages quality gates.

#### Mode 2: Slash Commands (Inside Claude Code)

Use `/aegis-team-*` commands — Claude will auto-execute `aegis-team.sh` and spawn tmux:

```bash
# Inside Claude Code:
> /aegis-team-build implement auth system
# → Claude runs: aegis-team.sh --team build --task "implement auth system"
# → tmux session opens with 3 agent panes

> /aegis-team-review check src/ directory
# → Claude runs: aegis-team.sh --team review --task "check src/ directory"

> /aegis-team-debate SQL vs NoSQL
# → Claude runs: aegis-team.sh --team debate --task "SQL vs NoSQL"
```

Thai triggers also work:

```bash
> ทีมสร้าง — เพิ่ม user authentication
> ทีมรีวิว — ดู src/ ทั้งหมด
> ถกเถียง — monolith หรือ microservices
```

#### Mode 3: Terminal Direct (Outside Claude Code)

Run `aegis-team.sh` directly from your terminal:

```bash
# Build team: Sage specs → Bolt implements → Vigil reviews
~/AEGIS-Team/aegis-team.sh --team build --task "Implement auth system"

# Review team: Forge scans → Havoc challenges → Vigil gates
~/AEGIS-Team/aegis-team.sh --team review --task "Review src/ directory"

# Debate team: Sage proposes → Bolt evaluates → Havoc challenges → Navi decides
~/AEGIS-Team/aegis-team.sh --team debate --task "SQL vs NoSQL"

# Custom team: pick any agents
~/AEGIS-Team/aegis-team.sh --team custom --agents "sage,bolt" --task "Quick spec"

# Manage sessions:
~/AEGIS-Team/aegis-team.sh --attach     # Watch agents work
~/AEGIS-Team/aegis-team.sh --kill       # Stop all agents
```

#### Watching Agents Work

All 3 modes spawn the same tmux session:

```
$ tmux attach -t aegis-team

┌─── tmux: aegis-team ──────────────────────────────────────────────┐
│ ┌─ 📐 Sage — Architect ────────┐ ┌─ ⚡ Bolt — Implementer ──────┐ │
│ │ Writing spec...               │ │ Waiting for spec...           │ │
│ │ → PlanProposal sent ──────────│─▶ Implementing 12 files...     │ │
│ └───────────────────────────────┘ └───────────────────────────────┘ │
│ ┌─ 🛡️ Vigil — Reviewer ────────┐ ┌─ 📋 Activity Log ────────────┐ │
│ │ Review Pass 1: Correctness ✅ │ │ 18:31 Sage → in_progress     │ │
│ │ Review Pass 2: Security ✅    │ │ 18:34 Sage → PlanProposal    │ │
│ │ → QualityGate: PASS           │ │ 18:37 Bolt → done (12 files) │ │
│ └───────────────────────────────┘ │ 18:40 Vigil → APPROVED       │ │
│                                   └───────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

  Ctrl+B o  → switch pane    Ctrl+B z  → zoom pane
  Ctrl+B d  → detach         Ctrl+B [  → scroll history
```

### :wrench: Install Options Reference

```bash
# Syntax
~/AEGIS-Team/install.sh [OPTIONS]
~/AEGIS-Team/aegis-team.sh [OPTIONS]

# install.sh options:
#   --profile <tier>        minimal | standard | full (default: standard)
#   --project-name <name>   Project name for brain identity
#   --target-dir <path>     Target directory (default: current dir)
#   --upgrade               Update existing install (preserve brain)

# aegis-team.sh options:
#   --team <name>           build | review | debate | custom (required)
#   --task <description>    What the team should do (required)
#   --agents <list>         Comma-separated agents for custom team
#   --project <path>        Project directory (default: current dir)
#   --session <name>        tmux session name (default: aegis-team)
#   --kill                  Kill existing agent session
#   --attach                Attach to existing session

# Examples:
~/AEGIS-Team/install.sh --profile minimal --project-name "Quick Script"
~/AEGIS-Team/install.sh --profile full --project-name "Enterprise App"
~/AEGIS-Team/install.sh --upgrade --profile full    # upgrade minimal→full
~/AEGIS-Team/install.sh --upgrade                   # update keeping same profile
~/AEGIS-Team/aegis-team.sh --team build --task "Build auth" --project ~/my-app
```

### :clipboard: Post-Install Checklist

```bash
# Verify everything works:
claude --version                        # Claude Code CLI ✅
tmux -V                                 # tmux 3.x ✅
ls CLAUDE.md                            # Hub file ✅
ls .claude/agents/mother-brain.md       # Mother Brain ✅
ls .claude/settings.json                # Permissions (57 allow) ✅
wc -l skills/*.md | tail -1             # Skills (not stubs) ✅

# Start and verify:
claude
> /aegis-start
# 🧬 Mother Brain should activate and scan your project
```

> :book: **[Full Getting Started Guide →](GETTING_STARTED.md)** — step-by-step terminal walkthrough with iOS Todo App example

---

## :movie_camera: After `/aegis-start` — What Can You Do?

### Example 1: Code Review (Solo Agent)

```
You:    รีวิวโค้ดให้หน่อย ดู src/ ทั้งหมด

🧭 Navi:  Trigger "รีวิวโค้ด" → dispatching 🛡️ Vigil (sonnet)

🛡️ Vigil: Running 5-pass review...
          Pass 1 Correctness ✅
          Pass 2 Security    🔴 No input validation (CRITICAL)
          Pass 3 Performance 🟡 No caching configured
          Pass 4 Maintainability 🟡 All routes in one file
          Pass 5 SDD Compliance  🔵 No OpenAPI spec

          Gate: ❌ FAIL — 1 critical must be resolved
          Report: _aegis-output/reviews/2026-03-20.md
```

### Example 2: Build Feature (Team — tmux)

```
You:    ทีมสร้าง — เพิ่ม user authentication

🧭 Navi:  Trigger "ทีมสร้าง" → spawning tmux team
          📐 Sage + ⚡ Bolt + 🛡️ Vigil

┌─── tmux ──────────────────────────────────────────┐
│ ┌─ 📐 Sage ──────────┐ ┌─ ⚡ Bolt ──────────────┐ │
│ │ Writing auth spec   │ │ Waiting for spec...    │ │
│ │ → PlanProposal sent │ │ → Implementing JWT...  │ │
│ └─────────────────────┘ └────────────────────────┘ │
│ ┌─ 🛡️ Vigil ────────────────────────────────────┐  │
│ │ Reviewing... → QualityGate: ✅ PASS            │  │
│ └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘

Result: 📐 Spec written → ⚡ 4 files created → 🛡️ Review PASS
```

### Example 3: Architecture Debate (Team — tmux)

```
You:    ถกเถียง — ควรใช้ SQL หรือ NoSQL สำหรับ project นี้

🧭 Navi:  Spawning debate team...
          📐 Sage + ⚡ Bolt + 🔴 Havoc

📐 Sage:  "PostgreSQL — relational data, ACID, proven scale"
⚡ Bolt:  "PostgreSQL is 2x faster to implement with Prisma ORM"
🔴 Havoc: "What about schema migration pain at scale?
           What if requirements change to unstructured data?"
📐 Sage:  "Valid — add JSONB columns for flexible fields"
🧭 Navi:  Consensus: PostgreSQL + JSONB hybrid approach
          → Saved to _aegis-brain/resonance/architecture-decisions.md
```

### Example 4: Full Pipeline Analysis

```
You:    /aegis-pipeline

🧭 Navi:  Starting 3-phase pipeline...

Phase 1 — Research (parallel):
  🔧 Forge: Scanning codebase... 42 files, 3 deps outdated
  🎨 Muse:  Scanning docs... README outdated, no API docs
  → GATE 1: ✅ Research complete

Phase 2 — Deep Analysis (parallel):
  📐 Sage:  Architecture OK, but no error handling layer
  🛡️ Vigil: 2 critical, 5 warnings found
  🔴 Havoc: Auth token has no expiry — security risk
  → GATE 2: ❌ 2 critical findings

Phase 3 — Synthesis:
  🧭 Navi:  Compiling report...
  Report: _aegis-output/pipeline/2026-03-20.md
  Context used: +35K tokens (now at 43%)
```

### Example 5: End Session

```
You:    จบ session

🧭 Navi:  Running /aegis-retro...
          📓 AI Diary: 180 words (honest reflection)
          🔥 Friction: 3 points logged
          🎓 Lessons: 2 patterns extracted
          📁 Saved to _aegis-brain/retrospectives/

You:    ส่งต่อ

🧭 Navi:  ╔═══════════════════════════════════════════╗
          ║ HANDOFF BRIEF                              ║
          ║ ✅ Done: auth system, code review          ║
          ║ 📌 Next: write tests, fix 2 criticals     ║
          ║ 💡 Tip: upgrade autonomy to L2             ║
          ╚═══════════════════════════════════════════╝
          → Next session will auto-load this handoff
```

---

### :iphone: Full Walkthrough: Building an iOS App with AEGIS

> สร้าง iOS Todo App ตั้งแต่ศูนย์ ด้วย AEGIS + Claude Code

**Terminal — Setup:**

```bash
# Create iOS project
mkdir ~/TodoApp && cd ~/TodoApp
git init

# Install AEGIS
~/AEGIS-Team/install.sh --profile full --project-name "TodoApp iOS"

# Open Claude Code
claude
```

**Session 1 — Spec & Architecture:**

```
You:     /aegis-start

🧭 Navi: ╔═══════════════════════════════════════════════╗
         ║ 🛡️ AEGIS — TodoApp iOS                        ║
         ║ Context: 🟢 8% | Autonomy: L1 | Profile: full ║
         ╚═══════════════════════════════════════════════╝

You:     เขียน spec สำหรับ iOS Todo App
         - SwiftUI + MVVM
         - CoreData สำหรับ offline storage
         - CloudKit sync
         - Widget extension
         - Dark mode support

📐 Sage: Writing spec...
         ┌─────────────────────────────────────────────┐
         │ BRD: Todo App — personal task management     │
         │ SRS: SwiftUI + MVVM + CoreData + CloudKit    │
         │ UX:  5 screens (list, detail, add, settings, │
         │      widget config)                          │
         │ → _aegis-output/specs/todoapp-srs.md         │
         └─────────────────────────────────────────────┘

You:     ถกเถียง — CoreData vs SwiftData vs Realm

🧭 Navi: Spawning debate team...

📐 Sage: "SwiftData — native, modern, less boilerplate"
⚡ Bolt: "SwiftData needs iOS 17+, CoreData supports iOS 15+"
🔴 Havoc: "SwiftData has migration bugs in iOS 17.0-17.2.
           What about users on older devices?"
📐 Sage: "Target iOS 17+ only — 85% adoption rate"
🔴 Havoc: "CloudKit sync with SwiftData is still fragile.
           CoreData + NSPersistentCloudKitContainer is proven."
🧭 Navi: Decision: CoreData + CloudKit (proven stability)
         SwiftData migration planned for v2.0
         → Saved to _aegis-brain/resonance/architecture-decisions.md

You:     จบ session

🧭 Navi: 📓 Diary: "First session — spec and architecture decisions..."
         🎓 Lessons: SwiftData not ready for CloudKit sync yet
         📋 Handoff: Next → implement data model + core UI
```

**Session 2 — Build Core Features:**

```
You:     /aegis-start

🧭 Navi: ╔═══════════════════════════════════════════════╗
         ║ 📌 PENDING from Session 1:                    ║
         ║  • Implement CoreData model                   ║
         ║  • Build core UI (list + detail screens)      ║
         ║  • Set up CloudKit container                  ║
         ╚═══════════════════════════════════════════════╝

You:     ทีมสร้าง — implement data model และ core UI

┌─── tmux: aegis-build ──────────────────────────────────┐
│ ┌─ 📐 Sage ──────────────┐ ┌─ ⚡ Bolt ───────────────┐ │
│ │ Spec: CoreData model   │ │ Creating files...       │ │
│ │ • TodoItem entity      │ │ • TodoItem.swift        │ │
│ │ • Category entity      │ │ • Persistence.swift     │ │
│ │ • 1-to-many relation   │ │ • TodoListView.swift    │ │
│ │ → PlanProposal sent    │ │ • TodoDetailView.swift  │ │
│ │                        │ │ • AddTodoView.swift     │ │
│ │                        │ │ • TodoViewModel.swift   │ │
│ │                        │ │ → 7 files created       │ │
│ └────────────────────────┘ └─────────────────────────┘ │
│ ┌─ 🛡️ Vigil ──────────────────────────────────────────┐│
│ │ Review:                                              ││
│ │ ✅ Correctness — MVVM pattern correct                ││
│ │ ✅ Security — no hardcoded keys                      ││
│ │ 🟡 Maintainability — ViewModel needs protocol        ││
│ │ 🔵 Suggestion — add Previews for SwiftUI views       ││
│ │ → QualityGate: ✅ PASS (0 critical)                  ││
│ └──────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘

You:     เพิ่ม CloudKit sync

⚡ Bolt: Adding NSPersistentCloudKitContainer...
         • Updated Persistence.swift (CloudKit container)
         • Created CloudKitSync.swift (sync monitor)
         • Updated Info.plist (CloudKit entitlements)
         → 2 files created, 2 modified

You:     ตรวจความปลอดภัย

🔧 Forge: Scanning...
🛡️ Vigil: Security audit:
          ✅ No hardcoded API keys
          ✅ CloudKit uses system auth (no custom tokens)
          🟡 Add App Transport Security exceptions review
          🔵 Consider adding biometric lock for sensitive todos
          Gate: ✅ PASS

You:     จบ session

🧭 Navi: 📋 Handoff: Next → Widget extension + dark mode + tests
```

**Session 3 — Polish & Ship:**

```
You:     /aegis-start

🧭 Navi: 📌 PENDING: Widget extension, dark mode, tests

You:     ทีมสร้าง — Widget extension สำหรับ iOS

📐 Sage: Spec: WidgetKit timeline provider + 3 widget sizes
⚡ Bolt: Creating TodoWidget target...
         • TodoWidgetBundle.swift
         • TodoTimelineProvider.swift
         • TodoWidgetEntryView.swift (small/medium/large)
         • Shared AppGroup for CoreData access
🛡️ Vigil: ✅ PASS — widget reads from shared container correctly

You:     ทีมรีวิว — review ทั้ง project ก่อน submit App Store

┌─── tmux: aegis-review ─────────────────────────────────┐
│ ┌─ 🔧 Forge ─────────────┐ ┌─ 🔴 Havoc ─────────────┐ │
│ │ Scanning full project   │ │ Stress testing...       │ │
│ │ • 23 Swift files        │ │ • Empty state? ✅       │ │
│ │ • 2 targets (app+widget)│ │ • 1000+ items? 🟡 slow  │ │
│ │ • 0 TODO markers left   │ │ • No network? ✅ offline│ │
│ │ • Test coverage: 72%    │ │ • Delete all? ✅ works  │ │
│ └─────────────────────────┘ └─────────────────────────┘ │
│ ┌─ 🛡️ Vigil (Lead) ───────────────────────────────────┐│
│ │ Final Review:                                        ││
│ │ 🔴 Critical: 0                                       ││
│ │ 🟡 Warning:  1 (pagination needed for 1000+ items)   ││
│ │ 🔵 Suggest:  3 (accessibility labels, haptic, icon)  ││
│ │                                                      ││
│ │ → QualityGate: ✅ CONDITIONAL (fix pagination)       ││
│ └──────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘

You:     /aegis-launch

🧭 Navi: Launch Readiness Check:
         ✅ All tests pass (72% coverage)
         ✅ No critical findings
         🟡 1 warning: pagination for large lists
         ✅ README up to date
         ✅ App Store screenshots ready
         ✅ Privacy policy URL set

         Verdict: 🟡 CONDITIONAL GO
         Fix pagination, then ready to submit!

You:     จบ session

🧭 Navi: 📓 Diary: "Three sessions from zero to App Store ready.
         The debate about SwiftData vs CoreData saved us from
         sync bugs. Havoc's stress test caught the pagination
         issue before Apple review would have..."
         🎓 3 lessons → _aegis-brain/learnings/
```

**Result: 3 sessions → App Store ready** :rocket:

```
Session 1: Spec + architecture debate        (~20 min)
Session 2: Core features + CloudKit + audit   (~30 min)
Session 3: Widget + full review + launch      (~25 min)

Brain accumulated:
  _aegis-brain/
  ├── resonance/architecture-decisions.md  (CoreData chosen)
  ├── learnings/ (7 lessons across 3 sessions)
  ├── retrospectives/ (3 retros with honest diaries)
  └── logs/activity.log (full audit trail)
```

---

## :building_construction: Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AEGIS v6.0 Architecture                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─── Layer 6: Skills + Profiles ──────────────────────────┐   │
│  │  minimal (7)  ──▶  standard (13)  ──▶  full (21)        │   │
│  │  Progressive disclosure · ~50 tokens/skill scan          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 5: Personas + Model Routing ───────────────────┐   │
│  │  opus ───── Navi · Sage · Havoc    (strategy/synthesis)  │   │
│  │  sonnet ─── Bolt · Vigil · Pixel   (implementation)     │   │
│  │  haiku ──── Forge · Muse           (scanning/content)   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 4: Agent Teams (tmux) ─────────────────────────┐   │
│  │  review-team · build-team · debate-team                  │   │
│  │  Mesh communication · Structured message types (8)       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 3: ψ Brain (Persistent Knowledge) ─────────────┐   │
│  │  _aegis-brain/                                           │   │
│  │  ├── resonance/   (identity + conventions + ADRs)        │   │
│  │  ├── learnings/   (accumulated lessons)                  │   │
│  │  ├── logs/        (activity tracking)                    │   │
│  │  └── retrospectives/ (session retros)                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 2: Session Lifecycle ──────────────────────────┐   │
│  │  /aegis-start → WORK → /aegis-retro → /aegis-handoff    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 1: Context Budget ─────────────────────────────┐   │
│  │  20% rule · Token monitoring · Auto-distill              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## :busts_in_silhouette: The 9 Agents

| # | Agent | Model | Role | Blast Radius |
|:-:|:------|:-----:|:-----|:-------------|
| 🧬 | **Mother Brain** | `opus` | **Autonomous Controller** — Scans, decides, spawns teams, no human input needed | entire project (read+write) |
| 1 | :compass: **Navi** | `opus` | Navigator/Lead — Orchestrates, synthesizes, writes retros | CLAUDE*.md, brain, output |
| 2 | :triangular_ruler: **Sage** | `opus` | Architect — Specs, system design, ADRs | docs, specs, architecture |
| 3 | :zap: **Bolt** | `sonnet` | Implementer — Writes code, builds features, runs tests | src, lib, tests, configs |
| 4 | :shield: **Vigil** | `sonnet` | Reviewer — Code review, quality gates, security checks | output/reviews (read-only src) |
| 5 | :red_circle: **Havoc** | `opus` | Devil's Advocate — Challenges assumptions, finds flaws | output/challenges |
| 6 | :wrench: **Forge** | `haiku` | Scanner/Research — Gathers data, scans repos, metrics | brain/logs, output/scans |
| 7 | :art: **Pixel** | `sonnet` | UX Designer — UI/UX, accessibility, design systems | components, styles, assets |
| 8 | :paintbrush: **Muse** | `haiku` | Content Creator — Docs, changelogs, copywriting | docs, README, CHANGELOG |

### 🧬 Mother Brain — Autonomous Controller

After `/aegis-start`, Mother Brain takes full control:

```
/aegis-start
  → Dashboard (5 sec)
  → 🧬 Scan project state (git, tests, specs, deps, tech debt)
  → 🧬 Apply Decision Matrix (P0-P10)
  → 🧬 Spawn the right team via tmux
  → 🧬 Agents work → quality gates → next phase → repeat
  → 🧬 Report results when done
  → 🙋 Ask human ONLY when mission is complete or critical error
```

| Priority | Signal | Mother Brain Action |
|:--------:|:-------|:-------------------|
| P0 | Tests/build broken | Fix immediately |
| P1 | Security vulnerabilities | Audit + fix |
| P2 | Pending handoff tasks | Resume last session |
| P3 | Spec exists, no code | Implement spec |
| P4 | Code exists, no tests | Create test suite |
| P5 | Code exists, no review | Deep review |
| P6 | TODOs/FIXMEs found | Tech debt sweep |
| P7 | Outdated dependencies | Update cycle |
| P8 | No spec, no code | Generate spec |
| P9 | Everything clean | Optimize / refactor |
| P10 | Empty project | Ask ONE question, then GO |

### Model Routing Strategy

| Tier | Agents | Purpose | Cost |
|:-----|:-------|:--------|:----:|
| **Opus** | Navi, Sage, Havoc | Strategy, synthesis, deep reasoning | $$$ |
| **Sonnet** | Bolt, Vigil, Pixel | Implementation, review, design | $$ |
| **Haiku** | Forge, Muse | Data gathering, content, scanning | $ |

> **Rule of thumb:** Opus thinks, Sonnet builds, Haiku gathers.

---

## :keyboard: Commands

AEGIS provides 15 slash commands for session and team management:

| Command | Purpose |
|:--------|:--------|
| `/aegis-start` | Begin session — activate 🧬 Mother Brain, auto-execute |
| `/aegis-retro` | End session — run retrospective, extract lessons |
| `/aegis-handoff` | Generate handoff document for next session |
| `/aegis-pipeline` | Run full analysis pipeline across all agents |
| `/aegis-status` | Check progress of all active agents |
| `/aegis-mode` | Switch skill profile: `minimal` / `standard` / `full` |
| `/aegis-context` | Show context budget usage and token breakdown |
| `/aegis-distill` | Compress conversation context into essentials |
| `/aegis-memory` | Read/write to persistent brain |
| `/aegis-verify` | Verify agent outputs meet acceptance criteria |
| `/aegis-launch` | Launch a specific agent with a task |
| `/aegis-flow` | Visualize current pipeline flow and dependencies |
| `/aegis-team-build` | Spawn **build team** (Bolt + Vigil) via tmux |
| `/aegis-team-review` | Spawn **review team** (Vigil + Havoc + Forge) via tmux |
| `/aegis-team-debate` | Spawn **debate team** (Sage + Havoc) via tmux |

---

## :jigsaw: Skill Profiles

Skills load on-demand based on the active profile. Progressive disclosure keeps context lean — each skill scans at approximately 50 tokens.

### Minimal Profile — 7 skills (~3K tokens)

> Quick tasks, small projects, limited context

| # | Skill | Description |
|:-:|:------|:------------|
| 1 | `personas` | Load and activate AEGIS agent personas |
| 2 | `orchestrator` | Pipeline orchestration, task routing |
| 3 | `code-review` | Structured review with severity ratings |
| 4 | `code-standards` | Linting rules, style conventions |
| 5 | `git-workflow` | Git branching, commit conventions, PR workflow |
| 6 | `bug-lifecycle` | Bug triage, root cause analysis, fix verification |
| 7 | `project-navigator` | Explore project structure, find files |

### Standard Profile — 13 skills (~6K tokens)

> Normal development, team projects (includes all minimal skills)

| # | Skill | Description |
|:-:|:------|:------------|
| 8 | `super-spec` | Feature specifications from requirements |
| 9 | `test-architect` | Test strategy, test cases, coverage analysis |
| 10 | `security-audit` | Vulnerability scanning, threat modeling, OWASP |
| 11 | `tech-debt-tracker` | Identify and prioritize technical debt |
| 12 | `sprint-tracker` | Sprint planning, velocity, standup summaries |
| 13 | `api-docs` | API documentation, OpenAPI/Swagger specs |

### Full Profile — 21 skills (~12K tokens)

> Complex analysis, full pipeline, enterprise (includes all standard skills)

| # | Skill | Description |
|:-:|:------|:------------|
| 14 | `aegis-distill` | Compress context into essential summaries |
| 15 | `aegis-observe` | Monitor agent performance and pipeline health |
| 16 | `adversarial-review` | Red-team analysis, assumption challenging |
| 17 | `code-coverage` | Analyze test coverage, identify gaps |
| 18 | `retrospective` | Structured session retrospectives |
| 19 | `course-correction` | Detect pipeline drift, realign with goals |
| 20 | `skill-marketplace` | Discover and install community skills |
| 21 | `aegis-builder` | Meta-skill to create new AEGIS skills |

---

## :star2: Key Features

### Structured Message Types
Eight typed message formats (`TaskAssignment`, `StatusUpdate`, `FindingReport`, `PlanProposal`, `ApprovalRequest`, `EscalationAlert`, and more) ensure clean, parseable inter-agent communication.

### Graduated Autonomy
Four levels that scale trust with your comfort:

| Level | Mode | Description |
|:-----:|:-----|:------------|
| L1 | Supervised | Human approves every action |
| L2 | Guided | Human approves plans, agents execute |
| L3 | Autonomous | Agents work, human reviews output |
| L4 | Full Auto | Fully autonomous with async monitoring |

### Persistent Brain
The `_aegis-brain/` directory survives across sessions:
- **resonance/** — Project identity, team conventions, architecture decisions
- **learnings/** — Accumulated lessons from past sessions
- **logs/** — Activity tracking and scan results
- **retrospectives/** — Session retros with actionable insights

### Progressive Disclosure
Skills are scanned at approximately 50 tokens each, loaded fully only when needed. Context stays lean and efficient.

### Review Gates
Mandatory quality checkpoints between pipeline phases. Vigil reviews every change before merge. No auto-approvals.

### Reflexion Loop
Agents learn from failures. When something goes wrong, the retrospective captures lessons that feed into future decisions.

### Blast Radius Containment
Each agent has strict read/write boundaries. Bolt cannot touch CLAUDE.md. Vigil cannot modify source code. Forge only gathers — never decides. Scope limits prevent cascading mistakes.

---

## :file_folder: Directory Structure

```
AEGIS-Team/
├── CLAUDE.md                  # Main entry — golden rules, navigation
├── CLAUDE_agents.md           # 8 agent personas + routing
├── CLAUDE_safety.md           # Safety rules for git/file ops
├── CLAUDE_skills.md           # Skill catalog (21 skills)
├── CLAUDE_lessons.md          # Accumulated lessons learned
│
├── .claude/
│   ├── commands/              # 15 slash commands
│   │   ├── aegis-start.md
│   │   ├── aegis-retro.md
│   │   ├── aegis-handoff.md
│   │   ├── aegis-pipeline.md
│   │   ├── aegis-status.md
│   │   ├── aegis-mode.md
│   │   ├── aegis-context.md
│   │   ├── aegis-distill.md
│   │   ├── aegis-memory.md
│   │   ├── aegis-verify.md
│   │   ├── aegis-launch.md
│   │   ├── aegis-flow.md
│   │   ├── aegis-team-build.md
│   │   ├── aegis-team-review.md
│   │   └── aegis-team-debate.md
│   ├── settings.json          # Permissions (57 allow, 7 deny)
│   ├── agents/                # Agent profile configs
│   │   ├── mother-brain.md    # 🧬 Autonomous controller
│   │   ├── navi.md
│   │   ├── sage.md
│   │   ├── bolt.md
│   │   ├── vigil.md
│   │   ├── havoc.md
│   │   ├── forge.md
│   │   ├── pixel.md
│   │   └── muse.md
│   ├── teams/                 # Predefined team compositions
│   │   ├── aegis-review.md
│   │   ├── aegis-build.md
│   │   └── aegis-debate.md
│   └── references/            # Shared reference docs
│       ├── progress-protocol.md
│       ├── output-format.md
│       ├── review-checklist.md
│       ├── context-rules.md
│       ├── message-types.md
│       └── autonomy-levels.md
│
├── skills/                    # 21 loadable skill files
│   ├── ai-personas.md
│   ├── orchestrator.md
│   ├── code-review.md
│   ├── code-standards.md
│   ├── git-workflow.md
│   ├── bug-lifecycle.md
│   ├── project-navigator.md
│   ├── super-spec.md
│   ├── test-architect.md
│   ├── security-audit.md
│   ├── tech-debt-tracker.md
│   ├── sprint-tracker.md
│   ├── api-docs.md
│   ├── aegis-distill.md
│   ├── aegis-observe.md
│   ├── adversarial-review.md
│   ├── code-coverage.md
│   ├── retrospective.md
│   ├── course-correction.md
│   ├── skill-marketplace.md
│   └── aegis-builder.md
│
├── _aegis-brain/              # Persistent knowledge (ψ Brain)
│   ├── resonance/             # Project identity + conventions
│   ├── learnings/             # Accumulated lessons
│   ├── logs/                  # Activity logs
│   └── retrospectives/        # Session retrospectives
│
├── _aegis-output/             # Agent work products
│
├── install.sh                 # One-command installer
└── .gitignore
```

---

## :arrows_counterclockwise: Session Lifecycle

```
  ┌──────────────┐
  │ /aegis-start │  Load brain, restore state, check context budget
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │     WORK     │  Agents execute tasks within blast radius
  │              │  ├── /aegis-pipeline   (full analysis)
  │              │  ├── /aegis-team-*     (spawn teams)
  │              │  ├── /aegis-status     (check progress)
  │              │  └── /aegis-verify     (validate outputs)
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │ /aegis-retro │  Retrospective — what went well, what to improve
  └──────┬───────┘
         │
         ▼
  ┌────────────────┐
  │ /aegis-handoff │  Generate handoff doc for next session
  └────────────────┘  Brain persists → next session picks up where you left off
```

---

## :people_holding_hands: Agent Teams (tmux)

AEGIS has **two orchestration modes**. The system auto-selects based on task type:

```
  Task needs inter-agent communication?
         │
    ┌────┴────┐
    │ NO      │ YES
    ▼         ▼
  SUBAGENT   AGENT TEAM (tmux)
  mode       mode
```

| Mode | When | Example |
|:-----|:-----|:--------|
| **Subagent** | Agent works solo, no cross-talk needed | `"รีวิวโค้ดให้"` → Vigil alone |
| **Agent Team (tmux)** | Multiple agents need to communicate in real-time | `"ทีมสร้าง"` → Sage + Bolt + Vigil |

### Requirements for tmux mode

```bash
# Install tmux
brew install tmux          # macOS
sudo apt install tmux      # Linux

# Enable Agent Teams (required)
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# tmux is REQUIRED for AEGIS Agent Teams — install it before using team commands
```

### Review Team — `/aegis-team-review`
```
┌─── tmux session: aegis-review ─────────────────────────────┐
│                                                             │
│  ┌─ pane 0: 🔧 Forge ─────┐  ┌─ pane 1: 🔴 Havoc ──────┐ │
│  │ Scanning codebase...    │  │ Challenging assumptions.. │ │
│  │ → FindingReport sent    │  │ → FindingReport sent     │ │
│  └─────────────────────────┘  └──────────────────────────┘ │
│  ┌─ pane 2: 🛡️ Vigil (Lead) ────────────────────────────┐  │
│  │ Received findings from Forge + Havoc                  │  │
│  │ Synthesizing → QualityGate: PASS/FAIL                 │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```
Forge gathers data, Havoc challenges assumptions, Vigil synthesizes and issues the quality gate.

### Build Team — `/aegis-team-build`
```
┌─── tmux session: aegis-build ──────────────────────────────┐
│                                                             │
│  ┌─ pane 0: 📐 Sage ──────┐  ┌─ pane 1: ⚡ Bolt ────────┐ │
│  │ Writing spec...         │  │ Waiting for spec...       │ │
│  │ → PlanProposal sent ──────▶│ Implementing...           │ │
│  └─────────────────────────┘  │ → StatusUpdate sent ──┐   │ │
│  ┌─ pane 2: 🛡️ Vigil ────────────────────────────────┼──┐ │
│  │ Received StatusUpdate ◀────────────────────────────┘  │ │
│  │ Running 5-pass review... → QualityGate: PASS          │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```
Sage designs the spec → Bolt implements → Vigil reviews. Pipeline with review gates between each phase.

### Debate Team — `/aegis-team-debate`
```
┌─── tmux session: aegis-debate ─────────────────────────────┐
│                                                             │
│  ┌─ pane 0: 📐 Sage ──────┐  ┌─ pane 1: ⚡ Bolt ────────┐ │
│  │ Proposing Option A...   │  │ Option A is feasible but  │ │
│  │ → PlanProposal          │  │ costly to maintain...     │ │
│  └─────────────────────────┘  └──────────────────────────┘ │
│  ┌─ pane 2: 🔴 Havoc ─────┐  ┌─ pane 3: 🧭 Navi ───────┐ │
│  │ Option A fails when...  │  │ Synthesizing consensus... │ │
│  │ → CounterProposal       │  │ → ArchitectureDecision    │ │
│  └─────────────────────────┘  └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```
Sage proposes, Bolt evaluates feasibility, Havoc stress-tests. Navi drives consensus and records the Architecture Decision Record (ADR).

### Setting Up tmux Agent Teams (Step by Step)

**Step 1: Install tmux**

```bash
# macOS
brew install tmux

# Linux (Ubuntu/Debian)
sudo apt install tmux

# Verify
tmux -V    # → tmux 3.x
```

**Step 2: Learn tmux basics (30 seconds)**

```bash
# All tmux shortcuts start with Ctrl+B, then a key:
#
# Ctrl+B  o     → Switch between panes (cycle through agents)
# Ctrl+B  z     → Zoom current pane (fullscreen one agent)
# Ctrl+B  z     → Zoom out (back to all panes)
# Ctrl+B  [     → Scroll mode (use arrows, q to exit)
# Ctrl+B  d     → Detach (exit tmux but agents keep running)
# tmux attach   → Re-attach (get back to your agents)
```

**Step 3: Use tmux teams from Claude Code**

```bash
# Open Claude Code in your project
cd ~/my-project
claude

# Then use any team command:
> /aegis-team-build     # Sage specs → Bolt builds → Vigil reviews
> /aegis-team-review    # Forge scans → Havoc challenges → Vigil gates
> /aegis-team-debate    # Sage vs Bolt vs Havoc → Navi synthesizes
```

**Step 4: Watch agents communicate**

When a team command runs, tmux auto-creates a split-pane session:

```
┌─── Your terminal splits into panes ──────────────────────┐
│                                                           │
│  Each pane = one agent running its own Claude instance     │
│  Agents send structured messages to each other             │
│  You can watch them work in real-time                      │
│                                                           │
│  Ctrl+B o  → cycle through agent panes                    │
│  Ctrl+B z  → zoom into one agent's full output            │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

**Step 5: Manual tmux session (advanced)**

```bash
# Create a custom team session manually:
tmux new-session -d -s my-team

# Split into panes
tmux split-window -h -t my-team      # vertical split
tmux split-window -v -t my-team.0    # horizontal split (left)
tmux split-window -v -t my-team.1    # horizontal split (right)

# Label panes
tmux set -t my-team pane-border-status top
tmux select-pane -t my-team.0 -T "📐 Sage"
tmux select-pane -t my-team.1 -T "⚡ Bolt"
tmux select-pane -t my-team.2 -T "🛡️ Vigil"

# Run Claude in each pane
tmux send-keys -t my-team.0 "cd ~/my-project && claude" Enter
tmux send-keys -t my-team.1 "cd ~/my-project && claude" Enter
tmux send-keys -t my-team.2 "cd ~/my-project && claude" Enter

# Attach to watch
tmux attach -t my-team
```

### :rotating_light: tmux is Required

tmux is a **core dependency** of AEGIS — not optional. Agent Teams rely on tmux for:
- **Visible agent communication** — see what each agent is thinking
- **Parallel execution** — agents work simultaneously in split panes
- **Real-time monitoring** — watch message passing between agents
- **Session persistence** — detach/reattach without losing agent state

Without tmux, team commands (`/aegis-team-*`) will not function. Install tmux before using AEGIS.

### Which commands use tmux?

| Command | Mode | Agents |
|:--------|:-----|:-------|
| `/aegis-pipeline` | Subagent | Phases run sequentially |
| `/aegis-team-review` | **tmux** | Vigil + Havoc + Forge |
| `/aegis-team-build` | **tmux** | Sage + Bolt + Vigil |
| `/aegis-team-debate` | **tmux** | Sage + Bolt + Havoc + Navi |
| `"รีวิวโค้ด"` | Subagent | Vigil alone |
| `"ท้าทายการตัดสินใจ"` | Subagent | Havoc alone |

---

## :thailand: Thai Triggers (ภาษาไทย)

AEGIS supports Thai trigger words alongside English. Just type naturally:

| พิมพ์ | Triggers | Command/Skill |
|:------|:---------|:-------------|
| "เริ่ม session" | `/aegis-start` | Begin session |
| "รีวิวโค้ดให้" | code-review + Vigil | 5-pass code review |
| "ทีมสร้าง" | `/aegis-team-build` | Spawn build team (tmux) |
| "ทีมรีวิว" | `/aegis-team-review` | Spawn review team (tmux) |
| "ถกเถียง" | `/aegis-team-debate` | Architecture debate |
| "เช็ค context" | `/aegis-context` | Check token budget |
| "สถานะ" | `/aegis-status` | Agent status dashboard |
| "จบ session" | `/aegis-retro` | Session retrospective |
| "ส่งต่อ" | `/aegis-handoff` | Handoff to next session |
| "วางแผน" | orchestrator + Navi | Plan & orchestrate |
| "เขียน spec" | super-spec + Sage | Write specification |
| "ตรวจความปลอดภัย" | security-audit | Security audit |
| "หนี้เทคนิค" | tech-debt-tracker | Tech debt scan |
| "ท้าทายการตัดสินใจ" | adversarial-review + Havoc | Devil's advocate |

---

## :test_tube: Usage Example — Full Session

```
You:   /aegis-start
Navi:  ╔══════════════════════════════════════════════╗
       ║  🛡️ AEGIS SESSION — My Project               ║
       ║  CONTEXT: 🟢 8% | AUTONOMY: L1              ║
       ║  PENDING: (none — first session)              ║
       ╚══════════════════════════════════════════════╝

You:   รีวิวโค้ดให้หน่อย ดู src/ ทั้งหมด
Navi:  Trigger: "รีวิวโค้ด" → skill: code-review → agent: 🛡️ Vigil
Vigil: 5-pass review... 🔴 1 Critical | 🟡 3 Warnings | 🔵 4 Suggestions
       Gate: ❌ FAIL (1 critical: no input validation)

You:   ทีมสร้าง — fix แล้วเพิ่ม auth system
Navi:  Trigger: "ทีมสร้าง" → /aegis-team-build (tmux)
       Spawning: 📐 Sage + ⚡ Bolt + 🛡️ Vigil
Sage:  Auth spec (JWT + validation) → PlanProposal sent
Bolt:  Implementing... 4 files created → StatusUpdate sent
Vigil: Review PASS (0 critical) → QualityGate: ✅

You:   จบ session
Navi:  📓 AI Diary (150+ words, honest reflection)
       🔥 Friction: 3 points logged
       🎓 Lessons: 2 patterns extracted → _aegis-brain/learnings/

You:   ส่งต่อ
Navi:  ╔══════════════════════════════════════════════╗
       ║  📋 HANDOFF                                   ║
       ║  ✅ Done: auth system, input validation      ║
       ║  📌 Next: write tests, add CRUD endpoints    ║
       ║  💡 Recommend: upgrade to L2 autonomy        ║
       ╚══════════════════════════════════════════════╝
```

---

## :gear: Golden Rules

1. **NEVER** use `--force` flags on git
2. **NEVER** push to main — always branch + PR
3. **NEVER** `git commit --amend` — it breaks all agents
4. **NEVER** end turn before agents finish (false-ready guard)
5. Run `/aegis-start` at session begin
6. Run `/aegis-retro` at session end

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
