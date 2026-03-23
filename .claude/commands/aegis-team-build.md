---
name: aegis-team-build
description: "Spawn build team — Sage specs, Bolt implements, Vigil reviews"
triggers:
  en: team build, build team, spawn builders
  th: ทีมสร้าง, สร้างแบบทีม
---

You MUST execute ALL of the following steps NOW. Do not explain — just do it.

## Step 1: Get the task

The user's message contains the task. If empty, use: "$ARGUMENTS"

## Step 2: Create team NOW

Call TeamCreate right now:
- team_name: "aegis-build"
- description: "Build team for: [TASK]"

## Step 3: Spawn 3 teammates NOW (all in parallel)

Call Agent tool 3 times in a SINGLE message (parallel):

1. Agent with subagent_type="sage", team_name="aegis-build", name="sage", mode="bypassPermissions", run_in_background=true, prompt="You are 📐 Sage the architect. Read .claude/agents/sage.md for your full persona. TASK: [TASK]. Write a technical spec to _aegis-output/specs/. When done, send a message to bolt via SendMessage telling them the spec is ready."

2. Agent with subagent_type="bolt", team_name="aegis-build", name="bolt", mode="bypassPermissions", run_in_background=true, prompt="You are ⚡ Bolt the implementer. Read .claude/agents/bolt.md for your full persona. TASK: [TASK]. Wait for a message from sage with the spec. Then implement all files based on the spec. When done, send a message to vigil via SendMessage telling them to review."

3. Agent with subagent_type="vigil", team_name="aegis-build", name="vigil", mode="bypassPermissions", run_in_background=true, prompt="You are 🛡️ Vigil the reviewer. Read .claude/agents/vigil.md for your full persona. Wait for a message from bolt that implementation is done. Then do a 4-pass review (correctness, security, performance, maintainability). Write review to _aegis-output/reviews/. Send quality gate result (PASS/FAIL) to the team lead via SendMessage."

## Step 4: Report to user

Tell the user:
```
🛡️ AEGIS Build Team Spawned!

📐 Sage (opus) — Writing spec...
⚡ Bolt (sonnet) — Waiting for spec...
🛡️ Vigil (sonnet) — Waiting for review...

Agents are working in their own panes.
Messages will appear automatically when they complete.
```

## Step 5: When all done

After receiving completion messages from all 3 agents, summarize results and send shutdown_request to each, then TeamDelete.
