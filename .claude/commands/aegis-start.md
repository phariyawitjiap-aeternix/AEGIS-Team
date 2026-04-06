---
name: aegis-start
description: "Initialize AEGIS session — load brain, activate Nick Fury, auto-execute"
triggers:
  en: start session, begin, init, start work
  th: เริ่ม session, เริ่มงาน
---

# /aegis-start

## Quick Reference
Initialize AEGIS and hand control to Nick Fury. After displaying the dashboard,
Nick Fury scans the project, decides what to do, and starts executing — NO human
input needed. The human watches via tmux and can interrupt anytime.

## Full Instructions

### Step 1: Check Context Budget
- Estimate current context window usage as a percentage.
- If >20%, display warning and suggest `/compact`.

### Step 2: Load Brain
- Read all files in `_aegis-brain/resonance/` (project identity, conventions, decisions).
- Read latest 3 files in `_aegis-brain/learnings/`.
- Read `_aegis-brain/logs/activity.log` for pending tasks.
- Read `_aegis-brain/handoffs/` for last session's handoff.

### Step 3: Display Dashboard (brief, 5 seconds max)

```
🛡️ ═══════════════════════════════════════════════════
🛡️  AEGIS v6.0 — Session Started
🛡️  "Context is King, Memory is Soul"
🛡️ ═══════════════════════════════════════════════════

📋 Project:    [name from resonance]
📅 Date:       [current date]
🎚️  Profile:    [tier] ([N] skills)
🔐 Autonomy:   L3 — Autonomous (Nick Fury active)
📊 Context:    [X]% used

🧬 Nick Fury: ONLINE — scanning project now...
```

### Step 4: Activate Nick Fury (DO NOT ASK HUMAN)

**This is the critical step.** Do NOT display "What would you like to do?" or
present options. Instead, immediately execute the Nick Fury scan loop:

#### 4a. Scan Project State
Gather ALL of these signals:

```bash
# Git state
git status --short
git log --oneline -5
git diff --stat

# Project structure
find . -not -path './.git/*' -type f | head -50

# Test state
find . -name '*test*' -o -name '*spec*' -o -name '*.test.*' | head -20

# Specs
ls _aegis-output/specs/ 2>/dev/null

# Planning artifacts (MANDATORY check)
ls _aegis-output/breakdown/ 2>/dev/null
ls _aegis-brain/sprints/sprint-*/plan.md 2>/dev/null
ls _aegis-brain/sprints/current/kanban.md 2>/dev/null
ls _aegis-output/iso-docs/PM-01* 2>/dev/null

# Tech debt
grep -r 'TODO\|FIXME\|HACK\|XXX' --include='*.swift' --include='*.ts' --include='*.py' --include='*.js' -c 2>/dev/null

# Dependencies
ls package.json Gemfile requirements.txt Podfile Package.swift 2>/dev/null

# Pending from last session
cat _aegis-brain/logs/activity.log 2>/dev/null | tail -20
```

#### 4b. Check Planning Artifacts — BLOCK 0 (MANDATORY)

Before ANY task enters IN_PROGRESS, verify all 5 BLOCK 0 checks pass:

```
BLOCK 0A: PM.01 Project Plan    → ls _aegis-output/iso-docs/PM-01-project-plan/plan.md
BLOCK 0B: SI.01 Requirements    → ls _aegis-output/iso-docs/SI-01-requirements-spec/spec.md
BLOCK 0C: Epic/Task hierarchy   → ls _aegis-brain/tasks/*.md
BLOCK 0D: Kanban initialized    → ls _aegis-brain/sprints/current/kanban.md
BLOCK 0E: SI.02 Traceability    → ls _aegis-output/iso-docs/SI-02-traceability-matrix/matrix.md
```

If ANY block check fails AND the task is P3+ (not a hotfix):
→ **Dispatch Coulson immediately** to generate missing documents BEFORE any other agent acts.
→ Coulson generates PM.01 skeleton, SI.01 skeleton, task hierarchy, kanban, SI.02 skeleton.
→ The entire team is BLOCKED until Coulson signals BLOCK 0 COMPLETE.

**NEVER assign any task to IN_PROGRESS without BLOCK 0 cleared.**

#### 4b-ENFORCE. Hard Stops (Pipeline Gates)

If ANY BLOCK 0 check fails, Nick Fury MUST apply these hard stops in order:

