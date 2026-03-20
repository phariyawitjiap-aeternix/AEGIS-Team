# 🛡️ AEGIS v6.0 — Getting Started Guide

> ขั้นตอนการติดตั้งและใช้งาน AEGIS กับ project ใหม่ ผ่าน Terminal

---

## Prerequisites

```bash
# 1. Claude Code CLI (required)
# Install: https://docs.anthropic.com/en/docs/claude-code/overview
claude --version

# 2. Git (required)
git --version

# 3. tmux (optional — for Agent Teams)
brew install tmux        # macOS
sudo apt install tmux    # Linux
```

---

## Step 1: Clone AEGIS Framework

```bash
# Clone ไว้ที่ home directory (ทำครั้งเดียว)
git clone https://github.com/phariyawitjiap-aeternix/AEGIS-Team.git ~/AEGIS-Team
```

---

## Step 2: Create Your Project

```bash
# สร้าง project ใหม่
mkdir ~/my-api-project
cd ~/my-api-project
git init

# หรือถ้ามี project อยู่แล้ว
cd ~/my-existing-project
```

---

## Step 3: Install AEGIS

```bash
# Install with standard profile (recommended)
~/AEGIS-Team/install.sh --profile standard --project-name "My API Project"

# ============================================
# Output จะเห็นประมาณนี้:
# ============================================
# ================================================
#   AEGIS v6.0.0 Installer
# ================================================
#
# [INFO] Profile: standard
# [INFO] Target:  /Users/you/my-api-project
# [INFO] Project: My API Project
#
# [OK] git found
# [OK] tmux found
# [OK] claude CLI found
# [OK] Directory structure created
# [OK] CLAUDE*.md files installed
# [OK] 8 agent definitions installed
# [OK] 15 commands installed
# [OK] 6 reference files installed
# [OK] 3 team configs installed
# [OK] 13 skills installed (full definitions, not stubs)
#
#   AEGIS v6.0.0 Installation Complete!
# ============================================
```

### Profile Options

| Command | Skills | Best For |
|---------|--------|----------|
| `--profile minimal` | 7 | Small scripts, quick tasks |
| `--profile standard` | 13 | **Most projects (recommended)** |
| `--profile full` | 21 | Enterprise, complex analysis |

---

## Step 4: Verify Installation

```bash
# Check that everything was installed
ls -la CLAUDE*.md          # Should see 5 files
ls .claude/commands/       # Should see 15 .md files
ls .claude/agents/         # Should see 8 .md files
ls skills/                 # Should see 7-21 .md files (depends on profile)
ls _aegis-brain/resonance/ # Should see project identity files
```

---

## Step 5: Open Claude Code

```bash
# Make sure you're in your project directory
cd ~/my-api-project

# Launch Claude Code
claude
```

---

## Step 6: Start Your First Session

Once inside Claude Code, type:

```
> /aegis-start
```

You'll see the session dashboard:

```
╔══════════════════════════════════════════════════════╗
║  🛡️ AEGIS v6.0 — Session Start                      ║
╠══════════════════════════════════════════════════════╣
║  Project:    My API Project                          ║
║  Context:    🟢 8% used                              ║
║  Autonomy:   L1 — Supervised                         ║
║  Profile:    standard (13 skills)                    ║
╠══════════════════════════════════════════════════════╣
║  AVAILABLE AGENTS                                    ║
║  🧭 Navi (Lead/opus)     📐 Sage (Architect/opus)   ║
║  ⚡ Bolt (Implement/son) 🛡️ Vigil (Review/sonnet)   ║
║  🔴 Havoc (Adversarial)  🔧 Forge (Research/haiku)  ║
║  🖌️ Pixel (UX/sonnet)    🎨 Muse (Content/haiku)    ║
╚══════════════════════════════════════════════════════╝
```

---

## Step 7: Work With Agents

### Option A: Type in Thai or English naturally

```
> รีวิวโค้ดให้หน่อย
  → Triggers: code-review skill → Vigil agent

> เขียน spec สำหรับ auth system
  → Triggers: super-spec skill → Sage agent

> ตรวจความปลอดภัย
  → Triggers: security-audit skill → Forge + Vigil
```

