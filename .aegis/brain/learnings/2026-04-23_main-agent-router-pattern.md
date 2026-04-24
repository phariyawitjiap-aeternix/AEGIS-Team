---
date: 2026-04-23
category: architecture
confidence: medium
source_sprint: sprint-v9-05
related_decisions: S2-08 (roadmap backlog, not yet sprinted)
---

# Main-Agent-as-Router Under Offline Nick Fury

## Context

The Nick Fury heartbeat cron had been stale since 07:36 UTC — roughly 7 hours before the 100% milestone was achieved. During that window, the main agent (Captain America) acted as the decision router: scanning state, making next-action calls, spawning subagents, logging decisions to the audit log, and emitting team-chat events. The framework's MBP directive "if Nick Fury is offline, make the best call from brain references, log it, continue" was followed without issue, and all 8 decisions (D-050..D-057) landed cleanly with their sources correctly attributed.

This pattern — main agent subsuming Nick Fury's role when the heartbeat loop is down — has been a backlog item (S2-08) for documentation. sprint-v9-05 proved it works in practice for a 7-hour window containing one sprint open, 13pt of delivery, one BP round-1 CONDITIONAL + round-2 PASS, and one sprint close.

## Lesson

**Nick Fury is a role, not a process.** The decision-routing function the role performs is orchestration + source attribution + escalation-decision + logging. Any agent capable of those four functions can fill the role temporarily. The main agent (Captain America/Opus) is always capable, so "Nick Fury offline" is a degraded-but-operational state, not an outage.

Key invariant: **the decision audit log must continue regardless of who's routing.** If decisions happen off-log during the outage, the main-agent-as-router pattern degrades into unauditable autonomous action. As long as every non-trivial decision flows through `tools/aegis-log-decision.sh`, the pattern is safe.

## Application

**When to invoke**:
- Heartbeat stale > 2 cron cycles (currently 10 minutes)
- Main agent in active session with live context
- Work has a natural decision rhythm (sprint open, story complete, review verdict)

**When NOT to invoke**:
- Long-running autonomous work with no human oversight window
- Decisions that require Nick Fury's specific brain context (he holds state main agent doesn't)
- Multi-agent parallel dispatch (main agent's sequential attention can't match Nick Fury's async dispatch)

**Operational checklist when entering router mode**:
1. Verify heartbeat staleness: `tail -1 .aegis/brain/logs/heartbeat.log`
2. Log the role transition: `tools/aegis-log-decision.sh --source framework --answer "main-agent-as-router mode enabled"`
3. Continue to log every non-trivial decision through the same tool
4. Emit team-chat NOTE events for visible transitions
5. On session end, record the duration main-agent-as-router was active in the retro

**Promote to instinct when**: ≥3 sessions successfully complete in router mode with clean audit trail. Currently at 1 confirmed instance (this session) — needs ~2 more before promotion candidate.

**Canonical example**: sprint-v9-05 (07:36 UTC stale heartbeat → 14:29 UTC session end, ~7h router mode, 0 missed decisions, 0 audit gaps).