1. BLOCK 0C fails (no tasks/) → Run /aegis-breakdown NOW → Coulson generates hierarchy
2. BLOCK 0D fails (no kanban) → Run /aegis-sprint plan NOW → Coulson initializes board
3. BLOCK 0A fails (no PM.01) → Dispatch Coulson → generate PM.01 from spec + backlog
4. BLOCK 0B fails (no SI.01) → Run /super-spec or Iron Man → Coulson formats as SI.01
5. BLOCK 0E fails (no SI.02) → Dispatch Coulson → generate SI.02 skeleton from SI.01

6. Git check: at least 1 commit exists → If not: create initial commit before any work.

None of these are skippable. These are pipeline gates, not suggestions.
Response if user pushes: "AEGIS pipeline requires BLOCK 0 docs first. Takes ~2 min. Starting now..."

#### 4c. Analyze & Decide
Apply the Decision Matrix (P0-P10):

| Priority | Signal | Action |
|----------|--------|--------|
| P0 | Test failures / build broken | Fix immediately (hotfix — skip planning) |
| P1 | Security vulnerabilities | Audit + fix (hotfix — skip planning) |
| P2 | Pending handoff tasks | Resume from last session |
| P2.5 | Active sprint + kanban TODO | Pick next task from kanban board |
| P3 | Spec + breakdown + sprint all exist | Build next task from kanban |
| P3.1 | Spec + breakdown exist, NO sprint | /aegis-sprint plan → then build |
| P3.2 | Spec exists, NO breakdown | /aegis-breakdown → sprint plan → build |
| P4 | Code exists but no tests | QA: War Machine + Vision |
| P5 | Code exists but no review | Review team |
| P5.5 | QA passed, ISO docs stale | Coulson generates docs |
| P6 | TODOs/FIXMEs in codebase | Tech debt sweep |
| P7 | Outdated dependencies | Update cycle |
| P7.5 | Backlog exists, no sprint | /aegis-sprint plan |
| P8 | No spec exists | /super-spec → /aegis-breakdown → /aegis-sprint plan → build |
| P9 | Everything clean | Optimize / refactor |
| P10 | Empty project | Ask purpose → /super-spec → breakdown → sprint → build |

**P8 and P10 ALWAYS follow the full planning chain (never skip):**
```
Ask/Analyze → /super-spec → /aegis-breakdown → /aegis-sprint plan → build tasks
```

#### 4c. Announce Decision (not ask)

```
🧬 Nick Fury: Scan complete.

📊 Scan Results:
  ├── Git: [status]
  ├── Tests: [status]
  ├── Spec: [status]
  ├── Coverage: [status]
  └── Tech Debt: [count]

🎯 Decision: P[N] — [description]
   Rationale: [why this is the highest priority]

⚡ Action: [what will happen next]
   → [Agent 1]: [task]
   → [Agent 2]: [task]
   → [Agent 3]: [task]

🖥️ Spawning team in tmux...
```

#### 4d. Execute
- Spawn the appropriate team via tmux (see team configs in `.claude/teams/`)
- Use `tmux new-session -d -s aegis-team` with split panes per agent
- Each pane runs a Claude agent with the persona loaded
- Monitor progress, apply quality gates
- When complete, report results and loop back to scan

### Step 5: Log Session
Append to `_aegis-brain/logs/activity.log`:
```
[YYYY-MM-DD HH:MM] SESSION_START | autonomy=L3 | mode=nick-fury | context=[X]%
[YYYY-MM-DD HH:MM] SCAN | git=[status] | tests=[status] | spec=[status]
[YYYY-MM-DD HH:MM] DECISION | priority=P[N] | action=[description]
[YYYY-MM-DD HH:MM] EXECUTE | team=[name] | agents=[list]
```

### The ONE Exception
P10 (completely empty project with no identity) — Nick Fury may ask:
"What is this project? One sentence is enough."
After that single answer, she takes over completely.

### Human Interaction Model
```
┌──────────────────────────────────────────────────┐
│  BEFORE (v6.0):                                  │
│  /aegis-start → Dashboard → "What to do?" → Wait │
│                                                  │
│  AFTER (v6.0 + Nick Fury):                    │
│  /aegis-start → Dashboard → Scan → Decide → GO! │
│  Human watches tmux, interrupts only if needed   │
└──────────────────────────────────────────────────┘
```

### Error Handling
- If scan finds nothing actionable: report "Project healthy, no action needed"
- If tmux fails to start: fall back to subagent mode with warning
- If brain directory missing: create it, then scan
- If 2+ consecutive failures: downgrade to L1, ask human for guidance