### Option B: Use slash commands directly

```
> /aegis-pipeline              # Full analysis pipeline
> /aegis-team-build            # Spawn build team (Sage + Bolt + Vigil)
> /aegis-team-review           # Spawn review team (Vigil + Havoc + Forge)
> /aegis-team-debate           # Architecture debate (all agents)
> /aegis-status                # Check what agents are doing
> /aegis-context               # Check token budget
> /aegis-verify                # Verify everything works
```

### Option C: Use Thai triggers for teams

```
> ทีมสร้าง — เพิ่ม user authentication
  → Spawns build team via tmux

> ทีมรีวิว — ดู security ทั้ง project
  → Spawns review team via tmux

> ถกเถียง — ควรใช้ SQL หรือ NoSQL
  → Spawns debate team via tmux
```

---

## Step 8: End Session

```
> /aegis-retro
```

This will:
1. Summarize what was done
2. Write an AI diary (honest reflection)
3. Log 3+ friction points
4. Extract lessons → `_aegis-brain/learnings/`
5. Save retrospective → `_aegis-brain/retrospectives/`

```
> /aegis-handoff
```

This prepares a handoff for the next session:
- What was completed
- What's pending
- Blockers
- Recommendations

---

## Step 9: Next Session

```bash
# Next time you open the project:
cd ~/my-api-project
claude

# First command — always:
> /aegis-start
# → Brain loads automatically
# → Shows pending tasks from last session
# → Picks up where you left off
```

---

## Enable tmux Agent Teams (Optional but Recommended)

```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc):
echo 'export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1' >> ~/.zshrc
source ~/.zshrc

# Verify:
echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
# Should print: 1
```

With tmux enabled, `/aegis-team-*` commands spawn agents in visible tmux panes:

```
┌─── tmux: aegis-build ──────────────────────────────┐
│ ┌─ 📐 Sage ───────────┐ ┌─ ⚡ Bolt ──────────────┐ │
│ │ Writing spec...      │ │ Implementing...        │ │
│ └──────────────────────┘ └────────────────────────┘ │
│ ┌─ 🛡️ Vigil ──────────────────────────────────────┐ │
│ │ Reviewing... QualityGate: ✅ PASS                │ │
│ └──────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## Quick Reference Card

| Action | Command |
|--------|---------|
| Start session | `/aegis-start` |
| Code review | `/aegis-pipeline` or "รีวิวโค้ด" |
| Build feature | `/aegis-team-build` or "ทีมสร้าง" |
| Review code | `/aegis-team-review` or "ทีมรีวิว" |
| Debate architecture | `/aegis-team-debate` or "ถกเถียง" |
| Check status | `/aegis-status` or "สถานะ" |
| Check context | `/aegis-context` or "เช็ค context" |
| Switch profile | `/aegis-mode standard` or "เปลี่ยนโหมด" |
| End session | `/aegis-retro` or "จบ session" |
| Handoff | `/aegis-handoff` or "ส่งต่อ" |
| Memory recall | `/aegis-memory recall auth` or "จำอะไรได้บ้าง" |

---

## Upgrade Existing Installation

```bash
# When AEGIS releases a new version:
cd ~/AEGIS-Team
git pull

# Re-install with upgrade flag (preserves your customizations):
~/AEGIS-Team/install.sh --upgrade --target-dir ~/my-api-project
```

---

## Uninstall

```bash
# Remove AEGIS files (keeps your source code):
cd ~/my-api-project
rm -rf .claude/ skills/ _aegis-brain/ _aegis-output/
rm CLAUDE.md CLAUDE_safety.md CLAUDE_agents.md CLAUDE_skills.md CLAUDE_lessons.md
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `/aegis-start` not found | Make sure you're in the project directory with `.claude/commands/` |
| tmux teams not working | Run `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| Context too high at start | Run `/compact` before `/aegis-start` |
| Skills not loading | Check `ls skills/` — files should NOT be stubs (TODO) |
| Brain not persisting | Check `ls _aegis-brain/resonance/` — should have .md files |

---

> **"Context is King, Memory is Soul"** — AEGIS v6.0 🛡️
