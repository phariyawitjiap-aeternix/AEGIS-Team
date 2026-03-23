---
name: aegis-team-review
description: "Spawn review team — Forge scans, Havoc challenges, Vigil gates"
triggers:
  en: team review, review team, spawn reviewers
  th: ทีมรีวิว, รีวิวแบบทีม
---

You MUST execute ALL of the following steps NOW. Do not explain — just do it.

## Step 1: Get the task

The user's message contains what to review. If empty, use: "$ARGUMENTS"

## Step 2: Create team NOW

Call TeamCreate right now:
- team_name: "aegis-review"
- description: "Review team for: [TASK]"

## Step 3: Spawn 3 teammates NOW (all in parallel)

Call Agent tool 3 times in a SINGLE message (parallel):

1. Agent with subagent_type="forge", team_name="aegis-review", name="forge", mode="bypassPermissions", run_in_background=true, prompt="You are 🔧 Forge the scanner. Read .claude/agents/forge.md for your persona. TASK: Scan and gather data for: [TASK]. Count files, detect stack, find TODOs, check deps. Write to _aegis-output/scans/. When done, send findings to vigil via SendMessage."

2. Agent with subagent_type="havoc", team_name="aegis-review", name="havoc", mode="bypassPermissions", run_in_background=true, prompt="You are 🔴 Havoc the devil's advocate. Read .claude/agents/havoc.md for your persona. TASK: Challenge: [TASK]. Find edge cases, question assumptions, stress-test. Write to _aegis-output/challenges/. When done, send findings to vigil via SendMessage."

3. Agent with subagent_type="vigil", team_name="aegis-review", name="vigil", mode="bypassPermissions", run_in_background=true, prompt="You are 🛡️ Vigil the reviewer lead. Read .claude/agents/vigil.md for your persona. Wait for forge and havoc findings. Synthesize into 4-pass review. Issue PASS/CONDITIONAL/FAIL. Write to _aegis-output/reviews/. Send verdict to team lead via SendMessage."

## Step 4: Report and cleanup when done

Summarize, send shutdown_request to each, then TeamDelete.
