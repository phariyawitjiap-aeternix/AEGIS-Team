---
name: aegis-team-review
description: "Spawn review team via tmux/Agent Teams — Vigil leads, Havoc challenges, Forge gathers"
triggers:
  en: team review, review team, spawn reviewers
  th: ทีมรีวิว, รีวิวแบบทีม
---

# /aegis-team-review

## Quick Reference
Spawns a review team using tmux Agent Teams. Lead: Vigil (quality guardian),
Members: Havoc (adversarial challenger), Forge (data gatherer). Forge scans for issues,
Havoc challenges assumptions, Vigil synthesizes and writes the final review report.
Falls back to sequential subagent mode if tmux is unavailable.

## Full Instructions

### Step 1: Check tmux Availability
- Run `which tmux` to check if tmux is installed.
- Run `tmux -V` to verify it works.
- If tmux is available:
  ```
  ✅ tmux available — spawning Agent Team
  ```
- If tmux is NOT available:
  ```
  ⚠️ tmux not available — falling back to subagent mode
  Review will run sequentially instead of in parallel.
  ```
  - Continue with subagent fallback (run tasks sequentially as a single agent).

### Step 2: Configure Agent Teams
- Set environment variable:
  ```bash
  export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
  ```
- Define team structure:
  - **Lead**: Vigil (🛡️ Guardian) — synthesizes, quality gates, final report
  - **Member**: Havoc (💥 Adversarial) — challenges assumptions, stress-tests findings
  - **Member**: Forge (🔨 Builder) — data gathering, issue scanning, metrics collection

### Step 3: Spawn Team
- Create tmux session: `aegis-review-[timestamp]`
- Spawn three panes/windows for each agent.
- Each agent receives:
  - Their role description and persona
  - The review target (files, directory, or PR to review)
  - Communication protocol (structured message format)

### Step 4: Task Execution

**Forge (Data Gathering):**
- Scan target codebase for:
  - Static analysis issues (if tools available)
  - TODO/FIXME/HACK markers
  - Code complexity hotspots
  - Test coverage gaps
  - Dependency vulnerabilities
- Output structured findings to shared review document.
- Signal completion to Vigil.

**Havoc (Adversarial Challenge):**
- Read Forge's findings.
- For each finding, challenge:
  - Is this really a problem or acceptable trade-off?
  - What's the worst case if this isn't fixed?
  - Are there hidden assumptions in the code?
- Add own findings:
  - Edge cases not covered
  - Failure modes not handled
  - Security assumptions not validated
- Output challenges and additional findings.
- Signal completion to Vigil.

**Vigil (Synthesis & Quality Gate):**
- Wait for both Forge and Havoc to complete.
- Review all findings:
  - Validate each finding (is it real?)
  - Prioritize by severity: Critical / High / Medium / Low
  - Group by category
  - Note where Forge and Havoc agree (high confidence) or disagree (needs discussion)
- Write final review report.

### Step 5: Agent Communication Protocol
- Agents communicate via structured messages:
  ```
  [FROM: Forge] [TO: Vigil] [TYPE: findings]
  {structured findings data}
  ```
- Message types: `findings`, `challenge`, `question`, `synthesis`, `gate-result`
- All messages logged for transparency.

### Step 6: Final Review Report
- Vigil compiles the final report:
  ```markdown
  # AEGIS Code Review — [target]
  
  ## Summary
  - Total findings: [N]
  - Critical: [N] | High: [N] | Medium: [N] | Low: [N]
  
  ## Critical Findings
  [findings requiring immediate attention]
  
  ## High Priority
  [important but not blocking]
  
  ## Medium Priority
  [should fix soon]
  
  ## Low Priority / Suggestions
  [nice to have improvements]
  
  ## Adversarial Notes
  [Havoc's key challenges and stress-test results]
  
  ## Recommendation
  [Overall: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION]
  ```
- Save report to `_aegis-output/review-YYYY-MM-DD_HH-MM.md`.
- Display summary to user.
- Clean up tmux session when done.
