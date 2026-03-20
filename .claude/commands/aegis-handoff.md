---
name: aegis-handoff
description: "Create session handoff brief for the next session to pick up seamlessly"
triggers:
  en: handoff, hand off, transfer session, pass the baton
  th: ส่งต่อ, handoff, ส่งงาน
---

# /aegis-handoff

## Quick Reference
Creates a structured handoff document for the next AEGIS session. Reads the current
session's retro, summarizes completed and pending tasks, lists blockers, recommends
what to do first next session, saves to _aegis-brain/handoffs/, and prints a copyable
handoff brief. Run this after /aegis-retro or as a standalone end-of-session command.

## Full Instructions

### Step 1: Read Current Session's Retro
- Check `_aegis-brain/retrospectives/` for today's most recent retro file.
- If no retro exists, gather information directly:
  - Check `git log --oneline` for recent commits.
  - Check `_aegis-brain/logs/activity.log` for session activity.
- If retro exists, extract: summary, friction points, lessons.

### Step 2: Summarize Completed Tasks
- List everything that was finished this session.
- Be specific: include file paths, feature names, PR numbers.
- Format:
  ```markdown
  ## Completed
  - [x] Implemented auth module → `src/auth/`
  - [x] Fixed #42 pagination bug
  - [x] Added unit tests for user service (12 tests, all passing)
  ```

### Step 3: Summarize Pending Tasks
- List everything started but not finished.
- Include enough context that the next session can pick up without re-reading code.
- For each pending item, note:
  - What was done so far
  - What remains
  - Where the relevant code/files are
- Format:
  ```markdown
  ## Pending
  - [ ] Rate limiting middleware — skeleton created at `src/middleware/ratelimit.ts`,
        needs: Redis integration, config loading, tests
  - [ ] API documentation — Swagger annotations started for /auth endpoints,
        remaining: /users, /projects endpoints
  ```

### Step 4: List Blockers
- Anything preventing progress that the next session needs to know about.
- Types of blockers:
  - **Technical**: dependency issues, failing CI, environment problems
  - **Decision**: needs user input, architecture choice pending
  - **External**: waiting on API access, third-party response, PR review
- If no blockers, state: "No blockers identified."

### Step 5: Recommend Next Session's First Action
- Based on pending tasks and blockers, suggest what to tackle first.
- Consider:
  - What has the highest priority?
  - What would unblock the most other work?
  - What is freshest in context (easiest to resume)?
- Format:
  ```markdown
  ## Recommended First Action
  **Continue rate limiting middleware** — the skeleton is in place and Redis
  config patterns are already established in `src/config/`. This would unblock
  the API hardening epic. Start by reading `src/middleware/ratelimit.ts` and
  `src/config/redis.ts`.
  ```

### Step 6: Save Handoff File
- Save to `_aegis-brain/handoffs/YYYY-MM-DD_HH-MM.md`
- Create directory if needed.
- Full format:
  ```markdown
  ---
  date: YYYY-MM-DD HH:MM
  from_session: [session start time]
  autonomy_level: L[N]
  ---
  # Session Handoff — [date]
  
  ## Completed
  [from step 2]
  
  ## Pending
  [from step 3]
  
  ## Blockers
  [from step 4]
  
  ## Recommended First Action
  [from step 5]
  
  ## Context Notes
  - Autonomy was at L[N]
  - Context usage was [X]% at session end
  - [Any other relevant session state]
  ```

### Step 7: Print Handoff Brief
- Display a compact, copyable version for the user:
  ```
  ╔══════════════════════════════════════════════════╗
  ║  AEGIS Handoff Brief                            ║
  ╠══════════════════════════════════════════════════╣
  ║  Done: [count] tasks completed                  ║
  ║  Pending: [count] tasks remaining               ║
  ║  Blockers: [count or "none"]                    ║
  ║                                                 ║
  ║  → Next: [recommended first action, 1 line]     ║
  ║                                                 ║
  ║  Saved: _aegis-brain/handoffs/[filename]        ║
  ╚══════════════════════════════════════════════════╝
  ```
- Inform the user: "Next session, run /aegis-start to load this handoff automatically."
