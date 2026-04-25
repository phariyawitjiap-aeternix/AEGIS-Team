# Retrospective -- 2026-04-25 Session 2: Infrastructure Sweep

> Date: 2026-04-25
> Scope: 7 PRs (#67-#73), cross-project infrastructure hardening
> Session: Second session of the day (first was sprint-v10-02)
> Facilitator: Nick Fury (dispatched at session end)

## What Was Delivered

| PR | Title | Category |
|----|-------|----------|
| #67 | hook-path fix tool | Bug fix |
| #68 | install auto-normalize hook paths | Bug fix |
| #69 | /aegis-upgrade command for downstream projects | Feature |
| #70 | per-project CLAUDE_CODE_TASK_LIST_ID isolation | Bug fix |
| #71 | task-id idempotency fix + migrate all 5 AEGIS projects | Bug fix + migration |
| #72 | sprint-v10-02 RTK readiness (5pt) | Sprint delivery |
| #73 | token-profile installer (--install/--uninstall) | Feature |

Total: 7 PRs in a single session. Highest PR count in any AEGIS session to date.

## What Went Well

1. **Cross-project contamination finally killed**: The task-id saga (#70, #71)
   traced ghost tasks (e.g., "Cloud Build GitHub triggers" appearing in AEGIS-Team)
   to a shared ~/.claude/tasks/aegis-shared-tasks/ directory. Per-project isolation
   via CLAUDE_CODE_TASK_LIST_ID=aegis-tasks-<slug> eliminated the problem across
   all 5 AEGIS projects. This was a multi-session mystery that resolved in one
   focused investigation.

2. **Hook path anchoring pattern generalized**: The relative-path hook failure
   (#67, #68) affected every AEGIS project. The fix -- anchoring all hook commands
   to $CLAUDE_PROJECT_DIR in settings.json -- is now a reusable tool
   (tools/aegis-fix-hook-paths.sh) and auto-applied during /aegis-upgrade.

3. **/aegis-upgrade as force multiplier**: PR #69 created a single command to
   apply AEGIS improvements to downstream projects. Immediately used to upgrade
   4 projects (DriveWiki-MCP, RizzLab, AIKMS, Taew-Route). This is the v10
   "apply framework to real projects" mission in action.

4. **Main-agent-as-router at 7-PR scale**: Today proved that a single context
   window can drive investigation, fix, test, commit, PR, merge across 7 PRs
   without spawning sub-agents. The pattern works for infrastructure work where
   each PR is small (1-2 files) and independent.

5. **Upstream issue self-resolved**: aegis-rtk-upstream-check.sh discovered that
   rtk-ai/rtk#427 is already closed (2026-04-03). One of 5 ADOPT conditions for
   RTK met for free. Lesson: always check current state before assuming a blocker
   is still blocking.

## What Could Improve

1. **No retro until Nick Fury was explicitly invoked**: The main agent shipped 7
   PRs but did not autonomously run retro or write handoff. Session-end discipline
   requires the main agent to chain to retro without prompting. The "ask Nick"
   intervention by the user should not have been necessary.

2. **Heartbeat stale throughout**: Nick Fury heartbeat was never refreshed because
   the main agent acted as router. This means TinMan health checks, if running,
   would report the brain as unhealthy. Future: if main-agent-as-router exceeds
   3 PRs, refresh heartbeat manually.

3. **Activity log is 3778 lines**: Growing unbounded. Should consider rotation
   or archival at sprint boundaries.

## Lessons Extracted

### L1: Cross-project isolation requires explicit namespace keys
When multiple projects share a framework, any shared mutable state (task lists,
caches, lock files) MUST use per-project namespaces. Shared = contaminated.
Pattern: CLAUDE_CODE_TASK_LIST_ID=aegis-tasks-$(basename $PWD | tr A-Z a-z).

### L2: Relative paths in hook configs are a time bomb
Hook commands execute from arbitrary cwd (sub-agents, background processes).
Any hook path that is not anchored to $CLAUDE_PROJECT_DIR or an absolute path
WILL fail intermittently. Always anchor on install.

### L3: /aegis-upgrade is the distribution channel for framework fixes
When a bug fix applies to all AEGIS-powered projects, the fix goes in the
framework, then /aegis-upgrade distributes it. This is the v10 application
model working as designed.

### L4: Main-agent-as-router works for infrastructure, not for features
7 PRs worked because each was small, independent, and infrastructure-scoped.
Feature work (multi-file, interdependent, needs spec/review/QA gates) still
requires the full agent team pipeline.

### L5: Always check blocker freshness before planning around it
The upstream #427 "blocker" was already resolved. A 30-second API check saved
potentially weeks of waiting. Build freshness checks into any gate that
depends on external state.
