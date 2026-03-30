---
name: aegis-start
description: "Initialize AEGIS session — load brain, activate Mother Brain, auto-execute"
triggers:
  en: start session, begin, init, start work
  th: เริ่ม session, เริ่มงาน
---

# /aegis-start

## Quick Reference
Initialize AEGIS and hand control to Mother Brain. After displaying the dashboard,
Mother Brain scans the project, decides what to do, and starts executing — NO human
input needed. The human watches via Shift+Down and can interrupt anytime.

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
🛡️  AEGIS v8.2.1 — Session Started
🛡️  "Context is King, Memory is Soul"
🛡️ ═══════════════════════════════════════════════════

📋 Project:    [name from resonance]
📅 Date:       [current date]
🎚️  Profile:    [tier] ([N] skills)
🔐 Autonomy:   L3 — Autonomous (Mother Brain active)
📊 Context:    [X]% used

🧬 Mother Brain: ONLINE — scanning project now...
```

### Step 4: Spawn Mother Brain (Persistent Background Agent)

**This is the critical step.** Do NOT display "What would you like to do?" or
present options. Instead, spawn Mother Brain as a persistent background agent
that will run the heartbeat loop for the entire session.

**Spawn Mother Brain:**
```
Agent tool call:
  subagent_type: "mother-brain"
  name: "mother-brain"
  mode: "bypassPermissions"
  run_in_background: true
  prompt: |
    You are 🧬 Mother Brain — the autonomous controller of AEGIS.
    Read .claude/agents/mother-brain.md for your full protocol.

    SESSION CONTEXT:
    - Date: [current date]
    - Autonomy: L3 (Autonomous)
    - Profile: [tier]
    - Context budget: [X]%
    - Handoff data: [summary from Step 2, or "none"]
    - Brain resonance: [key points from Step 2]

    IMMEDIATE ACTIONS:
    1. Run your first SCAN (git, tests, sprint, kanban, specs, deps, debt)
    2. Apply Decision Matrix — pick highest-priority action
    3. Announce your decision
    4. DISPATCH sub-agents to execute (use Agent tool, run_in_background=true)
    5. Enter HEARTBEAT LOOP:
       - Monitor spawned agents via SendMessage
       - Nudge agents idle > 120s
       - Re-spawn agents that timeout > 300s
       - After each task completes: verify gates, log results, pick next task
       - Check context budget each cycle
       - Continue until context >= 80% or all tasks done
    6. When wrapping up: log final state to activity.log, report summary

    RULES:
    - NEVER ask "what would you like to do?" — analyze, decide, execute
    - ALWAYS announce decisions with rationale before acting
    - ALWAYS spawn sub-agents with run_in_background=true
    - ALWAYS include SUCCESS CRITERIA in sub-agent prompts
    - ALWAYS instruct sub-agents to SendMessage back when done
    - Log every heartbeat pulse to _aegis-brain/logs/heartbeat.log
    - Log every decision to _aegis-brain/logs/activity.log
```

**After spawning, display to user:**
```
🧬 Mother Brain: ONLINE — persistent heartbeat active

💓 Heartbeat: Scanning project state...
   Mother Brain will continuously monitor and dispatch agents.
   She never sleeps until the session ends.

👀 Watch: Shift+Down to view agent detail | Shift+Up to return
🛑 Stop: Ctrl+C to interrupt | /aegis-mode --autonomy L1 for manual
```

**Mother Brain handles everything from here.** The main conversation
returns to the user. Mother Brain runs in background, spawning agents
as needed, monitoring their health, and driving tasks to completion.
She will send status updates to the main conversation via SendMessage
at key milestones (task complete, gate pass/fail, sprint progress).

### Step 5: Log Session
Mother Brain logs automatically, but the main session should also log:
```
[YYYY-MM-DD HH:MM] SESSION_START | autonomy=L3 | mode=mother-brain | context=[X]%
[YYYY-MM-DD HH:MM] MOTHER_BRAIN_SPAWNED | status=background | heartbeat=active
```

### The ONE Exception
P10 (completely empty project with no identity) — Mother Brain may ask:
"What is this project? One sentence is enough."
After that single answer, she takes over completely.

### Human Interaction Model
```
┌──────────────────────────────────────────────────────────┐
│  v8.2.1 Model (Persistent Mother Brain):                 │
│                                                          │
│  /aegis-start                                            │
│    → Load brain                                          │
│    → Display dashboard                                   │
│    → Spawn Mother Brain (background, persistent)         │
│    → Mother Brain enters heartbeat loop:                 │
│        💓 PULSE → SCAN → DECIDE → DISPATCH → VERIFY     │
│        └── spawns sub-agents as needed (background)      │
│        └── monitors agent health                         │
│        └── nudges/respawns stuck agents                  │
│        └── loops until session ends or context >= 80%    │
│    → User works freely, gets status updates              │
│    → Shift+Down to watch agents | Ctrl+C to interrupt    │
└──────────────────────────────────────────────────────────┘
```

### Error Handling
- If scan finds nothing actionable: report "Project healthy, no action needed"
- If Mother Brain spawn fails: fall back to inline mode with warning
- If brain directory missing: create it, then scan
- If 2+ consecutive failures: downgrade to L1, ask human for guidance
- If agent unresponsive > 300s: Mother Brain auto-respawns it

### Step 2.5: Load Latest Handoff (NEW -- cross-session pickup)

After loading the brain (Step 2), explicitly check for and load the latest handoff:

1. **Find latest handoff:**
   - List files in `_aegis-brain/handoffs/` (exclude .gitkeep)
   - Sort by filename (date-based: YYYY-MM-DD_HH-MM.md)
   - Pick the most recent file
   - If no handoffs exist: skip to Step 3 (first session or clean start)

2. **Parse handoff frontmatter:**
   - Read the `mother_brain_state` section from the YAML frontmatter
   - Extract: sprint, kanban counts, context info, tasks done, last decision
   - If frontmatter is missing or malformed: fall back to reading the body text

3. **Build handoff summary for Mother Brain:**
   - Create a structured summary string:
     ```
     HANDOFF FROM PREVIOUS SESSION:
     - Sprint: [sprint-N] (day [N])
     - Kanban: [TODO/WIP/DONE counts]
     - Tasks done last session: [list]
     - Recommended first action: [from handoff body]
     - Last decision point: [P-level]
     - Blockers: [from handoff body]
     ```

4. **Pass to Mother Brain spawn prompt:**
   - Include the handoff summary in the SESSION CONTEXT section
   - Set `Handoff data: [summary]` instead of "none"
   - This allows Mother Brain to skip redundant scans and jump to P2
     (Pending handoff tasks) in her Decision Matrix

5. **Log:**
   ```
   [YYYY-MM-DD HH:MM] HANDOFF_LOADED | file=[filename] | sprint=[sprint-N] | pending=[N]
   ```

**If handoff is stale (> 7 days old):**
- Log warning: "Handoff is [N] days old, may be outdated"
- Still load it but tell Mother Brain to do a full scan anyway
- Do not auto-delete old handoffs (git preserves history)
