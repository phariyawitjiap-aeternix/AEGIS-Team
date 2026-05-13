# Sprint v15-06 — Close

**Status**: CLOSED 2026-05-13
**Velocity**: 2/2 pt

## Delivered

1. `/aegis-start` Step 4 is now **transparent** — it announces "Nick Fury: ONLINE" and starts; the user does NOT see "loop substrate selection", `/goal` text, or subagent spawn syntax. Internal details moved to `.claude/references/aegis-start-loop-substrate.md` for agents to read.

2. **Command audience model** documented in `.claude/references/command-audience.md`:
   - **User commands (5)**: /aegis-start, /aegis-status, /aegis-mode, /aegis-handoff, /aegis-upgrade
   - **Team commands (11)**: /aegis-sprint, /aegis-breakdown, /aegis-pipeline, /aegis-team, /aegis-verify, /aegis-deploy, /aegis-retro, /aegis-memory, /aegis-linear, /aegis-goal, /aegis-decisions
   - 16 commands total; only 5 should ever surface to a human.

3. `CLAUDE.md` Quick Commands table restructured to make the split explicit + link to the new ref doc.

## Principle stated

> The human is the **principal**; the agent team is the **operator**. AEGIS commands are operator tools. Putting them in front of the principal inverts the relationship.

## Re-evaluation

Re-visit when adding any new command:
- Does it belong on the user surface (Identity / Irreversible / External / Approval gate) or in the team surface (everything else)?
- Default answer for a new command: **team surface**. Only promote to user when there's a clear principal-side need.
