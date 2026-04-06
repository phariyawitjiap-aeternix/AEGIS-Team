---
name: aegis-mode
description: "Switch profile tier and/or autonomy level for the current session"
triggers:
  en: mode, switch mode, change mode, set autonomy, set profile
  th: โหมด, เปลี่ยนโหมด
---

# /aegis-mode

## Quick Reference
Profile and autonomy switcher. Parse arguments for profile (minimal|standard|full)
and/or autonomy (--autonomy L1|L2|L3|L4). Profile change loads/unloads skills per tier.
Autonomy change adjusts how independently the agent operates. Displays current state
after any change. Can be combined: `/aegis-mode full --autonomy L3`.

## Full Instructions

### Step 1: Parse Arguments
- Accept command format: `/aegis-mode [profile] [--autonomy LN]`
- Valid profiles:
  - `minimal` — Core skills only, lowest context cost
  - `standard` — Core + common skills, balanced
  - `full` — All skills loaded, highest capability but highest context cost
- Valid autonomy levels:
  - `L1` — Supervised
  - `L2` — Guided
  - `L3` — Autonomous
  - `L4` — Full Auto
- Either or both can be specified.
- If no arguments: just display current state.

### Step 2: Profile Change (if requested)
- **Minimal Profile:**
  - Active agents: Captain America only
  - Skills: basic file operations, git, search
  - Context cost: ~5%
  - Use when: simple tasks, low context budget, quick fixes
  - Report:
    ```
    Switched to MINIMAL profile — 1 agent, core skills only
    Active: 🧭 Captain America
    Context saved: ~15-20% vs full profile
    ```

- **Standard Profile:**
  - Active agents: Captain America, Beast, Black Panther
  - Skills: all minimal + code review, testing, analysis
  - Context cost: ~10%
  - Use when: regular development work, code reviews
  - Report:
    ```
    Switched to STANDARD profile — 3 agents, common skills
    Active: 🧭 Captain America, 🔨 Beast, 🛡️ Black Panther
    ```

- **Full Profile:**
  - Active agents: All (Captain America, Beast, Iron Man, Black Panther, Songbird, Spider-Man, Loki)
  - Skills: everything available
  - Context cost: ~15-20%
  - Use when: major analysis, team operations, full pipeline
  - Report:
    ```
    Switched to FULL profile — 7 agents, all skills
    Active: 🧭 Captain America, 🔨 Beast, 📖 Iron Man, 🛡️ Black Panther, 🎨 Songbird, ⚡ Spider-Man, 💥 Loki
    ⚠️ High context cost — monitor with /aegis-context
    ```

### Step 3: Autonomy Change (if requested)
- **L1 — Supervised:**
  - Ask before every significant action.
  - Show plan before executing.
  - Wait for user approval at each step.
  - Best for: new projects, critical operations, learning the codebase.
  - Report: "Autonomy set to L1 — Supervised. I'll ask before every action."

- **L2 — Guided:**
  - Execute known/safe patterns without asking.
  - Ask for novel decisions or risky operations.
  - Show summary after completing a batch of actions.
  - Best for: regular development, familiar codebases.
  - Report: "Autonomy set to L2 — Guided. I'll execute known patterns, ask for novel decisions."

- **L3 — Autonomous:**
  - Execute freely based on the task.
  - Report after completion, not before.
  - Only ask when genuinely blocked or when multiple valid paths exist.
  - Best for: well-defined tasks, experienced users.
  - Report: "Autonomy set to L3 — Autonomous. I'll execute freely and report results."

- **L4 — Full Auto:**
  - Execute everything without asking.
  - Only report errors or unexpected situations.
  - Chain multiple operations without confirmation.
  - Best for: automated pipelines, batch operations.
  - Report: "Autonomy set to L4 — Full Auto. I'll only stop for errors."
  - ⚠️ Warning: "L4 is powerful but risky. Destructive operations will still prompt."

### Step 4: Display Current State
- Always show the current configuration after any change:
  ```
  ┌─ AEGIS Mode ─────────────────────────────────┐
  │ Profile:   [minimal|standard|full]            │
  │ Autonomy:  L[N] — [description]               │
  │ Agents:    [N] active                          │
  │ Context:   ~[X]% used for mode config          │
  └───────────────────────────────────────────────┘
  ```

### Step 5: Log Change
- Append to `_aegis-brain/logs/activity.log`:
  ```
  [YYYY-MM-DD HH:MM] MODE_CHANGE | profile=[new] | autonomy=L[N]
  ```
