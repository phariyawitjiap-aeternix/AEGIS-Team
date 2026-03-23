---
name: aegis-team-build
description: "Spawn build team — Sage specs, Bolt implements, Vigil reviews"
triggers:
  en: team build, build team, spawn builders
  th: ทีมสร้าง, สร้างแบบทีม
---

# /aegis-team-build

Spawn a build team using Claude Code's **TeamCreate + Agent Teams**.

Each agent runs in its own tmux pane. They coordinate via shared task list and messages.

## Instructions

### Step 1: Determine the task

Look at the user's message for what they want built. If no task specified, ask: "What should the build team work on?"

### Step 2: Create the team

Use **TeamCreate**:
```
team_name: "aegis-build"
description: "Build team: Sage specs → Bolt implements → Vigil reviews. Task: [TASK]"
```

### Step 3: Spawn teammates

Use the **Agent tool** to spawn each teammate. Each gets its own tmux pane.

**Spawn Sage (Architect):**
```
Agent(
  subagent_type: "sage",
  team_name: "aegis-build",
  name: "sage",
  prompt: "You are Sage, the architect. Your task: [TASK]. Write a technical spec covering architecture, data model, and file structure. Write output to _aegis-output/specs/. When done, mark your task complete and notify bolt to start implementing.",
  run_in_background: true
)
```

**Spawn Bolt (Implementer):**
```
Agent(
  subagent_type: "bolt",
  team_name: "aegis-build",
  name: "bolt",
  prompt: "You are Bolt, the implementer. Your task: [TASK]. Wait for Sage to finish the spec in _aegis-output/specs/, then implement all files. When done, mark your task complete and notify vigil to review.",
  run_in_background: true
)
```

**Spawn Vigil (Reviewer):**
```
Agent(
  subagent_type: "vigil",
  team_name: "aegis-build",
  name: "vigil",
  prompt: "You are Vigil, the reviewer. Wait for Bolt to finish implementation. Then review all created files with 4-pass review: correctness, security, performance, maintainability. Write review to _aegis-output/reviews/. Issue quality gate: PASS/CONDITIONAL/FAIL.",
  run_in_background: true
)
```

### Step 4: Monitor and report

The team lead (you) monitors progress via automatic message delivery from teammates. When all agents report done:

```
🛡️ Build Team Complete!

📐 Sage: [spec summary]
⚡ Bolt: [implementation summary]
🛡️ Vigil: [quality gate result]
```

### Step 5: Shutdown team

When work is complete, send shutdown to all teammates:
```
SendMessage(to: "sage", message: {type: "shutdown_request", reason: "Build complete"})
SendMessage(to: "bolt", message: {type: "shutdown_request", reason: "Build complete"})
SendMessage(to: "vigil", message: {type: "shutdown_request", reason: "Build complete"})
```

Then use **TeamDelete** to clean up.

## Team Composition

| Agent | Role | Model | tmux Pane |
|-------|------|-------|-----------|
| 📐 Sage | Architect — writes spec | opus | Own pane |
| ⚡ Bolt | Implementer — builds from spec | sonnet | Own pane |
| 🛡️ Vigil | Reviewer — quality gates | sonnet | Own pane |
