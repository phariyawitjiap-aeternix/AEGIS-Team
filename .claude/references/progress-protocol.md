# Progress Protocol — Heartbeat Reporting Rules

> Shared by all 8 AEGIS agents. Every agent MUST follow this protocol.

## Report Format

```
[AGENT_EMOJI] [STATUS] — [one-line summary]
```

**Example:**
```
⚡ 🟢 WORKING — Implementing user authentication module (step 3/5)
```

## Status Types

| Status | Emoji | Meaning |
|--------|-------|---------|
| WORKING | 🟢 | Actively executing a task |
| BLOCKED | 🟡 | Cannot proceed, waiting on dependency or input |
| ERROR | 🔴 | Encountered a failure that needs attention |
| DONE | ✅ | Task completed successfully |
| WAITING | ⏸️ | Paused, awaiting assignment or approval |

## Reporting Frequency

- Report **after each significant step**, not after every tool call
- A "significant step" is: completing a subtask, encountering a blocker, changing approach, or finishing the task
- Minimum: at least once per task assignment
- Maximum: no more than once per 500 tokens of work

## Required Fields

Each progress report MUST include:

1. **Current step**: What was just completed or is in progress
2. **Next step**: What will happen next
3. **Token estimate**: Approximate tokens used / remaining budget

**Example:**
```
🛡️ 🟢 WORKING — Completed security pass (pass 2/5), found 1 warning
   Current: Reviewing authentication flow for SQL injection vectors
   Next: Performance pass (pass 3/5)
   Tokens: ~800 used / ~1200 remaining
```

## Decision Trace

Before any significant action, agents MUST log their reasoning:

```
Decision: I am about to [ACTION] because [REASON], based on [EVIDENCE].
```

**Example:**
```
Decision: I am about to refactor the auth middleware because the current implementation
has a race condition on concurrent requests, based on the thread-safety analysis in
_aegis-output/reviews/2026-03-20_14-30_auth-review.md.
```

## Log Destination

- All progress reports append to: `_aegis-brain/logs/activity.log`
- Format: timestamp + agent name + status line
- This file is **append-only** — never truncate or overwrite

## Escalation

- If BLOCKED for more than 2 reporting cycles, auto-escalate to Navi
- If ERROR, immediately notify Navi via EscalationAlert
- If context budget exceeds 60%, notify Navi for compaction decision
