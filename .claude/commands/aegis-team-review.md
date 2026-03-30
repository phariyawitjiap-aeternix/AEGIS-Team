---
name: aegis-team-review
description: "Spawn review team — Forge scans, Havoc challenges, Vigil gates"
triggers:
  en: team review, review team, spawn reviewers, /aegis-team-review
  th: ทีมรีวิว, รีวิวแบบทีม, ทีมตรวจ
---

You MUST execute ALL of the following steps NOW. Do not explain — just do it.

## Step 1: Capture Baseline

Run these commands and store the results:
- `git rev-parse HEAD` → {baseline_commit}
- `git branch --show-current` → {current_branch}
- `git diff --stat` → {changes_summary}

## Step 2: Get the Task

The user's message contains what to review. If empty, use: "$ARGUMENTS"
If still empty, default to: "Review the entire project codebase"

## Step 3: Threshold Check

Evaluate the review scope:
- If reviewing 1-2 specific files → run in **SOLO mode**: use a single Agent (Vigil) for a 4-pass review. Skip team creation. Go to Step 7.
- If reviewing 3+ files OR entire codebase OR needs multiple perspectives → run in **TEAM mode**: proceed to Step 4.

Report which mode was selected and why.

## Step 4: Create Team

Call TeamCreate:
- team_name: "aegis-review"
- description: "Review team for: [TASK]"

## Step 5: Spawn 3 Teammates (all in parallel)

Call Agent tool 3 times in a SINGLE message (parallel). All agents run in-process — user sees real-time updates and can use Shift+Down to view agent detail.

1. Agent with subagent_type="forge", team_name="aegis-review", name="forge", mode="bypassPermissions", run_in_background=true
   Prompt: "You are 🔧 Forge the scanner on team aegis-review. Read .claude/agents/forge.md for your persona. TASK: Scan and gather data for: [TASK]. Count files, detect tech stack, find TODOs/FIXMEs, check dependencies, measure complexity. Write findings to _aegis-output/scans/. SUCCESS CRITERIA: Scan report exists with file count, stack detection, dependency status, and hotspot list. When done, send findings summary to vigil via SendMessage."

2. Agent with subagent_type="havoc", team_name="aegis-review", name="havoc", mode="bypassPermissions", run_in_background=true
   Prompt: "You are 🔴 Havoc the devil's advocate on team aegis-review. Read .claude/agents/havoc.md for your persona. TASK: Challenge and stress-test: [TASK]. Find edge cases, question assumptions, identify security risks, spot missing error handling. Write challenges to _aegis-output/challenges/. SUCCESS CRITERIA: Challenge report exists with severity-ranked findings (Critical/High/Medium/Low) and specific file:line references. When done, send findings summary to vigil via SendMessage."

3. Agent with subagent_type="vigil", team_name="aegis-review", name="vigil", mode="bypassPermissions", run_in_background=true
   Prompt: "You are 🛡️ Vigil the review lead on team aegis-review. Read .claude/agents/vigil.md for your persona. Wait for findings from forge AND havoc. Then synthesize all findings into a unified 4-pass review (correctness, security, performance, maintainability). Merge findings, remove duplicates, rank by severity. Write to _aegis-output/reviews/. SUCCESS CRITERIA: Review file exists with PASS/CONDITIONAL/FAIL verdict, unified finding IDs (F1, F2...), source attribution (Forge/Havoc/Vigil), and specific remediation suggestions. Send verdict to team lead via SendMessage."

## Step 6: Report to user

```
🛡️ AEGIS Review Team Spawned!

🔧 Forge (scanner) — Scanning codebase...
🔴 Havoc (challenger) — Finding edge cases...
🛡️ Vigil (lead) — Waiting for Forge + Havoc...

Pipeline: Forge + Havoc (parallel) → Vigil (synthesize)
View agents: Shift+Down | Back to main: Shift+Up
```

## Step 7: Integration (after all agents complete)

1. Read Vigil's verdict from _aegis-output/reviews/
2. Present unified findings table:
   | ID | Source | Severity | File | Description |
3. If PASS → "Codebase looks good. N minor suggestions."
4. If CONDITIONAL → list required fixes before proceeding
5. If FAIL → list critical issues that must be addressed
6. Run `git diff {baseline_commit}` to confirm no accidental changes during review
7. Send shutdown_request to each teammate, then TeamDelete

## Failure Handling

If any agent fails to respond within a reasonable time:
1. Check agent status via team tools
2. If stuck → send a nudge message with simplified instructions
3. If errored → report error to user, proceed with available results
4. If multiple fail → abort team, report partial results, suggest retry

---

> Use **Shift+Down** to view agent activity in-process. **Shift+Up** to return to main.
