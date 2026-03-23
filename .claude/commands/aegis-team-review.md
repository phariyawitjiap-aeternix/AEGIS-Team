---
name: aegis-team-review
description: "Spawn review team — Forge scans, Havoc challenges, Vigil gates"
triggers:
  en: team review, review team, spawn reviewers
  th: ทีมรีวิว, รีวิวแบบทีม
---

# /aegis-team-review

Spawn a review team using Claude Code's **built-in Agent tool**.

## Instructions

When this command is triggered:

### Step 1: Determine the target

Look at the user's message for what to review:
- "ทีมรีวิว — review src/ directory" → target is "src/"
- "/aegis-team-review" with no target → review entire project source code

### Step 2: Spawn agents using the Agent tool

Launch Phase 1 agents in **parallel**, then Phase 2 to synthesize:

**Phase 1a: Scan (🔧 Forge) — run in background**

Use the Agent tool with `run_in_background: true`:
```
subagent_type: use the agent defined in .claude/agents/forge.md
prompt: |
  You are Forge, the scanner and researcher.
  Scan the codebase: [TARGET]

  Gather:
  1. File count, line count, language breakdown
  2. Dependency health (outdated? vulnerable?)
  3. TODO/FIXME count and locations
  4. Test coverage info (if tests exist)
  5. Code complexity hotspots

  Write scan report to: _aegis-output/scans/
```

**Phase 1b: Challenge (🔴 Havoc) — run in background**

Use the Agent tool with `run_in_background: true`:
```
subagent_type: use the agent defined in .claude/agents/havoc.md
prompt: |
  You are Havoc, the devil's advocate.
  Adversarial review of: [TARGET]

  Challenge:
  1. Architecture assumptions — what could break at scale?
  2. Security surface — injection, auth bypass, data leaks?
  3. Edge cases — empty inputs, concurrent access, failure modes?
  4. Design decisions — are there better alternatives?

  Write challenge report to: _aegis-output/challenges/
```

Wait for BOTH Forge and Havoc to complete.

**Phase 2: Synthesis (🛡️ Vigil)**

Use the Agent tool:
```
subagent_type: use the agent defined in .claude/agents/vigil.md
prompt: |
  You are Vigil, the lead reviewer.
  Read the reports from Forge (_aegis-output/scans/) and Havoc (_aegis-output/challenges/).

  Synthesize into a unified review:
  1. Critical findings (must fix before release)
  2. Warnings (should fix)
  3. Suggestions (nice to have)

  Issue Quality Gate: PASS / CONDITIONAL / FAIL
  Write final review to: _aegis-output/reviews/
```

### Step 3: Report results

```
🛡️ Review Team Complete!

🔧 Forge: [scan summary — file count, deps, TODOs]
🔴 Havoc: [challenge summary — weaknesses found]
🛡️ Vigil: Quality Gate [PASS/CONDITIONAL/FAIL]
         [N] critical, [N] warnings, [N] suggestions

Output: _aegis-output/reviews/
```
