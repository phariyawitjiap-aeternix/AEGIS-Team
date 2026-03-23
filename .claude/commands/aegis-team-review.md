---
name: aegis-team-review
description: "Spawn review team — Forge scans, Havoc challenges, Vigil gates"
triggers:
  en: team review, review team, spawn reviewers
  th: ทีมรีวิว, รีวิวแบบทีม
---

# /aegis-team-review

Spawn a review team using Claude Code's **TeamCreate + Agent Teams**.

Each agent runs in its own tmux pane. Forge + Havoc work in parallel, then Vigil synthesizes.

## Instructions

### Step 1: Determine the target

Look at the user's message for what to review. If no target, review entire project source code.

### Step 2: Create the team

Use **TeamCreate**:
```
team_name: "aegis-review"
description: "Review team: Forge scans + Havoc challenges → Vigil synthesizes. Target: [TARGET]"
```

### Step 3: Spawn teammates

**Spawn Forge (Scanner):**
```
Agent(
  subagent_type: "forge",
  team_name: "aegis-review",
  name: "forge",
  prompt: "You are Forge, the scanner. Scan the codebase: [TARGET]. Gather file count, dependency health, TODO/FIXME count, test coverage, complexity hotspots. Write scan report to _aegis-output/scans/. When done, mark task complete.",
  run_in_background: true
)
```

**Spawn Havoc (Challenger):**
```
Agent(
  subagent_type: "havoc",
  team_name: "aegis-review",
  name: "havoc",
  prompt: "You are Havoc, the devil's advocate. Adversarial review of: [TARGET]. Challenge architecture assumptions, find security surface, test edge cases, question design decisions. Write challenge report to _aegis-output/challenges/. When done, mark task complete.",
  run_in_background: true
)
```

**Spawn Vigil (Lead Reviewer):**
```
Agent(
  subagent_type: "vigil",
  team_name: "aegis-review",
  name: "vigil",
  prompt: "You are Vigil, the lead reviewer. Wait for Forge and Havoc to finish their reports in _aegis-output/scans/ and _aegis-output/challenges/. Synthesize into unified review with critical findings, warnings, suggestions. Issue Quality Gate: PASS/CONDITIONAL/FAIL. Write to _aegis-output/reviews/.",
  run_in_background: true
)
```

### Step 4: Monitor, report, and shutdown

Same as aegis-team-build — monitor via automatic messages, report results, then shutdown + TeamDelete.

## Team Composition

| Agent | Role | Model | tmux Pane |
|-------|------|-------|-----------|
| 🔧 Forge | Scanner — gathers data | haiku | Own pane |
| 🔴 Havoc | Challenger — finds weaknesses | opus | Own pane |
| 🛡️ Vigil | Lead Reviewer — synthesizes + gates | sonnet | Own pane |
