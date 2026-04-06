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

#### 4b. Check Planning Artifacts (MANDATORY)
Before ANY build/implementation, verify these exist:

```
Check 1: Spec?         → ls _aegis-output/specs/*.md
Check 2: Breakdown?    → ls _aegis-output/breakdown/*/
Check 3: Sprint?       → ls _aegis-brain/sprints/sprint-*/plan.md
Check 4: Kanban?       → ls _aegis-brain/sprints/current/kanban.md
Check 5: ISO PM.01?    → ls _aegis-output/iso-docs/PM-01*.md
```

If ANY check fails AND the task is P3+ (not a hotfix), create the missing artifacts FIRST:
- Missing spec → run /super-spec or Iron Man writes spec
- Missing breakdown → run /aegis-breakdown from spec
- Missing sprint → run /aegis-sprint plan from backlog
- Missing kanban → auto-created by /aegis-sprint plan
- Missing PM.01 → Coulson generates from sprint plan

**NEVER skip to implementation without planning artifacts.**

#### 4b-ENFORCE. Hard Stop on Missing Artifacts

If ANY of the checks above fail, Nick Fury MUST apply these hard stops:

1. CHECK: `_aegis-brain/counters.json` exists and has counters > 0
   — If not: Run /aegis-breakdown NOW. Do NOT proceed to code.

2. CHECK: `_aegis-brain/sprints/current/` has plan.md
   — If not: Run /aegis-sprint plan NOW. Do NOT proceed to code.

3. CHECK: `_aegis-output/iso-docs/` has at least PM-01 directory
   — If not: Run Coulson NOW to generate initial ISO docs.

4. CHECK: Git has at least 1 commit
   — If not: Create initial commit before any work.

If ANY check fails, Nick Fury MUST fix that check BEFORE doing anything else.
Do NOT skip to code generation. These are pipeline gates, not suggestions.
Response if user pushes: "AEGIS pipeline requires planning first. This takes ~2 min. Starting now..."

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
