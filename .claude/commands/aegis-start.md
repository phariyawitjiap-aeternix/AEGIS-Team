---
name: aegis-start
description: "Initialize AEGIS session — load brain, check context, display dashboard"
triggers:
  en: start session, begin, init, start work
  th: เริ่ม session, เริ่มงาน
---

# /aegis-start

## Quick Reference
Initialize a new AEGIS working session. Checks context budget, loads project identity
from resonance files, reads recent learnings, checks for pending items from last session,
displays a session dashboard with project name/context%/pending tasks/available agents,
sets autonomy level (default L1), and logs session start. This is always the first
command to run when beginning work.

## Full Instructions

### Step 1: Check Context Budget
- Estimate current context window usage as a percentage of the model's limit.
- If context usage is already >20%, display a warning:
  ```
  ⚠️ Context budget is at [X]% before session even started.
  Consider running /compact or starting a fresh conversation.
  ```
- Record the context percentage for the dashboard.

### Step 2: Load Project Identity
- Read all files in `_aegis-brain/resonance/` directory.
- These files define the project's identity, principles, and architectural decisions.
- If the directory is empty or missing, note: "No resonance files found — this may be a new project."
- Extract: project name, core principles, key decisions.

### Step 3: Load Recent Learnings
- List files in `_aegis-brain/learnings/` sorted by date (newest first).
- Read the latest 3 files.
- Summarize each learning in one line for the dashboard.
- If fewer than 3 exist, load whatever is available.

### Step 4: Check Pending Items
- Read the latest file(s) in `_aegis-brain/logs/` (especially `activity.log`).
- Look for the last session's end entry and any items marked as "PENDING" or "TODO".
- Also check `_aegis-brain/handoffs/` for the most recent handoff file.
- Compile a list of pending/unfinished tasks.

### Step 5: Display Session Dashboard
Format and display:
```
╔══════════════════════════════════════════════════════╗
║  AEGIS v6 — Session Start                           ║
╠══════════════════════════════════════════════════════╣
║  Project:    [project name from resonance]           ║
║  Date:       [current date/time]                     ║
║  Context:    [X]% used [traffic light emoji]         ║
║  Autonomy:   L[N] — [description]                    ║
╠══════════════════════════════════════════════════════╣
║  PENDING TASKS                                       ║
║  • [task 1 from last session]                        ║
║  • [task 2 from last session]                        ║
╠══════════════════════════════════════════════════════╣
║  RECENT LEARNINGS                                    ║
║  • [learning 1 summary]                              ║
║  • [learning 2 summary]                              ║
║  • [learning 3 summary]                              ║
╠══════════════════════════════════════════════════════╣
║  AVAILABLE AGENTS                                    ║
║  🧭 Navi (Lead/opus)     📐 Sage (Architect/opus)   ║
║  ⚡ Bolt (Implement/son) 🛡️ Vigil (Review/sonnet)   ║
║  🔴 Havoc (Adversarial)  🔧 Forge (Research/haiku)  ║
║  🖌️ Pixel (UX/sonnet)    🎨 Muse (Content/haiku)    ║
╚══════════════════════════════════════════════════════╝
```

### Step 6: Set Autonomy Level
- Check `_aegis-brain/logs/activity.log` for last session's autonomy level.
- If found, restore it. If not, default to L1.
- Autonomy levels:
  - **L1 — Supervised**: Ask before every action. Default for new sessions.
  - **L2 — Guided**: Execute known patterns, ask for novel decisions.
  - **L3 — Autonomous**: Execute freely, report after completion.
  - **L4 — Full Auto**: Execute everything, only report errors.
- Announce: "Autonomy set to L[N] — [description]"

### Step 7: Log Session Start
- Append to `_aegis-brain/logs/activity.log`:
  ```
  [YYYY-MM-DD HH:MM] SESSION_START | autonomy=L[N] | context=[X]% | pending=[count]
  ```
- Create the log file and directories if they don't exist.

### Error Handling
- If `_aegis-brain/` doesn't exist, offer to create the directory structure.
- If any sub-step fails, continue with remaining steps and note the failure.
- Never block session start due to missing optional files.
